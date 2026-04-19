# CapyPocket (Flutter + Firebase)

CapyPocket is a personal finance mobile app built with Flutter and Firebase.
It uses Firebase Authentication, Cloud Firestore, and Firebase Storage.

This guide covers full setup: prerequisites, installation, Firebase access, rules deployment, running, testing, and troubleshooting.

## 1) Features

- Authentication with Firebase Auth (register and sign in)
- User data and finance data in Cloud Firestore
- Receipt image uploads in Firebase Storage
- Multi-platform support through FlutterFire config

## 2) Key Project Files

- `lib/main.dart`: App entry point and Firebase initialization
- `lib/firebase_options.dart`: Generated FlutterFire configuration
- `lib/services/firebase_service.dart`: Auth, Firestore, and Storage operations
- `firestore.rules`: Firestore access and validation rules
- `storage.rules`: Storage access rules
- `firebase.json`: Firebase deploy mapping and FlutterFire metadata

## 3) Prerequisites

Install these tools:

1. Flutter SDK (latest stable recommended)
2. Dart SDK (bundled with Flutter)
3. Android Studio or VS Code with Flutter extension
4. Firebase CLI
5. FlutterFire CLI

Verify installation:

```bash
flutter --version
dart --version
firebase --version
flutterfire --version
```

## 4) First-Time Setup

From the `capyproject` directory:

```bash
flutter clean
flutter pub get
```

Check local environment and devices:

```bash
flutter doctor
flutter devices
```

## 5) Firebase Access and Configuration

The project is already connected to Firebase project `capypocket` through:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `firebase.json`

### 5.1 Use Existing Team Firebase Project

1. Request Firebase project access from the owner (Editor role recommended).
2. Ensure these services are enabled in Firebase Console:
- Authentication (Email/Password)
- Cloud Firestore
- Firebase Storage
3. Confirm local config files match the same Firebase project.

### 5.2 Switch to a New Firebase Project

1. Sign in to Firebase CLI:

```bash
firebase login
```

2. Reconfigure FlutterFire:

```bash
flutterfire configure
```

3. Select your project and platforms.
4. Verify generated files are updated, especially:
- `lib/firebase_options.dart`
- `android/app/google-services.json` (for Android)

## 6) Deploy Access Rules and Indexes

Deploy Firestore and Storage rules:

```bash
firebase deploy --only firestore:rules,storage:rules
```

Deploy Firestore indexes when needed:

```bash
firebase deploy --only firestore:indexes
```

## 7) Current Access Model

### 7.1 Firestore Rules (`firestore.rules`)

- User must be authenticated (`request.auth != null`).
- User can access only their own data (`request.auth.uid == userId`).
- Main user document path: `users/{userId}`.
- Main subcollections:
- `users/{userId}/transactions`
- `users/{userId}/categories`
- `users/{userId}/goals`
- Rules validate schema and important value constraints.
- `usernames/{username}` is readable for username-to-email lookup.

### 7.2 Storage Rules (`storage.rules`)

- Receipt path: `receipts/{userId}/{fileName}`.
- Read/write allowed only when authenticated user owns the path userId.

## 8) Run the App

General run:

```bash
flutter run
```

Run by target device:

```bash
flutter run -d chrome
flutter run -d windows
flutter run -d android
```

## 9) Run Tests

```bash
flutter test
```

Tests are in the `test/` directory.

## 10) Build Commands

```bash
flutter build apk
flutter build web
flutter build windows
```

## 11) Note About `.env` and MySQL

The repository contains `.env.example` with MySQL values.
Current app runtime code (`lib/main.dart` and Firebase services) uses Firebase as the active backend.

In the current implementation, MySQL setup is not required to run the app.

## 12) Troubleshooting

1. Firebase not initialized
- Check `Firebase.initializeApp(...)` in `lib/main.dart`.
- Check that `lib/firebase_options.dart` matches your Firebase project.

2. Sign-in works but writes fail
- Deploy rules again.
- Confirm document path uses the signed-in UID (`users/{uid}`).

3. Receipt upload fails
- Check `storage.rules`.
- Confirm user is signed in and upload path is `receipts/{uid}/...`.

4. Android Firebase config errors
- Ensure `android/app/google-services.json` belongs to the same Firebase project.

## 13) Quick Commands

```bash
flutter pub get
flutter run
flutter test
firebase deploy --only firestore:rules,storage:rules
```

---

For better environment isolation, use separate Firebase projects for dev/staging/prod and generate config per environment.
