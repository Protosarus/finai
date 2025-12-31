// lib/features/onboarding/presentation/providers/onboarding_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/onboarding_data.dart';

class OnboardingState {
  final int currentStep;
  final Map<String, String> answers;
  final bool isLoading;
  final String? error;

  OnboardingState({
    this.currentStep = 0,
    this.answers = const {},
    this.isLoading = false,
    this.error,
  });

  OnboardingState copyWith({
    int? currentStep,
    Map<String, String>? answers,
    bool? isLoading,
    String? error,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      answers: answers ?? this.answers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  double get progress =>
      (currentStep + 1) / OnboardingQuestions.questions.length;

  bool get isComplete =>
      currentStep >= OnboardingQuestions.questions.length - 1;
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(OnboardingState());

  void nextStep(String answer) {
    final question = OnboardingQuestions.questions[state.currentStep];
    final updatedAnswers = Map<String, String>.from(state.answers);
    updatedAnswers[question.field] = answer;

    state = state.copyWith(
      currentStep: state.currentStep + 1,
      answers: updatedAnswers,
    );
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(
        currentStep: state.currentStep - 1,
      );
    }
  }

  void reset() {
    state = OnboardingState();
  }

  OnboardingData getOnboardingData() {
    return OnboardingData(
      monthlyIncome: state.answers['monthlyIncome'] ?? '',
      financialGoal: state.answers['financialGoal'] ?? '',
      spendingFrequency: state.answers['spendingFrequency'] ?? '',
      topCategory: state.answers['topCategory'] ?? '',
      experienceLevel: state.answers['experienceLevel'] ?? '',
    );
  }

  Future<void> saveToFirestore() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // TODO: Firestore'a kaydet
      // final user = FirebaseAuth.instance.currentUser;
      // await FirebaseFirestore.instance
      //     .collection('users')
      //     .doc(user?.uid)
      //     .update({
      //   'onboarding': getOnboardingData().toJson(),
      // });

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Veriler kaydedilemedi: ${e.toString()}',
      );
    }
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier();
});
