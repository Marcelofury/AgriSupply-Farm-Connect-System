import 'package:flutter/foundation.dart';

import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasNewNotifications = false;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasNewNotifications => _hasNewNotifications;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  List<NotificationModel> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  // Group notifications by date
  Map<String, List<NotificationModel>> get groupedNotifications {
    final Map<String, List<NotificationModel>> grouped = {};
    final now = DateTime.now();

    for (final notification in _notifications) {
      String key;
      final diff = now.difference(notification.createdAt);

      if (diff.inDays == 0) {
        key = 'Today';
      } else if (diff.inDays == 1) {
        key = 'Yesterday';
      } else if (diff.inDays < 7) {
        key = 'This Week';
      } else if (diff.inDays < 30) {
        key = 'This Month';
      } else {
        key = 'Earlier';
      }

      if (grouped.containsKey(key)) {
        grouped[key]!.add(notification);
      } else {
        grouped[key] = [notification];
      }
    }

    return grouped;
  }

  // Fetch notifications for user
  Future<void> fetchNotifications(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notifications = await _notificationService.getNotifications(userId);
      _hasNewNotifications = _notifications.any((n) => !n.isRead);
      _isLoading = false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
    }

    notifyListeners();
  }

  // Mark single notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);

      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index >= 0) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
      }

      _hasNewNotifications = _notifications.any((n) => !n.isRead);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      await _notificationService.markAllAsRead(userId);

      _notifications = _notifications.map((n) {
        return n.copyWith(isRead: true);
      }).toList();

      _hasNewNotifications = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      _notifications.removeWhere((n) => n.id == notificationId);
      _hasNewNotifications = _notifications.any((n) => !n.isRead);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications(String userId) async {
    try {
      await _notificationService.clearAllNotifications(userId);
      _notifications.clear();
      _hasNewNotifications = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Handle notification tap - navigate based on type
  void onNotificationTap(NotificationModel notification) {
    if (!notification.isRead) {
      markAsRead(notification.id);
    }

    // Return action data for navigation
    // The screen that uses this provider will handle navigation
  }

  // Add new notification (for real-time updates)
  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    _hasNewNotifications = true;
    notifyListeners();
  }

  // Update notification preferences
  Future<void> updatePreferences({
    required String userId,
    bool? orderUpdates,
    bool? newMessages,
    bool? promotions,
    bool? priceAlerts,
    bool? farmingTips,
  }) async {
    try {
      await _notificationService.updatePreferences(
        userId: userId,
        orderUpdates: orderUpdates,
        newMessages: newMessages,
        promotions: promotions,
        priceAlerts: priceAlerts,
        farmingTips: farmingTips,
      );
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Get notifications by type
  List<NotificationModel> getByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  // Subscribe to real-time notifications
  void subscribeToNotifications(String userId) {
    _notificationService.subscribeToNotifications(
      userId,
      onNewNotification: (notification) {
        addNotification(notification);
      },
    );
  }

  // Unsubscribe from real-time notifications
  void unsubscribeFromNotifications() {
    _notificationService.unsubscribeFromNotifications();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
