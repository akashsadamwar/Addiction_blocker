const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

function setCors(res) {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");
}

function parseBody(req) {
  if (typeof req.body === "object" && req.body !== null) return req.body;
  if (typeof req.rawBody === "string") {
    try {
      return JSON.parse(req.rawBody);
    } catch (_) {
      return {};
    }
  }
  return {};
}

/**
 * Snitch on user: when the blocker detects limit exceeded, it calls this.
 * Looks up the accountability partner and sends them a push notification.
 *
 * POST body (JSON):
 *   - userId (required): Firebase Auth UID of the user who exceeded the limit
 *   - appName (optional): e.g. "Instagram" for the message
 *   - shameMessage (optional): custom line, e.g. "is doom-scrolling on Tinder again"
 */
exports.snitchOnUser = functions.https.onRequest(async (req, res) => {
  setCors(res);
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }
  if (req.method !== "POST") {
    res.status(405).json({ error: "Method Not Allowed" });
    return;
  }

  const body = parseBody(req);
  const { userId, appName, shameMessage } = body;

  if (!userId) {
    res.status(400).json({ error: "Missing userId" });
    return;
  }

  try {
    const userRef = db.collection("users").doc(userId);
    const userDoc = await userRef.get();
    if (!userDoc.exists) {
      res.status(404).json({ error: "User not found" });
      return;
    }

    const userData = userDoc.data();
    const partnerId = userData.partnerId || userData.partner_id;
    if (!partnerId) {
      res.status(400).json({ error: "User has no accountability partner" });
      return;
    }

    const partnerRef = db.collection("users").doc(partnerId);
    const partnerDoc = await partnerRef.get();
    if (!partnerDoc.exists) {
      res.status(404).json({ error: "Partner not found" });
      return;
    }

    const partnerData = partnerDoc.data();
    const partnerToken = partnerData.fcmToken || partnerData.fcm_token;
    if (!partnerToken) {
      res.status(400).json({ error: "Partner has no FCM token" });
      return;
    }

    const displayName = userData.displayName || userData.name || "Your friend";
    const app = appName || "their restricted app";
    const message =
      shameMessage ||
      userData.shameMessage ||
      "has exceeded their time limit.";

    const notificationBody = `${displayName} ${message} (${app})`;

    await messaging.send({
      notification: {
        title: "🚨 ALERT",
        body: notificationBody,
      },
      token: partnerToken,
      data: {
        type: "snitch",
        userId,
        displayName,
      },
    });

    await userRef.update({
      lastTriggerAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.status(200).json({ success: true, message: "Snitched successfully." });
  } catch (e) {
    functions.logger.error("snitchOnUser error", e);
    res.status(500).json({ error: String(e.message) });
  }
});
