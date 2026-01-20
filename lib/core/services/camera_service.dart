// lib/core/services/camera_service.dart

import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CameraService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      return photo?.path;
    } catch (e) {
      return null;
    }
  }

  Future<String?> pickFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      return photo?.path;
    } catch (e) {
      return null;
    }
  }

  /// Gemini Vision API ile fatura/fiş okuma
  Future<Map<String, dynamic>?> extractTextFromImage(String imagePath) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null) {
        print("❌ GEMINI_API_KEY bulunamadı!");
        return null;
      }

      // Görseli base64'e çevir
      final imageFile = File(imagePath);
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Gemini Vision API URL
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
      );

      // AI'a gönderilecek prompt
      final prompt = '''
      Bu bir fatura/fiş fotoğrafı. Lütfen aşağıdaki bilgileri çıkar ve SADECE JSON formatında döndür.
      
      Kurallar:
      1. SADECE saf JSON döndür, başka hiçbir şey yazma (Markdown yok, açıklama yok).
      2. "amount" (toplam tutar) sayı olmalı (örn: 150.50)
      3. "description" kısa açıklama (örn: "Market alışverişi", "Restoran")
      4. "category" şunlardan biri olmalı: food, transport, shopping, bills, entertainment, health, education, other
      5. "date" ISO formatında (örn: "2024-01-20")
      
      Örnek çıktı:
      {
        "amount": 150.50,
        "description": "Market alışverişi",
        "category": "shopping",
        "date": "2024-01-20"
      }
      
      Eğer fotoğrafta fatura/fiş yoksa veya okunamazsa:
      {
        "amount": null,
        "description": "Fatura okunamadı",
        "category": "other",
        "date": null
      }
      ''';

      // API isteği
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt},
                {
                  "inline_data": {
                    "mime_type": "image/jpeg",
                    "data": base64Image
                  }
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Gemini'nin yanıtını al
        final aiText = data['candidates'][0]['content']['parts'][0]['text'];

        // Temizlik: ```json ... ``` varsa kaldır
        final cleanJson =
            aiText.replaceAll('```json', '').replaceAll('```', '').trim();

        print("📸 OCR Sonucu: $cleanJson");

        return jsonDecode(cleanJson);
      } else {
        print("❌ Gemini API Hatası: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("❌ OCR Hatası: $e");
      return null;
    }
  }
}
