-- ============================================================================
-- SUPABASE REALTIME - CHECK AND FIX EXISTING TABLES
-- ============================================================================
-- Run this if you get "already exists" errors
-- This script checks what's already there and only creates what's missing
-- ============================================================================

-- Check if tables exist
DO $$ 
BEGIN
    -- Check chat_rooms
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'chat_rooms') THEN
        RAISE NOTICE 'chat_rooms table already exists ✓';
    ELSE
        RAISE NOTICE 'chat_rooms table MISSING - will create';
        CREATE TABLE chat_rooms (
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
    END IF;

    -- Check messages
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'messages') THEN
        RAISE NOTICE 'messages table already exists ✓';
    ELSE
        RAISE NOTICE 'messages table MISSING - will create';
        CREATE TABLE messages (
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
    END IF;
END $$;

-- ============================================================================
-- ENABLE REALTIME (Safe - won't error if already enabled)
-- ============================================================================

-- Remove from publication if already there (to avoid "already member" error)
DO $$ 
BEGIN
    -- Try to add to publication (ignore if already there)
    BEGIN
        ALTER PUBLICATION supabase_realtime DROP TABLE IF EXISTS chat_rooms;
        ALTER PUBLICATION supabase_realtime DROP TABLE IF EXISTS messages;
        RAISE NOTICE 'Removed tables from publication (if they were there)';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Tables were not in publication';
    END;
    
    -- Now add them fresh
    ALTER PUBLICATION supabase_realtime ADD TABLE chat_rooms;
    ALTER PUBLICATION supabase_realtime ADD TABLE messages;
    RAISE NOTICE 'Added tables to realtime publication ✓';
END $$;

-- ============================================================================
-- CREATE INDEXES (Safe - won't error if already exist)
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_chat_rooms_participants ON chat_rooms USING GIN (participant_ids);
CREATE INDEX IF NOT EXISTS idx_chat_rooms_last_message ON chat_rooms (last_message_time DESC);
CREATE INDEX IF NOT EXISTS idx_messages_room_id ON messages (room_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages (sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_unread ON messages (room_id, is_read) WHERE is_read = false;

-- ============================================================================
-- ENABLE RLS (Safe - won't error if already enabled)
-- ============================================================================

ALTER TABLE chat_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- CREATE POLICIES (Drop existing ones first)
-- ============================================================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can read their chat rooms" ON chat_rooms;
DROP POLICY IF EXISTS "Users can create chat rooms" ON chat_rooms;
DROP POLICY IF EXISTS "Participants can update chat rooms" ON chat_rooms;
DROP POLICY IF EXISTS "Users can read messages from their rooms" ON messages;
DROP POLICY IF EXISTS "Users can send messages" ON messages;
DROP POLICY IF EXISTS "Users can update messages in their rooms" ON messages;

-- Create fresh policies
CREATE POLICY "Users can read their chat rooms"
ON chat_rooms FOR SELECT
USING (auth.uid() = ANY(participant_ids));

CREATE POLICY "Users can create chat rooms"
ON chat_rooms FOR INSERT
WITH CHECK (auth.uid() = ANY(participant_ids));

CREATE POLICY "Participants can update chat rooms"
ON chat_rooms FOR UPDATE
USING (auth.uid() = ANY(participant_ids));

CREATE POLICY "Users can read messages from their rooms"
ON messages FOR SELECT
USING (
  room_id IN (
    SELECT id FROM chat_rooms 
    WHERE auth.uid() = ANY(participant_ids)
  )
);

CREATE POLICY "Users can send messages"
ON messages FOR INSERT
WITH CHECK (
  sender_id = auth.uid() AND
  room_id IN (
    SELECT id FROM chat_rooms 
    WHERE auth.uid() = ANY(participant_ids)
  )
);

CREATE POLICY "Users can update messages in their rooms"
ON messages FOR UPDATE
USING (
  room_id IN (
    SELECT id FROM chat_rooms 
    WHERE auth.uid() = ANY(participant_ids)
  )
);

-- ============================================================================
-- CREATE HELPER FUNCTIONS (Drop existing ones first)
-- ============================================================================

DROP FUNCTION IF EXISTS update_chat_room_on_message();
DROP FUNCTION IF EXISTS create_direct_chat_room(UUID, UUID);
DROP FUNCTION IF EXISTS create_order_chat_room(UUID);
DROP FUNCTION IF EXISTS get_unread_count(UUID);

-- Update chat room on new message
CREATE OR REPLACE FUNCTION update_chat_room_on_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE chat_rooms
  SET 
    last_message = NEW.message,
    last_message_time = NEW.created_at,
    updated_at = NOW()
  WHERE id = NEW.room_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_update_chat_room ON messages;
CREATE TRIGGER trigger_update_chat_room
AFTER INSERT ON messages
FOR EACH ROW
EXECUTE FUNCTION update_chat_room_on_message();

-- Function: Create direct chat room
CREATE OR REPLACE FUNCTION create_direct_chat_room(
  user_id_1 UUID,
  user_id_2 UUID
)
RETURNS UUID AS $$
DECLARE
  room_id UUID;
  user1_name TEXT;
  user2_name TEXT;
BEGIN
  -- Get user names
  SELECT full_name INTO user1_name FROM users WHERE id = user_id_1;
  SELECT full_name INTO user2_name FROM users WHERE id = user_id_2;
  
  -- Check if room already exists
  SELECT id INTO room_id
  FROM chat_rooms
  WHERE type = 'direct'
    AND participant_ids @> ARRAY[user_id_1, user_id_2]
    AND participant_ids <@ ARRAY[user_id_1, user_id_2];
  
  -- If room doesn't exist, create it
  IF room_id IS NULL THEN
    INSERT INTO chat_rooms (name, type, participant_ids)
    VALUES (
      user1_name || ' & ' || user2_name,
      'direct',
      ARRAY[user_id_1, user_id_2]
    )
    RETURNING id INTO room_id;
  END IF;
  
  RETURN room_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get unread count
CREATE OR REPLACE FUNCTION get_unread_count(user_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
  total_unread INTEGER;
BEGIN
  SELECT COUNT(*)::INTEGER INTO total_unread
  FROM messages m
  JOIN chat_rooms cr ON m.room_id = cr.id
  WHERE cr.participant_ids @> ARRAY[user_uuid]
    AND m.sender_id != user_uuid
    AND m.is_read = false;
  
  RETURN COALESCE(total_unread, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Check if everything is set up correctly
DO $$ 
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'VERIFICATION COMPLETE!';
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
    
    -- Check tables
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'chat_rooms') THEN
        RAISE NOTICE '✓ chat_rooms table exists';
    ELSE
        RAISE NOTICE '✗ chat_rooms table MISSING!';
    END IF;
    
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'messages') THEN
        RAISE NOTICE '✓ messages table exists';
    ELSE
        RAISE NOTICE '✗ messages table MISSING!';
    END IF;
    
    -- Check realtime
    IF EXISTS (
        SELECT FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND schemaname = 'public' 
        AND tablename = 'chat_rooms'
    ) THEN
        RAISE NOTICE '✓ chat_rooms realtime enabled';
    ELSE
        RAISE NOTICE '✗ chat_rooms realtime NOT enabled!';
    END IF;
    
    IF EXISTS (
        SELECT FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND schemaname = 'public' 
        AND tablename = 'messages'
    ) THEN
        RAISE NOTICE '✓ messages realtime enabled';
    ELSE
        RAISE NOTICE '✗ messages realtime NOT enabled!';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'If all items show ✓, you are ready!';
    RAISE NOTICE '========================================';
END $$;
