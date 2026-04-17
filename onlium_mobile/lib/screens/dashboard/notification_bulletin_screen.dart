import 'package:flutter/material.dart';

class NotificationBulletinScreen extends StatelessWidget {
  final int initialTab;

  const NotificationBulletinScreen({super.key, this.initialTab = 0});

  static final List<_ItemData> notifications = [
    _ItemData(
      title: 'Enrollment requirement approved',
      subtitle: 'Your clearance document has been approved by the admin.',
      time: '2 hours ago',
      icon: Icons.check_circle,
      color: Colors.green,
    ),
    _ItemData(
      title: 'Enrollment schedule updated',
      subtitle: 'Your preferred schedule has been updated to Morning.',
      time: 'Yesterday',
      icon: Icons.schedule,
      color: Colors.orange,
    ),
    _ItemData(
      title: 'Payment due reminder',
      subtitle: 'Please submit the enrollment payment before the deadline.',
      time: '2 days ago',
      icon: Icons.payment,
      color: Colors.red,
    ),
  ];

  static final List<_ItemData> bulletins = [
    _ItemData(
      title: 'Enrollment deadline extended',
      subtitle: 'The deadline for submission has been moved to June 30, 2024.',
      time: 'Today',
      icon: Icons.campaign,
      color: Colors.blue,
    ),
    _ItemData(
      title: 'Campus orientation schedule',
      subtitle: 'Orientation starts on July 5. Check your portal for details.',
      time: 'Yesterday',
      icon: Icons.event,
      color: Colors.purple,
    ),
    _ItemData(
      title: 'New study resources available',
      subtitle: 'A new library of learning materials has been published.',
      time: '3 days ago',
      icon: Icons.library_books,
      color: Colors.teal,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: initialTab,
      length: 2,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3F7ED8), Color(0xFF8EC7FF), Color(0xFFD6ECFF)],
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text('Updates'),
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              bottom: const TabBar(
                indicatorColor: Colors.white,
                tabs: [
                  Tab(text: 'Notifications'),
                  Tab(text: 'Bulletins'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildListView(notifications),
                _buildListView(bulletins),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListView(List<_ItemData> items) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: item.color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                item.time,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ItemData {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color color;

  const _ItemData({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
  });
}
