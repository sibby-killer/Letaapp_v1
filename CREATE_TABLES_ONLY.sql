-- ============================================================================
-- SUPABASE REALTIME - CREATE TABLES ONLY (If They Don't Exist)
-- ============================================================================
-- Only run this if DATABASE_SIMPLE_FIX.sql shows tables are MISSING
-- ============================================================================

-- ============================================================================
-- 1. CREATE CHAT_ROOMS TABLE (Only if it doesn't exist)
-- ============================================================================

CREATE TABLE IF NOT EXISTS chat_rooms (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('direct', 'vendor_customer', 'rider_customer', 'group')),
  participant_ids UUID[] NOT NULL DEFAULT '{}',
  last_message TEXT,
  last_message_time TIMESTAMPTZ,
  unread_count INTEGER DEFAULT 0,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 2. CREATE MESSAGES TABLE (Only if it doesn't exist)
-- ============================================================================

CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  sender_name TEXT NOT NULL,
  sender_image_url TEXT,
  message TEXT NOT NULL,
  type TEXT DEFAULT 'text' CHECK (type IN ('text', 'image', 'location', 'system')),
  metadata JSONB,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

-- ============================================================================
-- 3. CREATE INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_chat_rooms_participants 
ON chat_rooms USING GIN (participant_ids);

CREATE INDEX IF NOT EXISTS idx_chat_rooms_last_message 
ON chat_rooms (last_message_time DESC);

CREATE INDEX IF NOT EXISTS idx_messages_room_id 
ON messages (room_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_messages_sender_id 
ON messages (sender_id);

CREATE INDEX IF NOT EXISTS idx_messages_unread 
ON messages (room_id, is_read) WHERE is_read = false;

-- ============================================================================
-- 4. ENABLE ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE chat_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 5. ENABLE REALTIME (Manual - see instructions below)
-- ============================================================================

/*
YOU MUST DO THIS MANUALLY IN SUPABASE DASHBOARD:

1. Go to Database → Replication
2. Find "supabase_realtime" publication
3. Click on it
4. Enable these tables:
   - chat_rooms
   - messages
5. Click "Save"

OR use Supabase Dashboard → API → Realtime → Enable for these tables
*/

-- ============================================================================
-- DONE!
-- ============================================================================

SELECT 'Tables created! Now enable realtime in Supabase Dashboard.' as message;
