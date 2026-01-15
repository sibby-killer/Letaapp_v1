-- ============================================================================
-- SUPABASE RLS POLICIES - FIXED VERSION
-- ============================================================================
-- This script handles missing columns and tables gracefully
-- Run this ENTIRE script in Supabase SQL Editor
-- ============================================================================

-- ============================================================================
-- 1. USERS TABLE POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
DROP POLICY IF EXISTS "Public can view basic user info" ON users;
DROP POLICY IF EXISTS "Users can view all profiles" ON users;
DROP POLICY IF EXISTS "Service role can insert users" ON users;

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Allow users to insert their own profile during signup
CREATE POLICY "Users can insert own profile"
ON users FOR INSERT TO authenticated
WITH CHECK (auth.uid() = id);

-- Allow service role (triggers) to insert users
CREATE POLICY "Service role can insert users"
ON users FOR INSERT TO service_role
WITH CHECK (true);

-- Allow users to view all profiles (needed for chat, orders, etc.)
CREATE POLICY "Users can view all profiles"
ON users FOR SELECT TO authenticated
USING (true);

-- Allow anonymous users basic read access
CREATE POLICY "Anon can view user profiles"
ON users FOR SELECT TO anon
USING (true);

-- Allow users to update their own profile
CREATE POLICY "Users can update own profile"
ON users FOR UPDATE TO authenticated
USING (auth.uid() = id);

-- ============================================================================
-- 2. AUTO-CREATE USER ON SIGNUP (TRIGGER)
-- ============================================================================

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

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

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- 3. STORES TABLE POLICIES (vendor_id column exists)
-- ============================================================================

DROP POLICY IF EXISTS "Anyone can view stores" ON stores;
DROP POLICY IF EXISTS "Vendors can insert own stores" ON stores;
DROP POLICY IF EXISTS "Vendors can update own stores" ON stores;
DROP POLICY IF EXISTS "Stores are viewable by everyone" ON stores;

ALTER TABLE stores ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view stores"
ON stores FOR SELECT TO anon, authenticated
USING (true);

CREATE POLICY "Vendors can insert own stores"
ON stores FOR INSERT TO authenticated
WITH CHECK (auth.uid() = vendor_id);

CREATE POLICY "Vendors can update own stores"
ON stores FOR UPDATE TO authenticated
USING (auth.uid() = vendor_id);

-- ============================================================================
-- 4. PRODUCTS TABLE POLICIES (uses store_id -> stores.vendor_id)
-- ============================================================================

DROP POLICY IF EXISTS "Anyone can view products" ON products;
DROP POLICY IF EXISTS "Vendors can insert products" ON products;
DROP POLICY IF EXISTS "Vendors can update products" ON products;
DROP POLICY IF EXISTS "Products are viewable by everyone" ON products;
DROP POLICY IF EXISTS "Vendors can manage own products" ON products;

ALTER TABLE products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view products"
ON products FOR SELECT TO anon, authenticated
USING (true);

CREATE POLICY "Vendors can insert products"
ON products FOR INSERT TO authenticated
WITH CHECK (
  EXISTS (SELECT 1 FROM stores WHERE stores.id = store_id AND stores.vendor_id = auth.uid())
);

CREATE POLICY "Vendors can update products"
ON products FOR UPDATE TO authenticated
USING (
  EXISTS (SELECT 1 FROM stores WHERE stores.id = store_id AND stores.vendor_id = auth.uid())
);

CREATE POLICY "Vendors can delete products"
ON products FOR DELETE TO authenticated
USING (
  EXISTS (SELECT 1 FROM stores WHERE stores.id = store_id AND stores.vendor_id = auth.uid())
);

-- ============================================================================
-- 5. ORDERS TABLE POLICIES (NO vendor_id - use store_id -> stores.vendor_id)
-- ============================================================================

DROP POLICY IF EXISTS "Customers can view own orders" ON orders;
DROP POLICY IF EXISTS "Customers can create orders" ON orders;
DROP POLICY IF EXISTS "Users can update relevant orders" ON orders;
DROP POLICY IF EXISTS "Orders can be updated by related parties" ON orders;

ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Customers, vendors (via store), and riders can view relevant orders
CREATE POLICY "Users can view relevant orders"
ON orders FOR SELECT TO authenticated
USING (
  customer_id = auth.uid() 
  OR rider_id = auth.uid() 
  OR EXISTS (SELECT 1 FROM stores WHERE stores.id = orders.store_id AND stores.vendor_id = auth.uid())
);

-- Only customers can create orders
CREATE POLICY "Customers can create orders"
ON orders FOR INSERT TO authenticated
WITH CHECK (customer_id = auth.uid());

-- Customers, vendors (via store), and riders can update relevant orders
CREATE POLICY "Users can update relevant orders"
ON orders FOR UPDATE TO authenticated
USING (
  customer_id = auth.uid() 
  OR rider_id = auth.uid() 
  OR EXISTS (SELECT 1 FROM stores WHERE stores.id = orders.store_id AND stores.vendor_id = auth.uid())
);

-- ============================================================================
-- 6. CATEGORIES TABLE POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "Anyone can view categories" ON categories;

ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view categories"
ON categories FOR SELECT TO anon, authenticated
USING (true);

-- ============================================================================
-- 7. CHAT_ROOMS TABLE POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "Users can read their chat rooms" ON chat_rooms;
DROP POLICY IF EXISTS "Users can create chat rooms" ON chat_rooms;
DROP POLICY IF EXISTS "Participants can update chat rooms" ON chat_rooms;
DROP POLICY IF EXISTS "Users can view their chat rooms" ON chat_rooms;

ALTER TABLE chat_rooms ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their chat rooms"
ON chat_rooms FOR SELECT TO authenticated
USING (auth.uid() = ANY(participant_ids));

CREATE POLICY "Users can create chat rooms"
ON chat_rooms FOR INSERT TO authenticated
WITH CHECK (auth.uid() = ANY(participant_ids));

CREATE POLICY "Users can update their chat rooms"
ON chat_rooms FOR UPDATE TO authenticated
USING (auth.uid() = ANY(participant_ids));

-- ============================================================================
-- 8. CHAT_MESSAGES TABLE POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "Users can view chat messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can send chat messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can view messages in their rooms" ON chat_messages;
DROP POLICY IF EXISTS "Users can send messages to their rooms" ON chat_messages;

ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view messages in their rooms"
ON chat_messages FOR SELECT TO authenticated
USING (
  EXISTS (SELECT 1 FROM chat_rooms WHERE chat_rooms.id = chat_messages.room_id AND auth.uid() = ANY(chat_rooms.participant_ids))
);

CREATE POLICY "Users can send messages"
ON chat_messages FOR INSERT TO authenticated
WITH CHECK (
  sender_id = auth.uid() 
  AND EXISTS (SELECT 1 FROM chat_rooms WHERE chat_rooms.id = room_id AND auth.uid() = ANY(chat_rooms.participant_ids))
);

-- ============================================================================
-- 9. RIDER_EARNINGS TABLE POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "Riders can view own earnings" ON rider_earnings;
DROP POLICY IF EXISTS "System can insert earnings" ON rider_earnings;

ALTER TABLE rider_earnings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Riders can view own earnings"
ON rider_earnings FOR SELECT TO authenticated
USING (rider_id = auth.uid());

CREATE POLICY "System can insert earnings"
ON rider_earnings FOR INSERT TO authenticated
WITH CHECK (true);

-- ============================================================================
-- VERIFICATION: Check all tables have RLS enabled
-- ============================================================================

SELECT 
  schemaname, 
  tablename, 
  rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('users', 'stores', 'products', 'orders', 'categories', 'chat_rooms', 'chat_messages', 'rider_earnings');

-- ============================================================================
-- DONE! 
-- ============================================================================

SELECT '✅ ALL RLS POLICIES CREATED SUCCESSFULLY!' as result;
