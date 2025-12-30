import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/game.dart';
import '../providers/game_provider.dart';

class EditRoundPage extends StatefulWidget {
  final Game game;
  final Round round;

  const EditRoundPage({super.key, required this.game, required this.round});

  @override
  State<EditRoundPage> createState() => _EditRoundPageState();
}

class _EditRoundPageState extends State<EditRoundPage> {
  final Map<String, TextEditingController> _controllers = {};
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    for (final entry in widget.round.playerScores.entries) {
      final controller = TextEditingController(text: entry.value.toString());
      controller.addListener(() {
        if (!_hasChanges) {
          setState(() {
            _hasChanges = true;
          });
        }
      });
      _controllers[entry.key] = controller;
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveScores() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final scores = <String, int>{};
      for (final entry in _controllers.entries) {
        scores[entry.key] = int.tryParse(entry.value.text) ?? 0;
      }

      await context.read<GameProvider>().updateRoundScores(
        widget.game.id,
        widget.round.id,
        scores,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scores updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update scores: $e'),
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

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Round ${widget.round.number}'),
          centerTitle: true,
          actions: [
            if (_hasChanges)
              IconButton(
                onPressed: _isLoading ? null : _saveScores,
                icon: const Icon(Icons.save),
              ).animate().scale(duration: 200.ms),
          ],
        ),
        body: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.casino,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Round ${widget.round.number} Scores',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().slideY(begin: -0.3, duration: 400.ms).fadeIn(),
                const SizedBox(height: 16),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Player Scores',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _controllers.length,
                              itemBuilder: (context, index) {
                                final entry = _controllers.entries.elementAt(index);
                                final playerId = entry.key;
                                final controller = entry.value;
                                final playerName = widget.game.players[playerId] ?? 'Unknown';

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Theme.of(context).primaryColor,
                                        child: Text(
                                          playerName[0].toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              playerName,
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            TextFormField(
                                              controller: controller,
                                              decoration: InputDecoration(
                                                labelText: 'Points',
                                                suffixText: 'pts',
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                contentPadding: const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 12,
                                                ),
                                              ),
                                              keyboardType: TextInputType.number,
                                              inputFormatters: [
                                                FilteringTextInputFormatter.digitsOnly,
                                              ],
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Please enter points';
                                                }
                                                final points = int.tryParse(value);
                                                if (points == null || points < 0) {
                                                  return 'Please enter a valid number';
                                                }
                                                return null;
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
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
                  ).animate(delay: 200.ms).slideY(begin: 0.3, duration: 400.ms).fadeIn(),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: (_isLoading || !_hasChanges) ? null : _saveScores,
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
                          'Save Scores',
                          style: TextStyle(fontSize: 16),
                        ),
                ).animate(delay: 400.ms).slideY(begin: 0.3, duration: 400.ms).fadeIn(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}