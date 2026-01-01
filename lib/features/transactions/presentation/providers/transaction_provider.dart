// lib/features/transactions/presentation/providers/transaction_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/transaction_model.dart';

class TransactionState {
  final List<TransactionModel> transactions;
  final bool isLoading;
  final String? error;

  TransactionState({
    this.transactions = const [],
    this.isLoading = false,
    this.error,
  });

  TransactionState copyWith({
    List<TransactionModel>? transactions,
    bool? isLoading,
    String? error,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  // Calculate total income
  double get totalIncome {
    return transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0, (sum, t) => sum + t.amount);
  }

  // Calculate total expense
  double get totalExpense {
    return transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (sum, t) => sum + t.amount);
  }

  // Calculate balance
  double get balance => totalIncome - totalExpense;

  // Get transactions for current month
  List<TransactionModel> get currentMonthTransactions {
    final now = DateTime.now();
    return transactions.where((t) {
      return t.date.year == now.year && t.date.month == now.month;
    }).toList();
  }

  // Monthly income
  double get monthlyIncome {
    return currentMonthTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0, (sum, t) => sum + t.amount);
  }

  // Monthly expense
  double get monthlyExpense {
    return currentMonthTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (sum, t) => sum + t.amount);
  }

  // Monthly balance
  double get monthlyBalance => monthlyIncome - monthlyExpense;
}

class TransactionNotifier extends StateNotifier<TransactionState> {
  TransactionNotifier() : super(TransactionState());

  // Add transaction
  Future<void> addTransaction({
    required TransactionType type,
    required TransactionCategory category,
    required double amount,
    required String description,
    required DateTime date,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw 'Kullanıcı oturumu bulunamadı';
      }

      final transaction = TransactionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.uid,
        type: type,
        category: category,
        amount: amount,
        description: description,
        date: date,
        createdAt: DateTime.now(),
      );

      // TODO: Save to Firestore
      // await FirebaseFirestore.instance
      //     .collection('transactions')
      //     .doc(transaction.id)
      //     .set(transaction.toJson());

      // Add to local state
      final updatedTransactions = [...state.transactions, transaction];

      // Sort by date (newest first)
      updatedTransactions.sort((a, b) => b.date.compareTo(a.date));

      state = state.copyWith(
        transactions: updatedTransactions,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'İşlem eklenemedi: ${e.toString()}',
      );
      rethrow;
    }
  }

  // Delete transaction
  Future<void> deleteTransaction(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // TODO: Delete from Firestore
      // await FirebaseFirestore.instance
      //     .collection('transactions')
      //     .doc(id)
      //     .delete();

      // Remove from local state
      final updatedTransactions =
          state.transactions.where((t) => t.id != id).toList();

      state = state.copyWith(
        transactions: updatedTransactions,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'İşlem silinemedi: ${e.toString()}',
      );
      rethrow;
    }
  }

  // Load transactions
  Future<void> loadTransactions() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw 'Kullanıcı oturumu bulunamadı';
      }

      // TODO: Load from Firestore
      // final snapshot = await FirebaseFirestore.instance
      //     .collection('transactions')
      //     .where('userId', isEqualTo: user.uid)
      //     .orderBy('date', descending: true)
      //     .get();

      // final transactions = snapshot.docs
      //     .map((doc) => TransactionModel.fromJson(doc.data()))
      //     .toList();

      state = state.copyWith(
        transactions: [], // Will be loaded from Firestore
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'İşlemler yüklenemedi: ${e.toString()}',
      );
    }
  }
}

// Provider
final transactionProvider =
    StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
  return TransactionNotifier();
});
