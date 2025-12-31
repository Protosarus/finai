// lib/features/onboarding/data/models/onboarding_data.dart

class OnboardingData {
  final String monthlyIncome;
  final String financialGoal;
  final String spendingFrequency;
  final String topCategory;
  final String experienceLevel;

  OnboardingData({
    required this.monthlyIncome,
    required this.financialGoal,
    required this.spendingFrequency,
    required this.topCategory,
    required this.experienceLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      'monthlyIncome': monthlyIncome,
      'financialGoal': financialGoal,
      'spendingFrequency': spendingFrequency,
      'topCategory': topCategory,
      'experienceLevel': experienceLevel,
      'completedAt': DateTime.now().toIso8601String(),
    };
  }

  factory OnboardingData.fromJson(Map<String, dynamic> json) {
    return OnboardingData(
      monthlyIncome: json['monthlyIncome'] ?? '',
      financialGoal: json['financialGoal'] ?? '',
      spendingFrequency: json['spendingFrequency'] ?? '',
      topCategory: json['topCategory'] ?? '',
      experienceLevel: json['experienceLevel'] ?? '',
    );
  }
}

// Onboarding soruları
class OnboardingQuestions {
  static const List<OnboardingQuestion> questions = [
    OnboardingQuestion(
      id: 1,
      question: 'Aylık geliriniz nedir?',
      field: 'monthlyIncome',
      options: [
        '0-5,000 TL',
        '5,000-15,000 TL',
        '15,000-30,000 TL',
        '30,000+ TL',
      ],
      icon: '💰',
    ),
    OnboardingQuestion(
      id: 2,
      question: 'Finansal hedefiniz nedir?',
      field: 'financialGoal',
      options: [
        'Borç ödemek',
        'Tasarruf yapmak',
        'Yatırım yapmak',
        'Bütçe kontrolü',
      ],
      icon: '🎯',
    ),
    OnboardingQuestion(
      id: 3,
      question: 'Ne sıklıkla harcama yaparsınız?',
      field: 'spendingFrequency',
      options: [
        'Her gün',
        'Haftada birkaç kez',
        'Haftada bir',
        'Ayda birkaç kez',
      ],
      icon: '📅',
    ),
    OnboardingQuestion(
      id: 4,
      question: 'En çok harcama yaptığınız kategori?',
      field: 'topCategory',
      options: [
        'Yemek & İçecek',
        'Ulaşım',
        'Alışveriş',
        'Faturalar',
        'Eğlence',
      ],
      icon: '🛒',
    ),
    OnboardingQuestion(
      id: 5,
      question: 'Finansal deneyim seviyeniz?',
      field: 'experienceLevel',
      options: [
        'Yeni başlayan',
        'Orta seviye',
        'İleri seviye',
      ],
      icon: '📊',
    ),
  ];
}

class OnboardingQuestion {
  final int id;
  final String question;
  final String field;
  final List<String> options;
  final String icon;

  const OnboardingQuestion({
    required this.id,
    required this.question,
    required this.field,
    required this.options,
    required this.icon,
  });
}
