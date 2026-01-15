-- ============================================================================
-- RIDER PROFILES TABLE - Run this in Supabase SQL Editor
-- ============================================================================

-- Create rider_profiles table
CREATE TABLE IF NOT EXISTS rider_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rider_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    transport_type VARCHAR(20) DEFAULT 'bicycle' CHECK (transport_type IN ('skates', 'bicycle', 'motorbike')),
    mobile_money_number VARCHAR(20),
    paystack_subaccount_id VARCHAR(100),
    is_verified BOOLEAN DEFAULT false,
    is_online BOOLEAN DEFAULT false,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    total_earnings DECIMAL(10, 2) DEFAULT 0.00,
    total_deliveries INTEGER DEFAULT 0,
    rating DECIMAL(3, 2) DEFAULT 5.00,
    rating_count INTEGER DEFAULT 0,
    notifications_enabled BOOLEAN DEFAULT true,
    overlay_permission_granted BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(rider_id)
);

-- Enable RLS
ALTER TABLE rider_profiles ENABLE ROW LEVEL SECURITY;

-- Policies for rider_profiles
DROP POLICY IF EXISTS "Riders can view own profile" ON rider_profiles;
DROP POLICY IF EXISTS "Riders can insert own profile" ON rider_profiles;
DROP POLICY IF EXISTS "Riders can update own profile" ON rider_profiles;

CREATE POLICY "Riders can view own profile"
ON rider_profiles FOR SELECT TO authenticated
USING (rider_id = auth.uid());

CREATE POLICY "Riders can insert own profile"
ON rider_profiles FOR INSERT TO authenticated
WITH CHECK (rider_id = auth.uid());

CREATE POLICY "Riders can update own profile"
ON rider_profiles FOR UPDATE TO authenticated
USING (rider_id = auth.uid());

-- Allow vendors and customers to view rider info (for order tracking)
CREATE POLICY "Users can view rider location when online"
ON rider_profiles FOR SELECT TO authenticated
USING (is_online = true);

-- Create index for location-based queries
CREATE INDEX IF NOT EXISTS idx_rider_profiles_location ON rider_profiles(latitude, longitude) WHERE is_online = true;
CREATE INDEX IF NOT EXISTS idx_rider_profiles_rider_id ON rider_profiles(rider_id);

-- ============================================================================
-- Update chat_messages table to match our model
-- ============================================================================

-- Add columns if they don't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'chat_messages' AND column_name = 'content') THEN
        ALTER TABLE chat_messages ADD COLUMN content TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'chat_messages' AND column_name = 'message_type') THEN
        ALTER TABLE chat_messages ADD COLUMN message_type VARCHAR(20) DEFAULT 'text';
    END IF;
END $$;

-- ============================================================================
-- Update chat_rooms table
-- ============================================================================

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'chat_rooms' AND column_name = 'last_message') THEN
        ALTER TABLE chat_rooms ADD COLUMN last_message TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'chat_rooms' AND column_name = 'unread_count') THEN
        ALTER TABLE chat_rooms ADD COLUMN unread_count INTEGER DEFAULT 0;
    END IF;
END $$;

-- ============================================================================
-- DONE!
-- ============================================================================

SELECT '✅ Rider profiles table and policies created!' as result;
