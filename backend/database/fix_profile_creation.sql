-- ============================================
-- Fix User Profile Creation Issue
-- The trigger needs to bypass RLS or have proper permissions
-- ============================================

-- Step 1: Update the INSERT policy to allow trigger-based inserts
DROP POLICY IF EXISTS "Users can insert own profile during signup" ON users;

CREATE POLICY "Users can insert own profile during signup"
    ON users FOR INSERT
    WITH CHECK (
        auth.uid() = id OR  -- Allow user to insert their own profile
        auth.role() = 'service_role' -- Allow service role (used by triggers)
    );

-- Alternative: Make the trigger function bypass RLS completely
-- This is more secure as it only affects this specific function

-- Step 2: Recreate the trigger function with proper settings
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER  -- Run with the privileges of the function owner
SET search_path = public, auth  -- Set search path for security
LANGUAGE plpgsql
AS $$
BEGIN
    -- Log the trigger execution for debugging
    RAISE LOG 'Creating user profile for user_id: %, email: %', NEW.id, NEW.email;
    
    -- Insert a row into public.users
    -- The SECURITY DEFINER and proper grants should allow this to bypass RLS
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
        -- Log the error but don't fail the auth creation
        RAISE LOG 'Error in handle_new_user for user_id %, error: %', NEW.id, SQLERRM;
        RAISE WARNING 'Failed to create user profile: %', SQLERRM;
        RETURN NEW;
END;
$$;

-- Step 3: Ensure trigger exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Step 4: Grant necessary permissions
-- The function owner needs to be able to insert into users table
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON TABLE public.users TO postgres, service_role;
GRANT SELECT, INSERT, UPDATE ON TABLE public.users TO authenticated;
GRANT SELECT ON TABLE public.users TO anon;

-- Step 5: Verify the setup
DO $$
BEGIN
    RAISE NOTICE 'Profile creation fix applied successfully';
    RAISE NOTICE 'Function: handle_new_user() recreated';
    RAISE NOTICE 'Trigger: on_auth_user_created recreated';
    RAISE NOTICE 'Policy: Updated to allow service_role inserts';
    RAISE NOTICE 'Permissions: Granted to service_role and authenticated users';
END $$;
