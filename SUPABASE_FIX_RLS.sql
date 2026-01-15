-- ============================================================================
-- SUPABASE RLS FIX - Run this to fix "row violates row-level security" error
-- ============================================================================
-- Safe to run multiple times - uses DROP IF EXISTS
-- ============================================================================

-- ============================================================================
-- 1. FIX USERS TABLE RLS POLICIES
-- ============================================================================

-- Drop existing policies first (prevents duplicate errors)
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON users;
DROP POLICY IF EXISTS "Enable read for users based on user_id" ON users;
DROP POLICY IF EXISTS "Enable update for users based on user_id" ON users;
DROP POLICY IF EXISTS "Allow user to create their profile" ON users;
DROP POLICY IF EXISTS "Service role can do anything" ON users;

-- Enable RLS on users table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Policy: Allow authenticated users to insert their own profile
CREATE POLICY "Users can insert own profile"
ON users FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- Policy: Allow users to read their own profile
CREATE POLICY "Users can view own profile"
ON users FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- Policy: Allow users to update their own profile
CREATE POLICY "Users can update own profile"
ON users FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Policy: Allow public to read basic user info (for chat, etc.)
DROP POLICY IF EXISTS "Public can view basic user info" ON users;
CREATE POLICY "Public can view basic user info"
ON users FOR SELECT
TO anon, authenticated
USING (true);

-- ============================================================================
-- 2. CREATE AUTO-CREATE USER PROFILE TRIGGER
-- ============================================================================

-- This automatically creates a user profile when someone signs up

-- Drop existing function and trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Create function to handle new user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name, role, created_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'role', 'customer'),
    NOW()
  )
  ON CONFLICT (id) DO NOTHING;
  
  RETURN NEW;
END;
$$;

-- Create trigger on auth.users
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

-- Anyone can view stores
CREATE POLICY "Anyone can view stores"
ON stores FOR SELECT
TO anon, authenticated
USING (true);

-- Vendors can insert their own stores
CREATE POLICY "Vendors can insert own stores"
ON stores FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = owner_id);

-- Vendors can update their own stores
CREATE POLICY "Vendors can update own stores"
ON stores FOR UPDATE
TO authenticated
USING (auth.uid() = owner_id)
WITH CHECK (auth.uid() = owner_id);

-- ============================================================================
-- 4. FIX PRODUCTS TABLE RLS
-- ============================================================================

DROP POLICY IF EXISTS "Anyone can view products" ON products;
DROP POLICY IF EXISTS "Store owners can manage products" ON products;
DROP POLICY IF EXISTS "Vendors can insert products" ON products;
DROP POLICY IF EXISTS "Vendors can update products" ON products;

ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Anyone can view products
CREATE POLICY "Anyone can view products"
ON products FOR SELECT
TO anon, authenticated
USING (true);

-- Store owners can insert products
CREATE POLICY "Vendors can insert products"
ON products FOR INSERT
TO authenticated
WITH CHECK (
  store_id IN (SELECT id FROM stores WHERE owner_id = auth.uid())
);

-- Store owners can update products
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

-- Customers can view their own orders
CREATE POLICY "Customers can view own orders"
ON orders FOR SELECT
TO authenticated
USING (
  customer_id = auth.uid() OR
  vendor_id = auth.uid() OR
  rider_id = auth.uid()
);

-- Customers can create orders
CREATE POLICY "Customers can create orders"
ON orders FOR INSERT
TO authenticated
WITH CHECK (customer_id = auth.uid());

-- Users can update orders they're involved in
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

-- Anyone can view categories
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

-- Users can view rooms they're in
CREATE POLICY "Users can read their chat rooms"
ON chat_rooms FOR SELECT
TO authenticated
USING (auth.uid() = ANY(participant_ids));

-- Users can create chat rooms
CREATE POLICY "Users can create chat rooms"
ON chat_rooms FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = ANY(participant_ids));

-- Participants can update rooms
CREATE POLICY "Participants can update chat rooms"
ON chat_rooms FOR UPDATE
TO authenticated
USING (auth.uid() = ANY(participant_ids));

-- ============================================================================
-- 8. FIX MESSAGES TABLE RLS
-- ============================================================================

DROP POLICY IF EXISTS "Users can read messages from their rooms" ON messages;
DROP POLICY IF EXISTS "Users can send messages" ON messages;
DROP POLICY IF EXISTS "Users can update messages in their rooms" ON messages;

ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Users can read messages from their rooms
CREATE POLICY "Users can read messages from their rooms"
ON messages FOR SELECT
TO authenticated
USING (
  room_id IN (
    SELECT id FROM chat_rooms 
    WHERE auth.uid() = ANY(participant_ids)
  )
);

-- Users can send messages
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
-- 9. VERIFICATION QUERIES
-- ============================================================================

-- Check RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('users', 'stores', 'products', 'orders', 'categories', 'chat_rooms', 'messages');

-- Check policies exist
SELECT tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename;

-- ============================================================================
-- DONE! Now signup should work.
-- ============================================================================

/*
SUMMARY OF FIXES:

1. ✅ Users table - Can insert own profile
2. ✅ Auto-trigger - Creates user profile on signup
3. ✅ Stores table - Vendors can manage own stores
4. ✅ Products table - Store owners can manage products
5. ✅ Orders table - Users can see relevant orders
6. ✅ Categories table - Anyone can view
7. ✅ Chat rooms table - Participants can access
8. ✅ Messages table - Users can send/receive

After running this SQL, try signing up again in the app!
*/
