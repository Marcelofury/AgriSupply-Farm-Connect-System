-- ============================================
-- AgriSupply Database Migration Script
-- Run this in Supabase SQL Editor
-- ============================================

-- 1. Add INSERT policy for users table
DROP POLICY IF EXISTS "Users can insert own profile during signup" ON users;
CREATE POLICY "Users can insert own profile during signup"
    ON users FOR INSERT
    WITH CHECK (auth.uid() = id);

-- 2. Create function to handle new user profile creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Insert a row into public.users if it doesn't exist
    INSERT INTO public.users (id, email, full_name, phone, role, created_at, updated_at)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'),
        COALESCE(NEW.phone, NEW.raw_user_meta_data->>'phone'),
        COALESCE(NEW.raw_user_meta_data->>'role', 'buyer'),
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Create trigger to automatically create user profile on auth.users insert
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 4. Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;

-- 5. Verify the setup
SELECT 
    'Setup complete!' as message,
    'Please test signup now' as next_step;
