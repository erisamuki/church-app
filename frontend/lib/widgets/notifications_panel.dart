import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';

class NotificationsBell extends StatefulWidget {
  const NotificationsBell({super.key});

  @override
  State<NotificationsBell> createState() => _NotificationsBellState();
}

class _NotificationsBellState extends State<NotificationsBell> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final res = await ApiService.get('/notifications/unread-count');
      final data = res['data'] ?? res;
      if (mounted) {
        setState(() => _unreadCount = data['count'] ?? 0);
      }
    } catch (e) {
      // silently ignore, badge just won't show
    }
  }

  void _openPanel() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _NotificationsSheet(),
    );
    _loadUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Color(0xFF64748B)),
          onPressed: _openPanel,
        ),
        if (_unreadCount > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Color(0xFFEA580C),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _unreadCount > 9 ? '9+' : '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NotificationsSheet extends StatefulWidget {
  const _NotificationsSheet();

  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiService.get('/notifications');
      final List<dynamic> data = res['data'] ?? res;
      setState(() {
        _notifications = data.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await ApiService.post('/notifications/read-all', {});
    } catch (e) {
      // ignore
    }
    _load();
  }

  Future<void> _onTapNotification(Map<String, dynamic> n) async {
    if (n['is_read'] != true) {
      try {
        await ApiService.post('/notifications/${n['id']}/read', {});
      } catch (e) {
        // ignore
      }
    }
    if (mounted) {
      Navigator.pop(context);
      if (n['type'] == 'new_member' && n['related_id'] != null) {
        context.push('/members/${n['related_id']}');
      }
    }
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'new_member':
        return Icons.person_add_outlined;
      case 'event_reminder':
        return Icons.event_outlined;
      case 'announcement':
        return Icons.campaign_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _timeAgo(String? createdAt) {
    if (createdAt == null) return '';
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _markAllRead,
                      child: const Text('Mark all read'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _notifications.isEmpty
                        ? const Center(child: Text('No notifications yet'))
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: _notifications.length,
                            itemBuilder: (context, index) {
                              final n = _notifications[index];
                              final isRead = n['is_read'] == true;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      isRead ? const Color(0xFFF1F5F9) : const Color(0xFFFFF1E6),
                                  child: Icon(
                                    _iconForType(n['type']),
                                    size: 18,
                                    color:
                                        isRead ? const Color(0xFF64748B) : const Color(0xFFEA580C),
                                  ),
                                ),
                                title: Text(
                                  n['title'] ?? '',
                                  style: TextStyle(
                                    fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  n['message'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Text(
                                  _timeAgo(n['created_at']?.toString()),
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                ),
                                onTap: () => _onTapNotification(n),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}
