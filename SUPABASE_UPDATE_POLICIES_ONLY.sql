-- ============================================================================
-- SUPABASE - UPDATE RLS POLICIES ONLY (Tables Already Exist)
-- ============================================================================
-- This script ONLY updates policies - does NOT create tables
-- Safe to run multiple times
-- ============================================================================

-- ============================================================================
-- 1. FIX USERS TABLE RLS POLICIES
-- ============================================================================

-- Drop existing policies first
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON users;
DROP POLICY IF EXISTS "Enable read for users based on user_id" ON users;
DROP POLICY IF EXISTS "Enable update for users based on user_id" ON users;
DROP POLICY IF EXISTS "Allow user to create their profile" ON users;
DROP POLICY IF EXISTS "Service role can do anything" ON users;
DROP POLICY IF EXISTS "Public can view basic user info" ON users;

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to insert their own profile
CREATE POLICY "Users can insert own profile"
ON users FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- Allow users to read their own profile
CREATE POLICY "Users can view own profile"
ON users FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- Allow users to update their own profile
CREATE POLICY "Users can update own profile"
ON users FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Allow everyone to read basic user info (for chat names, etc.)
CREATE POLICY "Public can view basic user info"
ON users FOR SELECT
TO anon, authenticated
USING (true);

-- ============================================================================
-- 2. CREATE AUTO-CREATE USER TRIGGER (Important for signup!)
-- ============================================================================

-- Drop existing trigger and function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Create function to auto-create user profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name, role, is_active, created_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'role', 'customer'),
    true,
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    full_name = COALESCE(EXCLUDED.full_name, users.full_name),
    role = COALESCE(EXCLUDED.role, users.role);
  
  RETURN NEW;
END;
$$;

-- Create trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- 3. FIX STORES TABLE RLS
-- ============================================================================

DROP POLICY IF EXISTS "Vendors can manage own stores" ON stores;
DROP POLICY IF EXISTS "Anyone can view stores" ON stores;
DROP POLICY IF EXISTS "Vendors can insert own stores" ON stores;
DROP POLICY IF EXISTS "Vendors can update own stores" ON stores;

ALTER TABLE stores ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view stores"
ON stores FOR SELECT
TO anon, authenticated
USING (true);

CREATE POLICY "Vendors can insert own stores"
ON stores FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = vendor_id);

CREATE POLICY "Vendors can update own stores"
ON stores FOR UPDATE
TO authenticated
USING (auth.uid() = vendor_id);

-- ============================================================================
-- 4. FIX PRODUCTS TABLE RLS
-- ============================================================================

DROP POLICY IF EXISTS "Anyone can view products" ON products;
DROP POLICY IF EXISTS "Store owners can manage products" ON products;
DROP POLICY IF EXISTS "Vendors can insert products" ON products;
DROP POLICY IF EXISTS "Vendors can update products" ON products;

ALTER TABLE products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view products"
ON products FOR SELECT
TO anon, authenticated
USING (true);

CREATE POLICY "Vendors can insert products"
ON products FOR INSERT
TO authenticated
WITH CHECK (
  store_id IN (SELECT id FROM stores WHERE owner_id = auth.uid())
);

CREATE POLICY "Vendors can update products"
ON products FOR UPDATE
TO authenticated
USING (
  store_id IN (SELECT id FROM stores WHERE owner_id = auth.uid())
);

-- ============================================================================
-- 5. FIX ORDERS TABLE RLS
-- ============================================================================

DROP POLICY IF EXISTS "Customers can view own orders" ON orders;
DROP POLICY IF EXISTS "Customers can create orders" ON orders;
DROP POLICY IF EXISTS "Vendors can view their orders" ON orders;
DROP POLICY IF EXISTS "Riders can view assigned orders" ON orders;
DROP POLICY IF EXISTS "Users can update relevant orders" ON orders;

ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Customers can view own orders"
ON orders FOR SELECT
TO authenticated
USING (
  customer_id = auth.uid() OR
  vendor_id = auth.uid() OR
  rider_id = auth.uid()
);

CREATE POLICY "Customers can create orders"
ON orders FOR INSERT
TO authenticated
WITH CHECK (customer_id = auth.uid());

CREATE POLICY "Users can update relevant orders"
ON orders FOR UPDATE
TO authenticated
USING (
  customer_id = auth.uid() OR
  vendor_id = auth.uid() OR
  rider_id = auth.uid()
);

-- ============================================================================
-- 6. FIX CATEGORIES TABLE RLS
-- ============================================================================

DROP POLICY IF EXISTS "Anyone can view categories" ON categories;

ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view categories"
ON categories FOR SELECT
TO anon, authenticated
USING (true);

-- ============================================================================
-- 7. FIX CHAT_ROOMS TABLE RLS
-- ============================================================================

DROP POLICY IF EXISTS "Users can read their chat rooms" ON chat_rooms;
DROP POLICY IF EXISTS "Users can create chat rooms" ON chat_rooms;
DROP POLICY IF EXISTS "Participants can update chat rooms" ON chat_rooms;

ALTER TABLE chat_rooms ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read their chat rooms"
ON chat_rooms FOR SELECT
TO authenticated
USING (auth.uid() = ANY(participant_ids));

CREATE POLICY "Users can create chat rooms"
ON chat_rooms FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = ANY(participant_ids));

CREATE POLICY "Participants can update chat rooms"
ON chat_rooms FOR UPDATE
TO authenticated
USING (auth.uid() = ANY(participant_ids));

-- ============================================================================
-- 8. FIX MESSAGES TABLE RLS
-- ============================================================================

DROP POLICY IF EXISTS "Users can read messages from their rooms" ON messages;
DROP POLICY IF EXISTS "Users can send messages" ON messages;

ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read messages from their rooms"
ON messages FOR SELECT
TO authenticated
USING (
  room_id IN (
    SELECT id FROM chat_rooms 
    WHERE auth.uid() = ANY(participant_ids)
  )
);

CREATE POLICY "Users can send messages"
ON messages FOR INSERT
TO authenticated
WITH CHECK (
  sender_id = auth.uid() AND
  room_id IN (
    SELECT id FROM chat_rooms 
    WHERE auth.uid() = ANY(participant_ids)
  )
);

-- ============================================================================
-- 9. FIX CHAT_MESSAGES TABLE RLS (if different from messages)
-- ============================================================================

DROP POLICY IF EXISTS "Users can view chat messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can send chat messages" ON chat_messages;

ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view chat messages"
ON chat_messages FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Users can send chat messages"
ON chat_messages FOR INSERT
TO authenticated
WITH CHECK (sender_id = auth.uid());

-- ============================================================================
-- 10. FIX RIDER_EARNINGS TABLE RLS
-- ============================================================================

DROP POLICY IF EXISTS "Riders can view own earnings" ON rider_earnings;
DROP POLICY IF EXISTS "System can insert earnings" ON rider_earnings;

ALTER TABLE rider_earnings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Riders can view own earnings"
ON rider_earnings FOR SELECT
TO authenticated
USING (rider_id = auth.uid());

CREATE POLICY "System can insert earnings"
ON rider_earnings FOR INSERT
TO authenticated
WITH CHECK (true);

-- ============================================================================
-- 11. ENABLE REALTIME FOR CHAT TABLES
-- ============================================================================

-- Add tables to realtime publication (ignore error if already added)
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE messages;
EXCEPTION WHEN duplicate_object THEN
  NULL;
END $$;

DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE chat_rooms;
EXCEPTION WHEN duplicate_object THEN
  NULL;
END $$;

DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;
EXCEPTION WHEN duplicate_object THEN
  NULL;
END $$;

DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE orders;
EXCEPTION WHEN duplicate_object THEN
  NULL;
END $$;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

SELECT 'RLS POLICIES UPDATED SUCCESSFULLY!' as status;

-- Show all policies
SELECT tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
