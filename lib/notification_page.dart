// notification_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:testing/AppointmentDetailsPage.dart';
import 'doctor/doctor_requests_page.dart';
import 'notification_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  int _unreadCount = 0;
  User? _currentUser;
  late StreamSubscription _notificationStream;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _loadNotifications();
    _setupNotificationListener();
  }

  @override
  void dispose() {
    _notificationStream.cancel();
    super.dispose();
  }

  void _setupNotificationListener() {
    if (_currentUser == null) return;
    _notificationStream = NotificationService.getNotificationStream(_currentUser!.uid)
        .listen((_) => _loadNotifications());
  }

  Future<void> _loadNotifications() async {
    if (_currentUser == null) return;

    setState(() => _isLoading = true);
    try {
      final notifications = await NotificationService.getUserNotifications(_currentUser!.uid);
      final unreadCount = await NotificationService.getUnreadCount(_currentUser!.uid);
      setState(() {
        _notifications = notifications;
        _unreadCount = unreadCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Failed to load notifications: ${e.toString()}');
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await NotificationService.markAsRead(_currentUser!.uid, notificationId);
      setState(() {
        final index = _notifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1) {
          _notifications[index]['isRead'] = true;
          _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
        }
      });
    } catch (e) {
      _showErrorSnackbar('Failed to mark as read: ${e.toString()}');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await NotificationService.markAllAsRead(_currentUser!.uid);
      setState(() {
        for (var notification in _notifications) {
          notification['isRead'] = true;
        }
        _unreadCount = 0;
      });
    } catch (e) {
      _showErrorSnackbar('Failed to mark all as read: ${e.toString()}');
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await NotificationService.deleteNotification(_currentUser!.uid, notificationId);
      setState(() {
        _notifications.removeWhere((n) => n['id'] == notificationId);
        if (_notifications.any((n) => n['id'] == notificationId && !n['isRead'])) {
          _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
        }
      });
    } catch (e) {
      _showErrorSnackbar('Failed to delete notification: ${e.toString()}');
    }
  }

  Future<void> _clearAllNotifications() async {
    try {
      await NotificationService.clearAllNotifications(_currentUser!.uid);
      setState(() {
        _notifications.clear();
        _unreadCount = 0;
      });
    } catch (e) {
      _showErrorSnackbar('Failed to clear notifications: ${e.toString()}');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'Notifications',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Badge(
                label: Text(_unreadCount.toString()),
                backgroundColor: Colors.red,
                smallSize: 20,
              ),
            ],
          ],
        ),
        centerTitle: true,
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.mark_as_unread),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _showClearAllDialog,
              tooltip: 'Clear all notifications',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? _buildEmptyState()
          : _buildNotificationList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final timestamp = notification['createdAt'] ?? 0;
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final formattedDate = DateFormat('MMM d, hh:mm a').format(date);
    final isUnread = notification['isRead'] == false;
    final type = notification['type'] ?? '';
    final title = notification['title'] ?? 'Notification';
    final body = notification['body'] ?? '';
    final notificationId = notification['id'] ?? '';
    final isForDoctor = notification['isForDoctor'] == true;

    final iconData = _getNotificationIcon(type);
    final iconColor = _getNotificationColor(type);
    final cardColor = isUnread
        ? Colors.blue.shade50.withOpacity(0.5)
        : Theme.of(context).cardColor;

    return Dismissible(
      key: Key(notificationId),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) => _showDeleteDialog(notificationId),
      onDismissed: (direction) => _deleteNotification(notificationId),
      child: InkWell(
        onTap: () {
          if (isUnread) _markAsRead(notificationId);
          _handleNotificationTap(notification);
        },
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: cardColor,
          elevation: isUnread ? 2 : 1,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor),
            ),
            title: Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  body,
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: GoogleFonts.poppins(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: isUnread
                ? const Badge(
              smallSize: 10,
              backgroundColor: Colors.red,
            )
                : null,
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    if (type.contains('appointment')) {
      if (type.contains('accepted') || type.contains('completed') || type.contains('booked')) {
        return Icons.check_circle;
      } else if (type.contains('rejected') || type.contains('canceled')) {
        return Icons.cancel;
      } else if (type.contains('request')) {
        return Icons.notifications_active;
      }
    }
    return Icons.notifications;
  }

  Color _getNotificationColor(String type) {
    if (type.contains('appointment')) {
      if (type.contains('accepted') || type.contains('completed') || type.contains('booked')) {
        return Colors.green;
      } else if (type.contains('rejected') || type.contains('canceled')) {
        return Colors.red;
      } else if (type.contains('request')) {
        return Colors.blue;
      }
    }
    return Colors.amber;
  }

  Future<bool?> _showDeleteDialog(String notificationId) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to clear all notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllNotifications();
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    final type = notification['type'] ?? '';
    final requestId = notification['requestId'] ?? '';
    final isForDoctor = notification['isForDoctor'] == true;

    if (type.contains('appointment') && requestId.isNotEmpty) {
      if (isForDoctor) {
        // For doctor - navigate to requests page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DoctorRequestsPage(),
          ),
        );
      } else {
        // For patient - navigate to appointment details
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AppointmentDetailsScreen(
              appointmentId: requestId,
            ),
          ),
        );
      }
    }
  }
}