import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class CloudinaryService {
  // Replace with your Cloudinary Cloud Name
  static const String cloudName = 'klwzdjtp';

  // Create an unsigned upload preset in Cloudinary
  static const String uploadPreset = 'greenoffice_issue_upload';

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

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        image.path,
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