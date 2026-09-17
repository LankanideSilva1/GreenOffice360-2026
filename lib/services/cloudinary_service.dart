import 'dart:convert';
import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // Replace with your Cloudinary Cloud Name
  static const String cloudName = 'klwzdjtp';

  // Create an unsigned upload preset in Cloudinary
  static const String uploadPreset = 'greenoffice_issue_upload';

  /// Compresses [image] into a high-quality JPEG (quality 88, shortest edge
  /// capped at 1920px) so uploads are smaller without visible quality loss.
  ///
  /// Falls back to the original file if compression is unavailable on the
  /// current platform or does not reduce the file size.
  Future<File> _compressImage(File image) async {
    try {
      final tempDir = await Directory.systemTemp.createTemp('greenoffice360_');
      final targetPath =
          '${tempDir.path}${Platform.pathSeparator}'
          '${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        image.absolute.path,
        targetPath,
        quality: 88,
        minWidth: 1920,
        minHeight: 1920,
        keepExif: true,
      );

      if (result == null) return image;

      final compressed = File(result.path);
      final compressedLength = await compressed.length();
      final originalLength = await image.length();

      // Keep the original when compression did not actually shrink the file.
      if (compressedLength <= 0 || compressedLength >= originalLength) {
        return image;
      }

      return compressed;
    } catch (_) {
      // Compression is best-effort and must never block an upload.
      return image;
    }
  }

  Future<String> uploadIssueImage({
    required File image,
    required String issueId,
    required String userId}) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest(
      'POST',
      uri,
    );

    request.fields['upload_preset'] = uploadPreset;
    request.fields['folder'] = 'greenoffice360/issues';
     request.fields['public_id'] = '${userId}_$issueId';

    final compressedImage = await _compressImage(image);

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        compressedImage.path,
      ),
    );

    final response = await request.send();

    final responseData =
        await response.stream.bytesToString();

    final data = jsonDecode(responseData);

    if (response.statusCode == 200) {
      return data['secure_url'];
    } else {
      throw Exception(
        'Cloudinary upload failed: ${data['error']?['message']}',
      );
    }
  }
}