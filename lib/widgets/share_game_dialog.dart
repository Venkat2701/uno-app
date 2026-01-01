import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import '../providers/game_provider.dart';
import '../providers/auth_provider.dart';
import '../models/game.dart';
import '../models/user.dart';

class ShareGameDialog extends StatefulWidget {
  final Game game;

  const ShareGameDialog({super.key, required this.game});

  @override
  State<ShareGameDialog> createState() => _ShareGameDialogState();
}

class _ShareGameDialogState extends State<ShareGameDialog> {
  List<AppUser> _users = [];
  Set<String> _selectedUserIds = {};
  bool _isLoading = false;
  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await context.read<GameProvider>().getAllUsers();
      final currentUserId = context.read<AuthProvider>().user?.uid;
      
      // Get fresh game data to check current shared users
      final gameSnapshot = await FirebaseDatabase.instance.ref('games/${widget.game.id}').get();
      final currentSharedWith = gameSnapshot.exists 
          ? Map<String, bool>.from((gameSnapshot.value as Map)['sharedWith'] ?? {})
          : <String, bool>{};
      
      setState(() {
        _users = users.where((user) => user.uid != currentUserId).toList();
        _selectedUserIds = Set<String>.from(currentSharedWith.keys);
        _isLoadingUsers = false;
      });
    } catch (e) {
      setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _shareGame() async {
    if (_selectedUserIds.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // Use actual user UIDs, not emails
      await context.read<GameProvider>().shareGame(widget.game.id, _selectedUserIds.toList());
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Game shared with ${_selectedUserIds.length} user(s)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share game: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Share Game'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            Text('Share "${widget.game.name}" with users:'),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoadingUsers
                  ? const Center(child: CircularProgressIndicator())
                  : _users.isEmpty
                      ? const Center(child: Text('No other users found'))
                      : ListView.builder(
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            return CheckboxListTile(
                              title: Text(user.username.isNotEmpty ? user.username : user.email),
                              subtitle: user.username.isNotEmpty ? Text(user.email) : null,
                              value: _selectedUserIds.contains(user.uid),
                              onChanged: (selected) {
                                setState(() {
                                  if (selected == true) {
                                    _selectedUserIds.add(user.uid);
                                  } else {
                                    _selectedUserIds.remove(user.uid);
                                  }
                                });
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading || _selectedUserIds.isEmpty ? null : _shareGame,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Share (${_selectedUserIds.length})'),
        ),
      ],
    );
  }
}