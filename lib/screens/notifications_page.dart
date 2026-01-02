import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import '../models/notification.dart';

class NotificationsPage extends StatelessWidget {
  final VoidCallback? onNavigateToGames;
  
  const NotificationsPage({super.key, this.onNavigateToGames});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    return Container(
      color: const Color(0xFFF8FAFC),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF4A90E2),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onNavigateToGames ?? () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.games, color: Colors.white, size: 20),
                          SizedBox(width: 6),
                          Text(
                            'Games',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.notifications, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<NotificationProvider>(
                builder: (context, notificationProvider, child) {
                  return StreamBuilder<List<GameNotification>>(
                    stream: notificationProvider.getUserNotifications(authProvider.user!.uid),
                    builder: (context, snapshot) {
                      print('NotificationsPage - Connection state: ${snapshot.connectionState}');
                      print('NotificationsPage - Has data: ${snapshot.hasData}');
                      print('NotificationsPage - Data: ${snapshot.data}');
                      print('NotificationsPage - Error: ${snapshot.error}');
                      
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        print('NotificationsPage - Error occurred: ${snapshot.error}');
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        print('NotificationsPage - No data or empty list');
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_none,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No notifications',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ).animate().fadeIn(duration: 600.ms),
                        );
                      }

                      final notifications = snapshot.data!;
                      print('NotificationsPage - Displaying ${notifications.length} notifications');
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notification = notifications[index];
                          print('NotificationsPage - Building notification card for: ${notification.gameName}');
                          return _NotificationCard(
                            notification: notification,
                            onAccept: () => _acceptShare(context, notification),
                            onDecline: () => _declineShare(context, notification),
                          ).animate(delay: (index * 100).ms).slideX(begin: 1.0, end: 0.0);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _acceptShare(BuildContext context, GameNotification notification) async {
    final notificationProvider = context.read<NotificationProvider>();
    await notificationProvider.acceptGameShare(
      notification.id,
      notification.gameId,
      notification.toUserId,
    );
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Game added to your list!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _declineShare(BuildContext context, GameNotification notification) async {
    final notificationProvider = context.read<NotificationProvider>();
    await notificationProvider.declineGameShare(notification.id);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Game share declined'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}

class _NotificationCard extends StatelessWidget {
  final GameNotification notification;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _NotificationCard({
    required this.notification,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90E2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.share,
                    color: Color(0xFF4A90E2),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Game Shared',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${notification.fromUserName} shared "${notification.gameName}" game with you',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDecline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Decline'),
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