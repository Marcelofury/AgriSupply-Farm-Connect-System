# AgriSupply Auth & Database Fixes

## Issues Fixed

### 1. **Sign Up Database Error** ✅
**Problem:** Sign up was failing with database table errors because:
- Users table had RLS enabled but no INSERT policy
- UserModel was trying to read `user_type` field but database uses `role`
- No automatic user profile creation on auth signup

**Solutions Applied:**
1. Added INSERT policy to users table: `"Users can insert own profile during signup"`
2. Fixed UserModel to read `role` field from database (with fallback to `user_type`)
3. Created automatic trigger `handle_new_user()` that creates user profile when auth.users is inserted
4. Updated auth service to rely on trigger instead of manual profile creation

### 2. **Database Schema Updates** ✅
- Added `handle_new_user()` function with SECURITY DEFINER
- Added `on_auth_user_created` trigger on auth.users table
- Updated RLS policies for proper access control

### 3. **Mobile App Updates** ✅
- Fixed UserModel.fromJson() to read `role` field
- Fixed UserModel.toJson() to write `role` field
- Updated auth_service.dart signup flow
- Improved error handling

## Database Migration Required

**IMPORTANT:** You must run the migration script in your Supabase SQL Editor:

```sql
-- File: backend/database/migration_fix_auth.sql
-- Copy and paste this into Supabase SQL Editor
```

### Steps to Apply Migration:

1. **Open Supabase Dashboard**
   - Go to https://app.supabase.com
   - Select your project: `ugrraxmjvbujpdzfsvzt`

2. **Run Migration**
   - Click "SQL Editor" in left sidebar
   - Click "New query"
   - Copy contents of `backend/database/migration_fix_auth.sql`
   - Paste into editor
   - Click "Run" button

3. **Verify Setup**
   - Query should return "Setup complete!"
   - Check that trigger exists: 
     ```sql
     SELECT * FROM information_schema.triggers 
     WHERE trigger_name = 'on_auth_user_created';
     ```

## Testing Sign Up

After running the migration, test signup:

1. **Open the app** on your phone
2. **Click "Sign Up"**
3. **Fill in the form:**
   - Email: test@example.com
   - Password: password123
   - Full Name: Test User
   - Phone: +256700000000
   - Select user type (Farmer/Buyer)
   
4. **Expected Result:**
   - Account created successfully
   - User profile auto-created via trigger
   - Redirected to home screen

## Other Potential Issues Analyzed

### ✅ **Sign In** - Should work correctly
- Uses standard Supabase auth
- Fetches profile after authentication
- Error handling in place

### ✅ **Phone OTP** - Should work if configured
- Requires Supabase phone auth setup
- SMS provider must be configured in Supabase dashboard

### ⚠️ **Google Sign In** - May need configuration
- Requires Google OAuth setup in Supabase
- Android SHA-1 fingerprint must be added
- Check: Supabase Dashboard > Authentication > Providers > Google

### ⚠️ **API Endpoint** - Currently uses localhost
- `apiBaseUrl = 'http://localhost:3000/api'` 
- Update to your actual backend URL in production
- File: `lib/config/app_config.dart`

### ⚠️ **Backend Server** - Must be running
- Ensure backend is deployed and accessible
- Update `app_config.dart` with production URL

## New APK Build

✅ **APK rebuilt with fixes:**
- Location: `build/app/outputs/flutter-apk/app-release.apk`
- Size: 55.8MB
- Includes all auth fixes

## Installation Instructions

1. **Install new APK** on your phone
2. **Run database migration** in Supabase (CRITICAL!)
3. **Test signup** with the steps above
4. **Test signin** with existing account

## Troubleshooting

### If signup still fails:

1. **Check Migration Applied:**
   ```sql
   SELECT * FROM information_schema.triggers 
   WHERE trigger_name = 'on_auth_user_created';
   ```
   Should return 1 row

2. **Check RLS Policy:**
   ```sql
   SELECT * FROM pg_policies 
   WHERE tablename = 'users' AND policyname LIKE '%insert%';
   ```
   Should show the INSERT policy

3. **Check Supabase Logs:**
   - Go to Supabase Dashboard > Logs
   - Filter by "Database" logs
   - Look for auth-related errors

4. **Test in Supabase SQL Editor:**
   ```sql
   -- Simulate trigger manually
   SELECT handle_new_user();
   ```

### If sign in fails:

1. **Check user exists:**
   ```sql
   SELECT * FROM auth.users WHERE email = 'your@email.com';
   ```

2. **Check profile created:**
   ```sql
   SELECT * FROM public.users WHERE email = 'your@email.com';
   ```

3. **Verify password:**
   - Use password reset if needed

## Additional Improvements Recommended

### Security:
1. Set up proper environment variables for production
2. Update Supabase RLS policies for tighter security
3. Add rate limiting for auth endpoints

### Features:
1. Email verification flow
2. Phone number verification
3. Social login (Google, Facebook)
4. Password reset functionality

### Monitoring:
1. Set up Sentry or similar for error tracking
2. Monitor Supabase usage and quotas
3. Set up logging for authentication events

## Support

If issues persist:
1. Check Supabase dashboard logs
2. Review error messages in app
3. Verify internet connectivity
4. Ensure Supabase project is not paused
