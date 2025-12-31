import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';

// Run this script once to migrate existing games to new structure
void main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await migrateExistingGames();
  print('Migration completed!');
}

Future<void> migrateExistingGames() async {
  final database = FirebaseDatabase.instance.ref();
  
  try {
    // Get all existing games
    final gamesSnapshot = await database.child('games').get();
    if (!gamesSnapshot.exists) {
      print('No games to migrate');
      return;
    }
    
    final gamesData = gamesSnapshot.value as Map<dynamic, dynamic>;
    
    // Create a default user for existing games (replace with actual user ID)
    const defaultUserId = 'default_user_id';
    
    // Create default user document
    await database.child('users').child(defaultUserId).set({
      'email': 'admin@unoapp.com',
      'createdGames': {},
      'sharedGames': {},
    });
    
    final updates = <String, dynamic>{};
    final userCreatedGames = <String, bool>{};
    
    // Update each game with ownerId and sharedWith fields
    for (final entry in gamesData.entries) {
      final gameId = entry.key.toString();
      final gameData = entry.value as Map<dynamic, dynamic>;
      
      // Add ownerId and sharedWith to existing games
      updates['games/$gameId/ownerId'] = defaultUserId;
      updates['games/$gameId/sharedWith'] = {};
      
      // Add to user's created games
      userCreatedGames[gameId] = true;
    }
    
    // Update user's created games
    updates['users/$defaultUserId/createdGames'] = userCreatedGames;
    
    // Apply all updates
    await database.update(updates);
    
    print('Successfully migrated ${gamesData.length} games');
  } catch (e) {
    print('Migration failed: $e');
  }
}