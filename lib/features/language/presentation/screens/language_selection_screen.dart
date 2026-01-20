// lib/features/language/presentation/screens/language_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/widgets/phoenix.dart';
import '../../../auth/presentation/screens/login_screen.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  Future<void> _selectLanguage(
      BuildContext context, String languageCode) async {
    // Save selected language to Hive
    final box = await Hive.openBox('settings');
    await box.put('language', languageCode);

    if (context.mounted) {
      // Restart the entire app to apply new language
      Phoenix.rebirth(context);

      // Navigate to login screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildLanguageCard({
    required BuildContext context,
    required String flag,
    required String name, // Tek bir isim alacak (English veya Türkçe)
    required String languageCode,
  }) {
    return InkWell(
      onTap: () => _selectLanguage(context, languageCode),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24, // Yazıyı biraz büyüttüm, daha net olsun
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.6),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Spacer(flex: 1), // Üstten biraz boşluk bırakır

                // App Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    size: 60,
                    color: Color(0xFF6366F1),
                  ),
                ),

                const SizedBox(height: 32),

                // App Title
                Text(
                  'FinAI Coach',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),

                // BURADAKİ İNGİLİZCE YAZILARI SİLDİK

                const SizedBox(height: 80),

                // Language Options
                _buildLanguageCard(
                  context: context,
                  flag: '🇬🇧',
                  name: 'English', // Sadece English
                  languageCode: 'en',
                ),

                const SizedBox(height: 20),

                _buildLanguageCard(
                  context: context,
                  flag: '🇹🇷',
                  name: 'Türkçe', // Sadece Türkçe
                  languageCode: 'tr',
                ),

                const Spacer(flex: 2), // Alttan daha fazla boşluk bırakır
              ],
            ),
          ),
        ),
      ),
    );
  }
}
