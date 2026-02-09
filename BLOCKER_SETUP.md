# Blocker setup (Android + iOS + Cloud Function)

## 1. Data model (aligned with your JSON)

- **User:** `user_id` (Firebase Auth UID), `name` / `displayName`, `partner_id` / `partnerId`, `fcm_token` / `fcmToken`.
- **Restricted apps:** List of package names (e.g. `com.instagram.android`, `com.tinder`, `com.zhiliaoapp.musically`).
- **Window:** `current_window_start`, `minutes_used_in_window` — used by the blocker to enforce "e.g. 30 min in 3 hours".

The app stores:
- Limit rules in `users/{uid}/limitRules` (per-app minutes/window/shame message).
- Blocker config in `users/{uid}/blockerConfig/current` (restrictedApps, minutesAllowed, windowMinutes) — written by Flutter when user saves limits.
- Usage state in `users/{uid}/usageState/current` (currentWindowStart, minutesUsedInWindow) — can be written by the native blocker.

---

## 2. Firebase Cloud Function: `snitchOnUser`

- **Path:** `functions/index.js`
- **Deploy:** From project root, run `firebase deploy --only functions` (after `cd functions && npm install`).
- **URL:** After deploy, use the HTTP URL shown (e.g. `https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/snitchOnUser`).

**POST body:**
```json
{
  "userId": "alex_01",
  "appName": "Instagram",
  "shameMessage": "has been on Instagram for 30 mins! Call them and tell them to stop!"
}
```

The function reads `users/{userId}` for `partnerId` and `displayName`, then `users/{partnerId}` for `fcmToken`, sends FCM, and updates `lastTriggerAt` on the user.

---

## 3. Android: BlockerService

- **BlockerService.kt** — AccessibilityService that listens for `TYPE_WINDOW_STATE_CHANGED`, checks if the foreground app is in the restricted list, tracks time in the current window, and when over the limit:
  - Draws the block overlay (`activity_block_screen.xml`).
  - Calls the `snitchOnUser` Cloud Function URL via HTTP POST.
- **Config:** The service reads from **SharedPreferences** `"gj4"`:
  - `user_id` — Firebase Auth UID (set by the Flutter app when user is logged in).
  - `restricted_apps` — JSON array string, e.g. `["com.instagram.android","com.tinder"]`.
  - `minutes_allowed` — e.g. 30.
  - `window_minutes` — e.g. 180.
  - `snitch_url` — Full URL to your deployed `snitchOnUser` function.

**What you need to do:**

1. **Create the Android project** if you don’t have it: run `flutter create . --project-name gj4_accountability --org com.gj4` so that `android/` exists.
2. **Add the service and overlay** (already added under `android/app/src/main/`):
   - `kotlin/.../BlockerService.kt`
   - `res/layout/activity_block_screen.xml`
   - `res/xml/accessibility_service_config.xml`
3. **AndroidManifest.xml** — add inside `<application>`:
   ```xml
   <service
       android:name=".BlockerService"
       android:exported="false"
       android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE">
       <intent-filter>
           <action android:name="android.accessibilityservice.AccessibilityService" />
       </intent-filter>
       <meta-data
           android:name="android.accessibilityservice"
           android:resource="@xml/accessibility_service_config" />
   </service>
   ```
   And in `<manifest>` (outside `<application>`), add:
   ```xml
   <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
   ```
4. **Request overlay permission** in the Flutter app (e.g. `PermissionHandler` or `android.permission.SYSTEM_ALERT_WINDOW`).
5. **When the user logs in or saves limits**, write SharedPreferences from Flutter via a **MethodChannel**:
   - `user_id` = Firebase Auth currentUser.uid
   - `restricted_apps` = JSON array of `appPackageOrCategory` from limit rules
   - `minutes_allowed` / `window_minutes` from the rule
   - `snitch_url` = your deployed Cloud Function URL
6. **Guide the user** to enable the “GJ4 Blocker” Accessibility Service in system settings.

---

## 4. iOS: DeviceActivity shield + “snitch”

iOS uses the **Screen Time / DeviceActivity** API. You can’t read the exact app from your process; you use **application tokens** and **DeviceActivityEvent** with a threshold.

**Concept (Swift):**

```swift
// Define the schedule (e.g. monitor 24/7)
let schedule = DeviceActivitySchedule(
    intervalStart: DateComponents(hour: 0, minute: 0),
    intervalEnd: DateComponents(hour: 23, minute: 59),
    repeats: true
)

// Define the event (30 minutes threshold)
let event = DeviceActivityEvent(
    applications: selection.applicationTokens,
    threshold: DateComponents(minute: 30)
)

// When the threshold is hit:
override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
    store.shield.applications = selection.applicationTokens
    // Notify partner via your backend
    NetworkManager.shared.notifyFriend(userId: "alex_01")
}
```

**What you need:**

- Add a **Device Activity Extension** target in Xcode (File → New → Target → Device Activity Extension).
- Use **FamilyControls** and **DeviceActivity** frameworks; request **Screen Time** authorization.
- In the extension, when `eventDidReachThreshold` is called, send a request to the same **snitchOnUser** Cloud Function (e.g. with `userId` from the app’s shared container or keychain).
- The **Shield** is the standard iOS block screen; you don’t draw a custom overlay like on Android.

Apple’s docs: [DeviceActivity](https://developer.apple.com/documentation/deviceactivity), [FamilyControls](https://developer.apple.com/documentation/familycontrols).

---

## 5. Summary

| Piece            | Role |
|------------------|------|
| **UsageState / BlockerConfig** | Models for window + minutes and restricted apps; Flutter syncs to Firestore and (Android) SharedPreferences. |
| **snitchOnUser** | Cloud Function: given `userId`, finds partner, sends FCM, updates `lastTriggerAt`. |
| **Android BlockerService** | AccessibilityService: restricted list + time in window → block overlay + POST to snitch URL. |
| **iOS**           | DeviceActivity extension: threshold → Shield + call snitch URL. |

Replace `YOUR_PROJECT_ID` (and the placeholder snitch URL in any sample code) with your Firebase project ID and the real function URL after deploy.
