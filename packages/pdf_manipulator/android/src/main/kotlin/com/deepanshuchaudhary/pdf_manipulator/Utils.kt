package com.deepanshuchaudhary.pdf_manipulator

import android.app.Activity
import android.content.ContentResolver
import android.database.Cursor
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.plugin.common.MethodChannel
import java.io.*

class Utils {

    fun deleteTempFiles(listOfTempFiles: List<File>) {
        listOfTempFiles.forEach { tempFile ->
            tempFile.delete()
        }
    }

    fun copyDataFromSourceToDestDocument(
        sourceFileUri: Uri, destinationFileUri: Uri, contentResolver: ContentResolver
    ) {
        // its important to truncate an output file to size zero before writing to it
        // as user may have selected an old file to overwrite which need to be cleaned before writing
        if (destinationFileUri.scheme == "file") {
            try {
                FileOutputStream(destinationFileUri.path).close()
            } catch (e: Exception) {
                e.printStackTrace()
            }
        } else {
            truncateDocumentToZeroSize(
                uri = destinationFileUri, contentResolver = contentResolver
            )
        }

        val inputStream: InputStream? = if (sourceFileUri.scheme == "content") {
            contentResolver.openInputStream(sourceFileUri)
        } else {
            FileInputStream(sourceFileUri.path)
        }

        val outputStream: OutputStream? = if (destinationFileUri.scheme == "content") {
            contentResolver.openOutputStream(destinationFileUri)
        } else {
            FileOutputStream(destinationFileUri.path)
        }

        if (inputStream != null && outputStream != null) {
            inputStream.use { input ->
                outputStream.use { output ->
                    input.copyTo(output)
                    println("Data successfully copied from one file to another")
                }
            }
        } else {
            inputStream?.close()
            outputStream?.close()
            throw IOException("Failed to open inputStream or outputStream for copying")
        }
    }

    private fun truncateDocumentToZeroSize(uri: Uri, contentResolver: ContentResolver) {
        try {
            contentResolver.openFileDescriptor(uri, "wt")?.use { parcelFileDescriptor ->
                FileOutputStream(parcelFileDescriptor.fileDescriptor).use { fileOutputStream ->
                    fileOutputStream.channel.truncate(0)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun getURI(uri: String): Uri {
        val parsed: Uri = Uri.parse(uri)
        val parsedScheme: String? = parsed.scheme
        return if ((parsedScheme == null) || parsedScheme.isEmpty() || "${uri[0]}" == "/") {
            // Using "${uri[0]}" == "/" in condition above because if uri is an absolute file path without any scheme starting with "/"
            // and if its filename contains ":" then the parsed scheme will be wrong.
            Uri.fromFile(File(uri))
        } else parsed
    }

    fun getFileNameFromPickedDocumentUri(uri: Uri, context: Activity): String? {
        var fileName: String? = null
        val parsedScheme: String? = uri.scheme

        if (parsedScheme == "file") {
            fileName = uri.lastPathSegment
        } else {
            val contentResolver: ContentResolver = context.contentResolver
            val cursor: Cursor? = contentResolver.query(uri, null, null, null, null)
            cursor.use {
                if ((it != null) && it.moveToFirst()) {
                    fileName = it.getString(it.getColumnIndexOrThrow(OpenableColumns.DISPLAY_NAME))
                }
            }
        }
        return cleanupFileName(fileName)
    }

    private fun cleanupFileName(fileName: String?): String? {
        // https://stackoverflow.com/questions/2679699/what-characters-allowed-in-file-names-on-android
        return fileName?.replace(Regex("[\\\\/:*?\"<>|\\[\\]]"), "_")
    }

    fun finishSuccessfullyWithString(
        result: String?, resultCallback: MethodChannel.Result?
    ) {
        resultCallback?.success(result)
    }

    fun finishSplitSuccessfullyWithListOfString(
        result: List<String>?, resultCallback: MethodChannel.Result?
    ) {
        resultCallback?.success(result)
    }

    fun finishSplitSuccessfullyWithListOfListOfDouble(
        result: List<List<Double>>?, resultCallback: MethodChannel.Result?
    ) {
        resultCallback?.success(result)
    }


    fun finishSplitSuccessfullyWithListOfBoolean(
        result: List<Boolean?>, resultCallback: MethodChannel.Result?
    ) {
        resultCallback?.success(result)
    }

    fun finishWithError(
        errorCode: String,
        errorMessage: String?,
        errorDetails: String?,
        resultCallback: MethodChannel.Result?
    ) {
        resultCallback?.error(errorCode, errorMessage, errorDetails)
    }

//    fun clearPDFFilesFromCache(context: Activity) {
//        val cacheDir: File = context.cacheDir
//        if (cacheDir.exists()) {
//            val cacheFilesArray: Array<out File>? = cacheDir.listFiles()
//            val cacheFilesList: List<File> = cacheFilesArray?.toList() ?: listOf()
//            cacheFilesList.forEach { cacheFile ->
//                if (cacheFile.name.contains(".pdf", ignoreCase = true)) {
//                    println(cacheFile.name + " deleted")
//                    cacheFile.delete()
//                }
//            }
//        } else {
//            cacheDir.mkdirs()
//        }
//    }

}