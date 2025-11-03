# Profile Upload Fix - Storage RLS Setup

## Problem
You're getting this error when trying to upload a profile image:
```
StorageException: new row violates row level security policies
```

## Cause
The Supabase Storage bucket `avatars` either doesn't exist or doesn't have proper Row Level Security (RLS) policies configured.

## Solution

### Step 1: Run the Storage Setup SQL

1. Go to your Supabase Dashboard
2. Click **SQL Editor** in the left sidebar
3. Click **New Query**
4. Copy the entire contents of `supabase_storage_setup.sql`
5. Paste into the SQL editor
6. Click **Run** (bottom right)
7. You should see: ✅ Success messages

### Step 2: Verify the Setup

Run this query to verify the bucket exists:
```sql
SELECT * FROM storage.buckets WHERE id = 'avatars';
```

You should see one row with:
- `id`: avatars
- `name`: avatars
- `public`: true

Run this query to verify RLS policies:
```sql
SELECT policyname, cmd
FROM pg_policies
WHERE schemaname = 'storage' AND tablename = 'objects';
```

You should see 4 policies:
- ✅ Avatar images are publicly accessible (SELECT)
- ✅ Authenticated users can upload avatars (INSERT)
- ✅ Users can update their own avatar (UPDATE)
- ✅ Users can delete their own avatar (DELETE)

### Step 3: Test in the App

1. Open the Flutter app
2. Go to Profile screen
3. Click Edit button
4. Click the camera icon on the avatar
5. Select an image from gallery
6. Click "Save Changes"
7. ✅ Image should upload successfully

## How It Works

### File Path Structure
```
avatars/
└── profile_images/
    └── {user_id}/
        ├── 1234567890.jpg
        ├── 1234567891.png
        └── ...
```

### RLS Policy Logic

**Upload (INSERT):**
```sql
-- Only allow uploads to folders matching the user's ID
bucket_id = 'avatars' AND
(storage.foldername(name))[1] = auth.uid()::text
```

**Read (SELECT):**
```sql
-- Anyone can view avatars (needed for displaying profiles)
bucket_id = 'avatars'
```

**Update/Delete:**
```sql
-- Only allow users to modify their own files
bucket_id = 'avatars' AND
(storage.foldername(name))[1] = auth.uid()::text
```

### Code in SupabaseService

The upload code correctly formats the path:
```dart
final userId = Supabase.instance.client.auth.currentUser?.id;
final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.$fileExt';
final filePath = 'profile_images/$fileName';
// Result: profile_images/{userId}/{timestamp}.jpg
```

This matches the RLS policy requirement: `(storage.foldername(name))[1] = auth.uid()`

## Troubleshooting

### Error: "Bucket not found"
**Solution:** Run the storage setup SQL again, specifically this part:
```sql
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO UPDATE SET public = true;
```

### Error: "RLS policy violation" (after running SQL)
**Possible causes:**
1. User not authenticated - Check `auth.uid()` returns valid UUID
2. File path doesn't match - Should be `profile_images/{userId}/...`
3. Policies not created - Verify with the SELECT query above

**Debug query:**
```sql
-- Check current user ID
SELECT auth.uid();

-- Check if policies exist
SELECT * FROM pg_policies
WHERE tablename = 'objects' AND schemaname = 'storage';
```

### Error: "Duplicate key violates unique constraint"
This means the bucket already exists. You can skip the INSERT and just run the RLS policies part.

### Storage Permissions in Supabase Dashboard

Alternative manual setup (if SQL doesn't work):

1. Go to **Storage** in Supabase Dashboard
2. Click **Policies** tab
3. Click **New Policy**
4. Create these policies manually using the policy definitions in `supabase_storage_setup.sql`

## Security Notes

✅ **What's Protected:**
- Users can only upload to their own folder
- Users can only delete their own images
- Users cannot modify other users' images
- File isolation enforced by folder structure

✅ **What's Public:**
- All avatars are viewable by anyone
- This is needed so profile pictures display for all users
- Images are served via public URLs

❌ **Not Recommended:**
- Don't make the bucket private (will break profile display)
- Don't remove the SELECT policy (needed for viewing profiles)
- Don't modify the folder structure (will break RLS)

## Testing Checklist

- [ ] Run `supabase_storage_setup.sql` in Supabase SQL Editor
- [ ] Verify bucket exists with `SELECT * FROM storage.buckets WHERE id = 'avatars'`
- [ ] Verify 4 RLS policies exist
- [ ] Login to Flutter app
- [ ] Go to Profile → Edit
- [ ] Click camera icon
- [ ] Select image
- [ ] Click Save
- [ ] ✅ Image uploads successfully
- [ ] ✅ Avatar displays in profile
- [ ] ✅ Avatar displays in other screens (posts, messages, etc.)

## Quick Fix Command

If you just want to fix it quickly, run this single SQL command:

```sql
-- Quick fix: Create bucket and basic policies
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true) ON CONFLICT DO NOTHING;

ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS "public_read" ON storage.objects FOR SELECT USING (bucket_id = 'avatars');
CREATE POLICY IF NOT EXISTS "auth_upload" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY IF NOT EXISTS "auth_update" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY IF NOT EXISTS "auth_delete" ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);
```

That's it! Your profile image uploads should now work. 🎉