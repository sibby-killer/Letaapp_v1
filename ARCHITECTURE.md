# Leta App - Architecture Documentation

## 🏗 System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        FLUTTER APP                           │
│  ┌─────────────┬─────────────┬─────────────┬─────────────┐ │
│  │  Customer   │   Vendor    │    Rider    │    Admin    │ │
│  │  Dashboard  │  Dashboard  │  Dashboard  │  Dashboard  │ │
│  └─────────────┴─────────────┴─────────────┴─────────────┘ │
│                           ▼                                  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              PROVIDERS (State Management)             │  │
│  │  • AuthProvider  • CartProvider  • OrderProvider     │  │
│  └──────────────────────────────────────────────────────┘  │
│                           ▼                                  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                   CORE SERVICES                       │  │
│  │  • AuthService    • ChatService    • MapService      │  │
│  │  • PaymentService • AIService                        │  │
│  └──────────────────────────────────────────────────────┘  │
│                           ▼                                  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              LOCAL DATABASE (SQLite)                  │  │
│  │  Offline cache for Products, Orders, Chat Messages   │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            ▼
        ┌───────────────────┴───────────────────┐
        ▼                                       ▼
┌───────────────┐                      ┌────────────────┐
│   SUPABASE    │                      │  SOCKET.IO     │
│  (PostgreSQL  │                      │    SERVER      │
│   + PostGIS)  │                      │  (Real-time    │
│               │                      │     Chat)      │
└───────────────┘                      └────────────────┘
        ▼                                       
┌───────────────┐                      ┌────────────────┐
│   PAYSTACK    │                      │   GROQ API     │
│  (Split Pay)  │                      │  (AI Search)   │
└───────────────┘                      └────────────────┘
        ▼
┌───────────────┐
│ OPENSTREETMAP │
│   + OSRM      │
│  (Routing)    │
└───────────────┘
```

## 📊 Data Flow

### Order Creation Flow

```
Customer Add to Cart
         ↓
CartProvider (State)
         ↓
Checkout Screen
         ↓
PaymentService.initializeTransaction()
         ↓
Paystack API (Create Split Transaction)
         ↓
OrderProvider.createOrder()
         ↓
Supabase (Insert Order)
         ↓
LocalDatabase (Cache Order)
         ↓
Dispatch Logic (Find Rider OR Self-Delivery)
         ↓
Real-time Tracking
```

### Digital Handshake Flow

```
Rider Arrives at Dropoff
         ↓
Rider "Complete" Button = DISABLED
         ↓
Customer Clicks "I Received Order"
         ↓
OrderProvider.customerConfirmReceipt()
         ↓
Supabase Update (customer_confirmed = true)
         ↓
Rider "Complete" Button = ENABLED
         ↓
Rider Clicks "Complete"
         ↓
OrderProvider.riderConfirmDelivery()
         ↓
Supabase Update (rider_confirmed = true)
         ↓
Check: Both confirmed?
         ↓
Status → "completed"
         ↓
Payment Finalized
```

## 🗂 Folder Structure Philosophy

### Feature-First Organization

```
features/
├── auth/              # Authentication feature
│   ├── providers/     # State management
│   ├── services/      # Business logic
│   ├── screens/       # UI screens
│   └── widgets/       # Reusable components
├── customer/          # Customer-specific features
├── vendor/            # Vendor-specific features
├── rider/             # Rider-specific features
└── admin/             # Admin-specific features
```

**Why?** Each feature is self-contained, making it easy to:
- Find related code quickly
- Test features in isolation
- Scale the team (assign features to developers)

### Core Layer

```
core/
├── config/            # App-wide configuration
├── theme/             # Design system
├── routes/            # Navigation logic
├── models/            # Data models (shared across features)
├── database/          # Local SQLite database
└── services/          # Shared services (DI setup)
```

## 🔄 State Management Strategy

### Provider Pattern

**Why Provider?**
- Simple and lightweight
- Built-in to Flutter ecosystem
- Perfect for this app's complexity level

### State Hierarchy

```
AuthProvider (Global)
    ├─ Controls user authentication state
    └─ Triggers role-based navigation

CartProvider (Global)
    ├─ Manages shopping cart
    └─ Calculates totals

OrderProvider (Global)
    ├─ Manages order lifecycle
    └─ Handles digital handshake
```

## 🔐 Security Architecture

### Row Level Security (RLS)

Every Supabase table has RLS policies:

```sql
-- Example: Orders table
CREATE POLICY "Users see own orders" ON orders
  FOR SELECT USING (
    auth.uid() = customer_id OR 
    auth.uid() = rider_id OR
    auth.uid() IN (SELECT vendor_id FROM stores WHERE id = store_id)
  );
```

### Authentication Flow

1. User signs in → Supabase Auth creates JWT
2. JWT stored in secure storage
3. Every API call includes JWT in Authorization header
4. Supabase verifies JWT and applies RLS policies

### Payment Security

- **Never** store card details in app
- Paystack handles PCI compliance
- Use test keys in development (`pk_test_`, `sk_test_`)
- Verify transactions server-side before completing orders

## 🗺 Geospatial Architecture

### PostGIS Integration

```sql
-- Store locations as GEOMETRY points
ALTER TABLE stores ADD COLUMN location GEOMETRY(POINT, 4326);

-- Auto-populate from lat/lng
CREATE TRIGGER update_location
BEFORE INSERT OR UPDATE ON stores
FOR EACH ROW EXECUTE FUNCTION update_store_location();

-- Find nearest riders
SELECT * FROM find_nearest_riders(
  store_lat := 6.5244,
  store_lng := 3.3792,
  max_distance_km := 10
);
```

### Map Rendering

- **Tiles**: OpenStreetMap (free, open-source)
- **Routing**: OSRM (Open Source Routing Machine)
- **Client**: flutter_map package

## 💬 Real-time Chat Architecture

### Socket.io Server

```javascript
// Event: join_room
socket.on('join_room', (data) => {
  socket.join(data.room_id);
});

// Event: send_message
socket.on('send_message', (data) => {
  io.to(data.room_id).emit('new_message', data);
  
  // Also save to Supabase for persistence
  supabase.from('chat_messages').insert(data);
});

// Event: typing
socket.on('typing', (data) => {
  socket.to(data.room_id).emit('user_typing', data);
});
```

### Chat Rooms

- **Direct**: Customer ↔ Vendor (1-to-1)
- **Global**: All Vendors room, All Riders room (broadcast)
- **Admin**: Can join any room for oversight

## 💳 Payment Split Architecture

### Paystack Subaccounts

During vendor onboarding:

```dart
final subaccountId = await paymentService.createSubaccount(
  businessName: storeName,
  settlementBank: bankCode,
  accountNumber: accountNumber,
  percentageCharge: 90, // Vendor gets 90% of subtotal
);
```

### Transaction Split

```dart
// When customer pays
{
  "amount": 10000, // ₦100.00 in kobo
  "email": "customer@email.com",
  "split": {
    "type": "flat",
    "subaccounts": [
      {
        "subaccount": "ACCT_vendor",
        "share": 7500  // Vendor: ₦75 (subtotal)
      },
      {
        "subaccount": "ACCT_rider",
        "share": 1500  // Rider: ₦15 (delivery)
      }
      // Company: ₦10 (platform fee + commission)
    ]
  }
}
```

## 🤖 AI Integration

### Groq API Flow

```
User Query: "I need gas refill and chapo"
         ↓
AIService.analyzeQuery()
         ↓
Groq API (Mixtral-8x7b model)
         ↓
Response: {
  categories: ['gas', 'food'],
  keywords: ['refill', 'chapo']
}
         ↓
Filter vendors by categories
         ↓
Display results to user
```

### Fallback Strategy

If Groq API fails, use simple keyword matching:
```dart
if (query.contains('gas')) categories.add('gas');
if (query.contains('food')) categories.add('food');
```

## 📴 Offline-First Strategy

### Data Persistence

```
User Action (e.g., place order)
         ↓
Try: Save to Supabase
         ↓
Success? → Cache in SQLite
         ↓
Failure? → Queue in SQLite with sync flag
         ↓
When internet restored:
         ↓
Sync queued actions to Supabase
```

### Sync Logic

```dart
// Check connectivity
final hasInternet = await connectivity.checkConnectivity();

if (hasInternet) {
  // Fetch latest from Supabase
  final orders = await supabase.from('orders').select();
  
  // Update local cache
  await localDb.cacheOrders(orders);
} else {
  // Load from cache
  final orders = await localDb.getCachedOrders(userId);
}
```

## 🔔 Notification Strategy (Future)

### Push Notifications Flow

```
Order Status Change
         ↓
Supabase Database Trigger
         ↓
Call Edge Function
         ↓
Firebase Cloud Messaging (FCM)
         ↓
User Device
```

**Events to notify:**
- Order confirmed
- Rider assigned
- Rider arriving
- Order delivered
- New chat message

## 🧪 Testing Strategy

### Unit Tests

Test individual services:
```dart
test('Calculate cart total correctly', () {
  final cart = CartProvider();
  cart.addItem(product1); // $10
  cart.addItem(product2); // $15
  cart.setDeliveryFee(5.0);
  
  expect(cart.subtotal, 25.0);
  expect(cart.total, 32.25); // includes fees & tax
});
```

### Integration Tests

Test feature flows:
```dart
testWidgets('User can place an order', (tester) async {
  // 1. Navigate to product
  await tester.tap(find.byType(ProductCard));
  
  // 2. Add to cart
  await tester.tap(find.text('Add to Cart'));
  
  // 3. Checkout
  await tester.tap(find.byIcon(Icons.shopping_cart));
  await tester.tap(find.text('Checkout'));
  
  // 4. Verify order created
  expect(find.text('Order placed successfully'), findsOneWidget);
});
```

### E2E Tests

Test complete user journeys across all roles.

## 📈 Scalability Considerations

### Current Architecture (MVP)

- **Users**: Up to 10,000 concurrent users
- **Database**: Supabase free tier (500MB)
- **Chat**: Single Socket.io server

### Scale-Up Strategy

1. **Database**: Upgrade Supabase tier, add read replicas
2. **Chat**: Use Redis for message queuing, multiple Socket.io instances
3. **CDN**: Add Cloudflare for static assets
4. **Caching**: Implement Redis for frequently accessed data
5. **Monitoring**: Add Sentry for error tracking, Mixpanel for analytics

## 🔄 Deployment Pipeline

```
Developer Push
         ↓
GitHub Actions (CI)
         ↓
Run Tests
         ↓
Build APK/IPA
         ↓
Upload to TestFlight/Play Console
         ↓
Manual QA
         ↓
Release to Production
```

## 📊 Performance Optimization

### Image Loading
- Use `cached_network_image` for product images
- Lazy load images in lists
- Compress images before upload

### List Performance
- Use `ListView.builder` (lazy loading)
- Implement pagination (load 20 items at a time)
- Add pull-to-refresh

### Database Queries
- Create indexes on frequently queried columns
- Use `select()` to fetch only needed columns
- Implement cursor-based pagination

---

**This architecture supports the Leta App from MVP to millions of users.** 🚀
