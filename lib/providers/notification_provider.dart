import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/notification.dart';

class NotificationProvider extends ChangeNotifier {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  List<GameNotification> _notifications = [];
  bool _isLoading = false;

  List<GameNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Stream<List<GameNotification>> getUserNotifications(String userId) {
    print('Getting notifications for user: $userId');
    return _database
        .child('notifications')
        .orderByChild('toUserId')
        .equalTo(userId)
        .onValue
        .asyncMap((event) async {
      print('Notification event received: ${event.snapshot.value}');
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        print('No notification data found');
        return <GameNotification>[];
      }
      
      final notifications = data.entries
          .map((entry) => GameNotification.fromJson(entry.key.toString(), entry.value))
          .toList();
      
      // Get user's shared games to filter out already accepted games
      final userSnapshot = await _database.child('users').child(userId).get();
      final userSharedGames = <String>{};
      if (userSnapshot.exists) {
        final userData = userSnapshot.value as Map<dynamic, dynamic>;
        final sharedGames = userData['sharedGames'] as Map<dynamic, dynamic>? ?? {};
        userSharedGames.addAll(sharedGames.keys.map((k) => k.toString()));
      }
      
      // Filter out notifications for games already in user's shared games
      final filteredNotifications = notifications
          .where((notification) => !userSharedGames.contains(notification.gameId))
          .toList();
      
      // Resolve actual usernames for notifications
      for (final notification in filteredNotifications) {
        try {
          final fromUserSnapshot = await _database.child('users').child(notification.fromUserId).get();
          if (fromUserSnapshot.exists) {
            final fromUserData = fromUserSnapshot.value as Map<dynamic, dynamic>;
            final username = fromUserData['username'] as String? ?? '';
            final email = fromUserData['email'] as String? ?? '';
            // Use username if available, otherwise fall back to email prefix
            notification.fromUserName = username.isNotEmpty ? username : email.split('@')[0];
          }
        } catch (e) {
          print('Error resolving username for ${notification.fromUserId}: $e');
        }
      }
      
      print('Found ${filteredNotifications.length} notifications after filtering');
      filteredNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return filteredNotifications;
    });
  }

  Future<void> createGameShareNotification({
    required String gameId,
    required String gameName,
    required String fromUserId,
    required String fromUserName,
    required String toUserId,
  }) async {
    try {
      final notificationRef = _database.child('notifications').push();
      await notificationRef.set({
        'type': 'game_share',
        'gameId': gameId,
        'gameName': gameName,
        'fromUserId': fromUserId,
        'fromUserName': fromUserName,
        'toUserId': toUserId,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'isRead': false,
      });
    } catch (e) {
      debugPrint('Failed to create notification: $e');
    }
  }

  Future<void> acceptGameShare(String notificationId, String gameId, String userId) async {
    try {
      final updates = <String, dynamic>{};
      
      // Add game to user's shared games
      updates['users/$userId/sharedGames/$gameId'] = true;
      
      // Add user to game's sharedWith list
      updates['games/$gameId/sharedWith/$userId'] = true;
      
      // Remove the notification completely
      updates['notifications/$notificationId'] = null;
      
      await _database.update(updates);
    } catch (e) {
      debugPrint('Failed to accept game share: $e');
    }
  }

  Future<void> declineGameShare(String notificationId) async {
    try {
      await _database.child('notifications/$notificationId').remove();
    } catch (e) {
      debugPrint('Failed to decline game share: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _database.child('notifications/$notificationId/isRead').set(true);
    } catch (e) {
      debugPrint('Failed to mark notification as read: $e');
    }
  }
}