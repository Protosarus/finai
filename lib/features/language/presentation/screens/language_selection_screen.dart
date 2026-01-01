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
    required String language,
    required String nativeName,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    nativeName,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                ],
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
                const SizedBox(height: 60),

                // App Icon
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
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
                    size: 56,
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

                const SizedBox(height: 80),

                // Title
                const Text(
                  'Select Language',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Choose your preferred language',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 17,
                  ),
                ),

                const SizedBox(height: 60),

                // Language Options
                _buildLanguageCard(
                  context: context,
                  flag: '🇬🇧',
                  language: 'English',
                  nativeName: 'English',
                  languageCode: 'en',
                ),

                const SizedBox(height: 20),

                _buildLanguageCard(
                  context: context,
                  flag: '🇹🇷',
                  language: 'Turkish',
                  nativeName: 'Türkçe',
                  languageCode: 'tr',
                ),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
