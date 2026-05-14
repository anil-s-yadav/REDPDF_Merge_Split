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
                } else if (call.method == "saveToDownloads") {
                    val args = call.arguments as? Map<*, *>
                    val filePath = args?.get("filePath") as? String
                    val fileName = args?.get("fileName") as? String
                    if (filePath != null && fileName != null) {
                        try {
                            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                                val resolver = context.contentResolver
                                val contentValues = android.content.ContentValues().apply {
                                    put(android.provider.MediaStore.Downloads.DISPLAY_NAME, fileName)
                                    put(android.provider.MediaStore.Downloads.MIME_TYPE, "application/pdf")
                                    put(android.provider.MediaStore.Downloads.RELATIVE_PATH, android.os.Environment.DIRECTORY_DOWNLOADS + "/RedPdf")
                                }
                                val uri = resolver.insert(android.provider.MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
                                if (uri != null) {
                                    resolver.openOutputStream(uri)?.use { outStream ->
                                        java.io.File(filePath).inputStream().use { inStream ->
                                            inStream.copyTo(outStream)
                                        }
                                    }
                                    val downloadDir = android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_DOWNLOADS)
                                    val finalPath = java.io.File(downloadDir, "RedPdf/" + fileName).absolutePath
                                    result.success(finalPath)
                                } else {
                                    result.error("ERROR", "Failed to create MediaStore entry", null)
                                }
                            } else {
                                val downloadDir = android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_DOWNLOADS)
                                val redPdfDir = java.io.File(downloadDir, "RedPdf")
                                if (!redPdfDir.exists()) redPdfDir.mkdirs()
                                val destFile = java.io.File(redPdfDir, fileName)
                                java.io.File(filePath).copyTo(destFile, overwrite = true)
                                result.success(destFile.absolutePath)
                            }
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "Missing filePath or fileName", null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
