# UNO Score Tracker - Authentication Setup

## 🚀 Quick Setup Instructions

### 1. Enable Firebase Authentication
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your existing project
3. Navigate to **Authentication** → **Sign-in method**
4. Enable **Email/Password** authentication
5. Click **Save**

### 2. Update Security Rules
1. Go to **Realtime Database** → **Rules**
2. Replace existing rules with the content from `firebase_rules.json`:

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "auth != null && auth.uid == $uid",
        ".write": "auth != null && auth.uid == $uid"
      }
    },
    "games": {
      "$gameId": {
        ".read": "auth != null && (root.child('games').child($gameId).child('ownerId').val() == auth.uid || root.child('games').child($gameId).child('sharedWith').child(auth.uid).exists())",
        ".write": "auth != null && root.child('games').child($gameId).child('ownerId').val() == auth.uid"
      }
    }
  }
}
```

3. Click **Publish**

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Run Migration (One-time only)
```bash
# Update migrate_data.dart with your actual user ID
flutter run lib/migrate_data.dart
```

### 5. Test the App
```bash
flutter run -d chrome
```

## 🧪 Test Cases

### Test User Accounts
Create these test accounts:

1. **Primary User**: `venkat2701@gmail.com` / `password123`
2. **Secondary User**: `ravi@gmail.com` / `password123`

### Test Flow
1. Register with `venkat2701@gmail.com`
2. Create game "Uno Night 1"
3. Add players and create rounds
4. Register second account `ravi@gmail.com`
5. Login as Venkat → Share game with Ravi
6. Login as Ravi → Verify shared game appears
7. Both users can view scores in real-time

## 🔧 Deployment
```bash
flutter build web --release
# Upload build/web to Netlify (drag-drop)
```

## ✅ Features Implemented
- ✅ Email/Password Authentication
- ✅ User-specific game lists
- ✅ Game sharing between users
- ✅ Real-time score updates
- ✅ Secure database rules
- ✅ Preserved blue theme & animations
- ✅ PWA compatibility maintained

## 🎮 New User Flow
1. **Splash Screen** (2s) → Auth check
2. **Login/Register** → Email/password forms
3. **Home** → "Hi [Name]! Your Games:"
4. **Create Game** → Owned by current user
5. **Share Game** → Multi-select users dialog
6. **Real-time Sync** → All shared users see updates

Your UNO Score Tracker is now fully authenticated! 🎉