class Game {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final Map<String, String> players;
  final Map<String, Round> rounds;

  Game({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.modifiedAt,
    this.players = const {},
    this.rounds = const {},
  });

  factory Game.fromJson(String id, Map<dynamic, dynamic> json) {
    final playersMap = <String, String>{};
    if (json['players'] != null) {
      final players = json['players'] as Map<dynamic, dynamic>;
      players.forEach((key, value) {
        playersMap[key.toString()] = value.toString();
      });
    }

    final roundsMap = <String, Round>{};
    if (json['rounds'] != null) {
      final rounds = json['rounds'] as Map<dynamic, dynamic>;
      rounds.forEach((key, value) {
        roundsMap[key.toString()] = Round.fromJson(key.toString(), value);
      });
    }

    return Game(
      id: id,
      name: json['name'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      modifiedAt: DateTime.fromMillisecondsSinceEpoch(json['modifiedAt'] ?? 0),
      players: playersMap,
      rounds: roundsMap,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'modifiedAt': modifiedAt.millisecondsSinceEpoch,
      'players': players,
      'rounds': rounds.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  Map<String, int> getPlayerTotals() {
    final totals = <String, int>{};
    for (final playerId in players.keys) {
      totals[playerId] = 0;
    }
    
    for (final round in rounds.values) {
      round.playerScores.forEach((playerId, score) {
        totals[playerId] = (totals[playerId] ?? 0) + score;
      });
    }
    
    return totals;
  }
}

class Round {
  final String id;
  final int number;
  final Map<String, int> playerScores;

  Round({
    required this.id,
    required this.number,
    this.playerScores = const {},
  });

  factory Round.fromJson(String id, Map<dynamic, dynamic> json) {
    final scoresMap = <String, int>{};
    if (json['players'] != null) {
      final players = json['players'] as Map<dynamic, dynamic>;
      players.forEach((key, value) {
        final points = value is Map ? (value['points'] ?? 0) : 0;
        scoresMap[key.toString()] = points is int ? points : int.tryParse(points.toString()) ?? 0;
      });
    }

    return Round(
      id: id,
      number: json['number'] ?? 1,
      playerScores: scoresMap,
    );
  }

  Map<String, dynamic> toJson() {
    final playersData = <String, dynamic>{};
    playerScores.forEach((playerId, points) {
      playersData[playerId] = {'points': points};
    });

    return {
      'number': number,
      'players': playersData,
    };
  }
}