-- Traverse App - Incremental Database Update
-- Run this script to add new tables without affecting existing ones

-- First, let's add missing columns to existing users table if they don't exist
DO $$
BEGIN
    -- Add username column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='username') THEN
        ALTER TABLE users ADD COLUMN username VARCHAR(50) UNIQUE;
    END IF;

    -- Add full_name column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='full_name') THEN
        ALTER TABLE users ADD COLUMN full_name VARCHAR(100);
    END IF;

    -- Add role column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='role') THEN
        ALTER TABLE users ADD COLUMN role VARCHAR(20) DEFAULT 'traveler';
    END IF;

    -- Add other missing columns
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='avatar_url') THEN
        ALTER TABLE users ADD COLUMN avatar_url TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='bio') THEN
        ALTER TABLE users ADD COLUMN bio TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='location') THEN
        ALTER TABLE users ADD COLUMN location VARCHAR(100);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='phone') THEN
        ALTER TABLE users ADD COLUMN phone VARCHAR(20);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='date_of_birth') THEN
        ALTER TABLE users ADD COLUMN date_of_birth DATE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='gender') THEN
        ALTER TABLE users ADD COLUMN gender VARCHAR(10);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='is_verified') THEN
        ALTER TABLE users ADD COLUMN is_verified BOOLEAN DEFAULT FALSE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='is_active') THEN
        ALTER TABLE users ADD COLUMN is_active BOOLEAN DEFAULT TRUE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='preferences') THEN
        ALTER TABLE users ADD COLUMN preferences JSONB DEFAULT '{}';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='provider') THEN
        ALTER TABLE users ADD COLUMN provider VARCHAR(50) DEFAULT 'email';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='provider_id') THEN
        ALTER TABLE users ADD COLUMN provider_id VARCHAR(255);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='provider_data') THEN
        ALTER TABLE users ADD COLUMN provider_data JSONB DEFAULT '{}';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='email_verified') THEN
        ALTER TABLE users ADD COLUMN email_verified BOOLEAN DEFAULT FALSE;
    END IF;
END $$;

-- Create storage buckets if they don't exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('avatars', 'avatars', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('posts', 'posts', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp', 'video/mp4', 'video/quicktime']),
  ('stories', 'stories', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp', 'video/mp4', 'video/quicktime'])
ON CONFLICT (id) DO NOTHING;

-- Create conversations table if it doesn't exist
CREATE TABLE IF NOT EXISTS conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user1_id UUID REFERENCES users(id) ON DELETE CASCADE,
    user2_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(100),
    avatar TEXT,
    is_group BOOLEAN DEFAULT FALSE,
    is_ai BOOLEAN DEFAULT FALSE,
    group_name VARCHAR(100),
    group_avatar_url TEXT,
    last_message_id UUID,
    last_message_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user1_id, user2_id)
);

-- Add missing columns to conversations table if they don't exist
DO $$
BEGIN
    -- Add avatar column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='conversations' AND column_name='avatar') THEN
        ALTER TABLE conversations ADD COLUMN avatar TEXT;
    END IF;

    -- Add is_group column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='conversations' AND column_name='is_group') THEN
        ALTER TABLE conversations ADD COLUMN is_group BOOLEAN DEFAULT FALSE;
    END IF;

    -- Add is_ai column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='conversations' AND column_name='is_ai') THEN
        ALTER TABLE conversations ADD COLUMN is_ai BOOLEAN DEFAULT FALSE;
    END IF;

    -- Add group_name column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='conversations' AND column_name='group_name') THEN
        ALTER TABLE conversations ADD COLUMN group_name VARCHAR(100);
    END IF;

    -- Add group_avatar_url column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='conversations' AND column_name='group_avatar_url') THEN
        ALTER TABLE conversations ADD COLUMN group_avatar_url TEXT;
    END IF;

    -- Add last_message_id column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='conversations' AND column_name='last_message_id') THEN
        ALTER TABLE conversations ADD COLUMN last_message_id UUID;
    END IF;

    -- Add last_message_at column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='conversations' AND column_name='last_message_at') THEN
        ALTER TABLE conversations ADD COLUMN last_message_at TIMESTAMP WITH TIME ZONE;
    END IF;
END $$;

-- Create messages table if it doesn't exist
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES users(id) ON DELETE CASCADE,
    content TEXT,
    message_type VARCHAR(20) DEFAULT 'text', -- text, image, video, location, file
    media_url TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    reply_to_id UUID REFERENCES messages(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create attractions table if it doesn't exist
CREATE TABLE IF NOT EXISTS attractions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    category VARCHAR(100) NOT NULL,
    description TEXT,
    location VARCHAR(200) NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    contact_phone VARCHAR(20),
    contact_email VARCHAR(255),
    website TEXT,
    images JSONB DEFAULT '[]',
    amenities JSONB DEFAULT '[]',
    pricing JSONB DEFAULT '{}',
    rating DECIMAL(3, 2) DEFAULT 0.0,
    review_count INTEGER DEFAULT 0,
    is_featured BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    owner_id UUID REFERENCES users(id) ON DELETE SET NULL,
    status VARCHAR(20) DEFAULT 'pending',
    verified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create business_claims table if it doesn't exist
CREATE TABLE IF NOT EXISTS business_claims (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    attraction_id UUID REFERENCES attractions(id) ON DELETE CASCADE,
    business_name VARCHAR(200) NOT NULL,
    owner_name VARCHAR(100) NOT NULL,
    contact_email VARCHAR(255) NOT NULL,
    contact_phone VARCHAR(20),
    proof_documents JSONB DEFAULT '[]',
    verification_notes TEXT,
    status VARCHAR(20) DEFAULT 'pending',
    reviewed_by UUID REFERENCES users(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create tour_guide_profiles table if it doesn't exist
CREATE TABLE IF NOT EXISTS tour_guide_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    business_name VARCHAR(200),
    specializations JSONB DEFAULT '[]',
    languages JSONB DEFAULT '[]',
    experience_years INTEGER DEFAULT 0,
    hourly_rate DECIMAL(10, 2),
    currency VARCHAR(3) DEFAULT 'USD',
    availability JSONB DEFAULT '{}',
    service_areas JSONB DEFAULT '[]',
    certifications JSONB DEFAULT '[]',
    portfolio_images JSONB DEFAULT '[]',
    rating DECIMAL(3, 2) DEFAULT 0.0,
    review_count INTEGER DEFAULT 0,
    total_tours INTEGER DEFAULT 0,
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    verification_documents JSONB DEFAULT '[]',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Create admin_activities table if it doesn't exist
CREATE TABLE IF NOT EXISTS admin_activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_id UUID REFERENCES users(id) ON DELETE CASCADE,
    action VARCHAR(100) NOT NULL,
    target_type VARCHAR(50),
    target_id UUID,
    description TEXT,
    metadata JSONB DEFAULT '{}',
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create notifications table if it doesn't exist
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(200) NOT NULL,
    body TEXT NOT NULL,
    data JSONB DEFAULT '{}',
    is_read BOOLEAN DEFAULT FALSE,
    action_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create system_settings table if it doesn't exist
CREATE TABLE IF NOT EXISTS system_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key VARCHAR(100) UNIQUE NOT NULL,
    value JSONB NOT NULL,
    description TEXT,
    is_public BOOLEAN DEFAULT FALSE,
    updated_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create user_wallets table if it doesn't exist
CREATE TABLE IF NOT EXISTS user_wallets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    balance DECIMAL(10, 2) DEFAULT 0.00,
    currency VARCHAR(3) DEFAULT 'USD',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Create wallet_transactions table if it doesn't exist
CREATE TABLE IF NOT EXISTS wallet_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    wallet_id UUID REFERENCES user_wallets(id) ON DELETE CASCADE,
    transaction_type VARCHAR(20) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    description TEXT,
    reference_id VARCHAR(100),
    status VARCHAR(20) DEFAULT 'completed',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create rewards table if it doesn't exist
CREATE TABLE IF NOT EXISTS rewards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    points_required INTEGER NOT NULL,
    reward_type VARCHAR(50) NOT NULL,
    reward_value DECIMAL(10, 2),
    currency VARCHAR(3) DEFAULT 'USD',
    image_url TEXT,
    terms_conditions TEXT,
    expiry_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    max_redemptions INTEGER,
    current_redemptions INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create user_reward_redemptions table if it doesn't exist
CREATE TABLE IF NOT EXISTS user_reward_redemptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    reward_id UUID REFERENCES rewards(id) ON DELETE CASCADE,
    points_used INTEGER NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    redemption_code VARCHAR(50),
    redeemed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes only if they don't exist
CREATE INDEX IF NOT EXISTS idx_attractions_category ON attractions(category);
CREATE INDEX IF NOT EXISTS idx_attractions_location ON attractions(location);
CREATE INDEX IF NOT EXISTS idx_attractions_rating ON attractions(rating DESC);
CREATE INDEX IF NOT EXISTS idx_attractions_owner_id ON attractions(owner_id);
CREATE INDEX IF NOT EXISTS idx_business_claims_user_id ON business_claims(user_id);
CREATE INDEX IF NOT EXISTS idx_business_claims_status ON business_claims(status);
CREATE INDEX IF NOT EXISTS idx_tour_guide_profiles_user_id ON tour_guide_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_tour_guide_profiles_rating ON tour_guide_profiles(rating DESC);
CREATE INDEX IF NOT EXISTS idx_admin_activities_admin_id ON admin_activities(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_activities_created_at ON admin_activities(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_system_settings_key ON system_settings(key);
CREATE INDEX IF NOT EXISTS idx_user_wallets_user_id ON user_wallets(user_id);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_user_id ON wallet_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_wallet_id ON wallet_transactions(wallet_id);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_created_at ON wallet_transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_rewards_is_active ON rewards(is_active);
CREATE INDEX IF NOT EXISTS idx_user_reward_redemptions_user_id ON user_reward_redemptions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_reward_redemptions_reward_id ON user_reward_redemptions(reward_id);

-- Create or replace the update trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers only if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_attractions_updated_at') THEN
        CREATE TRIGGER update_attractions_updated_at BEFORE UPDATE ON attractions
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_business_claims_updated_at') THEN
        CREATE TRIGGER update_business_claims_updated_at BEFORE UPDATE ON business_claims
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_tour_guide_profiles_updated_at') THEN
        CREATE TRIGGER update_tour_guide_profiles_updated_at BEFORE UPDATE ON tour_guide_profiles
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_system_settings_updated_at') THEN
        CREATE TRIGGER update_system_settings_updated_at BEFORE UPDATE ON system_settings
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_user_wallets_updated_at') THEN
        CREATE TRIGGER update_user_wallets_updated_at BEFORE UPDATE ON user_wallets
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_rewards_updated_at') THEN
        CREATE TRIGGER update_rewards_updated_at BEFORE UPDATE ON rewards
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

-- Enable RLS for new tables
ALTER TABLE attractions ENABLE ROW LEVEL SECURITY;
ALTER TABLE business_claims ENABLE ROW LEVEL SECURITY;
ALTER TABLE tour_guide_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallet_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_reward_redemptions ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for new tables (using DO blocks to handle existing policies)
DO $$
BEGIN
    -- Attractions policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'attractions' AND policyname = 'Anyone can view approved attractions') THEN
        CREATE POLICY "Anyone can view approved attractions" ON attractions FOR SELECT USING (status = 'approved' AND is_active = true);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'attractions' AND policyname = 'Users can create attractions') THEN
        CREATE POLICY "Users can create attractions" ON attractions FOR INSERT WITH CHECK (auth.uid() = owner_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'attractions' AND policyname = 'Users can update own attractions') THEN
        CREATE POLICY "Users can update own attractions" ON attractions FOR UPDATE USING (auth.uid() = owner_id);
    END IF;

    -- Business claims policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'business_claims' AND policyname = 'Users can view own claims') THEN
        CREATE POLICY "Users can view own claims" ON business_claims FOR SELECT USING (auth.uid() = user_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'business_claims' AND policyname = 'Users can create claims') THEN
        CREATE POLICY "Users can create claims" ON business_claims FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'business_claims' AND policyname = 'Users can update own claims') THEN
        CREATE POLICY "Users can update own claims" ON business_claims FOR UPDATE USING (auth.uid() = user_id);
    END IF;

    -- Tour guide policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'tour_guide_profiles' AND policyname = 'Anyone can view active tour guides') THEN
        CREATE POLICY "Anyone can view active tour guides" ON tour_guide_profiles FOR SELECT USING (is_active = true);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'tour_guide_profiles' AND policyname = 'Users can manage own tour guide profile') THEN
        CREATE POLICY "Users can manage own tour guide profile" ON tour_guide_profiles FOR ALL USING (auth.uid() = user_id);
    END IF;
END $$;

-- Create remaining RLS policies using DO blocks
DO $$
BEGIN
    -- Notifications policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'notifications' AND policyname = 'Users can view own notifications') THEN
        CREATE POLICY "Users can view own notifications" ON notifications FOR SELECT USING (auth.uid() = user_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'notifications' AND policyname = 'Users can update own notifications') THEN
        CREATE POLICY "Users can update own notifications" ON notifications FOR UPDATE USING (auth.uid() = user_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'notifications' AND policyname = 'System can create notifications') THEN
        CREATE POLICY "System can create notifications" ON notifications FOR INSERT WITH CHECK (true);
    END IF;

    -- System settings policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'system_settings' AND policyname = 'Anyone can view public settings') THEN
        CREATE POLICY "Anyone can view public settings" ON system_settings FOR SELECT USING (is_public = true);
    END IF;

    -- Wallet policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'user_wallets' AND policyname = 'Users can view own wallet') THEN
        CREATE POLICY "Users can view own wallet" ON user_wallets FOR SELECT USING (auth.uid() = user_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'user_wallets' AND policyname = 'Users can update own wallet') THEN
        CREATE POLICY "Users can update own wallet" ON user_wallets FOR UPDATE USING (auth.uid() = user_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'user_wallets' AND policyname = 'Users can create own wallet') THEN
        CREATE POLICY "Users can create own wallet" ON user_wallets FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;

    -- Transaction policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'wallet_transactions' AND policyname = 'Users can view own transactions') THEN
        CREATE POLICY "Users can view own transactions" ON wallet_transactions FOR SELECT USING (auth.uid() = user_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'wallet_transactions' AND policyname = 'Users can create own transactions') THEN
        CREATE POLICY "Users can create own transactions" ON wallet_transactions FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;

    -- Rewards policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'rewards' AND policyname = 'Anyone can view active rewards') THEN
        CREATE POLICY "Anyone can view active rewards" ON rewards FOR SELECT USING (is_active = true);
    END IF;

    -- User reward redemptions policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'user_reward_redemptions' AND policyname = 'Users can view own redemptions') THEN
        CREATE POLICY "Users can view own redemptions" ON user_reward_redemptions FOR SELECT USING (auth.uid() = user_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'user_reward_redemptions' AND policyname = 'Users can create own redemptions') THEN
        CREATE POLICY "Users can create own redemptions" ON user_reward_redemptions FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'user_reward_redemptions' AND policyname = 'Users can update own redemptions') THEN
        CREATE POLICY "Users can update own redemptions" ON user_reward_redemptions FOR UPDATE USING (auth.uid() = user_id);
    END IF;
END $$;

-- Insert sample data only if tables are empty
INSERT INTO attractions (name, category, description, location, contact_phone, contact_email, website, images, pricing, rating, review_count, status)
SELECT name, category, description, location, contact_phone, contact_email, website, images::jsonb, pricing::jsonb, rating, review_count, status FROM (VALUES
    ('The Louvre Restaurant', 'restaurant', 'Fine dining experience near the Louvre Museum', 'Paris, France', '+33 1 42 97 48 16', 'contact@louvrerestaurant.fr', 'https://louvrerestaurant.fr', '["https://images.unsplash.com/photo-1414235077428-338989a2e8c0", "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4"]', '{"average_price": 85, "currency": "EUR", "price_range": "luxury"}', 4.3, 127, 'approved'),
    ('Tokyo Street Food Tours', 'activity', 'Authentic street food experience in Tokyo', 'Tokyo, Japan', '+81 3-1234-5678', 'info@tokyostreetfood.jp', 'https://tokyostreetfood.jp', '["https://images.unsplash.com/photo-1553909489-cd47e0ef937f", "https://images.unsplash.com/photo-1576169219024-3e2e36ec8aa2"]', '{"average_price": 45, "currency": "USD", "price_range": "budget"}', 4.7, 89, 'approved'),
    ('Santorini Sunset Hotel', 'hotel', 'Luxury hotel with amazing sunset views', 'Santorini, Greece', '+30 22860 71234', 'reservations@santorinisunet.gr', 'https://santorinisunet.gr', '["https://images.unsplash.com/photo-1566073771259-6a8506099945", "https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9"]', '{"average_price": 250, "currency": "EUR", "price_range": "luxury"}', 4.8, 203, 'approved'),
    ('Bali Scooter Rentals', 'transport', 'Affordable scooter rentals for island exploration', 'Bali, Indonesia', '+62 361 123456', 'rent@baliscooters.id', 'https://baliscooters.id', '["https://images.unsplash.com/photo-1558618047-3c8c76ca7d13", "https://images.unsplash.com/photo-1449824913935-59a10b8d2000"]', '{"average_price": 8, "currency": "USD", "price_range": "budget"}', 4.2, 156, 'approved')
) AS v(name, category, description, location, contact_phone, contact_email, website, images, pricing, rating, review_count, status)
WHERE NOT EXISTS (SELECT 1 FROM attractions LIMIT 1);

-- Insert sample system settings only if table is empty
INSERT INTO system_settings (key, value, description, is_public)
SELECT key, value::jsonb, description, is_public FROM (VALUES
    ('app_name', '"Traverse"', 'Application name', true),
    ('app_version', '"1.0.0"', 'Current application version', true),
    ('maintenance_mode', 'false', 'Enable/disable maintenance mode', false),
    ('max_file_upload_size', '10485760', 'Maximum file upload size in bytes', false),
    ('supported_currencies', '["USD", "EUR", "JPY", "GBP", "CAD"]', 'List of supported currencies', true),
    ('default_currency', '"USD"', 'Default application currency', true),
    ('admin_email', '"admin@traverse.app"', 'Primary admin email address', false),
    ('features', '{"real_time_chat": true, "ai_assistant": true, "wallet": true, "rewards": true}', 'Enabled application features', true)
) AS v(key, value, description, is_public)
WHERE NOT EXISTS (SELECT 1 FROM system_settings LIMIT 1);

-- Storage policies (create only if they don't exist)
DO $$
BEGIN
    -- Avatars bucket policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Avatar images are publicly accessible' AND tablename = 'objects') THEN
        CREATE POLICY "Avatar images are publicly accessible" ON storage.objects
            FOR SELECT USING (bucket_id = 'avatars');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can upload their own avatar' AND tablename = 'objects') THEN
        CREATE POLICY "Users can upload their own avatar" ON storage.objects
            FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
    END IF;

    -- Posts bucket policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Post images are publicly accessible' AND tablename = 'objects') THEN
        CREATE POLICY "Post images are publicly accessible" ON storage.objects
            FOR SELECT USING (bucket_id = 'posts');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can upload post images' AND tablename = 'objects') THEN
        CREATE POLICY "Users can upload post images" ON storage.objects
            FOR INSERT WITH CHECK (bucket_id = 'posts' AND auth.uid()::text = (storage.foldername(name))[1]);
    END IF;

    -- Stories bucket policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Story media are publicly accessible' AND tablename = 'objects') THEN
        CREATE POLICY "Story media are publicly accessible" ON storage.objects
            FOR SELECT USING (bucket_id = 'stories');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can upload story media' AND tablename = 'objects') THEN
        CREATE POLICY "Users can upload story media" ON storage.objects
            FOR INSERT WITH CHECK (bucket_id = 'stories' AND auth.uid()::text = (storage.foldername(name))[1]);
    END IF;
END $$;

-- Add verification request system
-- This is an incremental update to add verification features

-- Verification requests table
CREATE TABLE IF NOT EXISTS verification_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    request_type VARCHAR(50) NOT NULL, -- email, phone, identity, business
    status VARCHAR(20) DEFAULT 'pending', -- pending, approved, rejected, expired
    verification_method VARCHAR(50), -- email_link, phone_sms, document_upload, manual_review
    verification_data JSONB DEFAULT '{}', -- Store verification codes, document URLs, etc.
    submitted_documents JSONB DEFAULT '[]', -- Array of document URLs
    admin_notes TEXT,
    expires_at TIMESTAMP WITH TIME ZONE,
    verified_at TIMESTAMP WITH TIME ZONE,
    verified_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- AI chat sessions table for verified users
CREATE TABLE IF NOT EXISTS ai_chat_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    session_name VARCHAR(200),
    is_archived BOOLEAN DEFAULT FALSE,
    message_count INTEGER DEFAULT 0,
    last_message_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- AI chat messages table
CREATE TABLE IF NOT EXISTS ai_chat_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID REFERENCES ai_chat_sessions(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    message_type VARCHAR(20) DEFAULT 'text', -- text, image, location
    role VARCHAR(20) NOT NULL, -- user, assistant
    content TEXT NOT NULL,
    metadata JSONB DEFAULT '{}', -- Store additional message data
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User verification levels table
CREATE TABLE IF NOT EXISTS user_verification_levels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    verification_type VARCHAR(50) NOT NULL, -- email, phone, identity, business, premium
    verified_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE, -- For time-limited verifications
    verification_data JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, verification_type)
);

-- Create indexes if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_verification_requests_user_id') THEN
        CREATE INDEX idx_verification_requests_user_id ON verification_requests(user_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_verification_requests_status') THEN
        CREATE INDEX idx_verification_requests_status ON verification_requests(status);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_ai_chat_sessions_user_id') THEN
        CREATE INDEX idx_ai_chat_sessions_user_id ON ai_chat_sessions(user_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_ai_chat_messages_session_id') THEN
        CREATE INDEX idx_ai_chat_messages_session_id ON ai_chat_messages(session_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_ai_chat_messages_user_id') THEN
        CREATE INDEX idx_ai_chat_messages_user_id ON ai_chat_messages(user_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_user_verification_levels_user_id') THEN
        CREATE INDEX idx_user_verification_levels_user_id ON user_verification_levels(user_id);
    END IF;
END
$$;

-- Create triggers if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_verification_requests_updated_at') THEN
        CREATE TRIGGER update_verification_requests_updated_at BEFORE UPDATE ON verification_requests
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_ai_chat_sessions_updated_at') THEN
        CREATE TRIGGER update_ai_chat_sessions_updated_at BEFORE UPDATE ON ai_chat_sessions
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END
$$;

-- Enable RLS
ALTER TABLE verification_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_verification_levels ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist and recreate them
DROP POLICY IF EXISTS "Users can view own verification requests" ON verification_requests;
DROP POLICY IF EXISTS "Users can create own verification requests" ON verification_requests;
DROP POLICY IF EXISTS "Users can update own verification requests" ON verification_requests;
DROP POLICY IF EXISTS "Admins can manage all verification requests" ON verification_requests;
DROP POLICY IF EXISTS "Users can manage own AI chat sessions" ON ai_chat_sessions;
DROP POLICY IF EXISTS "Users can manage own AI chat messages" ON ai_chat_messages;
DROP POLICY IF EXISTS "Users can view own verification levels" ON user_verification_levels;
DROP POLICY IF EXISTS "System can manage verification levels" ON user_verification_levels;

-- Verification requests policies
CREATE POLICY "Users can view own verification requests" ON verification_requests
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own verification requests" ON verification_requests
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own verification requests" ON verification_requests
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Admins can manage all verification requests" ON verification_requests
    FOR ALL USING (EXISTS (
        SELECT 1 FROM users
        WHERE users.id = auth.uid() AND users.role = 'admin'
    ));

-- AI chat sessions policies
CREATE POLICY "Users can manage own AI chat sessions" ON ai_chat_sessions
    FOR ALL USING (auth.uid() = user_id);

-- AI chat messages policies
CREATE POLICY "Users can manage own AI chat messages" ON ai_chat_messages
    FOR ALL USING (auth.uid() = user_id);

-- User verification levels policies
CREATE POLICY "Users can view own verification levels" ON user_verification_levels
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "System can manage verification levels" ON user_verification_levels
    FOR ALL USING (true);

-- Function to check if user is verified
CREATE OR REPLACE FUNCTION is_user_verified(user_uuid UUID, verification_type VARCHAR DEFAULT 'email')
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM user_verification_levels
        WHERE user_id = user_uuid
        AND verification_type = verification_type
        AND (expires_at IS NULL OR expires_at > NOW())
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user verification status
CREATE OR REPLACE FUNCTION get_user_verification_status(user_uuid UUID)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_object_agg(verification_type, jsonb_build_object(
        'verified', true,
        'verified_at', verified_at,
        'expires_at', expires_at
    )) INTO result
    FROM user_verification_levels
    WHERE user_id = user_uuid
    AND (expires_at IS NULL OR expires_at > NOW());

    RETURN COALESCE(result, '{}'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Insert default verification for existing users based on email_verified
INSERT INTO user_verification_levels (user_id, verification_type, verified_at)
SELECT id, 'email', created_at
FROM users
WHERE email_verified = true
ON CONFLICT (user_id, verification_type) DO NOTHING;

-- Success message
SELECT 'Database successfully updated! All verification features have been added.' as result;