// lib/l10n/app_localizations_delegate.dart

import 'package:flutter/material.dart';
import 'app_localizations.dart';
import 'app_en.dart';
import 'app_tr.dart';

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Sadece İngilizce ve Türkçe destekleniyor
    return ['en', 'tr'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    // Locale'e göre doğru çeviri sınıfını döndür
    switch (locale.languageCode) {
      case 'tr':
        return AppLocalizationsTr();
      case 'en':
      default:
        return AppLocalizationsEn();
    }
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}