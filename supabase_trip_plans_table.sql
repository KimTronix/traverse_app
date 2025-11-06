-- Trip Plans Table
-- Run this script in your Supabase SQL Editor to create the trip_plans table

CREATE TABLE trip_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    destination VARCHAR(200) NOT NULL,
    budget_range VARCHAR(20) DEFAULT 'medium', -- budget, medium, luxury
    duration VARCHAR(50), -- e.g., "5 days", "1 week"
    travel_style VARCHAR(50) DEFAULT 'Casual', -- Casual, Adventure, Luxury, Family, Romantic
    activities JSONB DEFAULT '[]', -- Array of activities
    start_date DATE,
    end_date DATE,
    travelers INTEGER DEFAULT 1,
    tags JSONB DEFAULT '[]', -- Array of tags
    status VARCHAR(20) DEFAULT 'draft', -- draft, confirmed, completed, cancelled
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for trip_plans table
CREATE INDEX idx_trip_plans_user_id ON trip_plans(user_id);
CREATE INDEX idx_trip_plans_destination ON trip_plans(destination);
CREATE INDEX idx_trip_plans_start_date ON trip_plans(start_date);
CREATE INDEX idx_trip_plans_status ON trip_plans(status);
CREATE INDEX idx_trip_plans_created_at ON trip_plans(created_at DESC);

-- Create trigger for updated_at timestamp
CREATE TRIGGER update_trip_plans_updated_at BEFORE UPDATE ON trip_plans
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security
ALTER TABLE trip_plans ENABLE ROW LEVEL SECURITY;

-- RLS policies for trip_plans
-- Users can view own trip plans
CREATE POLICY "Users can view own trip plans" ON trip_plans FOR SELECT
    USING (auth.uid() = user_id);

-- Users can create own trip plans
CREATE POLICY "Users can create own trip plans" ON trip_plans FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update own trip plans
CREATE POLICY "Users can update own trip plans" ON trip_plans FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can delete own trip plans
CREATE POLICY "Users can delete own trip plans" ON trip_plans FOR DELETE
    USING (auth.uid() = user_id);

-- Admins can view all trip plans
CREATE POLICY "Admins can view all trip plans" ON trip_plans FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM users
        WHERE users.id = auth.uid() AND users.role = 'admin'
    ));
