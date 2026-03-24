package com.legendarysoftware.marge_pdf_split_pdf

import android.media.MediaScannerConnection
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.legendarysoftware.marge_pdf_split_pdf/files"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "scanFiles") {
                    val args = call.arguments as? Map<*, *>
                    val paths = args?.get("paths") as? List<*>
                    if (paths != null) {
                        val pathStrings = paths.mapNotNull { it as? String }.toTypedArray()
                        MediaScannerConnection.scanFile(
                            this,
                            pathStrings,
                            null
                        ) { _, _ -> }
                    }
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }
}
