package com.deepanshuchaudhary.pdf_manipulator

import android.app.Activity
import android.content.ContentResolver
import android.net.Uri
import androidx.core.net.toUri
import com.itextpdf.kernel.pdf.PdfDocument
import com.itextpdf.kernel.pdf.PdfReader
import com.itextpdf.kernel.pdf.PdfWriter
import com.itextpdf.kernel.utils.PdfMerger
import com.itextpdf.layout.Document
import com.itextpdf.layout.element.Paragraph
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.coroutines.yield
import java.io.File
import java.io.IOException
import android.util.Log

// For merging multiple pdf files.
// For merging multiple pdf files.
suspend fun getMergedPDFPath(
    sourceFilesPaths: List<String>,
    context: Activity,
): String? {
    var mergedPDFPath: String? = null

    withContext<Unit>(Dispatchers.IO) {
        // Workaround for Provider org.apache.xerces.parsers.XIncludeAwareParserConfiguration not found on Android 16
        System.setProperty("javax.xml.parsers.DocumentBuilderFactory", "org.apache.harmony.xml.parsers.DocumentBuilderFactoryImpl")
        System.setProperty("javax.xml.parsers.SAXParserFactory", "org.apache.harmony.xml.parsers.SAXParserFactoryImpl")
        val utils = Utils()
        val begin = System.nanoTime()
        val contentResolver: ContentResolver = context.contentResolver
        
        Log.d("PdfMerger", "Starting merge of ${sourceFilesPaths.size} files")

        // 1. Create result file
        val mergeResultFile: File = File.createTempFile("mergeResultFile", ".pdf")
        val pdfWriter = PdfWriter(mergeResultFile)
        pdfWriter.setSmartMode(true)
        pdfWriter.compressionLevel = 9

        val tempListOfUrisForFilesToMerge: MutableList<Uri> = mutableListOf()
        try {
            // 2. Resolve all URIs
            for (path in sourceFilesPaths) {
                yield()
                tempListOfUrisForFilesToMerge.add(utils.getURI(path))
            }

            // 3. Check for PDF Tagging
            val listOfTaggingStatus: MutableList<Boolean> = mutableListOf()
            for ((index, uri) in tempListOfUrisForFilesToMerge.withIndex()) {
                yield()
                val tempCheckFile = File.createTempFile("tagCheck_$index", ".pdf")
                try {
                    utils.copyDataFromSourceToDestDocument(uri, tempCheckFile.toUri(), contentResolver)
                    if (tempCheckFile.length() == 0L) {
                        throw IOException("Source file at index $index is empty or inaccessible: $uri")
                    }
                    PdfReader(tempCheckFile).use { reader ->
                        reader.setUnethicalReading(true)
                        PdfDocument(reader).use { doc ->
                            listOfTaggingStatus.add(doc.isTagged)
                        }
                    }
                } finally {
                    tempCheckFile.delete()
                }
            }

            // 4. Handle Tagged PDF Logic (iText specific)
            var taggedFileAdded = false
            if (listOfTaggingStatus.isNotEmpty() && !listOfTaggingStatus[0] && listOfTaggingStatus.contains(true)) {
                val taggedPDFFile = File.createTempFile("taggedMarker", ".pdf")
                PdfWriter(taggedPDFFile).use { writer ->
                    PdfDocument(writer).use { pdf ->
                        Document(pdf).use { doc ->
                            pdf.setTagged()
                            doc.add(Paragraph(" "))
                        }
                    }
                }
                tempListOfUrisForFilesToMerge.add(0, taggedPDFFile.toUri())
                taggedFileAdded = true
                Log.d("PdfMerger", "Added tagging marker file at beginning")
            }

            // 5. Perform Merge
            val firstUri = tempListOfUrisForFilesToMerge[0]
            val parentTempFile = File.createTempFile("mergeParent", ".pdf")
            try {
                utils.copyDataFromSourceToDestDocument(firstUri, parentTempFile.toUri(), contentResolver)
                if (parentTempFile.length() == 0L) {
                    throw IOException("Failed to copy first file for merge: $firstUri")
                }

                PdfReader(parentTempFile).use { reader ->
                    reader.setUnethicalReading(true)
                    reader.setMemorySavingMode(true)
                    
                    PdfDocument(reader, pdfWriter).use { pdfDocument ->
                        val merger = PdfMerger(pdfDocument)
                        
                        for (i in 1 until tempListOfUrisForFilesToMerge.size) {
                            yield()
                            val nextUri = tempListOfUrisForFilesToMerge[i]
                            val nextTempFile = File.createTempFile("mergeNext_$i", ".pdf")
                            try {
                                utils.copyDataFromSourceToDestDocument(nextUri, nextTempFile.toUri(), contentResolver)
                                if (nextTempFile.length() == 0L) {
                                    throw IOException("Failed to copy file at index $i for merge: $nextUri")
                                }

                                PdfReader(nextTempFile).use { nextReader ->
                                    nextReader.setUnethicalReading(true)
                                    nextReader.setMemorySavingMode(true)
                                    PdfDocument(nextReader).use { nextDoc ->
                                        merger.merge(nextDoc, 1, nextDoc.numberOfPages)
                                        pdfDocument.flushCopiedObjects(nextDoc)
                                    }
                                }
                            } finally {
                                nextTempFile.delete()
                            }
                        }

                        if (taggedFileAdded) {
                            pdfDocument.removePage(1)
                        }
                    }
                }
            } finally {
                parentTempFile.delete()
                if (taggedFileAdded) {
                    // Clean up the tagged marker file if it was created
                    val markerUri = tempListOfUrisForFilesToMerge[0]
                    if (markerUri.scheme == "file") {
                        File(markerUri.path!!).delete()
                    }
                }
            }

            Log.d("PdfMerger", "Merge completed successfully. Result size: ${mergeResultFile.length()}")
            mergedPDFPath = mergeResultFile.path

        } catch (e: Exception) {
            Log.e("PdfMerger", "Merge failed", e)
            mergeResultFile.delete()
            throw e
        } finally {
            // pdfWriter is closed when the PdfDocument(reader, pdfWriter) is closed
            // but we ensure it's closed just in case
            try { pdfWriter.close() } catch (e: Exception) {}
        }

        val end = System.nanoTime()
        Log.d("PdfMerger", "Elapsed time in ms: ${(end - begin) / 1_000_000}")
    }

    return mergedPDFPath
}