import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Temayı yöneten Riverpod Provider'ı
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  // Başlangıçta sistem temasını kullan
  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  // Hafızadan (Hive) tema tercihini oku
  void _loadTheme() async {
    final box = await Hive.openBox('settings');
    // Varsayılan olarak karanlık mod kapalı (false)
    final isDark = box.get('darkMode', defaultValue: false);
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  // Temayı değiştir ve hafızaya kaydet
  Future<void> toggleTheme(bool isDark) async {
    final box = await Hive.openBox('settings');
    await box.put('darkMode', isDark);
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }
}
