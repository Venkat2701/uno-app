import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/game_provider.dart';
import '../providers/auth_provider.dart';
import '../models/game.dart';
import '../widgets/game_card.dart';
import 'create_game_page.dart';
import 'game_dashboard.dart';
import 'login_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedFilter = 'All';
  Map<String, String> _userNames = {};
  bool _userNamesLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadUserNames();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage('https://images.unsplash.com/photo-1606092195730-5d7b9af1efc5?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2070&q=80'),
            fit: BoxFit.cover,
            opacity: 0.1,
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4A90E2),
              Color(0xFFE8F4FD),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          // Try username first, then email local part, then 'User'
                          String displayName = 'User';
                          if (authProvider.appUser?.username.isNotEmpty == true) {
                            displayName = authProvider.appUser!.username;
                          } else if (authProvider.user?.email != null) {
                            displayName = authProvider.user!.email!.split('@')[0];
                          }
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'UNO Games List',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Roboto',
                                  letterSpacing: 1.2,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                      color: Colors.black26,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Hi $displayName!',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white, size: 28),
                      onPressed: () async {
                        await context.read<AuthProvider>().logout();
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                return FadeTransition(opacity: animation, child: child);
                              },
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Consumer2<GameProvider, AuthProvider>(
                  builder: (context, gameProvider, authProvider, child) {
                    if (authProvider.user == null) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return StreamBuilder<List<Game>>(
                      stream: gameProvider.getUserGames(authProvider.user!.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.red[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Error loading games',
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  snapshot.error.toString(),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }

                        final games = snapshot.data ?? [];
                        final filteredGames = _filterGames(games, authProvider.user!.uid);

                        return Column(
                          children: [
                            // Filter chips - always visible
                            Container(
                              height: 50,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                children: _buildFilterChips(games, authProvider.user!.uid),
                              ),
                            ),
                            // Games list or empty state
                            Expanded(
                              child: _buildGamesList(games, filteredGames, gameProvider, authProvider),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A90E2).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const CreateGamePage(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return ScaleTransition(
                    scale: animation.drive(
                      Tween(begin: 0.0, end: 1.0).chain(
                        CurveTween(curve: Curves.elasticOut),
                      ),
                    ),
                    child: child,
                  );
                },
              ),
            );
          },
          backgroundColor: const Color(0xFF4A90E2),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ).animate().scale(delay: 800.ms, duration: 400.ms),
    );
  }

  Widget _buildGamesList(List<Game> games, List<Game> filteredGames, GameProvider gameProvider, AuthProvider authProvider) {
    if (games.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.gamepad_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No games yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to create your first game',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ).animate().fadeIn(duration: 600.ms).scale(delay: 200.ms),
      );
    }

    if (filteredGames.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No games match filter',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try changing the filter or create a new game',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ).animate().fadeIn(duration: 600.ms).scale(delay: 200.ms),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Stream automatically refreshes
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: filteredGames.length,
        itemBuilder: (context, index) {
          final game = filteredGames[index];
          final isOwner = game.ownerId == authProvider.user!.uid;
          
          if (isOwner) {
            return Dismissible(
              key: Key(game.id),
              direction: DismissDirection.endToStart,
              confirmDismiss: (direction) async {
                return await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Game'),
                    content: Text('Are you sure you want to delete "${game.name}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('No'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Yes', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (direction) async {
                await gameProvider.deleteGame(game.id, authProvider.user!.uid);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"${game.name}" deleted'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: Colors.red,
                child: const Icon(
                  Icons.delete,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              child: GameCard(
                game: game,
                index: index,
                onTap: () => _navigateToGame(game),
              ),
            );
          } else {
            return GameCard(
              game: game,
              index: index,
              onTap: () => _navigateToGame(game),
            );
          }
        },
      ),
    );
  }

  void _navigateToGame(Game game) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => GameDashboard(game: game),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(0.0, 1.0), end: Offset.zero)
                  .chain(CurveTween(curve: Curves.easeInOut)),
            ),
            child: child,
          );
        },
      ),
    );
  }

  void _loadUserNames() async {
    if (_userNamesLoaded) return;
    
    final gameProvider = context.read<GameProvider>();
    try {
      final users = await gameProvider.getAllUsers();
      final userMap = <String, String>{};
      for (final user in users) {
        userMap[user.uid] = user.username.isNotEmpty ? user.username : user.email.split('@')[0];
      }
      if (mounted) {
        setState(() {
          _userNames = userMap;
          _userNamesLoaded = true;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  List<Game> _filterGames(List<Game> games, String currentUserId) {
    if (_selectedFilter == 'All') return games;
    if (_selectedFilter == 'Owned') {
      return games.where((game) => game.ownerId == currentUserId).toList();
    }
    // Filter by shared user
    final userId = _userNames.entries
        .firstWhere((entry) => 'Shared by ${entry.value}' == _selectedFilter,
            orElse: () => const MapEntry('', ''))
        .key;
    if (userId.isNotEmpty) {
      return games.where((game) => game.ownerId == userId).toList();
    }
    return games;
  }

  List<Widget> _buildFilterChips(List<Game> games, String currentUserId) {
    final chips = <Widget>[];
    
    // All games chip
    chips.add(_buildFilterChip('All', Icons.apps));
    
    // Owned games chip
    chips.add(_buildFilterChip('Owned', Icons.person));
    
    // Shared by other users chips
    final sharedByUsers = <String>{};
    for (final game in games) {
      if (game.ownerId != currentUserId) {
        sharedByUsers.add(game.ownerId);
      }
    }
    
    for (final userId in sharedByUsers) {
      final userName = _userNames[userId] ?? 'Unknown';
      chips.add(_buildFilterChip('Shared by $userName', Icons.share));
    }
    
    return chips;
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _selectedFilter == label;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF4A90E2),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF4A90E2),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        selectedColor: const Color(0xFF4A90E2),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFF4A90E2)),
        onSelected: (selected) {
          setState(() {
            _selectedFilter = label;
          });
        },
      ),
    );
  }
}