# Leta App - Implementation Guide

## 🚦 Current Status

### ✅ Completed Components

1. **Project Structure** - Complete Flutter project architecture
2. **Database Schema** - Full Supabase schema with PostGIS
3. **Authentication** - Login, Signup, Role-based routing
4. **All 4 Dashboards** - Customer, Vendor, Rider, Admin UIs
5. **Core Services** - Auth, Chat, Map, Payment, AI services
6. **State Management** - Providers for Auth, Cart, Orders
7. **Offline Cache** - SQLite database for offline-first
8. **Theme System** - Material 3 with VIBE Framework colors

### 🚧 Next Steps to Complete

1. **Dynamic Category System** - Fetch categories from Supabase and render dynamically
2. **Complete Order Flow** - Cart screen → Checkout → Payment integration
3. **Map Integration** - flutter_map with OpenStreetMap tiles and OSRM routing
4. **Chat UI** - Build chat screens with Socket.io integration
5. **Dispatch Logic** - Implement rider assignment and self-delivery modes
6. **Digital Handshake UI** - Build order confirmation screens

## 📋 Implementation Checklist

### Phase 1: Core Functionality (Priority High)

- [ ] **Category Service & UI**
  - Create `category_service.dart` to fetch from Supabase
  - Update Customer home to render categories dynamically
  - Add category management UI for Vendors

- [ ] **Product Management**
  - Create product listing screens
  - Build product details screen
  - Implement add to cart functionality

- [ ] **Cart & Checkout**
  - Build cart screen with item management
  - Create checkout flow
  - Integrate Paystack payment

- [ ] **Order Tracking**
  - Build order details screen
  - Add real-time order status updates
  - Implement push notifications (optional)

### Phase 2: Advanced Features (Priority Medium)

- [ ] **Map Integration**
  - Implement `MapScreen` with flutter_map
  - Add real-time rider tracking
  - Display route polylines with OSRM

- [ ] **Chat System**
  - Build chat list screen
  - Create chat conversation screen
  - Add typing indicators
  - Implement message notifications

- [ ] **Rider Features**
  - Build delivery acceptance flow
  - Add navigation to pickup/dropoff
  - Implement earnings tracking

- [ ] **Vendor Features**
  - Complete Kanban board interactions
  - Add product inventory management
  - Build financial reports

### Phase 3: Polish & Production (Priority Low)

- [ ] **AI Integration**
  - Connect Groq API to search
  - Add smart suggestions
  - Implement auto-filtering

- [ ] **Admin Tools**
  - Complete dispute resolution UI
  - Add user management
  - Build analytics charts

- [ ] **Testing**
  - Write unit tests
  - Add integration tests
  - Perform end-to-end testing

- [ ] **Deployment**
  - Configure production environment
  - Set up CI/CD
  - Deploy to app stores

## 🔧 Quick Start Development

### 1. Set Up Supabase

```bash
# 1. Go to https://supabase.com and create a project
# 2. Go to SQL Editor and run supabase_schema.sql
# 3. Copy your project URL and anon key
# 4. Update lib/core/config/app_config.dart
```

### 2. Set Up Socket.io Server

```bash
mkdir chat-server && cd chat-server
npm init -y
npm install express socket.io cors
# Create server.js (see README for code)
node server.js
```

### 3. Configure Environment

```dart
// lib/core/config/app_config.dart
class AppConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_KEY';
  static const String socketUrl = 'http://localhost:3000';
  static const String paystackPublicKey = 'pk_test_xxx';
  // ... etc
}
```

### 4. Run the App

```bash
flutter pub get
flutter run
```

## 🎯 Feature Implementation Examples

### Example 1: Fetch Dynamic Categories

```dart
// Create: lib/features/category/services/category_service.dart
class CategoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<CategoryModel>> getActiveCategories() async {
    final response = await _supabase
        .from('categories')
        .select()
        .eq('is_active', true)
        .order('display_order');

    return response
        .map((json) => CategoryModel.fromJson(json))
        .toList();
  }
}

// Update: lib/features/customer/screens/customer_home_screen.dart
// Replace hardcoded categories with:
FutureBuilder<List<CategoryModel>>(
  future: categoryService.getActiveCategories(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();
    return ListView.builder(
      itemCount: snapshot.data!.length,
      itemBuilder: (context, index) {
        final category = snapshot.data![index];
        return CategoryCard(category: category);
      },
    );
  },
)
```

### Example 2: Complete Checkout Flow

```dart
// Create: lib/features/checkout/screens/checkout_screen.dart
class CheckoutScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    
    return Scaffold(
      appBar: AppBar(title: Text('Checkout')),
      body: Column(
        children: [
          // Order Summary
          OrderSummaryCard(
            subtotal: cart.subtotal,
            deliveryFee: cart.deliveryFee,
            platformFee: cart.platformFee,
            tax: cart.tax,
            total: cart.total,
          ),
          
          // Payment Button
          ElevatedButton(
            onPressed: () async {
              final order = await orderProvider.createOrder(
                customerId: userId,
                storeId: storeId,
                items: cart.toOrderItems(),
                subtotal: cart.subtotal,
                deliveryFee: cart.deliveryFee,
                platformFee: cart.platformFee,
                tax: cart.tax,
                total: cart.total,
                deliveryMode: 'rider',
                deliveryAddress: selectedAddress,
              );
              
              // Initialize payment
              final paymentRef = await paymentService.initializeTransaction(
                order: order!,
                vendorSubaccountId: vendor.paystackSubaccountId,
              );
              
              // Show payment UI
              await paymentService.chargeCard(
                email: user.email,
                amount: order.total,
                reference: paymentRef,
              );
              
              cart.clear();
              Navigator.pushNamed(context, '/order-tracking', arguments: order.id);
            },
            child: Text('Pay ${cart.total.toStringAsFixed(2)}'),
          ),
        ],
      ),
    );
  }
}
```

### Example 3: Live Map Tracking

```dart
// Create: lib/features/tracking/screens/order_tracking_screen.dart
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  
  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  MapController _mapController = MapController();
  LatLng? _riderLocation;
  List<LatLng> _routePoints = [];
  
  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }
  
  Future<void> _initializeTracking() async {
    // Get route
    final route = await mapService.getRoute(
      origin: storeLocation,
      destination: customerLocation,
    );
    
    setState(() {
      _routePoints = route['polyline'];
    });
    
    // Listen to rider location updates
    mapService.getLocationStream().listen((location) {
      setState(() {
        _riderLocation = location;
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Track Order')),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          center: _riderLocation ?? storeLocation,
          zoom: 14,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routePoints,
                color: AppTheme.primaryGreen,
                strokeWidth: 4,
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              if (_riderLocation != null)
                Marker(
                  point: _riderLocation!,
                  builder: (_) => Icon(Icons.delivery_dining, size: 40),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
```

## 🐛 Common Issues & Solutions

### Issue: "get_it not found"
**Solution**: Add to pubspec.yaml:
```yaml
dependencies:
  get_it: ^7.6.4
```

### Issue: Paystack subaccount creation fails
**Solution**: Ensure you're using test keys and the bank code is valid. Check Paystack docs for bank codes.

### Issue: Socket.io not connecting
**Solution**: 
1. Verify server is running: `node server.js`
2. Check CORS settings allow Flutter app origin
3. Use `http://10.0.2.2:3000` for Android emulator (not localhost)

### Issue: Location permissions denied
**Solution**: Add to AndroidManifest.xml:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

## 📚 Additional Resources

- [Flutter Documentation](https://docs.flutter.dev)
- [Supabase Flutter SDK](https://supabase.com/docs/reference/dart/introduction)
- [Paystack Documentation](https://paystack.com/docs)
- [flutter_map Documentation](https://docs.fleaflet.dev/)
- [Socket.io Client](https://socket.io/docs/v4/client-api/)

## 🎓 Learning Path

1. **Week 1**: Get familiar with the codebase structure
2. **Week 2**: Implement category and product features
3. **Week 3**: Build cart and checkout flow
4. **Week 4**: Add map integration and tracking
5. **Week 5**: Implement chat system
6. **Week 6**: Polish UI and add animations
7. **Week 7**: Testing and bug fixes
8. **Week 8**: Production deployment

---

**Happy Coding! 🚀**
