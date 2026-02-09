package com.gj4.gj4_accountability

import android.accessibilityservice.AccessibilityService
import android.graphics.PixelFormat
import android.util.JsonReader
import android.util.Log
import android.view.LayoutInflater
import android.view.accessibility.AccessibilityEvent
import android.view.WindowManager
import android.widget.Toast
import java.io.StringReader
import java.net.URL
import javax.net.ssl.HttpsURLConnection

/**
 * Listens for app switches. When the foreground app is in the user's restricted list
 * and they've exceeded the allowed time in the current window, shows the block overlay
 * and calls the "snitch" Cloud Function to notify the accountability partner.
 *
 * Config is read from SharedPreferences "gj4":
 *   - user_id: Firebase Auth UID (set by Flutter app)
 *   - restricted_apps: JSON array string, e.g. ["com.instagram.android","com.tinder"]
 *   - minutes_allowed: Int (default 30)
 *   - window_minutes: Int (default 180)
 *   - snitch_url: (optional) Cloud Function URL
 *
 * Requires: Accessibility permission, overlay permission (SYSTEM_ALERT_WINDOW).
 */
class BlockerService : AccessibilityService() {

    private val prefs by lazy { getSharedPreferences("gj4", MODE_PRIVATE) }

    private var restrictedPackages: Set<String> = emptySet()
    private var minutesAllowed: Int = 30
    private var windowMinutes: Int = 180
    private var userId: String? = null
    private var snitchUrl: String? = null

    private var currentWindowStartMs: Long = 0
    private var minutesUsedInWindow: Int = 0
    private var lastForegroundPackage: String? = null
    private var lastForegroundChangeMs: Long = 0

    override fun onServiceConnected() {
        super.onServiceConnected()
        loadConfig()
    }

    private fun loadConfig() {
        userId = prefs.getString("user_id", null)?.takeIf { it.isNotBlank() }
        snitchUrl = prefs.getString("snitch_url", null)?.takeIf { it.isNotBlank() }
        minutesAllowed = prefs.getInt("minutes_allowed", 30)
        windowMinutes = prefs.getInt("window_minutes", 180)
        restrictedPackages = parseRestrictedApps(prefs.getString("restricted_apps", "[]") ?: "[]")
    }

    private fun parseRestrictedApps(json: String): Set<String> {
        return try {
            JsonReader(StringReader(json)).use { reader ->
                reader.beginArray()
                val list = mutableListOf<String>()
                while (reader.hasNext()) list.add(reader.nextString())
                reader.endArray()
                list.toSet()
            }
        } catch (e: Exception) {
            Log.e(TAG, "parse restricted_apps", e)
            emptySet()
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val pkg = event.packageName?.toString() ?: return
        if (restrictedPackages.isEmpty()) {
            loadConfig()
            if (restrictedPackages.isEmpty()) return
        }

        if (!isAppRestricted(pkg)) {
            if (pkg == lastForegroundPackage) lastForegroundPackage = null
            return
        }

        val now = System.currentTimeMillis()
        if (pkg != lastForegroundPackage) {
            if (lastForegroundPackage != null && lastForegroundChangeMs > 0) {
                val elapsedMin = ((now - lastForegroundChangeMs) / 60_000).toInt()
                minutesUsedInWindow += elapsedMin
                maybeResetWindow(now)
            }
            lastForegroundPackage = pkg
            lastForegroundChangeMs = now
            if (currentWindowStartMs == 0L) currentWindowStartMs = now
        }

        if (getTimeUsedInWindow() >= minutesAllowed) {
            blockUser()
            notifyFriend()
        }
    }

    private fun isAppRestricted(packageName: String): Boolean {
        return restrictedPackages.any { pkg ->
            packageName == pkg || packageName.startsWith(pkg)
        }
    }

    private fun getTimeUsedInWindow(): Int {
        val now = System.currentTimeMillis()
        if (lastForegroundPackage != null && lastForegroundChangeMs > 0) {
            val extra = ((now - lastForegroundChangeMs) / 60_000).toInt()
            return minutesUsedInWindow + extra
        }
        return minutesUsedInWindow
    }

    private fun maybeResetWindow(now: Long) {
        val windowMs = windowMinutes * 60_000L
        if (now - currentWindowStartMs >= windowMs) {
            currentWindowStartMs = now
            minutesUsedInWindow = 0
        }
    }

    private fun blockUser() {
        val windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        val blockView = LayoutInflater.from(this).inflate(R.layout.activity_block_screen, null)
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        )
        try {
            windowManager.addView(blockView, params)
        } catch (e: Exception) {
            Toast.makeText(this, "Could not show block screen", Toast.LENGTH_SHORT).show()
        }
    }

    private fun notifyFriend() {
        val uid = userId ?: return
        val url = snitchUrl ?: return
        Thread {
            try {
                val conn = URL(url).openConnection() as HttpsURLConnection
                conn.requestMethod = "POST"
                conn.setRequestProperty("Content-Type", "application/json")
                conn.doOutput = true
                conn.outputStream.use { os ->
                    os.write("""{"userId":"$uid"}""".toByteArray(Charsets.UTF_8))
                }
                val code = conn.responseCode
                if (code !in 200..299) Log.e(TAG, "snitch failed: $code")
            } catch (e: Exception) {
                Log.e(TAG, "notifyFriend", e)
            }
        }.start()
    }

    override fun onInterrupt() {}

    companion object {
        private const val TAG = "BlockerService"
    }
}
