package com.nasser.messages

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var sharedData: String = ""

    override fun onCreate(
            savedInstanceState: Bundle?
    ) {
        super.onCreate(savedInstanceState)
        handleIntent()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
                "com.nasser.messages").setMethodCallHandler { call, result ->
            if (call.method == "getSharedData") {
                handleIntent()
                result.success(sharedData)
                sharedData = ""
            }
        }
    }


    private fun handleIntent() {
        if (intent?.action == Intent.ACTION_SEND) {
            if (intent.type == "text/plain") {
                intent.getStringExtra(Intent.EXTRA_TEXT)?.let { intentData ->
                    sharedData = intentData
                }
            }
        }
    }
}
