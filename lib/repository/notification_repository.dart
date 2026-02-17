// lib/repository/notification_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/notification_model.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _notificationsCollection = 'notifications';

  // Create notification
  Future<void> createNotification(NotificationModel notification) async {
    try {
      await _firestore
          .collection(_notificationsCollection)
          .doc(notification.notificationId)
          .set(notification.toMap());
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  // Get user notifications
  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_notificationsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return NotificationModel.fromMap({
          'notificationId': doc.id,
          ...doc.data(),
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to get notifications: $e');
    }
  }

  // Mark as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception('Failed to mark as read: $e');
    }
  }

  // Mark all as read
  Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_notificationsCollection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all as read: $e');
    }
  }

  // Get unread count
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_notificationsCollection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Watch notifications (real-time)
  Stream<List<NotificationModel>> watchUserNotifications(String userId) {
    return _firestore
        .collection(_notificationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return NotificationModel.fromMap({
          'notificationId': doc.id,
          ...doc.data(),
        });
      }).toList();
    });
  }
}

