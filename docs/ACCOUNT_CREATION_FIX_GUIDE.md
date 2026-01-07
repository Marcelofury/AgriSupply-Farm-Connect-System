# AgriSupply Account Creation Fix Guide

## Problem
Users cannot create accounts in the mobile app. The error "can't create account" appears during signup.

## Root Cause
The Supabase database triggers and Row Level Security (RLS) policies are not properly configured to allow automatic user profile creation during signup.

## Solution

### Step 1: Apply Database Migration

1. Open your Supabase project dashboard at https://app.supabase.com
2. Navigate to **SQL Editor**
3. Create a new query
4. Copy and paste the contents of `backend/database/migration_fix_auth_comprehensive.sql`
5. Click **Run** to execute the migration
6. Verify you see success messages in the results panel

### Step 2: Test the Fix

1. Stop your Flutter app if it's running (press `q` in the terminal)
2. Hot restart: Press `R` in the Flutter terminal or run:
   ```bash
   flutter run
   ```
3. Try to create a new account with test credentials
4. Check the console logs for detailed error messages (the updated code now includes debug logging)

### What the Migration Does

1. **Creates RLS Policies**: Allows authenticated and anonymous users to insert their own profiles
2. **Creates Database Trigger**: Automatically creates a user profile in the `users` table when an auth user is created
3. **Grants Permissions**: Ensures anon and authenticated users have necessary permissions
4. **Enables RLS**: Makes sure Row Level Security is properly enabled

### Debugging

If the issue persists after applying the migration, check the Flutter console for detailed logs:

```
[AuthService] Starting signup for email: test@example.com
[AuthService] Auth response: <user-id>
[AuthService] Waiting for trigger to create profile...
[AuthService] Attempting to fetch user profile...
```

Look for error messages that indicate:
- **"Failed to fetch profile"** - The trigger didn't create the profile
- **"ERROR in manual profile creation"** - RLS policies are blocking manual creation
- **"AuthException"** - Supabase auth error (duplicate email, weak password, etc.)

### Common Issues

1. **Email already exists**: Delete the test user from Supabase Authentication dashboard
2. **Weak password**: Use a password with at least 8 characters
3. **RLS blocking**: Make sure you ran the migration completely
4. **Trigger not firing**: Check Supabase logs in the dashboard

### Verify Database Setup

Run this query in Supabase SQL Editor to check if everything is set up:

```sql
-- Check if trigger exists
SELECT 
    trigger_name, 
    event_manipulation, 
    action_statement
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';

-- Check if function exists
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines
WHERE routine_name = 'handle_new_user';

-- Check RLS policies
SELECT 
    tablename,
    policyname,
    roles,
    cmd
FROM pg_policies 
WHERE tablename = 'users';
```

### Alternative: Manual Testing

If you want to test the database directly:

1. Go to Supabase Authentication dashboard
2. Click "Add user" → "Create new user"
3. Enter test email and password
4. Click "Create user"
5. Go to Table Editor → users table
6. Verify a profile row was automatically created with the same ID

## Files Modified

- `mobile/lib/services/auth_service.dart` - Added debug logging and fallback manual profile creation
- `backend/database/migration_fix_auth_comprehensive.sql` - New comprehensive migration script

## Next Steps

After fixing the signup:
1. Test with multiple user types (farmer, buyer)
2. Verify email confirmation flow if enabled
3. Check that user profiles are properly created with correct roles
4. Test signin after successful signup
