import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

// A result class to communicate success or failure back to the UI
class ShareResult {
  final bool success;
  final String? message;

  const ShareResult({required this.success, this.message});

  factory ShareResult.success([String? message]) =>
      ShareResult(success: true, message: message);

  factory ShareResult.failure(String message) =>
      ShareResult(success: false, message: message);
}

class ShareService {
  /// Gets the appropriate directory for temporary files based on platform
  Future<Directory> _getTempDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError('File operations not supported on web platform');
    }

    try {
      return await getTemporaryDirectory();
    } catch (e) {
      // Fallback for platforms where getTemporaryDirectory might fail
      if (Platform.isWindows) {
        final tempPath =
            Platform.environment['TEMP'] ?? Platform.environment['TMP'];
        if (tempPath != null) {
          return Directory(tempPath);
        }
      } else if (Platform.isLinux || Platform.isMacOS) {
        return Directory('/tmp');
      }
      rethrow;
    }
  }

  /// Captures a widget identified by a GlobalKey as a PNG image.
  Future<Uint8List> _captureWidget(GlobalKey key) async {
    final context = key.currentContext;
    if (context == null) {
      throw Exception('Widget context not found for capture');
    }

    final RenderRepaintBoundary? boundary =
        context.findRenderObject() as RenderRepaintBoundary?;

    if (boundary == null) {
      throw Exception('RepaintBoundary not found for widget capture');
    }

    try {
      // Use higher pixel ratio for better quality, but handle potential memory issues
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to convert image to byte data');
      }

      return byteData.buffer.asUint8List();
    } catch (e) {
      // Retry with lower pixel ratio if high quality fails
      try {
        final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
        final ByteData? byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);

        if (byteData == null) {
          throw Exception('Failed to convert image to byte data on retry');
        }

        return byteData.buffer.asUint8List();
      } catch (retryError) {
        throw Exception('Failed to capture widget as image: $retryError');
      }
    }
  }

  /// Creates a PDF document from an image byte array.
  Future<Uint8List> _createPdfFromImage(Uint8List imageBytes) async {
    try {
      final pdf = pw.Document(
        title: 'College Board Quiz Question',
        author: 'College Board Quiz App',
        creator: 'Flutter Quiz App',
        subject: 'Quiz Question Export',
      );

      final memoryImage = pw.MemoryImage(imageBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text(
                    'College Board Quiz Question',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Expanded(
                  child: pw.Center(
                    child: pw.Image(
                      memoryImage,
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                ),
                pw.Divider(),
                pw.Footer(
                  leading: pw.Text(
                    'Generated from College Board Quiz App',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                  trailing: pw.Text(
                    'Page ${context.pageNumber}',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                ),
              ],
            );
          },
        ),
      );

      return await pdf.save();
    } catch (e) {
      throw Exception('Failed to create PDF: $e');
    }
  }

  /// Saves the generated PDF to a temporary file and returns the file path.
  Future<String> _savePdf(Uint8List pdfBytes, String questionId) async {
    try {
      final tempDir = await _getTempDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'question_${questionId}_$timestamp.pdf';
      final file = File('${tempDir.path}${Platform.pathSeparator}$fileName');

      await file.writeAsBytes(pdfBytes);
      return file.path;
    } catch (e) {
      throw Exception('Failed to save PDF file: $e');
    }
  }

  /// Cross-platform file sharing implementation
  Future<void> _shareFile(
      String filePath, String fileName, BuildContext? context) async {
    if (kIsWeb) {
      throw UnsupportedError('File sharing not supported on web platform');
    }

    try {
      final box = context?.findRenderObject() as RenderBox?;

      await Share.shareXFiles(
        [XFile(filePath, mimeType: 'application/pdf', name: fileName)],
        text: 'Check out this question from the College Board Quiz app!',
        sharePositionOrigin:
            box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      );
    } catch (e) {
      // Fallback for platforms where sharing might not be available
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // On desktop, copy path to clipboard as fallback
        await Clipboard.setData(ClipboardData(text: filePath));
        throw ShareFallbackException(
            'File saved to: $filePath (path copied to clipboard)');
      } else {
        throw Exception('Failed to share file: $e');
      }
    }
  }

  /// The main public method that orchestrates the entire sharing process.
  Future<ShareResult> shareWidgetAsPdf({
    required GlobalKey widgetKey,
    required String questionId,
    required BuildContext context,
  }) async {
    if (kIsWeb) {
      return ShareResult.failure(
          'File sharing is not supported on web browsers. Please use the mobile or desktop app.');
    }

    if (widgetKey.currentContext == null) {
      return ShareResult.failure('Cannot find question content to share.');
    }

    try {
      // 1. Capture widget as image
      final imageBytes = await _captureWidget(widgetKey);

      // 2. Create PDF from image
      final pdfBytes = await _createPdfFromImage(imageBytes);

      // 3. Save PDF to temporary file
      final filePath = await _savePdf(pdfBytes, questionId);

      // 4. Share the file
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'question_${questionId}_$timestamp.pdf';

      await _shareFile(filePath, fileName, context);

      return ShareResult.success();
    } on ShareFallbackException catch (e) {
      // This is a "successful" fallback case for desktop platforms
      return ShareResult.success(e.message);
    } catch (e) {
      String errorMessage = 'Failed to share question';

      if (e is UnsupportedError) {
        errorMessage = e.message!;
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Permission denied. Please check app permissions.';
      } else if (e.toString().contains('storage')) {
        errorMessage = 'Storage access error. Please check available space.';
      } else {
        errorMessage = '$errorMessage: ${e.toString()}';
      }

      return ShareResult.failure(errorMessage);
    }
  }
}

/// Custom exception for desktop fallback scenarios
class ShareFallbackException implements Exception {
  final String message;
  const ShareFallbackException(this.message);

  @override
  String toString() => message;
}
