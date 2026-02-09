# GJ4 — Social Accountability App

App that enforces usage limits (e.g. 30 min in 3 hours) and notifies your accountability partner when you exceed them.

## Stack

- **Flutter** (Dart) — UI and cross-platform
- **Firebase** — Auth, Firestore, Cloud Messaging (FCM)

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable)
- A [Firebase project](https://console.firebase.google.com/)

## Setup

### 1. Create Flutter platform folders (if missing)

If you only have `lib/` and `pubspec.yaml`, generate Android/iOS/Web:

```bash
flutter create . --project-name gj4_accountability --org com.gj4
```

(Use a different `--org` if you prefer.)

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure Firebase

1. In [Firebase Console](https://console.firebase.google.com/), add an Android app and an iOS app (use the package name from `android/app/build.gradle` and the bundle ID from Xcode).
2. Download and add:
   - **Android:** `google-services.json` → `android/app/google-services.json`
   - **iOS:** `GoogleService-Info.plist` → `ios/Runner/GoogleService-Info.plist`
3. (Recommended) Install [FlutterFire CLI](https://firebase.flutter.dev/docs/overview) and run:

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

   This generates `lib/firebase_options.dart` and wires your app to the Firebase project.

4. If you **don’t** use FlutterFire, ensure `Firebase.initializeApp()` in `lib/main.dart` can find your config (e.g. by using the default app with the platform config files above).

### 4. Firestore security rules

In Firebase Console → Firestore → Rules, use rules that allow authenticated users to read/write their own data and pairing codes, for example:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /users/{userId}/limitRules/{ruleId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /pairingCodes/{code} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 5. Enable Auth and Firestore

- In Firebase Console, enable **Email/Password** (and optionally other sign-in methods).
- Create a **Firestore** database in production or test mode (then tighten rules as above).

## Run

```bash
flutter run
```

Pick a device or simulator when prompted.

## Project layout

- `lib/main.dart` — App entry, Firebase init, auth stream, routing.
- `lib/models/` — `UserProfile`, `LimitRule`, `PairingCode`.
- `lib/services/` — `AuthService`, `FirestoreService`, `PairingService`.
- `lib/screens/` — Splash, Login, Signup, Home, Add Partner, Enter Code, Limits.
- `USER_FLOW_ACCOUNTABILITY_PARTNERS.md` — User flow and sequence for User ↔ Partner.

## Next steps (not yet implemented)

- **FCM** — Push notifications to the partner when the user exceeds a limit (and for unlock requests).
- **Android** — Usage stats + overlay/block (Accessibility / UsageStatsManager) via platform channels.
- **iOS** — Screen Time / DeviceActivity shields via platform channels.
- **Keyholder** — Unlock request → partner sends code → user enters code to unlock.
- **Streaks** — Update `streakDays` and `lastTriggerAt` when a limit is triggered.

These will require platform-specific code and (for store submission) careful compliance with Apple/Google policies.
