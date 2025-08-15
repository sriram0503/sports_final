import 'package:flutter/material.dart';

enum NotificationType { message, follow, session }

class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String subtitle;
  final DateTime time;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.time,
    this.isRead = false,
  });
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final List<NotificationItem> _items = [
    NotificationItem(
      id: '1',
      type: NotificationType.message,
      title: 'New message from Mike',
      subtitle: '“Hey, wanna play this weekend?”',
      time: DateTime.now().subtract(const Duration(minutes: 5)),
      isRead: false,
    ),
    NotificationItem(
      id: '2',
      type: NotificationType.follow,
      title: 'John started following you',
      subtitle: 'Tap to view profile',
      time: DateTime.now().subtract(const Duration(hours: 1)),
      isRead: false,
    ),
    NotificationItem(
      id: '3',
      type: NotificationType.session,
      title: 'Coach Anna requested a session',
      subtitle: 'Today • 5:00 PM',
      time: DateTime.now().subtract(const Duration(days: 1)),
      isRead: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final unread = _items.where((e) => !e.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              tooltip: 'Mark all read',
              onPressed: () {
                setState(() {
                  for (final n in _items) n.isRead = true;
                });
              },
              icon: const Icon(Icons.done_all),
            ),
          if (_items.isNotEmpty)
            IconButton(
              tooltip: 'Clear all',
              onPressed: () {
                setState(() => _items.clear());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications cleared')),
                );
              },
              icon: const Icon(Icons.clear_all),
            ),
        ],
      ),
      body: _items.isEmpty
          ? const Center(child: Text('No notifications'))
          : ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return Dismissible(
            key: ValueKey(item.id),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            secondaryBackground: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) {
              setState(() => _items.removeAt(index));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification removed')),
              );
            },
            child: _NotificationTile(
              item: item,
              onMarkRead: () {
                setState(() => item.isRead = true);
              },
            ),
          );
        },
      ),
      bottomNavigationBar: unread == 0
          ? null
          : SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.notifications_active),
              const SizedBox(width: 12),
              Expanded(child: Text('$unread unread notification${unread == 1 ? '' : 's'}')),
              TextButton(
                onPressed: () {
                  setState(() {
                    for (final n in _items) n.isRead = true;
                  });
                },
                child: const Text('Mark all read'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onMarkRead;
  const _NotificationTile({required this.item, required this.onMarkRead});

  IconData _iconForType() {
    switch (item.type) {
      case NotificationType.message:
        return Icons.chat_bubble_outline;
      case NotificationType.follow:
        return Icons.person_add_alt_1;
      case NotificationType.session:
        return Icons.event_available;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !item.isRead;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: isUnread ? 3 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Stack(
                children: [
                  CircleAvatar(
                    child: Icon(_iconForType()),
                  ),
                  if (isUnread)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              title: Text(
                item.title,
                style: TextStyle(
                  fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              subtitle: Text(item.subtitle),
              trailing: Text(
                _timeAgo(item.time),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),

            // Contextual actions
            if (item.type == NotificationType.session)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Session declined')),
                        );
                        onMarkRead();
                      },
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Session accepted')),
                        );
                        onMarkRead();
                      },
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              )
            else if (item.type == NotificationType.message)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Open chat…')),
                    );
                    onMarkRead();
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open'),
                ),
              )
            else if (item.type == NotificationType.follow)
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('View follower profile…')),
                      );
                      onMarkRead();
                    },
                    icon: const Icon(Icons.person),
                    label: const Text('View'),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  static String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
    // keep it tiny; you can replace with intl later
  }
}

