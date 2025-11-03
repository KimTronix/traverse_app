-- Traverse App Database Schema for Supabase PostgreSQL
-- Run this script in your Supabase SQL Editor to create the database structure

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create storage buckets for file uploads
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
  ('avatars', 'avatars', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('posts', 'posts', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp', 'video/mp4', 'video/quicktime']),
  ('stories', 'stories', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp', 'video/mp4', 'video/quicktime'])
ON CONFLICT (id) DO NOTHING;

-- Storage policies for avatars bucket
CREATE POLICY "Avatar images are publicly accessible" ON storage.objects
  FOR SELECT USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload their own avatar" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can update their own avatar" ON storage.objects
  FOR UPDATE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete their own avatar" ON storage.objects
  FOR DELETE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Storage policies for posts bucket
CREATE POLICY "Post images are publicly accessible" ON storage.objects
  FOR SELECT USING (bucket_id = 'posts');

CREATE POLICY "Users can upload post images" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'posts' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can update their own post images" ON storage.objects
  FOR UPDATE USING (bucket_id = 'posts' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete their own post images" ON storage.objects
  FOR DELETE USING (bucket_id = 'posts' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Storage policies for stories bucket
CREATE POLICY "Story media are publicly accessible" ON storage.objects
  FOR SELECT USING (bucket_id = 'stories');

CREATE POLICY "Users can upload story media" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'stories' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can update their own story media" ON storage.objects
  FOR UPDATE USING (bucket_id = 'stories' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete their own story media" ON storage.objects
  FOR DELETE USING (bucket_id = 'stories' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(50) UNIQUE,
    full_name VARCHAR(100) NOT NULL,
    avatar_url TEXT,
    bio TEXT,
    location VARCHAR(100),
    phone VARCHAR(20),
    date_of_birth DATE,
    gender VARCHAR(10),
    role VARCHAR(20) DEFAULT 'traveler', -- traveler, business, guide, admin
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    preferences JSONB DEFAULT '{}',
    -- OAuth fields
    provider VARCHAR(50) DEFAULT 'email', -- email, google, facebook, apple
    provider_id VARCHAR(255),
    provider_data JSONB DEFAULT '{}',
    email_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Destinations table
CREATE TABLE destinations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    location VARCHAR(200) NOT NULL,
    country VARCHAR(100) NOT NULL,
    city VARCHAR(100),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    category VARCHAR(50), -- beach, mountain, city, historical, etc.
    rating DECIMAL(3, 2) DEFAULT 0.0,
    review_count INTEGER DEFAULT 0,
    price_range VARCHAR(20), -- budget, mid-range, luxury
    best_time_to_visit VARCHAR(100),
    images JSONB DEFAULT '[]', -- Array of image URLs
    amenities JSONB DEFAULT '[]', -- Array of amenities
    tags JSONB DEFAULT '[]', -- Array of tags
    is_featured BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Posts table
CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    destination_id UUID REFERENCES destinations(id) ON DELETE SET NULL,
    title VARCHAR(200),
    content TEXT,
    images JSONB DEFAULT '[]', -- Array of image URLs
    location VARCHAR(200),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    tags JSONB DEFAULT '[]',
    like_count INTEGER DEFAULT 0,
    comment_count INTEGER DEFAULT 0,
    share_count INTEGER DEFAULT 0,
    is_public BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Stories table
CREATE TABLE stories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    destination_id UUID REFERENCES destinations(id) ON DELETE SET NULL,
    content TEXT,
    media_url TEXT NOT NULL, -- Image or video URL
    media_type VARCHAR(20) DEFAULT 'image', -- image, video
    duration INTEGER DEFAULT 24, -- Hours until expiry
    view_count INTEGER DEFAULT 0,
    location VARCHAR(200),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    is_active BOOLEAN DEFAULT TRUE,
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '24 hours'),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Bookings table
CREATE TABLE bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    destination_id UUID REFERENCES destinations(id) ON DELETE SET NULL,
    booking_type VARCHAR(50) NOT NULL, -- hotel, flight, activity, car_rental
    title VARCHAR(200) NOT NULL,
    description TEXT,
    start_date DATE NOT NULL,
    end_date DATE,
    start_time TIME,
    end_time TIME,
    location VARCHAR(200),
    price DECIMAL(10, 2),
    currency VARCHAR(3) DEFAULT 'USD',
    status VARCHAR(20) DEFAULT 'confirmed', -- pending, confirmed, cancelled, completed
    booking_reference VARCHAR(100),
    provider VARCHAR(100), -- Booking platform or provider
    contact_info JSONB DEFAULT '{}',
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User interactions table (likes, saves, follows, etc.)
CREATE TABLE user_interactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    target_type VARCHAR(20) NOT NULL, -- post, story, destination, user
    target_id UUID NOT NULL,
    interaction_type VARCHAR(20) NOT NULL, -- like, save, follow, share, view
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, target_type, target_id, interaction_type)
);

-- Conversations table
CREATE TABLE conversations (
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

-- Messages table
CREATE TABLE messages (
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

-- Comments table
CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    parent_comment_id UUID REFERENCES comments(id) ON DELETE CASCADE,
    like_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Reviews table
CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    destination_id UUID REFERENCES destinations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    title VARCHAR(200),
    content TEXT,
    images JSONB DEFAULT '[]',
    visit_date DATE,
    is_verified BOOLEAN DEFAULT FALSE,
    helpful_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(destination_id, user_id)
);

-- User statuses table
CREATE TABLE user_statuses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    image_url TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    device_info JSONB DEFAULT '{}',
    likes INTEGER DEFAULT 0,
    comments INTEGER DEFAULT 0,
    shares INTEGER DEFAULT 0,
    is_liked BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Service providers table
CREATE TABLE service_providers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    category VARCHAR(100) NOT NULL,
    description TEXT,
    location VARCHAR(200),
    contact_email VARCHAR(255),
    contact_phone VARCHAR(20),
    website TEXT,
    services JSONB DEFAULT '[]',
    pricing JSONB DEFAULT '{}',
    status VARCHAR(20) DEFAULT 'active',
    rating DECIMAL(3, 2) DEFAULT 0.0,
    review_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Registered places table
CREATE TABLE registered_places (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    location VARCHAR(200) NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    category VARCHAR(50),
    owner_id UUID REFERENCES users(id) ON DELETE SET NULL,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User visits table
CREATE TABLE user_visits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    place_id UUID REFERENCES registered_places(id) ON DELETE CASCADE,
    visit_date DATE NOT NULL,
    duration_hours INTEGER,
    notes TEXT,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_posts_destination_id ON posts(destination_id);
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);
CREATE INDEX idx_stories_user_id ON stories(user_id);
CREATE INDEX idx_stories_expires_at ON stories(expires_at);
CREATE INDEX idx_bookings_user_id ON bookings(user_id);
CREATE INDEX idx_bookings_start_date ON bookings(start_date);
CREATE INDEX idx_user_interactions_user_id ON user_interactions(user_id);
CREATE INDEX idx_user_interactions_target ON user_interactions(target_type, target_id);
CREATE INDEX idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX idx_messages_created_at ON messages(created_at);
CREATE INDEX idx_comments_post_id ON comments(post_id);
CREATE INDEX idx_reviews_destination_id ON reviews(destination_id);
CREATE INDEX idx_destinations_location ON destinations(country, city);
CREATE INDEX idx_destinations_rating ON destinations(rating DESC);

-- Create triggers for updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_destinations_updated_at BEFORE UPDATE ON destinations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_posts_updated_at BEFORE UPDATE ON posts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bookings_updated_at BEFORE UPDATE ON bookings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_conversations_updated_at BEFORE UPDATE ON conversations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_comments_updated_at BEFORE UPDATE ON comments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reviews_updated_at BEFORE UPDATE ON reviews
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Row Level Security (RLS) policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE stories ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- Basic RLS policies (you can customize these based on your needs)
-- Users can read all public profiles but only update their own
CREATE POLICY "Users can view all profiles" ON users FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON users FOR INSERT WITH CHECK (auth.uid() = id);

-- Posts policies
CREATE POLICY "Anyone can view public posts" ON posts FOR SELECT USING (is_public = true);
CREATE POLICY "Users can manage own posts" ON posts FOR ALL USING (auth.uid() = user_id);

-- Stories policies
CREATE POLICY "Anyone can view active stories" ON stories FOR SELECT USING (is_active = true AND expires_at > NOW());
CREATE POLICY "Users can manage own stories" ON stories FOR ALL USING (auth.uid() = user_id);

-- Bookings policies
CREATE POLICY "Users can manage own bookings" ON bookings FOR ALL USING (auth.uid() = user_id);

-- User interactions policies
CREATE POLICY "Users can manage own interactions" ON user_interactions FOR ALL USING (auth.uid() = user_id);

-- Messages and conversations policies
CREATE POLICY "Users can view own conversations" ON conversations FOR SELECT 
    USING (auth.uid() = user1_id OR auth.uid() = user2_id);
CREATE POLICY "Users can create conversations" ON conversations FOR INSERT 
    WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);

CREATE POLICY "Users can view messages in their conversations" ON messages FOR SELECT 
    USING (EXISTS (
        SELECT 1 FROM conversations 
        WHERE conversations.id = messages.conversation_id 
        AND (conversations.user1_id = auth.uid() OR conversations.user2_id = auth.uid())
    ));
CREATE POLICY "Users can send messages to their conversations" ON messages FOR INSERT 
    WITH CHECK (auth.uid() = sender_id AND EXISTS (
        SELECT 1 FROM conversations 
        WHERE conversations.id = messages.conversation_id 
        AND (conversations.user1_id = auth.uid() OR conversations.user2_id = auth.uid())
    ));

-- Comments policies
CREATE POLICY "Anyone can view comments on public posts" ON comments FOR SELECT 
    USING (EXISTS (
        SELECT 1 FROM posts 
        WHERE posts.id = comments.post_id AND posts.is_public = true
    ));
CREATE POLICY "Authenticated users can create comments" ON comments FOR INSERT 
    WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can manage own comments" ON comments FOR ALL USING (auth.uid() = user_id);

-- Reviews policies
CREATE POLICY "Anyone can view reviews" ON reviews FOR SELECT USING (true);
CREATE POLICY "Users can manage own reviews" ON reviews FOR ALL USING (auth.uid() = user_id);

-- Destinations policies
ALTER TABLE destinations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view destinations" ON destinations FOR SELECT USING (true);
CREATE POLICY "Admins can manage destinations" ON destinations FOR ALL
    USING (EXISTS (
        SELECT 1 FROM users
        WHERE users.id = auth.uid() AND users.role = 'admin'
    ));

-- User wallets table
CREATE TABLE user_wallets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    balance DECIMAL(10, 2) DEFAULT 0.00,
    currency VARCHAR(3) DEFAULT 'USD',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Wallet transactions table
CREATE TABLE wallet_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    wallet_id UUID REFERENCES user_wallets(id) ON DELETE CASCADE,
    transaction_type VARCHAR(20) NOT NULL, -- credit, debit, transfer
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    description TEXT,
    reference_id VARCHAR(100),
    status VARCHAR(20) DEFAULT 'completed', -- pending, completed, failed, cancelled
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Rewards table
CREATE TABLE rewards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    points_required INTEGER NOT NULL,
    reward_type VARCHAR(50) NOT NULL, -- discount, voucher, experience, product
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

-- User reward redemptions table
CREATE TABLE user_reward_redemptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    reward_id UUID REFERENCES rewards(id) ON DELETE CASCADE,
    points_used INTEGER NOT NULL,
    status VARCHAR(20) DEFAULT 'pending', -- pending, approved, rejected, expired
    redemption_code VARCHAR(50),
    redeemed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for wallet tables
CREATE INDEX idx_user_wallets_user_id ON user_wallets(user_id);
CREATE INDEX idx_wallet_transactions_user_id ON wallet_transactions(user_id);
CREATE INDEX idx_wallet_transactions_wallet_id ON wallet_transactions(wallet_id);
CREATE INDEX idx_wallet_transactions_created_at ON wallet_transactions(created_at DESC);
CREATE INDEX idx_rewards_is_active ON rewards(is_active);
CREATE INDEX idx_user_reward_redemptions_user_id ON user_reward_redemptions(user_id);
CREATE INDEX idx_user_reward_redemptions_reward_id ON user_reward_redemptions(reward_id);

-- Create triggers for wallet tables
CREATE TRIGGER update_user_wallets_updated_at BEFORE UPDATE ON user_wallets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_rewards_updated_at BEFORE UPDATE ON rewards
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS policies for wallet tables
ALTER TABLE user_wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallet_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_reward_redemptions ENABLE ROW LEVEL SECURITY;

-- Wallet policies
CREATE POLICY "Users can view own wallet" ON user_wallets FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own wallet" ON user_wallets FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can create own wallet" ON user_wallets FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Transaction policies
CREATE POLICY "Users can view own transactions" ON wallet_transactions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own transactions" ON wallet_transactions FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Rewards policies
CREATE POLICY "Anyone can view active rewards" ON rewards FOR SELECT USING (is_active = true);
CREATE POLICY "Admins can manage rewards" ON rewards FOR ALL 
    USING (EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() AND users.role = 'admin'
    ));

-- User reward redemptions policies
CREATE POLICY "Users can view own redemptions" ON user_reward_redemptions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own redemptions" ON user_reward_redemptions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own redemptions" ON user_reward_redemptions FOR UPDATE USING (auth.uid() = user_id);

-- Attractions table for business listings
CREATE TABLE attractions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    category VARCHAR(100) NOT NULL, -- restaurant, hotel, activity, transport
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
    status VARCHAR(20) DEFAULT 'pending', -- pending, approved, rejected
    verified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Claims table for business ownership claims
CREATE TABLE business_claims (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    attraction_id UUID REFERENCES attractions(id) ON DELETE CASCADE,
    business_name VARCHAR(200) NOT NULL,
    owner_name VARCHAR(100) NOT NULL,
    contact_email VARCHAR(255) NOT NULL,
    contact_phone VARCHAR(20),
    proof_documents JSONB DEFAULT '[]', -- Array of document URLs
    verification_notes TEXT,
    status VARCHAR(20) DEFAULT 'pending', -- pending, approved, rejected
    reviewed_by UUID REFERENCES users(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tour guide profiles table
CREATE TABLE tour_guide_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    business_name VARCHAR(200),
    specializations JSONB DEFAULT '[]', -- Array of specialization areas
    languages JSONB DEFAULT '[]', -- Array of languages spoken
    experience_years INTEGER DEFAULT 0,
    hourly_rate DECIMAL(10, 2),
    currency VARCHAR(3) DEFAULT 'USD',
    availability JSONB DEFAULT '{}', -- Weekly availability schedule
    service_areas JSONB DEFAULT '[]', -- Areas where they provide services
    certifications JSONB DEFAULT '[]', -- Array of certifications
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

-- Admin activities log table
CREATE TABLE admin_activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_id UUID REFERENCES users(id) ON DELETE CASCADE,
    action VARCHAR(100) NOT NULL,
    target_type VARCHAR(50), -- user, attraction, claim, etc.
    target_id UUID,
    description TEXT,
    metadata JSONB DEFAULT '{}',
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Notifications table
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL, -- message, like, comment, booking, system
    title VARCHAR(200) NOT NULL,
    body TEXT NOT NULL,
    data JSONB DEFAULT '{}',
    is_read BOOLEAN DEFAULT FALSE,
    action_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- System settings table
CREATE TABLE system_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key VARCHAR(100) UNIQUE NOT NULL,
    value JSONB NOT NULL,
    description TEXT,
    is_public BOOLEAN DEFAULT FALSE,
    updated_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for new tables
CREATE INDEX idx_attractions_category ON attractions(category);
CREATE INDEX idx_attractions_location ON attractions(location);
CREATE INDEX idx_attractions_rating ON attractions(rating DESC);
CREATE INDEX idx_attractions_owner_id ON attractions(owner_id);
CREATE INDEX idx_business_claims_user_id ON business_claims(user_id);
CREATE INDEX idx_business_claims_status ON business_claims(status);
CREATE INDEX idx_tour_guide_profiles_user_id ON tour_guide_profiles(user_id);
CREATE INDEX idx_tour_guide_profiles_rating ON tour_guide_profiles(rating DESC);
CREATE INDEX idx_admin_activities_admin_id ON admin_activities(admin_id);
CREATE INDEX idx_admin_activities_created_at ON admin_activities(created_at DESC);
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_system_settings_key ON system_settings(key);

-- Create triggers for new tables
CREATE TRIGGER update_attractions_updated_at BEFORE UPDATE ON attractions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_business_claims_updated_at BEFORE UPDATE ON business_claims
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tour_guide_profiles_updated_at BEFORE UPDATE ON tour_guide_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_system_settings_updated_at BEFORE UPDATE ON system_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS policies for new tables
ALTER TABLE attractions ENABLE ROW LEVEL SECURITY;
ALTER TABLE business_claims ENABLE ROW LEVEL SECURITY;
ALTER TABLE tour_guide_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;

-- Attractions policies
CREATE POLICY "Anyone can view approved attractions" ON attractions FOR SELECT USING (status = 'approved' AND is_active = true);
CREATE POLICY "Users can create attractions" ON attractions FOR INSERT WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "Users can update own attractions" ON attractions FOR UPDATE USING (auth.uid() = owner_id);

-- Business claims policies
CREATE POLICY "Users can view own claims" ON business_claims FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create claims" ON business_claims FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own claims" ON business_claims FOR UPDATE USING (auth.uid() = user_id);

-- Tour guide policies
CREATE POLICY "Anyone can view active tour guides" ON tour_guide_profiles FOR SELECT USING (is_active = true);
CREATE POLICY "Users can manage own tour guide profile" ON tour_guide_profiles FOR ALL USING (auth.uid() = user_id);

-- Admin activities policies
CREATE POLICY "Admins can view all activities" ON admin_activities FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM users
        WHERE users.id = auth.uid() AND users.role = 'admin'
    ));
CREATE POLICY "Admins can create activities" ON admin_activities FOR INSERT
    WITH CHECK (auth.uid() = admin_id AND EXISTS (
        SELECT 1 FROM users
        WHERE users.id = auth.uid() AND users.role = 'admin'
    ));

-- Notifications policies
CREATE POLICY "Users can view own notifications" ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own notifications" ON notifications FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "System can create notifications" ON notifications FOR INSERT WITH CHECK (true);

-- System settings policies
CREATE POLICY "Anyone can view public settings" ON system_settings FOR SELECT USING (is_public = true);
CREATE POLICY "Admins can manage all settings" ON system_settings FOR ALL
    USING (EXISTS (
        SELECT 1 FROM users
        WHERE users.id = auth.uid() AND users.role = 'admin'
    ));

-- Insert sample data
INSERT INTO destinations (name, description, location, country, city, latitude, longitude, category, rating, images, price_range) VALUES
('Eiffel Tower', 'Iconic iron lattice tower in Paris', 'Paris, France', 'France', 'Paris', 48.8584, 2.2945, 'landmark', 4.5, '["https://images.unsplash.com/photo-1511739001486-6bfe10ce785f", "https://images.unsplash.com/photo-1431274172761-fca41d930114"]', 'mid-range'),
('Santorini', 'Beautiful Greek island with white buildings and blue domes', 'Santorini, Greece', 'Greece', 'Santorini', 36.3932, 25.4615, 'island', 4.7, '["https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff", "https://images.unsplash.com/photo-1613395877344-13d4a8e0d49e"]', 'luxury'),
('Machu Picchu', 'Ancient Incan citadel in the Andes Mountains', 'Cusco, Peru', 'Peru', 'Cusco', -13.1631, -72.5450, 'historical', 4.8, '["https://images.unsplash.com/photo-1587595431973-160d0d94add1", "https://images.unsplash.com/photo-1526392060635-9d6019884377"]', 'mid-range'),
('Tokyo', 'Vibrant capital city of Japan', 'Tokyo, Japan', 'Japan', 'Tokyo', 35.6762, 139.6503, 'city', 4.6, '["https://images.unsplash.com/photo-1540959733332-eab4deabeeaf", "https://images.unsplash.com/photo-1513407030348-c983a97b98d8"]', 'mid-range'),
('Bali', 'Tropical paradise in Indonesia', 'Bali, Indonesia', 'Indonesia', 'Denpasar', -8.3405, 115.0920, 'beach', 4.4, '["https://images.unsplash.com/photo-1537953773345-d172ccf13cf1", "https://images.unsplash.com/photo-1552733407-5d5c46c3bb3b"]', 'budget');

-- Insert sample attractions
INSERT INTO attractions (name, category, description, location, contact_phone, contact_email, website, images, pricing, rating, review_count, status) VALUES
('The Louvre Restaurant', 'restaurant', 'Fine dining experience near the Louvre Museum', 'Paris, France', '+33 1 42 97 48 16', 'contact@louvrerestaurant.fr', 'https://louvrerestaurant.fr', '["https://images.unsplash.com/photo-1414235077428-338989a2e8c0", "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4"]', '{"average_price": 85, "currency": "EUR", "price_range": "luxury"}', 4.3, 127, 'approved'),
('Tokyo Street Food Tours', 'activity', 'Authentic street food experience in Tokyo', 'Tokyo, Japan', '+81 3-1234-5678', 'info@tokyostreetfood.jp', 'https://tokyostreetfood.jp', '["https://images.unsplash.com/photo-1553909489-cd47e0ef937f", "https://images.unsplash.com/photo-1576169219024-3e2e36ec8aa2"]', '{"average_price": 45, "currency": "USD", "price_range": "budget"}', 4.7, 89, 'approved'),
('Santorini Sunset Hotel', 'hotel', 'Luxury hotel with amazing sunset views', 'Santorini, Greece', '+30 22860 71234', 'reservations@santorinisunet.gr', 'https://santorinisunet.gr', '["https://images.unsplash.com/photo-1566073771259-6a8506099945", "https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9"]', '{"average_price": 250, "currency": "EUR", "price_range": "luxury"}', 4.8, 203, 'approved'),
('Bali Scooter Rentals', 'transport', 'Affordable scooter rentals for island exploration', 'Bali, Indonesia', '+62 361 123456', 'rent@baliscooters.id', 'https://baliscooters.id', '["https://images.unsplash.com/photo-1558618047-3c8c76ca7d13", "https://images.unsplash.com/photo-1449824913935-59a10b8d2000"]', '{"average_price": 8, "currency": "USD", "price_range": "budget"}', 4.2, 156, 'approved');

-- Insert sample system settings
INSERT INTO system_settings (key, value, description, is_public) VALUES
('app_name', '"Traverse"', 'Application name', true),
('app_version', '"1.0.0"', 'Current application version', true),
('maintenance_mode', 'false', 'Enable/disable maintenance mode', false),
('max_file_upload_size', '10485760', 'Maximum file upload size in bytes', false),
('supported_currencies', '["USD", "EUR", "JPY", "GBP", "CAD"]', 'List of supported currencies', true),
('default_currency', '"USD"', 'Default application currency', true),
('admin_email', '"admin@traverse.app"', 'Primary admin email address', false),
('features', '{"real_time_chat": true, "ai_assistant": true, "wallet": true, "rewards": true}', 'Enabled application features', true);