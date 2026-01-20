import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finai/features/transactions/data/models/transaction_model.dart';
import 'package:finai/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:finai/core/services/voice_service.dart';
import 'package:finai/core/services/camera_service.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final TransactionType type;
  final bool autoStartVoice;

  const AddTransactionScreen({
    super.key,
    required this.type,
    this.autoStartVoice = false,
  });

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  TransactionCategory _selectedCategory = TransactionCategory.other;
  DateTime _selectedDate = DateTime.now();
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isFabMenuOpen = false;

  @override
  void initState() {
    super.initState();

    if (widget.type == TransactionType.expense) {
      _selectedCategory = TransactionCategory.food;
    } else {
      _selectedCategory = TransactionCategory.salary;
    }

    if (widget.autoStartVoice) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _startListening();
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool fromCamera) async {
    setState(() => _isFabMenuOpen = false);

    try {
      final cameraService = CameraService();
      final imagePath = fromCamera
          ? await cameraService.takePhoto()
          : await cameraService.pickFromGallery();

      if (imagePath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('📸 Fotoğraf alındı! OCR özelliği yakında eklenecek.'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kamera hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startListening() async {
    if (_isListening) return;

    setState(() {
      _isFabMenuOpen = false;
      _isListening = true;
    });

    try {
      final voiceService = VoiceService();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎤 Dinliyorum... Örnek: "50 TL market alışverişi"'),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF6366F1),
          ),
        );
      }

      final result = await voiceService.listen();

      if (result != null && result.isNotEmpty && mounted) {
        setState(() => _isProcessing = true);

        final analyzed = await voiceService.analyzeWithAI(result);

        if (analyzed != null && mounted) {
          setState(() {
            if (analyzed['amount'] != null) {
              _amountController.text = analyzed['amount'].toString();
            }

            if (analyzed['description'] != null) {
              _descriptionController.text = analyzed['description'];
            }

            if (analyzed['category'] != null) {
              _selectedCategory = _mapAICategory(analyzed['category']);
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('✅ ${analyzed['description'] ?? 'İşlem algılandı!'}'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Komut anlaşılamadı, lütfen tekrar deneyin'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔇 Ses algılanamadı'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isListening = false;
          _isProcessing = false;
        });
      }
    }
  }

  TransactionCategory _mapAICategory(String aiCategory) {
    switch (aiCategory.toLowerCase()) {
      case 'food':
        return TransactionCategory.food;
      case 'transport':
        return TransactionCategory.transport;
      case 'shopping':
        return TransactionCategory.shopping;
      case 'bills':
        return TransactionCategory.bills;
      case 'entertainment':
        return TransactionCategory.entertainment;
      case 'health':
        return TransactionCategory.health;
      case 'education':
        return TransactionCategory.education;
      case 'salary':
        return TransactionCategory.salary;
      case 'freelance':
        return TransactionCategory.freelance;
      case 'investment':
        return TransactionCategory.investment;
      default:
        return TransactionCategory.other;
    }
  }

  Future<void> _saveTransaction() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Lütfen tutar girin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Geçerli bir tutar girin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await ref.read(transactionProvider.notifier).addTransaction(
            type: widget.type,
            category: _selectedCategory,
            amount: amount,
            description: _descriptionController.text.isEmpty
                ? _selectedCategory.displayName
                : _descriptionController.text,
            date: _selectedDate,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ ${widget.type == TransactionType.expense ? "Gider" : "Gelir"} eklendi!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = widget.type == TransactionType.expense;
    final mainColor =
        isExpense ? const Color(0xFFEF4444) : const Color(0xFF10B981);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;

    final amountBoxColor = Colors.white;
    final amountTextColor = Colors.black;

    final cardColor = isDarkMode ? const Color(0xFF2C2C2C) : Colors.white;
    final borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;

    final categories = isExpense
        ? TransactionCategoryExtension.getExpenseCategories()
        : TransactionCategoryExtension.getIncomeCategories();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.close, size: 28, color: textColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          isExpense ? 'Gider Ekle' : 'Gelir Ekle',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                      if (_isProcessing)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tutar',
                            style: TextStyle(
                                color: textColor.withOpacity(0.7),
                                fontSize: 16)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 8),
                          decoration: BoxDecoration(
                            color: amountBoxColor,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            style: TextStyle(
                              color: amountTextColor,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: '0',
                              hintStyle: TextStyle(
                                  color: amountTextColor.withOpacity(0.5)),
                              prefixText: '₺',
                              prefixStyle: TextStyle(
                                  color: amountTextColor.withOpacity(0.5),
                                  fontSize: 40),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text('Kategori',
                            style: TextStyle(
                                color: textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: categories.map((cat) {
                            final isSelected = _selectedCategory == cat;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedCategory = cat),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? mainColor.withOpacity(0.1)
                                      : cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? mainColor : borderColor,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(cat.icon,
                                        style: const TextStyle(fontSize: 18)),
                                    const SizedBox(width: 8),
                                    Text(
                                      cat.displayName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color:
                                            isSelected ? mainColor : textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 32),
                        Text('Açıklama (İsteğe bağlı)',
                            style: TextStyle(
                                color: textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _descriptionController,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            hintText: 'Örn: Haftalık market alışverişi',
                            hintStyle:
                                TextStyle(color: textColor.withOpacity(0.5)),
                            filled: true,
                            fillColor: cardColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide:
                                  BorderSide(color: mainColor, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text('Tarih',
                            style: TextStyle(
                                color: textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                              builder: (context, child) {
                                return Theme(
                                  data: isDarkMode
                                      ? ThemeData.dark()
                                      : ThemeData.light(),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() => _selectedDate = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_rounded,
                                    color: mainColor),
                                const SizedBox(width: 12),
                                Text(
                                  "${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: textColor),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _saveTransaction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        elevation: 5,
                        shadowColor: mainColor.withOpacity(0.4),
                      ),
                      child: Text(
                        isExpense ? 'Gider Ekle' : 'Gelir Ekle',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // FAB Menü - Yukarıda
          if (_isFabMenuOpen) ...[
            Positioned(
              right: 16,
              bottom: 200,
              child: _buildFabMenuItem(
                icon: Icons.camera_alt,
                label: 'Fotoğraf Çek',
                color: Colors.blue,
                isDarkMode: isDarkMode,
                onTap: () => _pickImage(true),
              ),
            ),
            Positioned(
              right: 16,
              bottom: 140,
              child: _buildFabMenuItem(
                icon: Icons.image,
                label: 'Galeri',
                color: Colors.purple,
                isDarkMode: isDarkMode,
                onTap: () => _pickImage(false),
              ),
            ),
            Positioned(
              right: 16,
              bottom: 80,
              child: _buildFabMenuItem(
                icon: _isListening ? Icons.mic : Icons.mic_none,
                label: _isListening ? 'Dinleniyor' : 'Sesli Komut',
                color: _isListening ? Colors.red : mainColor,
                isDarkMode: isDarkMode,
                onTap: _startListening,
              ),
            ),
          ],

          // ARTI BUTONU - MANUEL POZİSYON (SABİT)
          Positioned(
            right: 16,
            bottom: 16,
            child: Material(
              elevation: 6,
              shape: const CircleBorder(),
              color: mainColor,
              child: InkWell(
                onTap: () {
                  setState(() => _isFabMenuOpen = !_isFabMenuOpen);
                },
                customBorder: const CircleBorder(),
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _isFabMenuOpen ? Icons.close : Icons.add,
                      key: ValueKey(_isFabMenuOpen),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFabMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }
}
