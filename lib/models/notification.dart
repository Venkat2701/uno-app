class GameNotification {
  final String id;
  final String type;
  final String gameId;
  final String gameName;
  final String fromUserId;
  String fromUserName;
  final String toUserId;
  final DateTime createdAt;
  final bool isRead;

  GameNotification({
    required this.id,
    required this.type,
    required this.gameId,
    required this.gameName,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.createdAt,
    this.isRead = false,
  });

  factory GameNotification.fromJson(String id, Map<dynamic, dynamic> json) {
    return GameNotification(
      id: id,
      type: json['type'] ?? '',
      gameId: json['gameId'] ?? '',
      gameName: json['gameName'] ?? '',
      fromUserId: json['fromUserId'] ?? '',
      fromUserName: json['fromUserName'] ?? '',
      toUserId: json['toUserId'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'gameId': gameId,
      'gameName': gameName,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'toUserId': toUserId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isRead': isRead,
    };
  }
}