package com.example.pug_vpn

import android.app.Activity
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
import java.io.BufferedReader
import java.io.StringReader
import java.util.Locale
import java.util.concurrent.Executors

class AwgVpnManager(
    private val activity: Activity,
) : MethodChannel.MethodCallHandler, PluginRegistry.ActivityResultListener {
    companion object {
        const val CHANNEL = "pug_vpn/awg"
        private const val PREPARE_REQUEST_CODE = 7942
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
            "listInstalledApps" -> listInstalledApps(result)
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
                        mapOf(
                            "packageName" to packageName,
                            "label" to resolveInfo.loadLabel(packageManager).toString(),
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

    private fun sanitizeTunnelName(raw: String): String {
        val cleaned = raw.replace(Regex("[^a-zA-Z0-9_=+.-]"), "").take(15)
        return if (cleaned.isEmpty()) "pugvpn" else cleaned
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
