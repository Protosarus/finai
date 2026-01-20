// lib/core/services/voice_service.dart

import 'package:speech_to_text/speech_to_text.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;

  // Başlatma (İzin alma)
  Future<bool> initialize() async {
    return await _speech.initialize(
      onError: (error) => print('Speech error: $error'),
      onStatus: (status) => print('Speech status: $status'),
    );
  }

  // Dinleme Fonksiyonu
  Future<String?> listen() async {
    if (!_speech.isAvailable) {
      final initialized = await initialize();
      if (!initialized) return null;
    }

    final completer = Completer<String?>();
    String? result;

    await _speech.listen(
      onResult: (speechResult) {
        result = speechResult.recognizedWords;
        if (speechResult.finalResult) {
          if (!completer.isCompleted) completer.complete(result);
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: 'tr_TR',
      cancelOnError: true,
      listenMode: ListenMode.confirmation,
    );

    _isListening = true;

    try {
      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          _speech.stop();
          return result;
        },
      );
    } finally {
      _isListening = false;
      _speech.stop();
    }
  }

  void stopListening() {
    _speech.stop();
    _isListening = false;
  }

  // --- İŞTE EKSİK OLAN AI FONKSİYONU ---

  /// Kullanıcının cümlesini Google Gemini AI'a gönderir ve JSON yanıtı alır.
  Future<Map<String, dynamic>?> analyzeWithAI(String command) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null) {
        print("API Key bulunamadı! .env dosyasını kontrol et.");
        return null;
      }

      // Modelimizde tanımlı kategoriler
      const validCategories = [
        'food', 'transport', 'shopping', 'bills', 'entertainment', 'health',
        'education', // Gider
        'salary', 'freelance', 'investment', 'other' // Gelir
      ];

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
      );

      // AI'a gönderilecek talimat
      final prompt = '''
      Sen bir finansal asistan yapay zekasısın. 
      Kullanıcının girdiği metni analiz et ve aşağıdaki JSON formatında veri döndür.
      
      Kullanıcı Metni: "$command"
      
      Kurallar:
      1. Sadece saf JSON döndür. Markdown (```json) kullanma.
      2. "amount" (tutar) sayı olmalı.
      3. "category" şu listeden biri olmalı: ${validCategories.join(', ')}. Eğer bulamazsan en yakınını veya "other" seç.
      4. "description" kısa ve açıklayıcı olsun (Türkçe).
      5. Eğer harcama ise "type": "expense", gelir ise "type": "income" olsun.
      
      Örnek Çıktı:
      {
        "amount": 150.5,
        "category": "food",
        "description": "Öğle yemeği",
        "type": "expense"
      }
      ''';

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Gemini'nin yanıtını alalım
        final aiText = data['candidates'][0]['content']['parts'][0]['text'];

        // Temizlik: Bazen AI ```json ... ``` şeklinde döner, temizleyelim.
        final cleanJson =
            aiText.replaceAll('```json', '').replaceAll('```', '').trim();

        return jsonDecode(cleanJson);
      } else {
        print("AI Hatası: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("AI Servis Hatası: $e");
      return null;
    }
  }
}
