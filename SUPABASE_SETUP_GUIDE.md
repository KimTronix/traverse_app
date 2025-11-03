# Supabase Setup Guide for Traverse App

This guide will help you set up PostgreSQL + Supabase for your Traverse travel app.

## Step 1: Create a Supabase Project

1. Go to [supabase.com](https://supabase.com) and sign up/sign in
2. Click "New Project"
3. Choose your organization
4. Fill in project details:
   - **Name**: `traverse-app` (or your preferred name)
   - **Database Password**: Create a strong password (save this!)
   - **Region**: Choose the closest region to your users
5. Click "Create new project"
6. Wait for the project to be created (usually takes 1-2 minutes)

## Step 2: Get Your Project Credentials

1. In your Supabase dashboard, go to **Settings** > **API**
2. Copy the following values:
   - **Project URL** (looks like: `https://your-project-id.supabase.co`)
   - **Anon public key** (starts with `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`)

## Step 3: Update Configuration

1. Open `lib/config/supabase_config.dart`
2. Replace the placeholder values:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://your-project-id.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key-here';
  // ... rest of the file
}
```

## Step 4: Set Up Database Schema

1. In your Supabase dashboard, go to **SQL Editor**
2. Click "New query"
3. Copy the entire content from `supabase_schema.sql` file
4. Paste it into the SQL editor
5. Click "Run" to execute the schema

This will create all the necessary tables:
- `users` - User profiles and authentication
- `destinations` - Travel destinations
- `posts` - User posts and content
- `stories` - Temporary stories (24h expiry)
- `bookings` - Hotel, flight, activity bookings
- `user_interactions` - Likes, saves, follows
- `conversations` - Chat conversations
- `messages` - Chat messages
- `comments` - Post comments
- `reviews` - Destination reviews

## Step 5: Configure Authentication (Optional)

If you want to enable email/password authentication:

1. Go to **Authentication** > **Settings**
2. Configure your authentication settings:
   - Enable email confirmations if needed
   - Set up email templates
   - Configure redirect URLs

## Step 6: Set Up Row Level Security (RLS)

The schema includes basic RLS policies, but you may want to customize them:

1. Go to **Authentication** > **Policies**
2. Review and modify the policies as needed
3. The current policies allow:
   - Public reading of destinations and public posts
   - Users can only modify their own data
   - Users can only see their own bookings and conversations

## Step 7: Test the Connection

1. Run your Flutter app: `flutter run`
2. Check the console for any Supabase connection errors
3. If successful, you should see "Supabase initialized" in the logs

## Step 8: Environment Variables (Recommended)

For production, consider using environment variables:

1. Create a `.env` file in your project root:
```
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

2. Add `.env` to your `.gitignore` file
3. Use a package like `flutter_dotenv` to load environment variables

## Features Enabled

✅ **Real-time subscriptions** - Live updates for posts, messages, stories
✅ **Authentication** - Email/password sign up and sign in
✅ **File storage** - For user avatars and post images (configure in Storage)
✅ **Row Level Security** - Data protection and user privacy
✅ **PostgreSQL** - Full SQL database with relationships
✅ **Scalability** - Auto-scaling infrastructure

## Next Steps

1. **Configure Storage**: Set up buckets for images and files
2. **Set up Real-time**: Enable real-time features for chat and live updates
3. **Add Indexes**: Optimize database performance with additional indexes
4. **Backup Strategy**: Configure automated backups
5. **Monitoring**: Set up alerts and monitoring

## Migration from SQLite

The app will automatically fall back to sample data if Supabase is not configured or fails to connect. To fully migrate:

1. Update `TravelProvider` and `BookingProvider` to use `SupabaseService`
2. Remove SQLite dependencies once migration is complete
3. Test all features with the new database

## Troubleshooting

**Connection Issues:**
- Verify your project URL and anon key
- Check your internet connection
- Ensure the project is not paused (free tier limitation)

**RLS Issues:**
- Check if policies are correctly configured
- Verify user authentication status
- Review policy conditions in the Supabase dashboard

**Performance Issues:**
- Add indexes for frequently queried columns
- Use pagination for large datasets
- Optimize your queries

## Support

- [Supabase Documentation](https://supabase.com/docs)
- [Flutter Supabase Package](https://pub.dev/packages/supabase_flutter)
- [Supabase Community](https://github.com/supabase/supabase/discussions)