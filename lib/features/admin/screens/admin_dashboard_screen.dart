import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const OverviewTab(),
    const ChatOversightTab(),
    const DisputesTab(),
    const AnalyticsTab(),
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
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_outlined),
            activeIcon: Icon(Icons.chat),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_problem_outlined),
            activeIcon: Icon(Icons.report_problem),
            label: 'Disputes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}

class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Platform Overview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Active Orders',
                    '127',
                    Icons.shopping_bag,
                    AppTheme.warningOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Total Vendors',
                    '89',
                    Icons.store,
                    AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Active Riders',
                    '45',
                    Icons.delivery_dining,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Revenue Today',
                    '\$2.5K',
                    Icons.attach_money,
                    AppTheme.successGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...List.generate(
              8,
              (index) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getActivityColor(index % 4),
                    child: Icon(
                      _getActivityIcon(index % 4),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(_getActivityTitle(index % 4)),
                  subtitle: Text('${index + 1} mins ago'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.trending_up, color: AppTheme.successGreen, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getActivityColor(int index) {
    switch (index) {
      case 0:
        return AppTheme.primaryGreen;
      case 1:
        return Colors.blue;
      case 2:
        return AppTheme.warningOrange;
      case 3:
        return AppTheme.errorRed;
      default:
        return AppTheme.textGray;
    }
  }

  IconData _getActivityIcon(int index) {
    switch (index) {
      case 0:
        return Icons.shopping_bag;
      case 1:
        return Icons.store;
      case 2:
        return Icons.delivery_dining;
      case 3:
        return Icons.report_problem;
      default:
        return Icons.circle;
    }
  }

  String _getActivityTitle(int index) {
    switch (index) {
      case 0:
        return 'New order placed';
      case 1:
        return 'New vendor registered';
      case 2:
        return 'Delivery completed';
      case 3:
        return 'Dispute reported';
      default:
        return 'Activity';
    }
  }
}

class ChatOversightTab extends StatelessWidget {
  const ChatOversightTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Oversight'),
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'All Chats'),
                Tab(text: 'Vendors'),
                Tab(text: 'Riders'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildChatList(context),
                  _buildChatList(context),
                  _buildChatList(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 15,
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryGreen,
              child: Text('U${index + 1}'),
            ),
            title: Text('Chat Room ${index + 1}'),
            subtitle: const Text('Last message: Hi, where is my order?'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  '2m ago',
                  style: TextStyle(fontSize: 12, color: AppTheme.textGray),
                ),
                const SizedBox(height: 4),
                if (index % 3 == 0)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppTheme.errorRed,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      '3',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            onTap: () {
              // TODO: Navigate to chat details
            },
          ),
        );
      },
    );
  }
}

class DisputesTab extends StatelessWidget {
  const DisputesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dispute Resolution')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        itemBuilder: (context, index) {
          return Card(
            child: ExpansionTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: index % 2 == 0
                      ? AppTheme.warningOrange.withOpacity(0.2)
                      : AppTheme.errorRed.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.report_problem,
                  color: index % 2 == 0 ? AppTheme.warningOrange : AppTheme.errorRed,
                ),
              ),
              title: Text('Dispute #${5000 + index}'),
              subtitle: Text('Order #${3000 + index} • ${index + 1} hours ago'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: index % 2 == 0
                      ? AppTheme.warningOrange
                      : AppTheme.errorRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  index % 2 == 0 ? 'Pending' : 'Urgent',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Issue: Order not delivered',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Customer claims the order was not received, but the rider marked it as delivered.',
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {},
                              child: const Text('View Details'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {},
                              child: const Text('Resolve'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AnalyticsTab extends StatelessWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Platform Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Commission Revenue',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Card(
              color: AppTheme.primaryGreen,
              child: const Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Total Commission (30 Days)',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '\$12,450.75',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Platform Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildStatRow('Total Orders', '2,345'),
            _buildStatRow('Completed Orders', '2,198'),
            _buildStatRow('Cancelled Orders', '147'),
            _buildStatRow('Average Order Value', '\$28.50'),
            _buildStatRow('Total Users', '1,234'),
            _buildStatRow('Active Vendors', '89'),
            _buildStatRow('Active Riders', '45'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download),
              label: const Text('Export Report'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }
}
