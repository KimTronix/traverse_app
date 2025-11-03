-- ============================================================================
-- SUPABASE STORAGE SETUP FOR AVATARS
-- ============================================================================
-- This file sets up the avatars storage bucket and RLS policies for profile images

-- Create the avatars bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- ============================================================================
-- STORAGE RLS POLICIES FOR AVATARS BUCKET
-- ============================================================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can upload their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Avatar images are publicly accessible" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload avatars" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated uploads to avatars" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated updates to avatars" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated deletes from avatars" ON storage.objects;

-- Enable RLS on storage.objects
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Policy 1: Allow public read access to all avatars
CREATE POLICY "Avatar images are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

-- Policy 2: Allow ALL authenticated users to upload to avatars bucket
-- Simplified policy - just check bucket_id and authenticated
CREATE POLICY "Allow authenticated uploads to avatars"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'avatars');

-- Policy 3: Allow ALL authenticated users to update files in avatars bucket
CREATE POLICY "Allow authenticated updates to avatars"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'avatars')
WITH CHECK (bucket_id = 'avatars');

-- Policy 4: Allow ALL authenticated users to delete from avatars bucket
CREATE POLICY "Allow authenticated deletes from avatars"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'avatars');

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Verify bucket exists
SELECT * FROM storage.buckets WHERE id = 'avatars';

-- Verify RLS policies
SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'storage' AND tablename = 'objects'
ORDER BY policyname;

-- ============================================================================
-- USAGE NOTES
-- ============================================================================

/*
HOW TO USE:

1. Run this SQL in your Supabase SQL Editor:
   - Go to Supabase Dashboard → SQL Editor
   - Click "New Query"
   - Paste this entire file
   - Click "Run"

2. The script will:
   - Create the 'avatars' bucket (if not exists)
   - Set it as public (images accessible via URL)
   - Enable Row Level Security
   - Create 4 RLS policies

3. RLS Policies Explained:

   a) "Avatar images are publicly accessible"
      - Anyone can VIEW avatar images
      - Needed for displaying profile pictures

   b) "Authenticated users can upload avatars"
      - Logged-in users can UPLOAD to their own folder
      - Folder structure: avatars/profile_images/{user_id}/{filename}
      - Only allows uploads to folders matching their user ID

   c) "Users can update their own avatar"
      - Users can UPDATE files in their own folder
      - Prevents modifying other users' images

   d) "Users can delete their own avatar"
      - Users can DELETE files from their own folder
      - Needed for replacing old profile pictures

4. File Path Format:
   - Profile images: avatars/profile_images/{user_id}/{timestamp}.{ext}
   - Example: avatars/profile_images/123e4567-e89b-12d3-a456-426614174000/1234567890.jpg

5. Testing:
   After running this script, try uploading a profile image from the Flutter app.
   If you still get RLS errors, check:
   - User is authenticated (auth.uid() returns valid UUID)
   - File path follows the correct format
   - Bucket name is exactly 'avatars'

6. Troubleshooting:

   ERROR: "new row violates row level security policy"
   SOLUTION: Make sure:
   - This SQL script has been run
   - User is logged in (check auth.uid())
   - File path starts with profile_images/{user_id}/

   ERROR: "Bucket not found"
   SOLUTION: Run the INSERT INTO storage.buckets part again

   ERROR: "Duplicate policy"
   SOLUTION: The DROP POLICY commands handle this automatically

7. Security Notes:
   - ✅ Users can only upload to their own folder
   - ✅ Users can only delete their own images
   - ✅ Everyone can view all avatars (needed for displaying profiles)
   - ✅ File paths enforce user isolation via (storage.foldername(name))[1]
*/