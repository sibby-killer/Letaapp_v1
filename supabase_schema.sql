-- LETA APP DATABASE SCHEMA
-- Run this in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable PostGIS for geospatial queries
CREATE EXTENSION IF NOT EXISTS postgis;

-- ============================================
-- USERS TABLE
-- ============================================
CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('customer', 'vendor', 'rider', 'admin')),
    profile_image_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE
);

-- Add location column for riders (for geospatial queries)
ALTER TABLE users ADD COLUMN location GEOMETRY(POINT, 4326);

-- Create index for role-based queries
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_location ON users USING GIST(location);

-- ============================================
-- CATEGORIES TABLE (Dynamic)
-- ============================================
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    icon_url TEXT NOT NULL,
    color TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    is_custom BOOLEAN DEFAULT FALSE,
    created_by UUID REFERENCES users(id),
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_categories_is_active ON categories(is_active);
CREATE INDEX idx_categories_display_order ON categories(display_order);

-- Insert default categories
INSERT INTO categories (name, description, icon_url, color, display_order) VALUES
    ('Food', 'Restaurants and food delivery', 'food_icon', '#FF6B6B', 1),
    ('Gas', 'Gas cylinder refills', 'gas_icon', '#4ECDC4', 2),
    ('Second-Hand', 'Used items marketplace', 'secondhand_icon', '#95E1D3', 3),
    ('Groceries', 'Fresh produce and groceries', 'grocery_icon', '#F38181', 4);

-- ============================================
-- STORES TABLE
-- ============================================
CREATE TABLE stores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vendor_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    logo_url TEXT,
    banner_url TEXT,
    address TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    location GEOMETRY(POINT, 4326),
    phone TEXT,
    is_open BOOLEAN DEFAULT TRUE,
    opening_hours JSONB,
    paystack_subaccount_id TEXT NOT NULL,
    bank_account TEXT,
    mobile_money_number TEXT,
    category_ids UUID[] NOT NULL,
    rating NUMERIC(3, 2) DEFAULT 0.00,
    total_orders INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE
);

-- Create geospatial index
CREATE INDEX idx_stores_location ON stores USING GIST(location);
CREATE INDEX idx_stores_vendor_id ON stores(vendor_id);
CREATE INDEX idx_stores_is_open ON stores(is_open);

-- Auto-populate location from lat/lng
CREATE OR REPLACE FUNCTION update_store_location()
RETURNS TRIGGER AS $$
BEGIN
    NEW.location = ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_store_location
BEFORE INSERT OR UPDATE ON stores
FOR EACH ROW
EXECUTE FUNCTION update_store_location();

-- ============================================
-- PRODUCTS TABLE
-- ============================================
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES categories(id),
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC(10, 2) NOT NULL,
    image_url TEXT,
    image_urls TEXT[],
    is_available BOOLEAN DEFAULT TRUE,
    stock INTEGER DEFAULT 0,
    unit TEXT,
    variants JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_products_store_id ON products(store_id);
CREATE INDEX idx_products_category_id ON products(category_id);
CREATE INDEX idx_products_is_available ON products(is_available);

-- ============================================
-- ORDERS TABLE
-- ============================================
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES users(id),
    store_id UUID NOT NULL REFERENCES stores(id),
    rider_id UUID REFERENCES users(id),
    order_number TEXT UNIQUE NOT NULL,
    items JSONB NOT NULL,
    subtotal NUMERIC(10, 2) NOT NULL,
    delivery_fee NUMERIC(10, 2) NOT NULL,
    platform_fee NUMERIC(10, 2) NOT NULL,
    tax NUMERIC(10, 2) NOT NULL,
    total NUMERIC(10, 2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
        'pending', 'confirmed', 'preparing', 'ready', 
        'picked_up', 'delivering', 'completed', 'cancelled'
    )),
    delivery_mode TEXT NOT NULL CHECK (delivery_mode IN ('rider', 'self_delivery')),
    payment_status TEXT NOT NULL DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'refunded')),
    paystack_reference TEXT,
    delivery_address JSONB NOT NULL,
    estimated_delivery_time TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    customer_confirmed BOOLEAN DEFAULT FALSE,
    rider_confirmed BOOLEAN DEFAULT FALSE,
    cancellation_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_store_id ON orders(store_id);
CREATE INDEX idx_orders_rider_id ON orders(rider_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_order_number ON orders(order_number);

-- ============================================
-- CHAT ROOMS TABLE
-- ============================================
CREATE TABLE chat_rooms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('direct', 'vendor_room', 'rider_room')),
    participant_ids UUID[] NOT NULL,
    last_message TEXT,
    last_message_time TIMESTAMP WITH TIME ZONE,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_chat_rooms_type ON chat_rooms(type);
CREATE INDEX idx_chat_rooms_participant_ids ON chat_rooms USING GIN(participant_ids);

-- ============================================
-- CHAT MESSAGES TABLE
-- ============================================
CREATE TABLE chat_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    room_id UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id),
    sender_name TEXT NOT NULL,
    sender_image_url TEXT,
    message TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'text' CHECK (type IN ('text', 'image', 'location', 'system')),
    metadata JSONB,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_chat_messages_room_id ON chat_messages(room_id);
CREATE INDEX idx_chat_messages_sender_id ON chat_messages(sender_id);
CREATE INDEX idx_chat_messages_created_at ON chat_messages(created_at DESC);

-- ============================================
-- RIDER EARNINGS TABLE
-- ============================================
CREATE TABLE rider_earnings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rider_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    order_id UUID NOT NULL REFERENCES orders(id),
    amount NUMERIC(10, 2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'withdrawn')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_rider_earnings_rider_id ON rider_earnings(rider_id);
CREATE INDEX idx_rider_earnings_status ON rider_earnings(status);

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Users: Can read all, update own profile
CREATE POLICY "Users can view all profiles" ON users FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid() = id);

-- Stores: Public read, vendors can manage own stores
CREATE POLICY "Stores are viewable by everyone" ON stores FOR SELECT USING (true);
CREATE POLICY "Vendors can insert own stores" ON stores FOR INSERT WITH CHECK (auth.uid() = vendor_id);
CREATE POLICY "Vendors can update own stores" ON stores FOR UPDATE USING (auth.uid() = vendor_id);

-- Products: Public read, vendors can manage own products
CREATE POLICY "Products are viewable by everyone" ON products FOR SELECT USING (true);
CREATE POLICY "Vendors can manage own products" ON products FOR ALL USING (
    EXISTS (SELECT 1 FROM stores WHERE stores.id = products.store_id AND stores.vendor_id = auth.uid())
);

-- Orders: Users can see own orders
CREATE POLICY "Customers can view own orders" ON orders FOR SELECT USING (
    auth.uid() = customer_id OR 
    auth.uid() = rider_id OR
    EXISTS (SELECT 1 FROM stores WHERE stores.id = orders.store_id AND stores.vendor_id = auth.uid())
);

CREATE POLICY "Customers can create orders" ON orders FOR INSERT WITH CHECK (auth.uid() = customer_id);

CREATE POLICY "Orders can be updated by related parties" ON orders FOR UPDATE USING (
    auth.uid() = customer_id OR 
    auth.uid() = rider_id OR
    EXISTS (SELECT 1 FROM stores WHERE stores.id = orders.store_id AND stores.vendor_id = auth.uid())
);

-- Chat: Users can only access their chat rooms
CREATE POLICY "Users can view their chat rooms" ON chat_rooms FOR SELECT USING (
    auth.uid() = ANY(participant_ids)
);

CREATE POLICY "Users can view messages in their rooms" ON chat_messages FOR SELECT USING (
    EXISTS (SELECT 1 FROM chat_rooms WHERE chat_rooms.id = chat_messages.room_id AND auth.uid() = ANY(chat_rooms.participant_ids))
);

CREATE POLICY "Users can send messages to their rooms" ON chat_messages FOR INSERT WITH CHECK (
    auth.uid() = sender_id AND
    EXISTS (SELECT 1 FROM chat_rooms WHERE chat_rooms.id = room_id AND auth.uid() = ANY(chat_rooms.participant_ids))
);

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Function to find nearest riders
CREATE OR REPLACE FUNCTION find_nearest_riders(
    store_lat DOUBLE PRECISION,
    store_lng DOUBLE PRECISION,
    max_distance_km DOUBLE PRECISION DEFAULT 10
)
RETURNS TABLE (
    rider_id UUID,
    distance_km DOUBLE PRECISION
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id,
        ST_Distance(
            u.location::geography,
            ST_SetSRID(ST_MakePoint(store_lng, store_lat), 4326)::geography
        ) / 1000 AS distance_km
    FROM users u
    WHERE u.role = 'rider' 
        AND u.is_active = true
        AND u.location IS NOT NULL
        AND ST_DWithin(
            u.location::geography,
            ST_SetSRID(ST_MakePoint(store_lng, store_lat), 4326)::geography,
            max_distance_km * 1000
        )
    ORDER BY distance_km ASC
    LIMIT 10;
END;
$$ LANGUAGE plpgsql;

-- Function to generate unique order numbers
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TEXT AS $$
DECLARE
    new_number TEXT;
    done BOOLEAN := FALSE;
BEGIN
    WHILE NOT done LOOP
        new_number := 'ORD-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');
        IF NOT EXISTS (SELECT 1 FROM orders WHERE order_number = new_number) THEN
            done := TRUE;
        END IF;
    END LOOP;
    RETURN new_number;
END;
$$ LANGUAGE plpgsql;
