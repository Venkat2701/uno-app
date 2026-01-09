import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ActivityTracker extends StatelessWidget {
  final Widget child;

  const ActivityTracker({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _updateActivity(context),
      onPanDown: (_) => _updateActivity(context),
      onScaleStart: (_) => _updateActivity(context),
      behavior: HitTestBehavior.translucent,
      child: Listener(
        onPointerDown: (_) => _updateActivity(context),
        onPointerMove: (_) => _updateActivity(context),
        child: child,
      ),
    );
  }

  void _updateActivity(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isAuthenticated) {
      authProvider.updateActivity();
    }
  }
}