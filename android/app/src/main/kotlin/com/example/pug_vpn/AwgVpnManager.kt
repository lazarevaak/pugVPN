package com.example.pug_vpn

import android.app.Activity
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.VpnService
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import org.amnezia.awg.backend.GoBackend
import org.amnezia.awg.backend.Tunnel
import org.amnezia.awg.config.Config
import java.io.ByteArrayOutputStream
import java.io.BufferedReader
import java.io.StringReader
import java.util.Base64
import java.util.Locale
import java.util.concurrent.Executors

class AwgVpnManager(
    private val activity: Activity,
) : MethodChannel.MethodCallHandler, PluginRegistry.ActivityResultListener {
    companion object {
        const val CHANNEL = "pug_vpn/awg"
        private const val PREPARE_REQUEST_CODE = 7942
        private const val STORAGE_NAME = "pug_vpn_storage"
        private const val PRIVATE_KEY = "device_private_key_base64"
        private const val PUBLIC_KEY = "device_public_key_base64"
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private val executor = Executors.newSingleThreadExecutor()
    private val backend = GoBackend(activity.applicationContext)
    private val tunnel = ManagedTunnel()

    @Volatile
    private var currentState: Tunnel.State = Tunnel.State.DOWN

    private var pendingPrepareResult: MethodChannel.Result? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "prepare" -> prepare(result)
            "connect" -> connect(call, result)
            "disconnect" -> disconnect(result)
            "status" -> status(result)
            "loadDeviceKeyPair" -> loadDeviceKeyPair(result)
            "saveDeviceKeyPair" -> saveDeviceKeyPair(call, result)
            "listInstalledApps" -> listInstalledApps(result)
            "shareText" -> shareText(call, result)
            else -> result.notImplemented()
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != PREPARE_REQUEST_CODE) return false
        val pending = pendingPrepareResult ?: return true
        pendingPrepareResult = null
        val granted = resultCode == Activity.RESULT_OK
        pending.success(granted)
        return true
    }

    fun dispose() {
        executor.execute {
            try {
                backend.setState(tunnel, Tunnel.State.DOWN, null)
            } catch (_: Exception) {
                // Ignore disposal errors.
            }
        }
        executor.shutdown()
    }

    private fun prepare(result: MethodChannel.Result) {
        if (pendingPrepareResult != null) {
            result.error("PREPARE_IN_PROGRESS", "VPN permission request already in progress.", null)
            return
        }

        val intent = VpnService.prepare(activity)
        if (intent == null) {
            result.success(true)
            return
        }

        pendingPrepareResult = result
        activity.startActivityForResult(intent, PREPARE_REQUEST_CODE)
    }

    private fun connect(call: MethodCall, result: MethodChannel.Result) {
        val configRaw = call.argument<String>("config")
        if (configRaw.isNullOrBlank()) {
            result.error("INVALID_ARGS", "config is required.", null)
            return
        }

        val tunnelName = call.argument<String>("tunnelName")
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
            ?: "pugvpn"

        executor.execute {
            try {
                if (VpnService.prepare(activity) != null) {
                    postError(result, "VPN_NOT_AUTHORIZED", "VPN permission is not granted.")
                    return@execute
                }

                tunnel.tunnelName = sanitizeTunnelName(tunnelName)
                val config = Config.parse(BufferedReader(StringReader(configRaw)))
                val state = backend.setState(tunnel, Tunnel.State.UP, config)
                currentState = state
                postSuccess(result, state == Tunnel.State.UP)
            } catch (error: Exception) {
                postError(result, "CONNECT_ERROR", error.message ?: error.toString())
            }
        }
    }

    private fun disconnect(result: MethodChannel.Result) {
        executor.execute {
            try {
                val state = backend.setState(tunnel, Tunnel.State.DOWN, null)
                currentState = state
                postSuccess(result, true)
            } catch (error: Exception) {
                postError(result, "DISCONNECT_ERROR", error.message ?: error.toString())
            }
        }
    }

    private fun status(result: MethodChannel.Result) {
        executor.execute {
            try {
                val state = backend.getState(tunnel)
                currentState = state
                postSuccess(
                    result,
                    mapOf(
                        "state" to state.name.lowercase(Locale.ENGLISH),
                        "is_connected" to (state == Tunnel.State.UP),
                    ),
                )
            } catch (_: Exception) {
                postSuccess(
                    result,
                    mapOf(
                        "state" to currentState.name.lowercase(Locale.ENGLISH),
                        "is_connected" to (currentState == Tunnel.State.UP),
                    ),
                )
            }
        }
    }

    private fun listInstalledApps(result: MethodChannel.Result) {
        executor.execute {
            try {
                val packageManager = activity.packageManager
                val launcherIntent = Intent(Intent.ACTION_MAIN, null).apply {
                    addCategory(Intent.CATEGORY_LAUNCHER)
                }
                val apps = packageManager.queryIntentActivities(launcherIntent, 0)
                    .mapNotNull { resolveInfo ->
                        val packageName = resolveInfo.activityInfo?.packageName ?: return@mapNotNull null
                        if (packageName == activity.packageName) return@mapNotNull null
                        val iconDrawable = resolveInfo.loadIcon(packageManager)
                        mapOf(
                            "packageName" to packageName,
                            "label" to resolveInfo.loadLabel(packageManager).toString(),
                            "iconBase64" to drawableToBase64(iconDrawable),
                        )
                    }
                    .distinctBy { it["packageName"] }
                    .sortedBy { (it["label"] as String).lowercase(Locale.ENGLISH) }
                postSuccess(result, apps)
            } catch (error: Exception) {
                postError(result, "LIST_APPS_ERROR", error.message ?: error.toString())
            }
        }
    }

    private fun loadDeviceKeyPair(result: MethodChannel.Result) {
        val preferences = activity.getSharedPreferences(STORAGE_NAME, Context.MODE_PRIVATE)
        val privateKey = preferences.getString(PRIVATE_KEY, null)
        val publicKey = preferences.getString(PUBLIC_KEY, null)
        if (privateKey.isNullOrBlank() || publicKey.isNullOrBlank()) {
            result.success(null)
            return
        }

        result.success(
            mapOf(
                "privateKeyBase64" to privateKey,
                "publicKeyBase64" to publicKey,
            ),
        )
    }

    private fun saveDeviceKeyPair(call: MethodCall, result: MethodChannel.Result) {
        val privateKey = call.argument<String>("privateKeyBase64")
        val publicKey = call.argument<String>("publicKeyBase64")
        if (privateKey.isNullOrBlank() || publicKey.isNullOrBlank()) {
            result.error(
                "INVALID_ARGS",
                "privateKeyBase64 and publicKeyBase64 are required.",
                null,
            )
            return
        }

        val preferences = activity.getSharedPreferences(STORAGE_NAME, Context.MODE_PRIVATE)
        preferences.edit()
            .putString(PRIVATE_KEY, privateKey)
            .putString(PUBLIC_KEY, publicKey)
            .apply()
        result.success(true)
    }

    private fun shareText(call: MethodCall, result: MethodChannel.Result) {
        val text = call.argument<String>("text")
        if (text.isNullOrBlank()) {
            result.error("INVALID_ARGS", "text is required.", null)
            return
        }

        try {
            val shareIntent = Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"
                putExtra(Intent.EXTRA_TEXT, text)
            }
            val chooser = Intent.createChooser(shareIntent, "Share PugVPN").apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            activity.startActivity(chooser)
            result.success(true)
        } catch (error: Exception) {
            result.error("SHARE_TEXT_ERROR", error.message ?: error.toString(), null)
        }
    }

    private fun sanitizeTunnelName(raw: String): String {
        val cleaned = raw.replace(Regex("[^a-zA-Z0-9_=+.-]"), "").take(15)
        return if (cleaned.isEmpty()) "pugvpn" else cleaned
    }

    private fun drawableToBase64(drawable: Drawable): String {
        val bitmap = when (drawable) {
            is BitmapDrawable -> drawable.bitmap
            else -> {
                val width = drawable.intrinsicWidth.takeIf { it > 0 } ?: 96
                val height = drawable.intrinsicHeight.takeIf { it > 0 } ?: 96
                Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888).also { bitmap ->
                    val canvas = Canvas(bitmap)
                    drawable.setBounds(0, 0, canvas.width, canvas.height)
                    drawable.draw(canvas)
                }
            }
        }
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return Base64.getEncoder().encodeToString(stream.toByteArray())
    }

    private fun postSuccess(result: MethodChannel.Result, payload: Any) {
        mainHandler.post { result.success(payload) }
    }

    private fun postError(result: MethodChannel.Result, code: String, message: String) {
        mainHandler.post { result.error(code, message, null) }
    }

    private inner class ManagedTunnel : Tunnel {
        @Volatile
        var tunnelName: String = "pugvpn"

        override fun getName(): String = tunnelName

        override fun onStateChange(newState: Tunnel.State) {
            currentState = newState
        }
    }
}
