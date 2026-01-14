import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const OrdersKanbanTab(),
    const ProductsTab(),
    const FinancialsTab(),
    const VendorProfileTab(),
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
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_outlined),
            activeIcon: Icon(Icons.inventory),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Financials',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store_outlined),
            activeIcon: Icon(Icons.store),
            label: 'Store',
          ),
        ],
      ),
    );
  }
}

class OrdersKanbanTab extends StatelessWidget {
  const OrdersKanbanTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders - Kanban Board'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_outlined),
            onPressed: () {
              // TODO: Navigate to chat
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildKanbanColumn(context, 'New', AppTheme.warningOrange, 3),
            _buildKanbanColumn(context, 'Processing', Colors.blue, 2),
            _buildKanbanColumn(context, 'Ready', AppTheme.successGreen, 1),
            _buildKanbanColumn(context, 'Completed', AppTheme.textGray, 5),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Toggle store open/closed
        },
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(Icons.store),
      ),
    );
  }

  Widget _buildKanbanColumn(
    BuildContext context,
    String title,
    Color color,
    int count,
  ) {
    return Container(
      width: 280,
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(
            count,
            (index) => _buildOrderCard(context, title, index),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, String status, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${1000 + index}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${(25.50 + index * 5).toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('3 items', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              '5 mins ago',
              style: TextStyle(fontSize: 12, color: AppTheme.textGray),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('View', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Accept', style: TextStyle(fontSize: 12)),
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

class ProductsTab extends StatelessWidget {
  const ProductsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products & Inventory'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 10,
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
                child: const Icon(Icons.fastfood, color: AppTheme.primaryGreen),
              ),
              title: Text('Product ${index + 1}'),
              subtitle: Text('\$${(10.0 + index * 2).toStringAsFixed(2)} • Stock: ${20 - index}'),
              trailing: Switch(
                value: index % 2 == 0,
                onChanged: (value) {},
                activeColor: AppTheme.primaryGreen,
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Add product
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }
}

class FinancialsTab extends StatelessWidget {
  const FinancialsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Financials')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatCard('Today\'s Revenue', '\$245.50', AppTheme.successGreen),
            _buildStatCard('Pending Orders', '5', AppTheme.warningOrange),
            _buildStatCard('Completed Orders', '23', AppTheme.primaryGreen),
            const SizedBox(height: 24),
            Text(
              'Recent Transactions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...List.generate(
              5,
              (index) => ListTile(
                leading: const Icon(Icons.payment, color: AppTheme.successGreen),
                title: Text('Order #${2000 + index}'),
                subtitle: Text('${DateTime.now().subtract(Duration(hours: index)).hour}:00'),
                trailing: Text(
                  '+\$${(25.0 + index * 5).toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppTheme.successGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VendorProfileTab extends StatelessWidget {
  const VendorProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Store Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.store, size: 60, color: AppTheme.primaryGreen),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'My Store Name',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          Text(
            '⭐ 4.8 (245 reviews)',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit Store Info'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Manage Categories'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.schedule_outlined),
            title: const Text('Opening Hours'),
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
