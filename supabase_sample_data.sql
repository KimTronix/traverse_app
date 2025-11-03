-- Sample Data for Traverse App
-- Run this in your Supabase SQL Editor AFTER running the main schema

-- Note: Make sure you have at least one user in auth.users and public.users first!
-- You can create one by signing up through the app

-- Insert sample destinations (these should already be there from schema, but adding more)
INSERT INTO destinations (name, description, location, country, city, latitude, longitude, category, rating, review_count, images, price_range, is_featured) VALUES
('Victoria Falls', 'One of the Seven Natural Wonders of the World, Victoria Falls is a spectacular sight of awe-inspiring beauty and grandeur', 'Victoria Falls, Zimbabwe', 'Zimbabwe', 'Victoria Falls', -17.9244, 25.8567, 'nature', 4.9, 1523,
'["https://images.unsplash.com/photo-1547471080-7cc2caa01a7e", "https://images.unsplash.com/photo-1516026672322-bc52d61a55d5"]', 'mid-range', true),

('Great Zimbabwe', 'Ancient stone city ruins showcasing medieval African civilization', 'Masvingo, Zimbabwe', 'Zimbabwe', 'Masvingo', -20.2674, 30.9337, 'historical', 4.6, 892,
'["https://images.unsplash.com/photo-1523805009345-7448845a9e53", "https://images.unsplash.com/photo-1548013146-72479768bada"]', 'budget', true),

('Hwange National Park', 'Zimbabwe''s largest game reserve with abundant wildlife and elephants', 'Hwange, Zimbabwe', 'Zimbabwe', 'Hwange', -18.6297, 26.5000, 'wildlife', 4.8, 1247,
'["https://images.unsplash.com/photo-1516426122078-c23e76319801", "https://images.unsplash.com/photo-1551958219-acbc608c6377"]', 'luxury', true),

('Lake Kariba', 'Massive man-made lake perfect for fishing, boating, and houseboat holidays', 'Kariba, Zimbabwe', 'Zimbabwe', 'Kariba', -16.5167, 28.8000, 'lake', 4.5, 678,
'["https://images.unsplash.com/photo-1505142468610-359e7d316be0", "https://images.unsplash.com/photo-1544551763-46a013bb70d5"]', 'mid-range', false),

('Mana Pools National Park', 'UNESCO World Heritage Site known for walking safaris and riverside camps', 'Mana Pools, Zimbabwe', 'Zimbabwe', 'Mana Pools', -15.7694, 29.3844, 'wildlife', 4.9, 534,
'["https://images.unsplash.com/photo-1516426122078-c23e76319801", "https://images.unsplash.com/photo-1551958219-acbc608c6377"]', 'luxury', true),

('Nyanga National Park', 'Mountain retreat with waterfalls, trout fishing, and cool climate', 'Nyanga, Zimbabwe', 'Zimbabwe', 'Nyanga', -18.2167, 32.7500, 'mountain', 4.4, 423,
'["https://images.unsplash.com/photo-1506905925346-21bda4d32df4", "https://images.unsplash.com/photo-1511593358241-7eea1f3c84e5"]', 'budget', false),

('Matobo National Park', 'Granite rock formations and ancient cave paintings', 'Bulawayo, Zimbabwe', 'Zimbabwe', 'Bulawayo', -20.5500, 28.5000, 'nature', 4.7, 756,
'["https://images.unsplash.com/photo-1523805009345-7448845a9e53", "https://images.unsplash.com/photo-1469854523086-cc02fe5d8800"]', 'mid-range', false),

('Eastern Highlands', 'Scenic mountain range with lush forests and coffee plantations', 'Mutare, Zimbabwe', 'Zimbabwe', 'Mutare', -18.9661, 32.6701, 'mountain', 4.3, 312,
'["https://images.unsplash.com/photo-1506905925346-21bda4d32df4", "https://images.unsplash.com/photo-1501785888041-af3ef285b470"]', 'budget', false)

ON CONFLICT (id) DO NOTHING;

-- Insert sample posts (IMPORTANT: Replace 'YOUR_USER_ID_HERE' with actual user ID from auth.users)
-- You can get user IDs by running: SELECT id, email FROM auth.users;

-- First, let's create a function to get a random user ID
DO $$
DECLARE
    sample_user_id UUID;
BEGIN
    -- Get the first user ID from the users table
    SELECT id INTO sample_user_id FROM users LIMIT 1;

    -- Only insert sample posts if we have at least one user
    IF sample_user_id IS NOT NULL THEN
        -- Insert sample posts
        INSERT INTO posts (user_id, content, location, latitude, longitude, images, tags, like_count, comment_count, share_count, is_public) VALUES
        (sample_user_id, 'Just visited Victoria Falls and it was absolutely breathtaking! The sheer power and beauty of the falls is something everyone should experience at least once. #TraverseZimbabwe #VictoriaFalls', 'Victoria Falls, Zimbabwe', -17.9244, 25.8567,
        '["https://images.unsplash.com/photo-1547471080-7cc2caa01a7e", "https://images.unsplash.com/photo-1516026672322-bc52d61a55d5"]',
        '["victoria-falls", "travel", "zimbabwe", "adventure"]', 156, 23, 12, true),

        (sample_user_id, 'Safari at Hwange National Park was incredible! Saw a herd of over 50 elephants at a watering hole. The guides were knowledgeable and the accommodation was top-notch. Highly recommend! 🐘', 'Hwange National Park, Zimbabwe', -18.6297, 26.5000,
        '["https://images.unsplash.com/photo-1516426122078-c23e76319801", "https://images.unsplash.com/photo-1551958219-acbc608c6377", "https://images.unsplash.com/photo-1534567110243-e25c33e9e9c5"]',
        '["safari", "wildlife", "elephants", "hwange"]', 243, 34, 18, true),

        (sample_user_id, 'Exploring the ancient ruins of Great Zimbabwe. The stone structures are fascinating and the history behind them is mind-blowing. A must-visit for history buffs! 🏛️', 'Great Zimbabwe, Masvingo', -20.2674, 30.9337,
        '["https://images.unsplash.com/photo-1523805009345-7448845a9e53", "https://images.unsplash.com/photo-1548013146-72479768bada"]',
        '["history", "culture", "great-zimbabwe", "ruins"]', 189, 28, 9, true),

        (sample_user_id, 'Houseboat holiday on Lake Kariba 🚤 Perfect mix of relaxation and adventure. Fishing, wildlife watching, and stunning sunsets. This is the life!', 'Lake Kariba, Zimbabwe', -16.5167, 28.8000,
        '["https://images.unsplash.com/photo-1505142468610-359e7d316be0", "https://images.unsplash.com/photo-1544551763-46a013bb70d5"]',
        '["lake-kariba", "houseboat", "fishing", "relaxation"]', 134, 19, 7, true),

        (sample_user_id, 'Walking safari in Mana Pools! Getting this close to wildlife on foot is an adrenaline rush like no other. Our guide made us feel safe while we walked alongside elephants and buffalo. Unforgettable! 🦁', 'Mana Pools National Park, Zimbabwe', -15.7694, 29.3844,
        '["https://images.unsplash.com/photo-1516426122078-c23e76319801", "https://images.unsplash.com/photo-1551958219-acbc608c6377"]',
        '["mana-pools", "walking-safari", "wildlife", "adventure"]', 278, 42, 21, true),

        (sample_user_id, 'Weekend getaway to Nyanga! The cool mountain air, beautiful waterfalls, and fresh trout made for a perfect escape from the city heat. Already planning my next trip back! 🏔️', 'Nyanga National Park, Zimbabwe', -18.2167, 32.7500,
        '["https://images.unsplash.com/photo-1506905925346-21bda4d32df4", "https://images.unsplash.com/photo-1511593358241-7eea1f3c84e5"]',
        '["nyanga", "mountains", "waterfalls", "weekend-getaway"]', 167, 25, 11, true),

        (sample_user_id, 'Rock climbing and cave art at Matobo! The granite formations here are unlike anything I''ve seen. Plus, the ancient San paintings are a window into our ancestors'' lives. 🎨⛰️', 'Matobo National Park, Bulawayo', -20.5500, 28.5000,
        '["https://images.unsplash.com/photo-1523805009345-7448845a9e53", "https://images.unsplash.com/photo-1469854523086-cc02fe5d8800"]',
        '["matobo", "rock-climbing", "cave-art", "adventure"]', 201, 31, 14, true),

        (sample_user_id, 'Coffee plantation tour in the Eastern Highlands ☕ Learned so much about coffee production and enjoyed some of the best coffee I''ve ever tasted. The misty mountains are absolutely gorgeous!', 'Eastern Highlands, Mutare', -18.9661, 32.6701,
        '["https://images.unsplash.com/photo-1506905925346-21bda4d32df4", "https://images.unsplash.com/photo-1501785888041-af3ef285b470"]',
        '["coffee", "eastern-highlands", "plantation", "mountains"]', 145, 22, 8, true);

        RAISE NOTICE 'Sample posts inserted successfully for user: %', sample_user_id;
    ELSE
        RAISE NOTICE 'No users found. Please create a user account first by signing up in the app.';
    END IF;
END $$;

-- Insert sample stories (active for 24 hours)
DO $$
DECLARE
    sample_user_id UUID;
BEGIN
    SELECT id INTO sample_user_id FROM users LIMIT 1;

    IF sample_user_id IS NOT NULL THEN
        INSERT INTO stories (user_id, content, media_url, media_type, location, latitude, longitude, duration, is_active, expires_at) VALUES
        (sample_user_id, 'Sunset at Victoria Falls! 🌅', 'https://images.unsplash.com/photo-1547471080-7cc2caa01a7e', 'image', 'Victoria Falls', -17.9244, 25.8567, 24, true, NOW() + INTERVAL '24 hours'),
        (sample_user_id, 'Close encounter with elephants! 🐘', 'https://images.unsplash.com/photo-1516426122078-c23e76319801', 'image', 'Hwange National Park', -18.6297, 26.5000, 24, true, NOW() + INTERVAL '24 hours'),
        (sample_user_id, 'Morning mist in Nyanga 🌄', 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4', 'image', 'Nyanga', -18.2167, 32.7500, 24, true, NOW() + INTERVAL '24 hours'),
        (sample_user_id, 'Lake Kariba sunset cruise 🚤', 'https://images.unsplash.com/photo-1505142468610-359e7d316be0', 'image', 'Lake Kariba', -16.5167, 28.8000, 24, true, NOW() + INTERVAL '24 hours');

        RAISE NOTICE 'Sample stories inserted successfully';
    END IF;
END $$;

-- Success message
SELECT 'Sample data inserted successfully! Your app should now show real data from the database.' as result;

-- Query to verify data was inserted
SELECT
    (SELECT COUNT(*) FROM destinations) as total_destinations,
    (SELECT COUNT(*) FROM posts) as total_posts,
    (SELECT COUNT(*) FROM stories) as total_stories,
    (SELECT COUNT(*) FROM users) as total_users;