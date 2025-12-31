// lib/features/onboarding/presentation/screens/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/onboarding_provider.dart';
import '../../data/models/onboarding_data.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.watch(onboardingProvider);
    final question = OnboardingQuestions.questions[onboardingState.currentStep];

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
          child: Column(
            children: [
              // Progress Bar
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Adım ${onboardingState.currentStep + 1}/${OnboardingQuestions.questions.length}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        if (onboardingState.currentStep > 0)
                          IconButton(
                            onPressed: () {
                              ref
                                  .read(onboardingProvider.notifier)
                                  .previousStep();
                            },
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: onboardingState.progress,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                      borderRadius: BorderRadius.circular(10),
                      minHeight: 6,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Question Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      // Icon
                      Text(
                        question.icon,
                        style: const TextStyle(fontSize: 80),
                      ),

                      const SizedBox(height: 32),

                      // Question
                      Text(
                        question.question,
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),

                      const SizedBox(height: 48),

                      // Options
                      ...question.options.map((option) {
                        final isSelected =
                            onboardingState.answers[question.field] == option;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                ref
                                    .read(onboardingProvider.notifier)
                                    .nextStep(option);

                                // Son adımsa kaydet ve dashboard'a git
                                if (onboardingState.isComplete) {
                                  await ref
                                      .read(onboardingProvider.notifier)
                                      .saveToFirestore();

                                  if (context.mounted) {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (_) => const DashboardScreen(),
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.2),
                                foregroundColor: isSelected
                                    ? const Color(0xFF6366F1)
                                    : Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.5),
                                    width: 2,
                                  ),
                                ),
                                elevation: isSelected ? 8 : 0,
                              ),
                              child: Text(
                                option,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),

              // Bottom hint
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Cevabınızı seçin',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
