import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/game.dart';
import '../models/user.dart';

class GameProvider extends ChangeNotifier {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  List<Game> _games = [];
  bool _isLoading = false;
  String? _error;

  List<Game> get games => _games;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Stream<List<Game>> getUserGames(String uid) {
    return _database.child('users').child(uid).onValue.asyncMap((userEvent) async {
      // If user document doesn't exist, create it and return empty list
      if (!userEvent.snapshot.exists) {
        await _database.child('users').child(uid).set({
          'createdGames': {},
          'sharedGames': {},
        });
        return <Game>[];
      }
      
      final userData = userEvent.snapshot.value as Map<dynamic, dynamic>;
      final user = AppUser.fromJson(uid, userData);
      
      final allGameIds = <String>{};
      allGameIds.addAll(user.createdGames.keys);
      allGameIds.addAll(user.sharedGames.keys);
      
      if (allGameIds.isEmpty) return <Game>[];
      
      final games = <Game>[];
      for (final gameId in allGameIds) {
        final gameSnapshot = await _database.child('games').child(gameId).get();
        if (gameSnapshot.exists) {
          final game = Game.fromJson(gameId, gameSnapshot.value as Map<dynamic, dynamic>);
          games.add(game);
        }
      }
      
      games.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
      return games;
    });
  }

  Stream<Game?> getGameStream(String gameId) {
    return _database.child('games').child(gameId).onValue.map((event) {
      final gameData = event.snapshot.value as Map<dynamic, dynamic>?;
      if (gameData == null) return null;
      return Game.fromJson(gameId, gameData);
    });
  }

  Future<void> createGame(String name, String ownerId) async {
    try {
      _setLoading(true);
      final now = DateTime.now();
      final gameRef = _database.child('games').push();
      final gameId = gameRef.key!;
      
      await gameRef.set({
        'name': name,
        'ownerId': ownerId,
        'sharedWith': {},
        'createdAt': now.millisecondsSinceEpoch,
        'modifiedAt': now.millisecondsSinceEpoch,
      });
      
      // Ensure user document exists and add to user's created games
      final userRef = _database.child('users').child(ownerId);
      final userSnapshot = await userRef.get();
      
      if (!userSnapshot.exists) {
        // Create minimal user document if it doesn't exist
        await userRef.set({
          'createdGames': {gameId: true},
          'sharedGames': {},
        });
      } else {
        await userRef.child('createdGames').child(gameId).set(true);
      }
      
      _clearError();
    } catch (e) {
      _setError('Failed to create game: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> shareGame(String gameId, List<String> userIds) async {
    try {
      final updates = <String, dynamic>{};
      
      // Ensure all user documents exist before sharing
      for (final userId in userIds) {
        final userSnapshot = await _database.child('users').child(userId).get();
        if (!userSnapshot.exists) {
          await _database.child('users').child(userId).set({
            'createdGames': {},
            'sharedGames': {gameId: true},
          });
        } else {
          updates['users/$userId/sharedGames/$gameId'] = true;
        }
        updates['games/$gameId/sharedWith/$userId'] = true;
      }
      
      await _database.update(updates);
    } catch (e) {
      _setError('Failed to share game: $e');
    }
  }

  Future<List<AppUser>> getAllUsers() async {
    try {
      final snapshot = await _database.child('users').get();
      if (!snapshot.exists) return [];
      
      final usersData = snapshot.value as Map<dynamic, dynamic>;
      return usersData.entries
          .map((entry) => AppUser.fromJson(entry.key.toString(), entry.value))
          .toList();
    } catch (e) {
      _setError('Failed to load users: $e');
      return [];
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

  Future<void> deleteGame(String gameId, String ownerId) async {
    try {
      final updates = <String, dynamic>{};
      
      // Remove game from games collection
      updates['games/$gameId'] = null;
      
      // Remove game from owner's createdGames
      updates['users/$ownerId/createdGames/$gameId'] = null;
      
      // Get game data to find shared users
      final gameSnapshot = await _database.child('games').child(gameId).get();
      if (gameSnapshot.exists) {
        final gameData = gameSnapshot.value as Map<dynamic, dynamic>;
        final sharedWith = Map<String, bool>.from(gameData['sharedWith'] ?? {});
        
        // Remove game from all shared users
        for (final userId in sharedWith.keys) {
          updates['users/$userId/sharedGames/$gameId'] = null;
        }
      }
      
      await _database.update(updates);
    } catch (e) {
      _setError('Failed to delete game: $e');
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