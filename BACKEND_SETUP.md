# Firebase backend setup (GJ4)

Step-by-step to get Firestore, Auth, and Cloud Functions running for the GJ4 app.

---

## 1. Prerequisites

- **Node.js** 18+ (you have v22)
- **Firebase CLI**: `npm install -g firebase-tools`
- **Google account** for Firebase Console

---

## 2. Create a Firebase project

1. Go to [Firebase Console](https://console.firebase.google.com/).
2. Click **Add project** (or use an existing one).
3. Name it (e.g. **gj4-accountability**), enable/disable Google Analytics as you like, then create the project.
4. Note the **Project ID** (e.g. `gj4-accountability-xxxxx`). You’ll use it in the next step.

---

## 3. Link this repo to your Firebase project

From the **project root** (where `firebase.json` and `functions/` are):

```bash
cd "c:\Users\akash\OneDrive\Documents\Jeremy\Gj4"
firebase login
firebase use --add
```

When prompted, choose the project you created (or create one). This updates `.firebaserc` with that project’s ID.

**Or** edit `.firebaserc` by hand and set `"default"` to your project ID:

```json
{
  "projects": {
    "default": "YOUR_PROJECT_ID"
  }
}
```

---

## 4. Enable Firebase services

In [Firebase Console](https://console.firebase.google.com/) → your project:

1. **Authentication**
   - Go to **Build → Authentication**.
   - Click **Get started**.
   - In **Sign-in method**, enable **Email/Password** (and optionally other providers).

2. **Firestore**
   - Go to **Build → Firestore Database**.
   - Click **Create database**.
   - Choose **Start in test mode** for local/dev (you’ll deploy rules in step 6), or **Production** and then deploy rules.

3. **Cloud Messaging (FCM)**  
   - No extra enable step; it works once the project exists. The app will use it for “snitch” notifications.

---

## 5. Install and deploy Cloud Functions

From the project root:

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

After deploy, the CLI prints the function URL, e.g.:

```
https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/snitchOnUser
```

Save this URL. The Android blocker (and any other client) must call this URL when the user exceeds their limit (see BLOCKER_SETUP.md).

---

## 6. Deploy Firestore rules and indexes

From the project root:

```bash
firebase deploy --only firestore
```

This deploys:

- **firestore.rules** – who can read/write `users`, `pairingCodes`, `unlockRequests`, and subcollections.
- **firestore.indexes.json** – composite indexes for `unlockRequests` queries.

If the CLI says an index is missing, open the link it gives you to create it in the console, then run `firebase deploy --only firestore` again.

---

## 7. (Optional) Run the emulators

To test Auth, Firestore, and Functions locally:

```bash
firebase emulators:start --only auth,firestore,functions
```

- Auth: http://localhost:9099  
- Firestore: http://localhost:8080  
- Functions: http://localhost:5001  
- Emulator UI: http://localhost:4000  

Point your Flutter app at the emulators only when you explicitly want local testing (see FlutterFire / Firebase docs for how to connect the app to the emulators).

---

## 8. Summary: what’s in the backend

| Item | Role |
|------|------|
| **firebase.json** | Tells the CLI where Firestore rules/indexes and Functions live; configures emulators. |
| **.firebaserc** | Maps the `default` alias to your Firebase project ID. |
| **firestore.rules** | Security rules for `users`, `limitRules`, `blockerConfig`, `usageState`, `pairingCodes`, `unlockRequests`. |
| **firestore.indexes.json** | Composite indexes for unlock-request queries. |
| **functions/** | Node.js Cloud Functions; `snitchOnUser` looks up the partner and sends FCM. |

---

## 9. Connect the Flutter app to this project

1. **Android**  
   - In Firebase Console → Project settings → **Add app** → Android.  
   - Register with the Android package name (e.g. `com.gj4.gj4_accountability`).  
   - Download **google-services.json** and put it in `android/app/`.

2. **iOS**  
   - In Firebase Console → Project settings → **Add app** → iOS.  
   - Register with the iOS bundle ID.  
   - Download **GoogleService-Info.plist** and add it to the iOS app in Xcode.

3. **Flutter**  
   - Either run **FlutterFire**: `dart pub global activate flutterfire_cli` then `flutterfire configure` in the Flutter app directory (generates `lib/firebase_options.dart`),  
   - Or keep using the default Firebase app and ensure the platform files above are in place so `Firebase.initializeApp()` in `main.dart` can find the config.

After that, the app will use the same Firebase project (Auth + Firestore + the deployed `snitchOnUser` URL) as the backend.
