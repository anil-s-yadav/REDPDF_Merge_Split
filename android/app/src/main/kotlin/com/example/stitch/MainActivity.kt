package com.legendarysoftware.marge_pdf_split_pdf

import android.content.ContentValues
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.legendarysoftware.marge_pdf_split_pdf/files"
    private val TAG = "MainActivity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scanFiles" -> {
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
                    }
                    "saveToDownloads" -> {
                        val args = call.arguments as? Map<*, *>
                        val filePath = args?.get("filePath") as? String
                        val fileName = args?.get("fileName") as? String
                        if (filePath != null && fileName != null) {
                            handleSaveToDownloads(filePath, fileName, result)
                        } else {
                            result.error("INVALID_ARGS", "Missing filePath or fileName", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun handleSaveToDownloads(filePath: String, fileName: String, result: MethodChannel.Result) {
        try {
            val sourceFile = java.io.File(filePath)
            if (!sourceFile.exists() || sourceFile.length() == 0L) {
                Log.e(TAG, "Source file does not exist or is empty: $filePath")
                result.error("ERROR", "Source file does not exist or is empty", null)
                return
            }
            Log.d(TAG, "saveToDownloads: source=$filePath (${sourceFile.length()} bytes), fileName=$fileName")

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // Android 10+ (API 29+): Try multiple strategies

                // Strategy 1: MediaStore Downloads API
                var savedPath = tryMediaStoreDownloads(sourceFile, fileName)
                if (savedPath != null) {
                    Log.d(TAG, "MediaStore Downloads succeeded: $savedPath")
                    result.success(savedPath)
                    return
                }

                // Strategy 2: Direct file copy (works on some Android 10 devices
                // with requestLegacyExternalStorage)
                savedPath = tryDirectFileCopy(sourceFile, fileName)
                if (savedPath != null) {
                    Log.d(TAG, "Direct file copy succeeded: $savedPath")
                    result.success(savedPath)
                    return
                }

                // Strategy 3: MediaStore Files API (more compatible on some OEMs)
                savedPath = tryMediaStoreFiles(sourceFile, fileName)
                if (savedPath != null) {
                    Log.d(TAG, "MediaStore Files succeeded: $savedPath")
                    result.success(savedPath)
                    return
                }

                Log.e(TAG, "All save methods failed for Android Q+")
                result.error("ERROR", "Could not save file to Downloads", null)
            } else {
                // Android 9 and below: direct file access
                val savedPath = tryDirectFileCopy(sourceFile, fileName)
                if (savedPath != null) {
                    result.success(savedPath)
                } else {
                    result.error("ERROR", "Could not save file to Downloads", null)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "saveToDownloads failed", e)
            result.error("ERROR", e.message ?: "Unknown error", e.stackTraceToString())
        }
    }

    /**
     * Strategy 1: Use MediaStore.Downloads API (Android 10+)
     */
    private fun tryMediaStoreDownloads(sourceFile: java.io.File, fileName: String): String? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return null
        try {
            val resolver = context.contentResolver
            val contentValues = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                put(MediaStore.Downloads.MIME_TYPE, "application/pdf")
                put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                put(MediaStore.Downloads.IS_PENDING, 1)
            }

            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
            if (uri == null) {
                Log.w(TAG, "MediaStore.Downloads insert returned null")
                return null
            }

            val outStream = resolver.openOutputStream(uri)
            if (outStream == null) {
                Log.w(TAG, "MediaStore.Downloads openOutputStream returned null")
                resolver.delete(uri, null, null)
                return null
            }

            outStream.use { os ->
                sourceFile.inputStream().use { inStream ->
                    inStream.copyTo(os)
                }
                os.flush()
            }

            // Clear IS_PENDING to make file visible in file managers
            val updateValues = ContentValues().apply {
                put(MediaStore.Downloads.IS_PENDING, 0)
            }
            val rowsUpdated = resolver.update(uri, updateValues, null, null)
            Log.d(TAG, "Cleared IS_PENDING, rowsUpdated: $rowsUpdated")

            val downloadDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            val realPath = getRealPathFromURI(uri)
            val finalPath = realPath ?: java.io.File(downloadDir, fileName).absolutePath

            Log.d(TAG, "MediaStore Downloads final path to scan: $finalPath")

            // Trigger media scan to ensure file manager picks it up immediately
            MediaScannerConnection.scanFile(
                this,
                arrayOf(finalPath),
                arrayOf("application/pdf")
            ) { path, scannedUri ->
                Log.d(TAG, "MediaScanner scanned: path=$path, uri=$scannedUri")
            }

            return finalPath
        } catch (e: Exception) {
            Log.w(TAG, "MediaStore.Downloads failed", e)
            return null
        }
    }

    /**
     * Strategy 2: Direct file copy to public Downloads directory.
     * Works on Android 9 and below, and on some Android 10+ devices with
     * requestLegacyExternalStorage or OEM-specific behavior.
     */
    private fun tryDirectFileCopy(sourceFile: java.io.File, fileName: String): String? {
        try {
            val downloadDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            val destFile = java.io.File(downloadDir, fileName)
            sourceFile.copyTo(destFile, overwrite = true)

            if (destFile.exists() && destFile.length() > 0) {
                MediaScannerConnection.scanFile(
                    this,
                    arrayOf(destFile.absolutePath),
                    arrayOf("application/pdf")
                ) { path, scannedUri ->
                    Log.d(TAG, "Direct file copy MediaScanner scanned: path=$path, uri=$scannedUri")
                }
                return destFile.absolutePath
            }
            Log.w(TAG, "Direct copy produced empty or missing file")
            return null
        } catch (e: Exception) {
            Log.w(TAG, "Direct file copy failed: ${e.message}")
            return null
        }
    }

    /**
     * Strategy 3: Use MediaStore.Files API — more widely supported than
     * MediaStore.Downloads on some Android 10-12 OEM devices.
     */
    private fun tryMediaStoreFiles(sourceFile: java.io.File, fileName: String): String? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return null
        try {
            val resolver = context.contentResolver
            val contentValues = ContentValues().apply {
                put(MediaStore.Files.FileColumns.DISPLAY_NAME, fileName)
                put(MediaStore.Files.FileColumns.MIME_TYPE, "application/pdf")
                put(MediaStore.Files.FileColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                put(MediaStore.Files.FileColumns.IS_PENDING, 1)
            }

            val collection = MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            val uri = resolver.insert(collection, contentValues)
            if (uri == null) {
                Log.w(TAG, "MediaStore.Files insert returned null")
                return null
            }

            val outStream = resolver.openOutputStream(uri)
            if (outStream == null) {
                Log.w(TAG, "MediaStore.Files openOutputStream returned null")
                resolver.delete(uri, null, null)
                return null
            }

            outStream.use { os ->
                sourceFile.inputStream().use { inStream ->
                    inStream.copyTo(os)
                }
                os.flush()
            }

            // Clear IS_PENDING
            val updateValues = ContentValues().apply {
                put(MediaStore.Files.FileColumns.IS_PENDING, 0)
            }
            val rowsUpdated = resolver.update(uri, updateValues, null, null)
            Log.d(TAG, "MediaStore.Files cleared IS_PENDING, rowsUpdated: $rowsUpdated")

            val downloadDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            val realPath = getRealPathFromURI(uri)
            val finalPath = realPath ?: java.io.File(downloadDir, fileName).absolutePath

            Log.d(TAG, "MediaStore.Files final path to scan: $finalPath")

            MediaScannerConnection.scanFile(
                this,
                arrayOf(finalPath),
                arrayOf("application/pdf")
            ) { path, scannedUri ->
                Log.d(TAG, "MediaStore.Files MediaScanner scanned: path=$path, uri=$scannedUri")
            }

            return finalPath
        } catch (e: Exception) {
            Log.w(TAG, "MediaStore.Files failed: ${e.message}")
            return null
        }
    }

    /**
     * Resolves the actual file path on disk from a MediaStore content URI.
     */
    private fun getRealPathFromURI(uri: Uri): String? {
        val projection = arrayOf(MediaStore.MediaColumns.DATA)
        try {
            context.contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val columnIndex = cursor.getColumnIndex(MediaStore.MediaColumns.DATA)
                    if (columnIndex != -1) {
                        return cursor.getString(columnIndex)
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get real path from URI: ${e.message}", e)
        }
        return null
    }
}
