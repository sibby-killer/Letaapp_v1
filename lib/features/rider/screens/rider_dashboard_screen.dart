import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
  bool _isOnline = false;
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const MapTab(),
    const DeliveriesTab(),
    const EarningsTab(),
    const RiderProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
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
  bool _isOnline = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_outlined),
            onPressed: () {
              // TODO: Navigate to chat
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map placeholder
          Container(
            color: AppTheme.cardBackground,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 80, color: AppTheme.textGray),
                  SizedBox(height: 16),
                  Text('OpenStreetMap will render here'),
                ],
              ),
            ),
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
                        Text(
                          _isOnline ? 'You\'re Online' : 'You\'re Offline',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _isOnline
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
                      value: _isOnline,
                      onChanged: (value) {
                        setState(() {
                          _isOnline = value;
                        });
                        // TODO: Update rider status in database
                      },
                      activeColor: AppTheme.successGreen,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Current Delivery Card (if active)
          if (_isOnline)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'New Delivery Request',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$8.50',
                            style: TextStyle(
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
                          const Icon(Icons.restaurant, size: 16),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text('From: Pizza Palace'),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '1.2 km',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Icon(Icons.location_on, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text('To: 123 Main Street'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {},
                              child: const Text('Decline'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {},
                              child: const Text('Accept'),
                            ),
                          ),
                        ],
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

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.primaryGreen,
            child: Text(
              authProvider.currentUser?.fullName.substring(0, 1).toUpperCase() ?? 'R',
              style: const TextStyle(fontSize: 32, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            authProvider.currentUser?.fullName ?? 'Rider',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          Text(
            '⭐ 4.9 (152 deliveries)',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ListTile(
            leading: const Icon(Icons.phone_outlined),
            title: const Text('Contact Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.history_outlined),
            title: const Text('Delivery History'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<AuthProvider>().signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
