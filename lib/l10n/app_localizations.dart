// lib/l10n/app_localizations.dart

import 'package:flutter/material.dart';

abstract class AppLocalizations {
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  // Language Selection Screen
  String get selectLanguage;
  String get chooseYourLanguage;
  String get continue_;

  // Auth Screens
  String get welcomeBack;
  String get appSubtitle;
  String get email;
  String get password;
  String get login;
  String get or;
  String get noAccount;
  String get register;
  String get createAccount;
  String get alreadyHaveAccount;
  String get name;
  String get confirmPassword;

  // Validation
  String get emailRequired;
  String get emailInvalid;
  String get passwordRequired;
  String get passwordTooShort;
  String get nameRequired;
  String get passwordsDoNotMatch;

  // Dashboard
  String get dashboard;
  String get totalIncome;
  String get totalExpense;
  String get balance;
  String get recentTransactions;
  String get addTransaction;

  // Transaction Categories
  String get food;
  String get transport;
  String get shopping;
  String get bills;
  String get entertainment;
  String get health;
  String get education;

  // Transaction Screen
  String get amount;
  String get category;
  String get description;
  String get date;
  String get save;
  String get cancel;

  // Camera & Voice
  String get takePhoto;
  String get chooseFromGallery;
  String get photoTaken;
  String get ocrComingSoon;
  String get listening;
  String get voiceExample;
  String get commandReceived;
  String get microphonePermissionRequired;
  String get cameraPermissionDenied;

  // Messages
  String get appleSignInComingSoon;
}
