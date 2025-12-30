import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/game.dart';

class GameProvider extends ChangeNotifier {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  List<Game> _games = [];
  bool _isLoading = false;
  String? _error;

  List<Game> get games => _games;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Stream<List<Game>> getGamesStream() {
    return _database.child('games').onValue.map((event) {
      final gamesMap = event.snapshot.value as Map<dynamic, dynamic>?;
      if (gamesMap == null) return <Game>[];
      
      final games = gamesMap.entries
          .map((entry) => Game.fromJson(entry.key.toString(), entry.value))
          .toList();
      
      games.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
      return games;
    });
  }

  Stream<Game?> getGameStream(String gameId) {
    return _database.child('games/$gameId').onValue.map((event) {
      final gameData = event.snapshot.value as Map<dynamic, dynamic>?;
      if (gameData == null) return null;
      return Game.fromJson(gameId, gameData);
    });
  }

  Future<void> createGame(String name) async {
    try {
      _setLoading(true);
      final now = DateTime.now();
      final gameRef = _database.child('games').push();
      
      await gameRef.set({
        'name': name,
        'createdAt': now.millisecondsSinceEpoch,
        'modifiedAt': now.millisecondsSinceEpoch,
      });
      
      _clearError();
    } catch (e) {
      _setError('Failed to create game: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> finalizeGame(String gameId) async {
    try {
      await _database.child('games/$gameId/modifiedAt').set(DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      _setError('Failed to finalize game: $e');
    }
  }

  Future<void> createRound(String gameId, int roundNumber, List<String> selectedPlayerIds) async {
    try {
      final roundRef = _database.child('games/$gameId/rounds').push();
      final playersData = <String, dynamic>{};
      
      for (final playerId in selectedPlayerIds) {
        playersData[playerId] = {'points': 0};
      }
      
      await roundRef.set({
        'number': roundNumber,
        'players': playersData,
      });
      
      await _database.child('games/$gameId/modifiedAt').set(DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      _setError('Failed to create round: $e');
    }
  }

  Future<void> updateRoundScores(String gameId, String roundId, Map<String, int> scores) async {
    try {
      final playersData = <String, dynamic>{};
      scores.forEach((playerId, points) {
        playersData[playerId] = {'points': points};
      });
      
      await _database.child('games/$gameId/rounds/$roundId/players').set(playersData);
      await _database.child('games/$gameId/modifiedAt').set(DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      _setError('Failed to update scores: $e');
    }
  }

  Future<void> addPlayersToGame(String gameId, List<String> playerNames) async {
    try {
      final playersData = <String, String>{};
      for (int i = 0; i < playerNames.length; i++) {
        playersData['player_$i'] = playerNames[i];
      }
      
      await _database.child('games/$gameId/players').set(playersData);
      await _database.child('games/$gameId/modifiedAt').set(DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      _setError('Failed to add players: $e');
    }
  }

  Future<void> updateGamePlayers(String gameId, Map<String, String> playersData) async {
    try {
      await _database.child('games/$gameId/players').set(playersData);
      await _database.child('games/$gameId/modifiedAt').set(DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      _setError('Failed to update players: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}