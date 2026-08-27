import 'dart:io';

import '../../../services/image_service.dart';

class IssueDetailsController {
  IssueDetailsController({ImageService? imageService})
      : _imageService = imageService ?? ImageService();

  final ImageService _imageService;

  Future<File?> takePhoto() async {
    return _imageService.takePhoto();
  }

  Future<File?> pickFromGallery() async {
    return _imageService.pickFromGallery();
  }

  Future<File?> recoverLostPhoto() async {
    return _imageService.recoverLostPhoto();
  }
}