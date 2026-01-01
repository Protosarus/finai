// lib/core/services/camera_service.dart

import 'package:image_picker/image_picker.dart';

class CameraService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> takePhoto() async {
    try {
      // image_picker handles permissions automatically
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      return photo?.path;
    } catch (e) {
      // User cancelled or permission denied
      return null;
    }
  }

  Future<String?> pickFromGallery() async {
    try {
      // image_picker handles permissions automatically
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      return photo?.path;
    } catch (e) {
      // User cancelled or permission denied
      return null;
    }
  }

  // Future: OCR processing
  Future<Map<String, dynamic>> extractTextFromImage(String imagePath) async {
    // TODO: Implement OCR with ML Kit
    // This will extract amount, date, category from receipt

    return {
      'amount': null,
      'date': null,
      'description': null,
    };
  }
}
