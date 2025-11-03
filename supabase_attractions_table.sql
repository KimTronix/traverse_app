-- Create attractions table for business owners to manage their places/events
CREATE TABLE IF NOT EXISTS public.attractions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('restaurant', 'hotel', 'activity', 'transport', 'event', 'food', 'culture', 'sites', 'game_parks', 'recreation', 'nature', 'shopping', 'entertainment', 'religious', 'historical', 'other')),
    description TEXT NOT NULL,
    location TEXT NOT NULL,
    address TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,

    
    contact_email TEXT,
    contact_phone TEXT,

    website TEXT,
    images TEXT[],
    opening_hours JSONB,
    entry_fee DOUBLE PRECISION,
    currency TEXT DEFAULT 'USD',
    rating DOUBLE PRECISION DEFAULT 0.0,
    review_count INTEGER DEFAULT 0,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'inactive')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_attractions_owner_id ON public.attractions(owner_id);
CREATE INDEX IF NOT EXISTS idx_attractions_category ON public.attractions(category);
CREATE INDEX IF NOT EXISTS idx_attractions_status ON public.attractions(status);
CREATE INDEX IF NOT EXISTS idx_attractions_created_at ON public.attractions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_attractions_location ON public.attractions USING gin(to_tsvector('english', location));
CREATE INDEX IF NOT EXISTS idx_attractions_name ON public.attractions USING gin(to_tsvector('english', name));

-- Enable Row Level Security
ALTER TABLE public.attractions ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can view approved attractions
CREATE POLICY "Users can view approved attractions" ON public.attractions
    FOR SELECT
    USING (status = 'approved' OR auth.uid() = owner_id);

-- RLS Policy: Business owners can insert their own attractions
CREATE POLICY "Business owners can insert attractions" ON public.attractions
    FOR INSERT
    WITH CHECK (auth.uid() = owner_id);

-- RLS Policy: Business owners can update their own attractions
CREATE POLICY "Business owners can update own attractions" ON public.attractions
    FOR UPDATE
    USING (auth.uid() = owner_id)
    WITH CHECK (auth.uid() = owner_id);

-- RLS Policy: Business owners can delete their own attractions
CREATE POLICY "Business owners can delete own attractions" ON public.attractions
    FOR DELETE
    USING (auth.uid() = owner_id);

-- RLS Policy: Admins can view all attractions
CREATE POLICY "Admins can view all attractions" ON public.attractions
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE users.id = auth.uid()
            AND users.role = 'admin'
        )
    );

-- RLS Policy: Admins can update any attraction
CREATE POLICY "Admins can update any attraction" ON public.attractions
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE users.id = auth.uid()
            AND users.role = 'admin'
        )
    );

-- RLS Policy: Admins can delete any attraction
CREATE POLICY "Admins can delete any attraction" ON public.attractions
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE users.id = auth.uid()
            AND users.role = 'admin'
        )
    );

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_attractions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_attractions_updated_at
    BEFORE UPDATE ON public.attractions
    FOR EACH ROW
    EXECUTE FUNCTION update_attractions_updated_at();

-- Add some comments for documentation
COMMENT ON TABLE public.attractions IS 'Stores attractions, places, and events created by business owners';
COMMENT ON COLUMN public.attractions.owner_id IS 'Reference to the business owner who created this attraction';
COMMENT ON COLUMN public.attractions.status IS 'Approval status: pending (awaiting admin approval), approved (visible to all users), rejected, inactive';
COMMENT ON COLUMN public.attractions.category IS 'Type of attraction: restaurant, hotel, activity, transport, event, etc.';