// lib/core/services/voice_service.dart

import 'package:speech_to_text/speech_to_text.dart';
import 'dart:async';

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;

  Future<bool> initialize() async {
    // speech_to_text handles permissions automatically
    return await _speech.initialize(
      onError: (error) => print('Speech error: $error'),
      onStatus: (status) => print('Speech status: $status'),
    );
  }

  Future<String?> listen() async {
    if (!_speech.isAvailable) {
      final initialized = await initialize();
      if (!initialized) {
        return null;
      }
    }

    final completer = Completer<String?>();
    String? result;

    await _speech.listen(
      onResult: (speechResult) {
        result = speechResult.recognizedWords;
        if (speechResult.finalResult) {
          if (!completer.isCompleted) {
            completer.complete(result);
          }
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
        const Duration(seconds: 15),
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

  bool get isListening => _isListening;

  Map<String, dynamic> parseCommand(String command) {
    final amountPattern = RegExp(r'(\d+)\s*(tl|lira)', caseSensitive: false);

    final amountMatch = amountPattern.firstMatch(command);
    final amount = amountMatch != null
        ? double.tryParse(amountMatch.group(1) ?? '0')
        : null;

    String? category;
    final lowerCommand = command.toLowerCase();

    if (lowerCommand.contains('market') || lowerCommand.contains('yemek')) {
      category = 'food';
    } else if (lowerCommand.contains('benzin') ||
        lowerCommand.contains('ulaşım')) {
      category = 'transport';
    } else if (lowerCommand.contains('alışveriş')) {
      category = 'shopping';
    } else if (lowerCommand.contains('fatura')) {
      category = 'bills';
    }

    return {
      'amount': amount,
      'category': category,
      'description': command,
    };
  }
}
