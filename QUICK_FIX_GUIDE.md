# 🚀 Quick Fix Guide - Profile Creation Issue

## Problem
User signup creates entries in `auth.users` but profiles aren't being created in `public.users` table.

## Root Cause
The database trigger `handle_new_user()` is blocked by RLS (Row Level Security) policy that doesn't allow `service_role` to insert profiles.

## ✅ Solution (Choose ONE method)

### Method 1: Supabase Dashboard (RECOMMENDED - Easiest)

1. **Open Supabase SQL Editor**
   - Go to: https://app.supabase.com/project/ugrraxmjvbujpdzfsvzt/sql/new

2. **Copy and Run SQL**
   - Open file: `backend/database/manual_fix.sql`
   - Copy ALL contents
   - Paste into Supabase SQL Editor
   - Click **"Run"** button

3. **Verify Success**
   - You should see: "Fix applied successfully!"
   - Check trigger info is displayed

4. **Test Signup**
   - Run your Flutter app
   - Try creating a new account
   - Profile should now be created automatically

---

### Method 2: Node.js Script (Alternative)

```bash
cd backend
node database/apply_fix.js
```

⚠️ **Note:** This requires a custom `exec_sql` function in your database. If it fails, use Method 1 instead.

---

## 🔍 Verify the Fix

### 1. Check Database
Go to: https://app.supabase.com/project/ugrraxmjvbujpdzfsvzt/editor
- Navigate to `public.users` table
- After signup, verify new row is created with matching `id` from `auth.users`

### 2. Check Logs
Go to: https://app.supabase.com/project/ugrraxmjvbujpdzfsvzt/logs/postgres-logs
- Look for: "Creating user profile for user_id:"
- Should see: "User profile created successfully"
- Should NOT see: "Error in handle_new_user"

### 3. Test in App
```bash
cd mobile
flutter run
```
- Create new account
- Login should work immediately
- Profile data should display

---

## 🛠️ What Was Changed

### 1. Updated Trigger Function (`handle_new_user`)
- Added proper error handling
- Added logging for debugging
- Changed `ON CONFLICT` from `DO NOTHING` to `DO UPDATE`
- Added `SET search_path = public, auth`

### 2. Updated RLS Policy
```sql
-- OLD (Doesn't work)
WITH CHECK (auth.uid() = id);

-- NEW (Works with triggers)
WITH CHECK (auth.uid() = id OR auth.role() = 'service_role');
```

### 3. Granted Permissions
- Ensured `service_role` has INSERT permissions
- Ensured `authenticated` users can read/update profiles

---

## 🧹 Files Updated/Removed

### ✅ Updated
- `backend/database/schema.sql` - Fixed trigger and policy

### ❌ Removed (Redundant)
- `backend/database/fix_profile_creation.sql` - Merged into schema.sql
- `backend/database/migration_fix_auth_comprehensive.sql` - Outdated

### ➕ Added
- `backend/database/manual_fix.sql` - Easy copy-paste fix
- `backend/database/apply_fix.js` - Automated fix script
- `QUICK_FIX_GUIDE.md` - This guide

---

## ❓ Troubleshooting

### Issue: "Profile fetched successfully: null"
**Solution:** The trigger isn't working. Apply the fix above.

### Issue: "Failed to create user profile. Please check database permissions"
**Solution:** RLS policy is blocking inserts. Apply the fix above.

### Issue: Profiles still not created after fix
1. Check if trigger exists:
   ```sql
   SELECT * FROM pg_trigger WHERE tgname = 'on_auth_user_created';
   ```
2. Check RLS policy:
   ```sql
   SELECT * FROM pg_policies WHERE tablename = 'users';
   ```
3. Check PostgreSQL logs in Supabase Dashboard

### Issue: Manual insert works but trigger doesn't
**Solution:** The trigger function needs `SECURITY DEFINER`. Apply the fix.

---

## 📞 Support

If you still have issues after applying the fix:
1. Check Supabase Dashboard > Logs > Postgres Logs
2. Look for error messages containing "handle_new_user"
3. Verify your Supabase project URL matches: `ugrraxmjvbujpdzfsvzt`
4. Ensure you're using the service role key in backend/.env

---

## 🎯 Summary

**Before Fix:**
- ❌ Trigger function blocked by RLS
- ❌ No error logging
- ❌ Silent failures

**After Fix:**
- ✅ Trigger bypasses RLS with `service_role`
- ✅ Detailed error logging
- ✅ Profiles created automatically
- ✅ Graceful error handling
