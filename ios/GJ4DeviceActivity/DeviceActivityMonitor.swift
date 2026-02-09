// MARK: - iOS DeviceActivity + Shield + Snitch (template)
//
// Add a **Device Activity Extension** target in Xcode (File → New → Target).
// Link FamilyControls and DeviceActivity. Request Screen Time authorization in the main app.
//
// This file is a TEMPLATE. Adapt to your extension’s actual base class and API.

import DeviceActivity
import FamilyControls

// Define the schedule (e.g. monitor 24/7)
// let schedule = DeviceActivitySchedule(
//     intervalStart: DateComponents(hour: 0, minute: 0),
//     intervalEnd: DateComponents(hour: 23, minute: 59),
//     repeats: true
// )

// Define the event (30 minutes threshold)
// let event = DeviceActivityEvent(
//     applications: selection.applicationTokens, // List of blocked app tokens
//     threshold: DateComponents(minute: 30)
// )

// When the threshold is hit, this function runs automatically:
// 1. Activate the Shield (standard iOS block screen)
//    store.shield.applications = selection.applicationTokens
//
// 2. Trigger the "Snitch" notification by calling your Cloud Function:
//    notifyFriend(userId: "alex_01")

func notifyFriend(userId: String) {
    guard let url = URL(string: "https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/snitchOnUser") else { return }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try? JSONSerialization.data(withJSONObject: ["userId": userId])
    URLSession.shared.dataTask(with: request).resume()
}
