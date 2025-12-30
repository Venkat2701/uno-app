# UNO Score Tracker

A Flutter mobile application for tracking UNO card game scores among friends using Firebase Realtime Database.

## Features

- **Game Management**: Create and manage multiple UNO games
- **Real-time Scoring**: Track scores across multiple rounds with real-time updates
- **Leaderboard**: View player rankings sorted by lowest points (UNO winner has fewest points)
- **Modern UI**: Blue-themed interface with smooth animations and transitions
- **Offline Support**: Firebase handles reconnection automatically

## Setup Instructions

### 1. Firebase Project Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use an existing one
3. Enable **Realtime Database**
4. Set database rules to allow read/write access:
   ```json
   {
     "rules": {
       ".read": true,
       ".write": true
     }
   }
   ```

### 2. Configure Firebase for Flutter

1. Install Firebase CLI: `npm install -g firebase-tools`
2. Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
3. Login to Firebase: `firebase login`
4. In your project directory, run: `flutterfire configure`
5. Select your Firebase project and platforms (Android/iOS)
6. This will generate `firebase_options.dart` with your project configuration

### 3. Alternative Manual Configuration

If you prefer manual setup, replace the placeholder values in `lib/firebase_options.dart` with your actual Firebase project configuration:

- `your-project-id`: Your Firebase project ID
- `your-api-key`: Your API key for each platform
- `your-app-id`: Your app ID for each platform
- `your-sender-id`: Your messaging sender ID
- `https://your-project-default-rtdb.firebaseio.com`: Your Realtime Database URL

### 4. Run the App

```bash
flutter pub get
flutter run
```

## App Structure

### Database Schema
```
games/
  gameId1/
    name: "Boys UNO Night 1"
    createdAt: timestamp
    modifiedAt: timestamp
    players/
      playerId1: "Player Name 1"
      playerId2: "Player Name 2"
    rounds/
      roundId1/
        number: 1
        players/
          playerId1: {points: 15}
          playerId2: {points: 8}
```

### Key Features

- **Home Page**: List all games with pull-to-refresh
- **Create Game**: Simple form to add new games
- **Game Dashboard**: Access to Table (leaderboard) and Rounds
- **Rounds Management**: Create and edit rounds with player selection
- **Real-time Updates**: All data syncs automatically across devices
- **Smooth Animations**: Page transitions, card animations, and loading states

### Dependencies

- `firebase_core`: Firebase initialization
- `firebase_database`: Realtime Database integration
- `provider`: State management
- `intl`: Date formatting
- `flutter_animate`: Smooth animations and transitions

## Usage Flow

1. **Create Game**: Tap + button on home page, enter game name
2. **Add Players**: When creating first round, add player names
3. **Create Rounds**: Add new rounds and select participating players
4. **Enter Scores**: Edit rounds to input player points
5. **View Leaderboard**: Tap "Table" to see current standings
6. **Finalize Game**: Mark game as complete when finished

## Technical Details

- **State Management**: Provider pattern for global state
- **Real-time Sync**: StreamBuilder with Firebase Realtime Database
- **Animations**: flutter_animate package for smooth transitions
- **Theme**: Material Design with custom blue color scheme
- **Error Handling**: Comprehensive error states and user feedback
- **Responsive Design**: Works on phones and tablets

The app automatically calculates player totals by summing points across all rounds, with the leaderboard showing players sorted by lowest total points (UNO scoring where lowest wins).