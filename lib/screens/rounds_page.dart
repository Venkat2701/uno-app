import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/game.dart';
import '../providers/game_provider.dart';
import 'create_round_page.dart';
import 'edit_round_page.dart';

class RoundsPage extends StatelessWidget {
  final Game game;

  const RoundsPage({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        return StreamBuilder<Game?>(
          stream: gameProvider.getGameStream(game.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                body: Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage('https://images.unsplash.com/photo-1541963463532-d68292c34d19?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2088&q=80'),
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
                  child: const Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final currentGame = snapshot.data ?? game;
            final rounds = currentGame.rounds.values.toList()
              ..sort((a, b) => b.number.compareTo(a.number));

            return Scaffold(
              body: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1596838132731-3301c3fd4317?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2070&q=80'),
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
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Expanded(
                              child: Text(
                                'Game Rounds List',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Roboto',
                                  letterSpacing: 1.0,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                      ),
                      Expanded(
                        child: rounds.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.casino_outlined,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No rounds yet',
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap the + button to create the first round',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ).animate().fadeIn(duration: 600.ms).scale(delay: 200.ms),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: rounds.length,
                                itemBuilder: (context, index) {
                                  final round = rounds[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFB3D9FF),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            pageBuilder: (context, animation, secondaryAnimation) =>
                                                EditRoundPage(game: currentGame, round: round),
                                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                              return SlideTransition(
                                                position: animation.drive(
                                                  Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                                                      .chain(CurveTween(curve: Curves.easeInOut)),
                                                ),
                                                child: child,
                                              );
                                            },
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(20),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 50,
                                              height: 50,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF4A90E2),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '${round.number}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Round ${round.number}',
                                                    style: const TextStyle(
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${round.playerScores.length} players',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              color: Colors.grey[400],
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ).animate(delay: Duration(milliseconds: index * 100))
                                      .slideX(begin: 0.3, duration: 400.ms)
                                      .fadeIn(duration: 400.ms);
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
                            CreateRoundPage(game: currentGame),
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
              ).animate().scale(delay: 600.ms, duration: 400.ms),
            );
          },
        );
      },
    );
  }
}