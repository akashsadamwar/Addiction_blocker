# GJ4 — Data model (basic)

This document describes the **data model**: Firestore collections, document structure, and the Dart classes that map to them.

---

## 1. Entity relationship (overview)

```
┌──────────────────┐         ┌──────────────────┐
│     User         │◄───────►│     User         │
│  (UserProfile)   │ partner │  (UserProfile)   │
└────────┬─────────┘  1 : 1 └────────┬─────────┘
         │                             │
         │ has many                    │ receives
         ▼                             ▼
┌──────────────────┐         ┌──────────────────┐
│   LimitRule      │         │  UnlockRequest   │
│ (subcollection)  │         │ (when blocked)   │
└──────────────────┘         └──────────────────┘

┌──────────────────┐
│   PairingCode    │   one-time, doc id = code
│ (top-level)      │   links two users when partner enters code
└──────────────────┘
```

- **User** ↔ **User**: linked by `partnerId` (one accountability partner per user).
- **User** has many **LimitRule** (subcollection).
- **PairingCode**: short-lived doc; id = 6-digit code; links creator and partner when consumed.
- **UnlockRequest**: when Keyholder mode is on, user requests unlock → partner generates code; request stored until used or expired.

---

## 2. Firestore collections and fields

### 2.1 `users` (collection)

| Document ID | Description |
|-------------|-------------|
| `{uid}`    | Firebase Auth UID |

| Field            | Type   | Description |
|------------------|--------|-------------|
| `email`          | string | User email. |
| `displayName`    | string | Shown to partner. |
| `fcmToken`       | string? | For push (shame + unlock). |
| `partnerId`      | string? | UID of linked accountability partner. |
| `streakDays`     | number | Consecutive days without triggering. |
| `lastTriggerAt`  | number? | Timestamp (ms) when limit was last exceeded. |
| `createdAt`      | number / Timestamp | When profile was created. |

**Dart class:** `UserProfile` (`lib/models/user_profile.dart`).

---

### 2.2 `users/{uid}/limitRules` (subcollection)

| Document ID | Description |
|-------------|-------------|
| auto-generated | One doc per rule. |

| Field                   | Type    | Description |
|-------------------------|---------|-------------|
| `appPackageOrCategory`   | string  | e.g. `com.instagram.android` or "Social". |
| `appDisplayName`        | string  | e.g. "Instagram". |
| `minutesAllowed`        | number  | e.g. 30. |
| `windowMinutes`         | number  | e.g. 180 (3 hours). |
| `shameMessage`          | string  | Message sent to partner when limit exceeded. |
| `keyholderRequired`     | boolean | If true, partner must send code to unlock. |
| `active`                | boolean | Soft delete when false. |

**Dart class:** `LimitRule` (`lib/models/limit_rule.dart`).

---

### 2.3 `pairingCodes` (collection)

| Document ID | Description |
|-------------|-------------|
| `{code}`   | 6-digit string (e.g. `"123456"`). |

| Field        | Type   | Description |
|--------------|--------|-------------|
| `code`       | string | Same as document ID. |
| `creatorUid` | string | User who generated the code. |
| `expiresAt`  | number | Timestamp (ms); typically 10 min from creation. |

- **Lifecycle:** Created when user taps “Generate code”; **deleted** when partner enters the code and the two users are linked.

**Dart class:** `PairingCode` (`lib/models/pairing_code.dart`).

---

### 2.4 `unlockRequests` (collection) — Keyholder flow

| Document ID | Description |
|-------------|-------------|
| auto-generated | One doc per unlock request. |

| Field         | Type   | Description |
|---------------|--------|-------------|
| `requestedByUid` | string | User who is blocked and requested unlock. |
| `partnerUid`    | string | Accountability partner who can generate code. |
| `code`          | string? | One-time code (set when partner generates). |
| `expiresAt`     | number | When the code expires (e.g. 5 min). |
| `status`        | string | `pending` \| `code_generated` \| `used` \| `expired`. |
| `createdAt`     | number | When request was created. |

**Dart class:** `UnlockRequest` (`lib/models/unlock_request.dart`).

---

### 2.5 `users/{uid}/blockerConfig/current` (for native blocker)

Written by the Flutter app from limit rules so the Android/iOS blocker can read config without Firestore in the service.

| Field              | Type     | Description |
|--------------------|----------|-------------|
| `userId`           | string   | Same as uid. |
| `restrictedApps`   | string[] | Package names, e.g. `["com.instagram.android"]`. |
| `minutesAllowed`   | number   | e.g. 30. |
| `windowMinutes`    | number   | e.g. 180. |
| `displayName`      | string   | For snitch message. |

**Dart class:** `BlockerConfig` (`lib/models/usage_state.dart`).

---

### 2.6 `users/{uid}/usageState/current` (runtime usage)

Current window start and minutes used in that window (for the blocker to persist or for analytics).

| Field                 | Type   | Description |
|-----------------------|--------|-------------|
| `userId`              | string | Same as uid. |
| `currentWindowStart`  | number | Timestamp (ms). |
| `minutesUsedInWindow` | number | Minutes used in current window. |

**Dart class:** `UsageState` (`lib/models/usage_state.dart`).

---

## 3. “Limit triggered” (no separate collection)

When the user exceeds a limit:

- **User profile:** `lastTriggerAt` is updated; `streakDays` can be reset (or updated by a Cloud Function / client logic).
- **Partner:** Notified via FCM using their `fcmToken`; payload includes shame message and optional deep link.
- No separate “events” collection in the basic model; optional later for history.

---

## 4. Dart model files

| File                 | Class(es)   | Firestore mapping |
|----------------------|------------|-------------------|
| `user_profile.dart`  | `UserProfile` | `users/{uid}` |
| `limit_rule.dart`    | `LimitRule`   | `users/{uid}/limitRules/{id}` |
| `pairing_code.dart`  | `PairingCode` | `pairingCodes/{code}` |
| `unlock_request.dart`| `UnlockRequest` | `unlockRequests/{id}` |

All models provide:

- `toMap()` for Firestore writes.
- `fromMap(...)` or `fromMap(String id, Map)` for reads.
- `copyWith(...)` where useful for updates.

---

## 5. Indexes (if needed)

- **Limit rules:** Usually not needed for small per-user rule sets.
- **Unlock requests:** Query by `partnerUid` + `status == 'pending'` to show “User X requested unlock” in the partner app. Add a composite index in Firestore if you hit “index required” in the console.
