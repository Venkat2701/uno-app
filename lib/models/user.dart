class AppUser {
  final String uid;
  final String email;
  final String username;
  final Map<String, bool> createdGames;
  final Map<String, bool> sharedGames;

  AppUser({
    required this.uid,
    required this.email,
    required this.username,
    this.createdGames = const {},
    this.sharedGames = const {},
  });

  factory AppUser.fromJson(String uid, Map<dynamic, dynamic> json) {
    return AppUser(
      uid: uid,
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      createdGames: Map<String, bool>.from(json['createdGames'] ?? {}),
      sharedGames: Map<String, bool>.from(json['sharedGames'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'username': username,
      'createdGames': createdGames,
      'sharedGames': sharedGames,
    };
  }
}