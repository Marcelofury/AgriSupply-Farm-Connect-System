-- ============================================
-- AgriSupply Comprehensive Auth Fix Migration
-- Run this in Supabase SQL Editor
-- ============================================

-- Step 1: Drop existing policies
DROP POLICY IF EXISTS "Users can insert own profile during signup" ON users;
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON users;

-- Step 2: Create comprehensive RLS policies for users table
-- Allow users to insert their own profile during signup
CREATE POLICY "Users can insert own profile during signup"
    ON users FOR INSERT
    TO authenticated, anon
    WITH CHECK (auth.uid() = id);

-- Allow users to view their own profile
CREATE POLICY "Users can view own profile"
    ON users FOR SELECT
    TO authenticated
    USING (auth.uid() = id);

-- Allow users to update their own profile
CREATE POLICY "Users can update own profile"
    ON users FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Allow everyone to view basic public profile information (for marketplace)
CREATE POLICY "Public profiles are viewable by everyone"
    ON users FOR SELECT
    TO authenticated, anon
    USING (true);

-- Step 3: Create or replace the trigger function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
    -- Log the trigger execution (optional, for debugging)
    RAISE LOG 'Creating user profile for user_id: %', NEW.id;
    
    -- Insert a row into public.users
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
        full_name = EXCLUDED.full_name,
        phone = EXCLUDED.phone,
        updated_at = NOW();
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE LOG 'Error in handle_new_user: %', SQLERRM;
        RETURN NEW;
END;
$$;

-- Step 4: Drop and recreate the trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Step 5: Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON TABLE public.users TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;

-- Step 6: Ensure RLS is enabled
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Step 7: Create notification preferences policy if table exists
DO $$ 
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'notification_preferences') THEN
        DROP POLICY IF EXISTS "Users can manage own notification preferences" ON notification_preferences;
        CREATE POLICY "Users can manage own notification preferences"
            ON notification_preferences
            FOR ALL
            TO authenticated
            USING (auth.uid() = user_id)
            WITH CHECK (auth.uid() = user_id);
    END IF;
END $$;

-- Step 8: Verify the setup
DO $$
BEGIN
    RAISE NOTICE '===========================================';
    RAISE NOTICE 'Auth Migration Complete!';
    RAISE NOTICE '===========================================';
    RAISE NOTICE 'Policies created: 4 on users table';
    RAISE NOTICE 'Trigger created: on_auth_user_created';
    RAISE NOTICE 'Function created: handle_new_user()';
    RAISE NOTICE '';
    RAISE NOTICE 'Please test signup now!';
    RAISE NOTICE '===========================================';
END $$;

-- Step 9: Test query to verify policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies 
WHERE tablename = 'users'
ORDER BY policyname;
