package com.example.pug_vpn

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var awgVpnManager: AwgVpnManager? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val manager = AwgVpnManager(this)
        awgVpnManager = manager
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            AwgVpnManager.CHANNEL,
        ).setMethodCallHandler(manager)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        val handled = awgVpnManager?.onActivityResult(requestCode, resultCode, data) == true
        if (!handled) {
            super.onActivityResult(requestCode, resultCode, data)
        }
    }

    override fun onDestroy() {
        awgVpnManager?.dispose()
        awgVpnManager = null
        super.onDestroy()
    }
}
