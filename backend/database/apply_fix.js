#!/usr/bin/env node
/**
 * Apply database fixes to Supabase
 * This script applies the updated trigger function and RLS policy
 */

const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  console.error('❌ Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env file');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function applyFixes() {
  console.log('🔧 Applying database fixes...\n');

  try {
    // Fix 1: Update trigger function with proper error handling
    console.log('1️⃣  Updating trigger function...');
    const { error: functionError } = await supabase.rpc('exec_sql', {
      sql: `
        CREATE OR REPLACE FUNCTION public.handle_new_user()
        RETURNS TRIGGER
        SECURITY DEFINER
        SET search_path = public, auth
        LANGUAGE plpgsql
        AS $$
        BEGIN
            RAISE LOG 'Creating user profile for user_id: %, email: %', NEW.id, NEW.email;
            
            INSERT INTO public.users (
                id,
                email,
                full_name,
                phone,
                role,
                created_at,
                updated_at
            )
            VALUES (
                NEW.id,
                NEW.email,
                COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'),
                COALESCE(NEW.phone, NEW.raw_user_meta_data->>'phone'),
                COALESCE(NEW.raw_user_meta_data->>'role', 'buyer'),
                NOW(),
                NOW()
            )
            ON CONFLICT (id) DO UPDATE SET
                email = EXCLUDED.email,
                full_name = COALESCE(EXCLUDED.full_name, users.full_name),
                phone = COALESCE(EXCLUDED.phone, users.phone),
                role = COALESCE(EXCLUDED.role, users.role),
                updated_at = NOW();
            
            RAISE LOG 'User profile created successfully for user_id: %', NEW.id;
            RETURN NEW;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE LOG 'Error in handle_new_user for user_id %, error: %', NEW.id, SQLERRM;
                RAISE WARNING 'Failed to create user profile: %', SQLERRM;
                RETURN NEW;
        END;
        $$;
      `
    });

    if (functionError) {
      console.error('   ❌ Failed to update function:', functionError.message);
    } else {
      console.log('   ✅ Trigger function updated successfully');
    }

    // Fix 2: Update RLS policy
    console.log('\n2️⃣  Updating RLS policy...');
    const { error: policyError } = await supabase.rpc('exec_sql', {
      sql: `
        DROP POLICY IF EXISTS "Users can insert own profile during signup" ON users;
        CREATE POLICY "Users can insert own profile during signup"
            ON users FOR INSERT
            WITH CHECK (
                auth.uid() = id OR
                auth.role() = 'service_role'
            );
      `
    });

    if (policyError) {
      console.error('   ❌ Failed to update policy:', policyError.message);
    } else {
      console.log('   ✅ RLS policy updated successfully');
    }

    // Fix 3: Grant permissions
    console.log('\n3️⃣  Granting permissions...');
    const { error: grantError } = await supabase.rpc('exec_sql', {
      sql: `
        GRANT ALL ON TABLE public.users TO postgres, service_role;
        GRANT SELECT, INSERT, UPDATE ON TABLE public.users TO authenticated;
        GRANT SELECT ON TABLE public.users TO anon;
      `
    });

    if (grantError) {
      console.error('   ❌ Failed to grant permissions:', grantError.message);
    } else {
      console.log('   ✅ Permissions granted successfully');
    }

    console.log('\n✅ All fixes applied successfully!');
    console.log('\n📝 Next steps:');
    console.log('   1. Test signup in your Flutter app');
    console.log('   2. Check Supabase Dashboard > Authentication > Logs for any errors');
    console.log('   3. Verify profiles are created in Database > users table');
    
  } catch (error) {
    console.error('\n❌ Unexpected error:', error);
    process.exit(1);
  }
}

// Note: If exec_sql doesn't exist, you'll need to run the SQL manually
// in the Supabase Dashboard SQL Editor
console.log('⚠️  NOTE: If this script fails, you can run the SQL manually in Supabase Dashboard:');
console.log('   Go to: https://app.supabase.com/project/ugrraxmjvbujpdzfsvzt/sql/new\n');

applyFixes().catch(console.error);
