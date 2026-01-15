import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_config.dart';
import '../../../core/routes/app_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/rider_provider.dart';
import '../services/rider_service.dart';
import '../../map/services/map_service.dart';

class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
  int _selectedIndex = 0;
  bool _showWelcomeNotification = true;

  @override
  void initState() {
    super.initState();
    _checkProfileCompletion();
  }

  void _checkProfileCompletion() {
    final riderProvider = context.read<RiderProvider>();
    if (riderProvider.profileCompletion < 100) {
      // Show welcome notification for incomplete profile
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_showWelcomeNotification && mounted) {
          _showProfileSetupNotification();
        }
      });
    }
  }

  void _showProfileSetupNotification() {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        padding: const EdgeInsets.all(16),
        content: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '👋 Welcome to Leta!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 4),
            Text('Complete your profile to start receiving deliveries'),
          ],
        ),
        backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              setState(() => _showWelcomeNotification = false);
            },
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              setState(() {
                _showWelcomeNotification = false;
                _selectedIndex = 3; // Go to profile tab
              });
            },
            child: const Text('Complete Profile'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          MapTab(),
          DeliveriesTab(),
          EarningsTab(),
          RiderProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.delivery_dining_outlined),
            activeIcon: Icon(Icons.delivery_dining),
            label: 'Deliveries',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money_outlined),
            activeIcon: Icon(Icons.attach_money),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  final MapController _mapController = MapController();
  final MapService _mapService = MapService();
  
  // MMUST Gate location as default
  static const LatLng _mmustGate = LatLng(0.2827, 34.7519);
  LatLng? _currentLocation;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final location = await _mapService.getCurrentLocation();
      setState(() {
        _currentLocation = location;
        _isLoadingLocation = false;
      });
      _mapController.move(location, 15);
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      // Stay at MMUST gate if location fails
    }
  }

  Future<void> _toggleOnlineStatus(bool value) async {
    final authProvider = context.read<AuthProvider>();
    final riderProvider = context.read<RiderProvider>();
    final userId = authProvider.currentUser?.id;
    
    if (userId == null) return;

    await riderProvider.toggleOnlineStatus(
      userId,
      latitude: _currentLocation?.latitude ?? _mmustGate.latitude,
      longitude: _currentLocation?.longitude ?? _mmustGate.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    final riderProvider = context.watch<RiderProvider>();
    final isOnline = riderProvider.isOnline;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Map'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_outlined),
            onPressed: () {
              Navigator.pushNamed(context, AppRouter.chatList);
            },
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          // OpenStreetMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation ?? _mmustGate,
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.leta.leta_app',
              ),
              MarkerLayer(
                markers: [
                  // MMUST Gate marker
                  Marker(
                    point: _mmustGate,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.school,
                      color: Colors.blue,
                      size: 30,
                    ),
                  ),
                  // Current location marker
                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isOnline ? AppTheme.successGreen : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.delivery_dining,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          
          // Loading overlay
          if (_isLoadingLocation)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
          
          // Online/Offline Toggle
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: isOnline ? AppTheme.successGreen : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isOnline ? 'You\'re Online' : 'You\'re Offline',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isOnline
                              ? 'Ready to accept deliveries'
                              : 'Tap to go online',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textGray,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: isOnline,
                      onChanged: _toggleOnlineStatus,
                      activeColor: AppTheme.successGreen,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Location info badge
          Positioned(
            top: 100,
            left: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.school, size: 16, color: Colors.blue),
                    const SizedBox(width: 6),
                    const Text('Near MMUST Gate', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
          
          // Available deliveries (when online)
          if (isOnline && riderProvider.availableDeliveries.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildDeliveryRequestCard(riderProvider.availableDeliveries.first),
            ),
          
          // Waiting for deliveries (when online but no deliveries)
          if (isOnline && riderProvider.availableDeliveries.isEmpty)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.hourglass_empty, size: 40, color: AppTheme.textGray),
                      const SizedBox(height: 12),
                      const Text(
                        'Waiting for deliveries...',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You\'ll be notified when a new order is available',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeliveryRequestCard(Map<String, dynamic> delivery) {
    final store = delivery['stores'] as Map<String, dynamic>?;
    final total = (delivery['total'] as num?)?.toDouble() ?? 0;
    final riderShare = total * (AppConfig.riderSharePercent / 100);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'New Delivery Request',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'KSh ${riderShare.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.store, size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(child: Text('From: ${store?['name'] ?? 'Store'}')),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '~1.2 km',
                    style: TextStyle(fontSize: 12, color: AppTheme.primaryGreen),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(child: Text('To: ${delivery['delivery_address'] ?? 'Customer'}')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Decline - just remove from list for now
                    },
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final authProvider = context.read<AuthProvider>();
                      final riderProvider = context.read<RiderProvider>();
                      await riderProvider.acceptDelivery(
                        delivery['id'],
                        authProvider.currentUser!.id,
                      );
                    },
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DeliveriesTab extends StatelessWidget {
  const DeliveriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Deliveries')),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Active'),
                Tab(text: 'Completed'),
                Tab(text: 'All'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildDeliveryList(context, 'active'),
                  _buildDeliveryList(context, 'completed'),
                  _buildDeliveryList(context, 'all'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryList(BuildContext context, String filter) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shopping_bag, color: AppTheme.primaryGreen),
            ),
            title: Text('Order #${3000 + index}'),
            subtitle: Text('${1 + index}.5 km • 15 mins'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${(8.0 + index * 2).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: filter == 'active'
                        ? AppTheme.warningOrange
                        : AppTheme.successGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    filter == 'active' ? 'In Transit' : 'Delivered',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            onTap: () {
              // TODO: Navigate to delivery details
            },
          ),
        );
      },
    );
  }
}

class EarningsTab extends StatelessWidget {
  const EarningsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: AppTheme.primaryGreen,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'Total Earnings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '\$1,245.50',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Today', '\$85.50'),
                        _buildStatItem('This Week', '\$312.00'),
                        _buildStatItem('Deliveries', '47'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Earnings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Withdraw'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(
              10,
              (index) => ListTile(
                leading: const Icon(Icons.attach_money, color: AppTheme.successGreen),
                title: Text('Delivery #${4000 + index}'),
                subtitle: Text('${DateTime.now().subtract(Duration(hours: index)).hour}:00'),
                trailing: Text(
                  '+\$${(8.0 + index * 1.5).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.successGreen,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class RiderProfileTab extends StatelessWidget {
  const RiderProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final riderProvider = context.watch<RiderProvider>();
    final user = authProvider.currentUser;
    final profile = riderProvider.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.pushNamed(context, AppRouter.editProfile),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile header
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                  backgroundImage: user?.profileImageUrl != null
                      ? NetworkImage(user!.profileImageUrl!)
                      : null,
                  child: user?.profileImageUrl == null
                      ? Text(
                          user?.fullName.substring(0, 1).toUpperCase() ?? 'R',
                          style: const TextStyle(
                            fontSize: 36,
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, AppRouter.editProfile),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.fullName ?? 'Rider',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, size: 18, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                '${profile?.rating.toStringAsFixed(1) ?? '5.0'} (${profile?.totalDeliveries ?? 0} deliveries)',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Transport badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getTransportColor(profile?.transportType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getTransportIcon(profile?.transportType),
                    size: 16,
                    color: _getTransportColor(profile?.transportType),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getTransportName(profile?.transportType),
                    style: TextStyle(
                      color: _getTransportColor(profile?.transportType),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Profile completion card
          if ((profile?.profileCompletionPercent ?? 0) < 100)
            Card(
              color: AppTheme.warningOrange.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber, color: AppTheme.warningOrange),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Complete your profile',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          '${profile?.profileCompletionPercent ?? 0}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.warningOrange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (profile?.profileCompletionPercent ?? 0) / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation(AppTheme.warningOrange),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Complete your profile to receive more deliveries',
                      style: TextStyle(fontSize: 12, color: AppTheme.textGray),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Menu items
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.person_outline, color: Colors.blue),
                  ),
                  title: const Text('Edit Profile'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, AppRouter.editProfile),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.phone_android, color: Colors.green),
                  ),
                  title: const Text('Payment Settings'),
                  subtitle: Text(profile?.mobileMoneyNumber ?? 'Not set'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, AppRouter.riderSettings),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.settings, color: Colors.purple),
                  ),
                  title: const Text('Settings'),
                  subtitle: const Text('Notifications, permissions'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, AppRouter.riderSettings),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.history, color: Colors.orange),
                  ),
                  title: const Text('Delivery History'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to delivery history
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.chat_bubble_outline, color: Colors.teal),
                  ),
                  title: const Text('Messages'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, AppRouter.chatList),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.cyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.help_outline, color: Colors.cyan),
                  ),
                  title: const Text('Help & Support'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, AppRouter.riderSettings),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Sign out button
          OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.read<AuthProvider>().signOut();
                        context.read<RiderProvider>().clear();
                        AppRouter.navigateToLogin(context);
                      },
                      child: const Text('Sign Out', style: TextStyle(color: AppTheme.errorRed)),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.logout, color: AppTheme.errorRed),
            label: const Text('Sign Out', style: TextStyle(color: AppTheme.errorRed)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.errorRed),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 16),

          // App version
          Center(
            child: Text(
              'Leta App v1.0.0',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  IconData _getTransportIcon(TransportType? type) {
    switch (type) {
      case TransportType.skates:
        return Icons.skateboarding;
      case TransportType.bicycle:
        return Icons.pedal_bike;
      case TransportType.motorbike:
        return Icons.two_wheeler;
      default:
        return Icons.help_outline;
    }
  }

  String _getTransportName(TransportType? type) {
    switch (type) {
      case TransportType.skates:
        return 'Skates';
      case TransportType.bicycle:
        return 'Bicycle';
      case TransportType.motorbike:
        return 'Motorbike';
      default:
        return 'Not set';
    }
  }

  Color _getTransportColor(TransportType? type) {
    switch (type) {
      case TransportType.skates:
        return Colors.purple;
      case TransportType.bicycle:
        return Colors.blue;
      case TransportType.motorbike:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
