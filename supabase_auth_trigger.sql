-- Trigger to automatically create user profile when a new user signs up
-- Run this in your Supabase SQL Editor

-- Create a function to handle new user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (
    id,
    email,
    full_name,
    username,
    role,
    email_verified,
    is_active,
    provider,
    provider_id,
    provider_data,
    created_at,
    updated_at
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', SPLIT_PART(NEW.email, '@', 1)),
    COALESCE(
      NEW.raw_user_meta_data->>'username',
      REPLACE(SPLIT_PART(NEW.email, '@', 1), '.', '_') || '_' || FLOOR(RANDOM() * 10000)::TEXT
    ),
    COALESCE(NEW.raw_user_meta_data->>'role', 'traveler'),
    NEW.email_confirmed_at IS NOT NULL,
    true,
    COALESCE(NEW.raw_app_meta_data->>'provider', 'email'),
    NEW.id,
    COALESCE(NEW.raw_user_meta_data, '{}'::jsonb),
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    full_name = EXCLUDED.full_name,
    email_verified = EXCLUDED.email_verified,
    provider = EXCLUDED.provider,
    provider_data = EXCLUDED.provider_data,
    updated_at = NOW();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop the trigger if it exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT OR UPDATE ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO postgres, anon, authenticated, service_role;

-- Success message
SELECT 'Trigger created successfully! New users will automatically get profiles in the users table.' as result;
