import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/game.dart';
import '../providers/game_provider.dart';

class CreateRoundPage extends StatefulWidget {
  final Game game;

  const CreateRoundPage({super.key, required this.game});

  @override
  State<CreateRoundPage> createState() => _CreateRoundPageState();
}

class _CreateRoundPageState extends State<CreateRoundPage> {
  final Set<String> _selectedPlayerIds = {};
  final List<TextEditingController> _playerControllers = [];
  bool _isLoading = false;
  bool _showPlayerForm = false;

  @override
  void initState() {
    super.initState();
    if (widget.game.players.isEmpty) {
      _showPlayerForm = true;
      _addPlayerController();
      _addPlayerController();
    }
  }

  @override
  void dispose() {
    for (final controller in _playerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addPlayerController() {
    _playerControllers.add(TextEditingController());
  }

  void _removePlayerController(int index) {
    if (_playerControllers.length > 2) {
      _playerControllers[index].dispose();
      _playerControllers.removeAt(index);
      setState(() {});
    }
  }

  Future<void> _createRound() async {
    if (_showPlayerForm) {
      await _createPlayersAndRound();
    } else {
      await _createRoundWithExistingPlayers();
    }
  }

  Future<void> _createPlayersAndRound() async {
    final playerNames = _playerControllers
        .map((c) => c.text.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    if (playerNames.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least 2 players'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await context.read<GameProvider>().addPlayersToGame(widget.game.id, playerNames);
      
      final playerIds = List.generate(playerNames.length, (index) => 'player_$index');
      await context.read<GameProvider>().createRound(widget.game.id, 1, playerIds);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Round created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create round: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createRoundWithExistingPlayers() async {
    final newPlayerNames = _playerControllers
        .map((c) => c.text.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    if (_selectedPlayerIds.isEmpty && newPlayerNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select existing players or add new players'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (newPlayerNames.isNotEmpty) {
        final currentPlayerCount = widget.game.players.length;
        final newPlayersData = <String, String>{};
        
        widget.game.players.forEach((key, value) {
          newPlayersData[key] = value;
        });
        
        for (int i = 0; i < newPlayerNames.length; i++) {
          final newPlayerId = 'player_${currentPlayerCount + i}';
          newPlayersData[newPlayerId] = newPlayerNames[i];
          _selectedPlayerIds.add(newPlayerId);
        }
        
        await context.read<GameProvider>().updateGamePlayers(widget.game.id, newPlayersData);
      }

      final nextRoundNumber = widget.game.rounds.length + 1;
      await context.read<GameProvider>().createRound(
        widget.game.id,
        nextRoundNumber,
        _selectedPlayerIds.toList(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Round created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create round: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nextRoundNumber = widget.game.rounds.length + 1;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage('https://images.unsplash.com/photo-1518611012118-696072aa579a?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2070&q=80'),
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
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'Create Round $nextRoundNumber',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.casino,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Round $nextRoundNumber',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _showPlayerForm 
                                    ? 'Add players for the first round'
                                    : 'Select players for this round',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().slideY(begin: -0.3, duration: 400.ms).fadeIn(),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _showPlayerForm ? _buildPlayerForm() : _buildPlayerSelection(),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _createRound,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Create Round',
                                style: TextStyle(fontSize: 16),
                              ),
                      ).animate(delay: 400.ms).slideY(begin: 0.3, duration: 400.ms).fadeIn(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Players',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _addPlayerController();
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Player'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _playerControllers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _playerControllers[index],
                            decoration: InputDecoration(
                              labelText: 'Player ${index + 1}',
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            textCapitalization: TextCapitalization.words,
                          ),
                        ),
                        if (_playerControllers.length > 2) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _removePlayerController(index),
                            icon: const Icon(Icons.remove_circle),
                            color: Colors.red,
                          ),
                        ],
                      ],
                    ),
                  ).animate(delay: Duration(milliseconds: index * 100))
                      .slideX(begin: 0.3, duration: 300.ms)
                      .fadeIn();
                },
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: 200.ms).slideY(begin: 0.3, duration: 400.ms).fadeIn();
  }

  Widget _buildPlayerSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Players',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _addPlayerController();
                    });
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add New Player'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.game.players.isNotEmpty) ...[
                      Text(
                        'Existing Players',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...widget.game.players.entries.map((entry) {
                        final playerId = entry.key;
                        final playerName = entry.value;
                        final index = widget.game.players.keys.toList().indexOf(playerId);
                        
                        return CheckboxListTile(
                          title: Text(playerName),
                          value: _selectedPlayerIds.contains(playerId),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedPlayerIds.add(playerId);
                              } else {
                                _selectedPlayerIds.remove(playerId);
                              }
                            });
                          },
                          activeColor: Theme.of(context).primaryColor,
                        ).animate(delay: Duration(milliseconds: index * 100))
                            .slideX(begin: 0.3, duration: 300.ms)
                            .fadeIn();
                      }).toList(),
                    ],
                    if (_playerControllers.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'New Players',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(_playerControllers.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _playerControllers[index],
                                  decoration: InputDecoration(
                                    labelText: 'New Player ${index + 1}',
                                    prefixIcon: const Icon(Icons.person_add),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  textCapitalization: TextCapitalization.words,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => _removePlayerController(index),
                                icon: const Icon(Icons.remove_circle),
                                color: Colors.red,
                              ),
                            ],
                          ),
                        ).animate(delay: Duration(milliseconds: index * 100))
                            .slideX(begin: 0.3, duration: 300.ms)
                            .fadeIn();
                      }),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: 200.ms).slideY(begin: 0.3, duration: 400.ms).fadeIn();
  }
}