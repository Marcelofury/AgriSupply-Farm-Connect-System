# Fix Profile Image Upload - Storage Buckets Setup

## Problem
Profile image upload fails with "Failed to upload image" error because **Supabase Storage buckets don't exist**.

## Solution
You need to create the storage buckets in Supabase. Follow these steps:

### Option 1: Run SQL Script (Recommended - 2 minutes)

1. **Open Supabase Dashboard**
   - Go to https://supabase.com/dashboard
   - Select your AgriSupply project

2. **Open SQL Editor**
   - Click "SQL Editor" in the left sidebar
   - Click "New query"

3. **Run the Setup Script**
   - Copy the contents of `backend/database/setup_storage.sql`
   - Paste into the SQL editor
   - Click **RUN** button

4. **Verify Creation**
   - Click "Storage" in the left sidebar
   - You should see 5 buckets:
     - ✓ profile-photos (public)
     - ✓ product-images (public)
     - ✓ review-images (public)
     - ✓ ai-images (private)
     - ✓ documents (private)

### Option 2: Manual Creation via Dashboard (5 minutes)

1. **Open Supabase Dashboard**
   - Go to https://supabase.com/dashboard
   - Select your AgriSupply project

2. **Navigate to Storage**
   - Click "Storage" in the left sidebar

3. **Create Buckets**
   Click "New bucket" and create each of these:
   
   - **Bucket 1: profile-photos**
     - Name: `profile-photos`
     - Public: ✓ Yes (checked)
     - Click "Create bucket"
   
   - **Bucket 2: product-images**
     - Name: `product-images`
     - Public: ✓ Yes (checked)
     - Click "Create bucket"
   
   - **Bucket 3: review-images**
     - Name: `review-images`
     - Public: ✓ Yes (checked)
     - Click "Create bucket"
   
   - **Bucket 4: ai-images**
     - Name: `ai-images`
     - Public: ✗ No (unchecked)
     - Click "Create bucket"
   
   - **Bucket 5: documents**
     - Name: `documents`
     - Public: ✗ No (unchecked)
     - Click "Create bucket"

4. **Set Policies (Important!)**
   - Go back to SQL Editor
   - Run only the policy section from `setup_storage.sql`:
   ```sql
   -- Storage policies
   CREATE POLICY "Anyone can view public images"
       ON storage.objects FOR SELECT
       USING (bucket_id IN ('profile-photos', 'product-images', 'review-images'));

   CREATE POLICY "Authenticated users can upload"
       ON storage.objects FOR INSERT
       WITH CHECK (auth.role() = 'authenticated');

   CREATE POLICY "Users can update own files"
       ON storage.objects FOR UPDATE
       USING (auth.uid()::text = (storage.foldername(name))[1]);

   CREATE POLICY "Users can delete own files"
       ON storage.objects FOR DELETE
       USING (auth.uid()::text = (storage.foldername(name))[1]);
   ```

## What Was Fixed in Code

1. **Mobile App (`storage_service.dart`)**
   - Changed product bucket from `products` → `product-images` (to match schema)

2. **Created Setup Script (`setup_storage.sql`)**
   - ID-empotent script to create all storage buckets
   - Sets up proper RLS policies for authenticated uploads
   - Can be run multiple times safely

## Test After Setup

1. **Rebuild the mobile app:**
   ```bash
   cd mobile
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Test Profile Image Upload:**
   - Login as farmer or buyer
   - Go to Profile → Edit Profile
   - Tap camera icon on profile photo
   - Select an image
   - Should upload successfully! ✅

## Why This Happened

The storage bucket creation was commented out in `schema.sql` and was never executed during initial setup. Images are stored in **Supabase Storage** (separate from database), not in database tables.

## Image Storage Architecture

- **Profile Photos** → `profile-photos` bucket → URL saved in `users.photo_url`
- **Product Images** → `product-images` bucket → URLs saved in `products.images` array
- **Review Images** → `review-images` bucket → URLs saved in `reviews` table
- **Database** stores only the **public URLs**, not the actual image data
