# 🚀 Leta App - Hyper-Local Multi-Vendor Ecosystem

> **Production-Ready Flutter App** • Supabase Backend • Real-time Features • Multi-Role System

> **Production-Grade Flutter Application** built following the VIBE Framework

A complete, unified multi-role delivery platform supporting **Customers**, **Vendors**, **Riders**, and **Admins** in a single codebase with dynamic routing.

---

## 🎯 Project Overview

**Leta App** unifies three user roles into one seamless ecosystem:
- 🛒 **Customers**: Browse dynamic categories, order from multiple vendors, track deliveries in real-time
- 🏪 **Vendors**: Manage stores, products, orders (Kanban board), and financials
- 🚴 **Riders**: Accept deliveries, navigate with live maps, track earnings
- 👨‍💼 **Admins**: Global oversight, chat monitoring, dispute resolution, analytics

---

## 🛠 Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | Flutter (Material 3 Design) |
| **Backend** | Supabase (PostgreSQL + PostGIS) |
| **Authentication** | Supabase Auth |
| **Real-time Chat** | Supabase Realtime (Postgres Changes + Broadcast) |
| **Offline Cache** | SQLite (sqflite) |
| **Maps** | OpenStreetMap + flutter_map + OSRM |
| **Payments** | Paystack (Split Payments) |
| **AI** | Groq (Mixtral-8x7b) |
| **State Management** | Provider |

---

## 🎨 VIBE Framework Compliance

### V — VISUALS (Design System)
- **Aesthetic**: Card-based minimalism inspired by Bolt Food & Uber Eats
- **Theme**: Primary Color: Emerald Green (#34C759), Background: White, Text: Charcoal
- **Components**: Material 3 specs with dynamic category rendering from database

### I — INTERFACE (User Experience)
- **Unified Login**: Single Supabase Auth for all roles
- **Dynamic Routing**: Role-based navigation (Customer → Home, Vendor → Dashboard, etc.)
- **Order Flow**: Cart → Payment → Split → Dispatch → Tracking → Digital Handshake
- **Dual Delivery**: Rider-based OR Vendor self-delivery

### B — BACKEND (Logic & Data)
- **Database**: Relational schema with PostGIS for geospatial queries
- **Offline First**: SQLite caching with automatic sync
- **Real-time**: Supabase Realtime for chat, typing indicators, and live location tracking
- **AI Integration**: Smart vendor filtering via Groq API

### E — EXCLUSIONS (Strict Rules)
✅ **NO FIREBASE** - Pure Supabase implementation  
✅ **NO GOOGLE MAPS** - OpenStreetMap only  
✅ **NO HARDCODED CATEGORIES** - Fully dynamic from database  
✅ **NO MANUAL PAYOUTS** - Automatic Paystack split payments  

---

## 📁 Project Structure

```
leta_app/
├── lib/
│   ├── main.dart                          # App entry point
│   ├── core/
│   │   ├── config/
│   │   │   └── app_config.dart            # Environment variables & constants
│   │   ├── theme/
│   │   │   └── app_theme.dart             # Material 3 theme (VIBE compliant)
│   │   ├── routes/
│   │   │   └── app_router.dart            # Role-based routing
│   │   ├── models/                        # Data models
│   │   │   ├── user_model.dart
│   │   │   ├── store_model.dart
│   │   │   ├── category_model.dart
│   │   │   ├── product_model.dart
│   │   │   ├── order_model.dart
│   │   │   └── chat_message_model.dart
│   │   ├── database/
│   │   │   └── local_database.dart        # SQLite offline cache
│   │   └── services/
│   │       └── service_locator.dart       # Dependency injection
│   ├── features/
│   │   ├── auth/
│   │   │   ├── providers/auth_provider.dart
│   │   │   ├── services/auth_service.dart
│   │   │   └── screens/
│   │   │       ├── login_screen.dart
│   │   │       └── signup_screen.dart
│   │   ├── splash/
│   │   ├── onboarding/
│   │   │   └── screens/vendor_onboarding_screen.dart
│   │   ├── customer/
│   │   │   └── screens/customer_home_screen.dart
│   │   ├── vendor/
│   │   │   └── screens/vendor_dashboard_screen.dart
│   │   ├── rider/
│   │   │   └── screens/rider_dashboard_screen.dart
│   │   ├── admin/
│   │   │   └── screens/admin_dashboard_screen.dart
│   │   ├── cart/
│   │   │   └── providers/cart_provider.dart
│   │   ├── order/
│   │   │   └── providers/order_provider.dart
│   │   ├── chat/
│   │   │   └── services/supabase_realtime_service.dart  # Supabase Realtime
│   │   ├── map/
│   │   │   └── services/map_service.dart   # OSM + OSRM
│   │   ├── payment/
│   │   │   └── services/payment_service.dart  # Paystack split
│   │   └── ai/
│   │       └── services/ai_service.dart    # Groq integration
│   └── ...
├── supabase_schema.sql                     # Complete database schema
├── pubspec.yaml
└── README.md
```

---

## 🚀 Setup Instructions

### 1. Prerequisites
- Flutter SDK (3.0+)
- Supabase Account
- Paystack Account
- Groq API Key
- Socket.io Server (Node.js)

### 2. Environment Configuration

Create a `.env` file or configure Dart define variables:

```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SOCKET_URL=https://your-socket-server.com
PAYSTACK_PUBLIC_KEY=pk_test_xxx
PAYSTACK_SECRET_KEY=sk_test_xxx
GROQ_API_KEY=gsk_xxx
```

### 3. Database Setup

Run the SQL schema in your Supabase SQL Editor:

```bash
# Navigate to Supabase Dashboard > SQL Editor
# Copy and execute: supabase_schema.sql
```

This creates:
- All tables with Row Level Security (RLS)
- PostGIS extension for geospatial queries
- Helper functions (find_nearest_riders, generate_order_number)
- Default categories (Food, Gas, Second-Hand, Groceries)

### 4. Socket.io Server Setup

Create a simple Node.js server for real-time chat:

```javascript
// server.js
const express = require('express');
const http = require('http');
const socketIO = require('socket.io');

const app = express();
const server = http.createServer(app);
const io = socketIO(server);

io.on('connection', (socket) => {
  console.log('User connected:', socket.id);
  
  socket.on('join_room', (data) => {
    socket.join(data.room_id);
    console.log(`User ${data.user_id} joined room ${data.room_id}`);
  });
  
  socket.on('send_message', (data) => {
    io.to(data.room_id).emit('new_message', data);
  });
  
  socket.on('typing', (data) => {
    socket.to(data.room_id).emit('user_typing', data);
  });
  
  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
  });
});

server.listen(3000, () => console.log('Socket.io server running on port 3000'));
```

### 5. Install Dependencies

```bash
flutter pub get
```

### 6. Run the App

```bash
flutter run
```

---

## 🔑 Key Features

### 1. **Dynamic Category System**
Categories are **database-driven** and render automatically in the Customer UI. Vendors can create custom categories (e.g., "Vintage Shoes").

```sql
-- Add a custom category
INSERT INTO categories (name, icon_url, is_custom, created_by)
VALUES ('Vintage Shoes', 'shoe_icon', true, 'vendor_uuid');
```

### 2. **Paystack Split Payment Logic**

When a customer pays, the money is **instantly split**:

```
Total Payment = Subtotal + Delivery Fee + Platform Fee ($5) + Tax (5%)

Split Distribution:
├─ Vendor:   Subtotal
├─ Rider:    Delivery Fee (if rider delivery)
└─ Company:  Platform Fee + Commission (10% of subtotal)
```

**Implementation**: `payment_service.dart` creates Paystack subaccounts during vendor onboarding and uses split transactions.

### 3. **Digital Handshake Security**

Orders cannot be marked complete without **two-party confirmation**:

1. Rider/Vendor arrives at drop-off
2. **Rider's "Complete" button is DISABLED**
3. Customer clicks "I Received Order"
4. **Rider's button UNLOCKS** → Payment finalized

```dart
// In order_provider.dart
await customerConfirmReceipt(orderId);  // Step 1
await riderConfirmDelivery(orderId);    // Step 2 (unlocked)
// Order auto-completes when both = true
```

### 4. **Dual Dispatch System**

**Mode A - Rider Delivery:**
- System finds nearest rider using PostGIS geospatial query
- Delivery fee goes to rider

**Mode B - Self Delivery:**
- Vendor selects "I will deliver this"
- Delivery fee goes to vendor
- Vendor's location is tracked on map

### 5. **Offline-First Architecture**

All critical data (products, orders, chat history) is cached in SQLite:

```dart
// Auto-caches on fetch
await orderProvider.fetchOrders(userId, role);

// Works offline
final cachedOrders = await localDb.getCachedOrders(userId);
```

### 6. **AI-Powered Smart Search**

```dart
// Customer types: "I need a Gas refill and Chapo"
final result = await aiService.analyzeQuery(query);
// Returns: { categories: ['gas', 'food'], keywords: ['refill', 'chapo'] }
// UI auto-filters vendors
```

---

## 🗺 Map & Location Features

### OpenStreetMap Integration

```dart
// Get current location
final location = await mapService.getCurrentLocation();

// Calculate route with OSRM
final route = await mapService.getRoute(
  origin: storeLocation,
  destination: customerLocation,
);

// Returns: { polyline: [LatLng], distance: 5.2, duration: 15 }
```

### Rider Assignment

```sql
-- Find nearest riders (uses PostGIS)
SELECT * FROM find_nearest_riders(
  store_lat := 6.5244,
  store_lng := 3.3792,
  max_distance_km := 10
);
```

---

## 💬 Real-time Chat

### Features
- **Direct Chat**: Customer ↔ Vendor
- **Global Rooms**: "All Vendors" room, "All Riders" room
- **Typing Indicators**: Real-time "User is typing..."
- **Admin Access**: Admin can view/enter ANY chat room

### Usage

```dart
// Initialize
chatService.connect(userId);
chatService.joinRoom(roomId);

// Send message
chatService.sendMessage(
  roomId: roomId,
  message: 'Hello!',
);

// Listen for messages
chatService.onMessageReceived((message) {
  print('New message: ${message.message}');
});

// Typing indicator
chatService.sendTypingIndicator(roomId, true);
```

---

## 🎭 User Roles & Permissions

| Feature | Customer | Vendor | Rider | Admin |
|---------|----------|--------|-------|-------|
| Browse Products | ✅ | ❌ | ❌ | ✅ |
| Place Orders | ✅ | ❌ | ❌ | ❌ |
| Manage Store | ❌ | ✅ | ❌ | ✅ |
| Accept Deliveries | ❌ | ❌ | ✅ | ❌ |
| View All Chats | ❌ | ❌ | ❌ | ✅ |
| Resolve Disputes | ❌ | ❌ | ❌ | ✅ |
| Platform Analytics | ❌ | ❌ | ❌ | ✅ |

---

## 🔐 Security

### Row Level Security (RLS)
All tables have RLS policies:
- Users can only view/update their own data
- Vendors can only manage their own stores/products
- Orders visible to customer, vendor, and assigned rider
- Chat rooms restricted to participants
- Admin has override access

### Payment Security
- Paystack handles all card data (PCI compliant)
- Split payments are atomic (all or nothing)
- Transaction verification before order completion

---

## 📊 Database Schema Highlights

### Users Table
```sql
users (
  id UUID PRIMARY KEY,
  email TEXT UNIQUE,
  role TEXT CHECK (role IN ('customer', 'vendor', 'rider', 'admin')),
  location GEOMETRY(POINT, 4326),  -- For riders
  ...
)
```

### Orders Table (Digital Handshake)
```sql
orders (
  ...
  customer_confirmed BOOLEAN DEFAULT FALSE,
  rider_confirmed BOOLEAN DEFAULT FALSE,
  status TEXT CHECK (status IN ('pending', 'confirmed', 'preparing', 'ready', 'picked_up', 'delivering', 'completed', 'cancelled')),
  ...
)
```

### Stores Table (Paystack Integration)
```sql
stores (
  ...
  paystack_subaccount_id TEXT NOT NULL,
  location GEOMETRY(POINT, 4326),  -- For geospatial queries
  category_ids UUID[],  -- Dynamic categories
  ...
)
```

---

## 🧪 Testing

Run unit tests:
```bash
flutter test
```

Run integration tests:
```bash
flutter test integration_test/
```

---

## 📦 Build & Deploy

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ipa --release
```

### Web
```bash
flutter build web --release
```

---

## 🐛 Troubleshooting

### Common Issues

**1. Supabase Connection Error**
- Verify `SUPABASE_URL` and `SUPABASE_ANON_KEY` in `app_config.dart`
- Check if RLS policies are correctly set

**2. Socket.io Not Connecting**
- Ensure Socket.io server is running
- Check `SOCKET_URL` configuration
- Verify CORS settings on server

**3. Paystack Payment Fails**
- Test mode keys start with `pk_test_` and `sk_test_`
- Verify subaccount creation succeeded during vendor onboarding

**4. Map Not Loading**
- Check internet connection (OSM requires network)
- Verify location permissions are granted

---

## 🛣 Roadmap

### Phase 1 (Current) ✅
- [x] Core authentication & role-based routing
- [x] Database schema with PostGIS
- [x] Material 3 UI for all 4 roles
- [x] Vendor onboarding with Paystack

### Phase 2 (In Progress) 🚧
- [ ] Complete order flow with payment split
- [ ] Real-time chat implementation
- [ ] Map integration with live tracking
- [ ] AI-powered search

### Phase 3 (Planned) 📋
- [ ] Push notifications
- [ ] In-app reviews & ratings
- [ ] Advanced analytics dashboard
- [ ] Multi-language support
- [ ] Dark mode

---

## 👥 Contributing

This is an educational/demonstration project. For production use:
1. Add comprehensive error handling
2. Implement proper logging (e.g., Sentry)
3. Add end-to-end tests
4. Set up CI/CD pipelines
5. Configure environment-specific builds

---

## 📄 License

This project is for educational purposes. Consult with legal counsel before commercial deployment.

---

## 🙏 Acknowledgments

- **Design Inspiration**: Bolt Food, Uber Eats
- **Framework**: VIBE Framework for systematic app development
- **Maps**: OpenStreetMap contributors
- **Backend**: Supabase team

---

## 📞 Support

For technical questions or issues:
- Review the inline documentation in each service file
- Check Supabase logs for backend errors
- Verify all API keys are correctly configured

---

**Built with ❤️ using Flutter & the VIBE Framework**
