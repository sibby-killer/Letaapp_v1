-- ============================================================================
-- SUPABASE REALTIME MIGRATION - DATABASE SCHEMA UPDATES
-- ============================================================================
-- Date: 2026-01-14
-- Purpose: Add required tables and functions for Supabase Realtime features
-- Migration: Socket.io → Supabase Realtime
-- ============================================================================

-- ============================================================================
-- 1. CHAT ROOMS TABLE
-- ============================================================================
-- Stores chat room metadata (who's in the room, last message, etc.)

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

-- Index for fast lookups by participant
CREATE INDEX IF NOT EXISTS idx_chat_rooms_participants ON chat_rooms USING GIN (participant_ids);

-- Index for sorting by last message time
CREATE INDEX IF NOT EXISTS idx_chat_rooms_last_message ON chat_rooms (last_message_time DESC);

-- Enable Realtime for chat_rooms
ALTER PUBLICATION supabase_realtime ADD TABLE chat_rooms;

-- ============================================================================
-- 2. MESSAGES TABLE
-- ============================================================================
-- Stores all chat messages (persistent storage)

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

-- Index for fast room lookups
CREATE INDEX IF NOT EXISTS idx_messages_room_id ON messages (room_id, created_at DESC);

-- Index for sender lookups
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages (sender_id);

-- Index for unread messages
CREATE INDEX IF NOT EXISTS idx_messages_unread ON messages (room_id, is_read) WHERE is_read = false;

-- Enable Realtime for messages (THIS IS CRITICAL!)
ALTER PUBLICATION supabase_realtime ADD TABLE messages;

-- ============================================================================
-- 3. AUTO-UPDATE CHAT ROOM ON NEW MESSAGE (Trigger Function)
-- ============================================================================
-- Automatically update chat_rooms.last_message and last_message_time
-- when a new message is inserted

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

-- ============================================================================
-- 4. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================
-- Security rules to control who can read/write messages

-- Enable RLS on chat_rooms
ALTER TABLE chat_rooms ENABLE ROW LEVEL SECURITY;

-- Enable RLS on messages
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- CHAT ROOMS POLICIES
-- ============================================================================

-- Policy: Users can read rooms they're a participant of
CREATE POLICY "Users can read their chat rooms"
ON chat_rooms FOR SELECT
USING (
  auth.uid() = ANY(participant_ids)
);

-- Policy: Users can create chat rooms
CREATE POLICY "Users can create chat rooms"
ON chat_rooms FOR INSERT
WITH CHECK (
  auth.uid() = ANY(participant_ids)
);

-- Policy: Participants can update room metadata
CREATE POLICY "Participants can update chat rooms"
ON chat_rooms FOR UPDATE
USING (
  auth.uid() = ANY(participant_ids)
);

-- ============================================================================
-- MESSAGES POLICIES
-- ============================================================================

-- Policy: Users can read messages from their rooms
CREATE POLICY "Users can read messages from their rooms"
ON messages FOR SELECT
USING (
  room_id IN (
    SELECT id FROM chat_rooms 
    WHERE auth.uid() = ANY(participant_ids)
  )
);

-- Policy: Users can send messages (insert their own messages)
CREATE POLICY "Users can send messages"
ON messages FOR INSERT
WITH CHECK (
  sender_id = auth.uid() AND
  room_id IN (
    SELECT id FROM chat_rooms 
    WHERE auth.uid() = ANY(participant_ids)
  )
);

-- Policy: Users can update their own messages (for read receipts)
CREATE POLICY "Users can update messages in their rooms"
ON messages FOR UPDATE
USING (
  room_id IN (
    SELECT id FROM chat_rooms 
    WHERE auth.uid() = ANY(participant_ids)
  )
);

-- ============================================================================
-- 5. HELPER FUNCTIONS
-- ============================================================================

-- Function: Create a direct chat room between two users
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

-- Function: Create chat room for order (customer, vendor, rider)
CREATE OR REPLACE FUNCTION create_order_chat_room(
  order_uuid UUID
)
RETURNS UUID AS $$
DECLARE
  room_id UUID;
  customer_id UUID;
  vendor_id UUID;
  rider_id UUID;
  order_number TEXT;
BEGIN
  -- Get order details
  SELECT customer_id, vendor_id, rider_id, order_number
  INTO customer_id, vendor_id, rider_id, order_number
  FROM orders
  WHERE id = order_uuid;
  
  -- Check if room already exists
  SELECT id INTO room_id
  FROM chat_rooms
  WHERE type = 'group'
    AND metadata->>'order_id' = order_uuid::TEXT;
  
  -- If room doesn't exist, create it
  IF room_id IS NULL THEN
    INSERT INTO chat_rooms (
      name, 
      type, 
      participant_ids,
      metadata
    )
    VALUES (
      'Order ' || order_number,
      'group',
      ARRAY[customer_id, vendor_id, rider_id],
      jsonb_build_object('order_id', order_uuid)
    )
    RETURNING id INTO room_id;
  END IF;
  
  RETURN room_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get unread message count for user
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
-- 6. REALTIME CONFIGURATION
-- ============================================================================

-- Note: Supabase Realtime is enabled by default for tables added to the
-- 'supabase_realtime' publication. We've already added chat_rooms and messages.

-- To verify realtime is enabled, run:
-- SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime';

-- ============================================================================
-- 7. SAMPLE DATA (for testing)
-- ============================================================================

-- Insert a test chat room
/*
INSERT INTO chat_rooms (name, type, participant_ids)
VALUES (
  'Test Room',
  'direct',
  ARRAY[
    '00000000-0000-0000-0000-000000000001'::UUID,
    '00000000-0000-0000-0000-000000000002'::UUID
  ]
);
*/

-- Insert a test message
/*
INSERT INTO messages (room_id, sender_id, sender_name, message)
VALUES (
  (SELECT id FROM chat_rooms LIMIT 1),
  '00000000-0000-0000-0000-000000000001'::UUID,
  'Test User',
  'Hello, this is a test message!'
);
*/

-- ============================================================================
-- 8. MIGRATION NOTES
-- ============================================================================

/*
IMPORTANT CHANGES FROM SOCKET.IO:

1. CHAT MESSAGES:
   - Old: Socket.io events (emit 'send_message')
   - New: INSERT into messages table
   - Benefit: Persistent storage, automatic realtime updates

2. TYPING INDICATORS:
   - Old: Socket.io events (emit 'typing')
   - New: Supabase Broadcast Channels (ephemeral)
   - Implementation: Done in Flutter (SupabaseRealtimeService)
   - No database storage needed

3. LIVE LOCATION:
   - Old: Socket.io events (emit 'location')
   - New: Supabase Broadcast Channels (ephemeral)
   - Implementation: Done in Flutter (SupabaseRealtimeService)
   - No database storage (too many updates)

4. READ RECEIPTS:
   - Old: Socket.io events (emit 'mark_read')
   - New: UPDATE messages SET is_read = true
   - Benefit: Persistent read status

5. AUTHENTICATION:
   - Old: Manual headers in Socket.io
   - New: Automatic via Supabase Auth + RLS
   - Benefit: Better security, no manual token management

WHAT'S REMOVED:
- Socket.io server (socket-server/ folder)
- Node.js dependencies
- WebSocket event handling code
- Manual connection management

WHAT'S ADDED:
- chat_rooms table
- messages table
- RLS policies
- Helper functions
- Automatic realtime updates
*/

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check if tables exist
SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename IN ('chat_rooms', 'messages');

-- Check if realtime is enabled
SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public';

-- Check RLS policies
SELECT tablename, policyname, cmd FROM pg_policies WHERE schemaname = 'public' AND tablename IN ('chat_rooms', 'messages');

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================

-- Run this entire file in your Supabase SQL Editor to complete the migration!
