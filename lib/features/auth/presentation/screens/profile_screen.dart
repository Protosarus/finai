import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finai/features/auth/presentation/screens/login_screen.dart';
import 'package:finai/core/providers/theme_provider.dart';
import 'package:finai/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:finai/features/transactions/data/models/transaction_model.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _user = FirebaseAuth.instance.currentUser;

  bool _isEditing = false;
  bool _isLoading = false;

  bool _notificationsEnabled = true;
  String _currency = 'TRY';
  double _budgetLimit = 20000;

  @override
  void initState() {
    super.initState();
    _nameController.text = _user?.displayName ?? '';
    _phoneController.text = _user?.phoneNumber ?? '';
    _loadSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final box = await Hive.openBox('settings');
    if (mounted) {
      setState(() {
        _budgetLimit = box.get('budgetLimit', defaultValue: 20000.0);
        _currency = box.get('currency', defaultValue: 'TRY');
        _notificationsEnabled = box.get('notifications', defaultValue: true);
      });
    }
  }

  // Finansal Arketip Hesapla
  Map<String, dynamic> _calculateArchetype() {
    final transactionState = ref.watch(transactionProvider);

    final monthlyIncome = transactionState.monthlyIncome;
    final monthlyExpense = transactionState.monthlyExpense;

    if (monthlyIncome == 0) {
      return {
        'name': 'Yeni Başlayan',
        'icon': '🌱',
        'color': Colors.blue,
        'description': 'İlk adımlarını atıyorsun!',
      };
    }

    final spendingRatio = monthlyExpense / monthlyIncome;

    if (spendingRatio >= 0.8) {
      return {
        'name': 'Müsrif',
        'icon': '💸',
        'color': Colors.red,
        'description':
            'Gelirinin %${(spendingRatio * 100).toInt()}\'unu harcıyorsun!',
      };
    } else if (spendingRatio >= 0.5) {
      return {
        'name': 'Dengeli',
        'icon': '⚖️',
        'color': Colors.orange,
        'description': 'Makul bir harcama dengesi',
      };
    } else if (spendingRatio >= 0.3) {
      return {
        'name': 'Tutumlu',
        'icon': '💰',
        'color': Colors.green,
        'description': 'Tasarruf etmeyi seviyorsun!',
      };
    } else {
      return {
        'name': 'Tasarruf Ustası',
        'icon': '🏆',
        'color': const Color(0xFFFFD700),
        'description': 'Mükemmel finansal disiplin!',
      };
    }
  }

  // En çok harcanan kategori
  String _getTopCategory() {
    final transactionState = ref.watch(transactionProvider);
    final monthlyTransactions = transactionState.currentMonthTransactions
        .where((t) => t.type.name == 'expense')
        .toList();

    if (monthlyTransactions.isEmpty) return 'Henüz yok';

    final categoryTotals = <String, double>{};
    for (var transaction in monthlyTransactions) {
      final category = transaction.category.displayName;
      categoryTotals[category] =
          (categoryTotals[category] ?? 0) + transaction.amount;
    }

    final topEntry =
        categoryTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
    return topEntry.key;
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      await _user?.updateDisplayName(_nameController.text.trim());
      await _user?.reload();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profil güncellendi ✅'),
              backgroundColor: Colors.green),
        );
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Oturumu kapatmak istediğinize emin misiniz?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Çıkış Yap',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showBudgetDialog() {
    final controller =
        TextEditingController(text: _budgetLimit.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aylık Bütçe Limiti'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bu tutarı aştığınızda sizi uyaracağız.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: '₺ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              final newValue = double.tryParse(controller.text) ?? _budgetLimit;
              final box = await Hive.openBox('settings');
              await box.put('budgetLimit', newValue);

              setState(() {
                _budgetLimit = newValue;
              });
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showCurrencyDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Para Birimi Seçin',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildCurrencyOption('Türk Lirası', 'TRY', '₺'),
            _buildCurrencyOption('Amerikan Doları', 'USD', '\$'),
            _buildCurrencyOption('Euro', 'EUR', '€'),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyOption(String name, String code, String symbol) {
    final isSelected = _currency == code;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6366F1).withOpacity(0.1)
              : Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Text(symbol,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF6366F1) : Colors.black)),
      ),
      title: Text(name),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Color(0xFF6366F1))
          : null,
      onTap: () async {
        final box = await Hive.openBox('settings');
        await box.put('currency', code);
        setState(() => _currency = code);
        if (mounted) Navigator.pop(context);
      },
    );
  }

  void _showExportDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Verileri Dışa Aktar',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Tüm harcama geçmişinizi raporlayın.',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                    child: _buildExportButton(
                        Icons.table_chart, 'Excel (.xlsx)', Colors.green)),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildExportButton(
                        Icons.picture_as_pdf, 'PDF Raporu', Colors.red)),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton(IconData icon, String label, Color color) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rapor hazırlanıyor... (Demo)')),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;
    final backgroundColor =
        isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F7FA);
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF2D3142);

    final transactionState = ref.watch(transactionProvider);
    final archetype = _calculateArchetype();
    final topCategory = _getTopCategory();

    final dailyAverage = transactionState.currentMonthTransactions.isEmpty
        ? 0.0
        : transactionState.monthlyExpense / DateTime.now().day;

    final initial = _user?.displayName?.isNotEmpty == true
        ? _user!.displayName![0].toUpperCase()
        : 'K';

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- ÜST HEADER ---
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10, right: 20),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          onPressed: () =>
                              setState(() => _isEditing = !_isEditing),
                          icon: Icon(_isEditing ? Icons.close : Icons.edit,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -50,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration:
                        BoxDecoration(color: cardColor, shape: BoxShape.circle),
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: const Color(0xFFE0E7FF),
                      backgroundImage: _user?.photoURL != null
                          ? NetworkImage(_user!.photoURL!)
                          : null,
                      child: _user?.photoURL == null
                          ? Text(initial,
                              style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6366F1)))
                          : null,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 60),

            // Kullanıcı Bilgisi
            if (!_isEditing) ...[
              Text(
                _user?.displayName ?? 'Kullanıcı',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor),
              ),
              Text(_user?.email ?? '',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            ],

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- FİNANSAL ARKETİP KARTI ---
                  if (!_isEditing) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            (archetype['color'] as Color).withOpacity(0.8),
                            (archetype['color'] as Color).withOpacity(0.4),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (archetype['color'] as Color).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            archetype['icon'],
                            style: const TextStyle(fontSize: 60),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Finansal Arketip',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            archetype['name'],
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            archetype['description'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- BU AY İSTATİSTİKLER ---
                    _buildSectionHeader('Bu Ay', isDarkMode),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            '₺${transactionState.monthlyExpense.toStringAsFixed(0)}',
                            'Harcama',
                            Icons.arrow_upward,
                            Colors.red,
                            cardColor,
                            textColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            '₺${dailyAverage.toStringAsFixed(0)}',
                            'Günlük Ort.',
                            Icons.calendar_today,
                            Colors.blue,
                            cardColor,
                            textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildStatCard(
                      topCategory,
                      'En Çok Harcanan',
                      Icons.star,
                      Colors.orange,
                      cardColor,
                      textColor,
                    ),

                    const SizedBox(height: 30),
                  ],

                  // --- DÜZENLEME MODU ---
                  if (_isEditing) ...[
                    _buildSectionHeader('Profili Düzenle', isDarkMode),
                    _buildTextField(
                        label: 'Ad Soyad',
                        controller: _nameController,
                        icon: Icons.person_outline,
                        cardColor: cardColor),
                    const SizedBox(height: 12),
                    _buildTextField(
                        label: 'Telefon',
                        controller: _phoneController,
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        cardColor: cardColor),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('Kaydet',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],

                  // --- FİNANSAL AYARLAR ---
                  _buildSectionHeader('Finansal Ayarlar', isDarkMode),
                  _buildMenuTile(
                    title: 'Aylık Bütçe Limiti',
                    subtitle: '₺${_budgetLimit.toStringAsFixed(0)}',
                    icon: Icons.account_balance_wallet_outlined,
                    onTap: _showBudgetDialog,
                    cardColor: cardColor,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 12),
                  _buildMenuTile(
                    title: 'Para Birimi',
                    subtitle: _currency,
                    icon: Icons.currency_exchange,
                    onTap: _showCurrencyDialog,
                    cardColor: cardColor,
                    textColor: textColor,
                  ),

                  const SizedBox(height: 24),

                  // --- UYGULAMA AYARLARI ---
                  _buildSectionHeader('Uygulama', isDarkMode),
                  _buildSwitchTile(
                    title: 'Bildirimler',
                    icon: Icons.notifications_outlined,
                    value: _notificationsEnabled,
                    onChanged: (val) async {
                      final box = await Hive.openBox('settings');
                      await box.put('notifications', val);
                      setState(() => _notificationsEnabled = val);
                    },
                    cardColor: cardColor,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 12),
                  _buildSwitchTile(
                    title: 'Karanlık Mod',
                    icon: Icons.dark_mode_outlined,
                    value: isDarkMode,
                    onChanged: (val) {
                      ref.read(themeProvider.notifier).toggleTheme(val);
                    },
                    cardColor: cardColor,
                    textColor: textColor,
                  ),

                  const SizedBox(height: 24),

                  // --- VERİ YÖNETİMİ ---
                  _buildSectionHeader('Veri Yönetimi', isDarkMode),
                  _buildMenuTile(
                    title: 'Dışa Aktar (Excel/PDF)',
                    icon: Icons.download_outlined,
                    onTap: _showExportDialog,
                    cardColor: cardColor,
                    textColor: textColor,
                  ),

                  const SizedBox(height: 32),

                  // --- ÇIKIŞ ---
                  _buildMenuTile(
                    title: 'Çıkış Yap',
                    icon: Icons.logout,
                    color: Colors.red[50],
                    iconColor: Colors.red,
                    textColor: Colors.red,
                    onTap: _handleLogout,
                    cardColor: cardColor,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color,
      Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.grey[400] : Colors.grey),
      ),
    );
  }

  Widget _buildTextField(
      {required String label,
      required TextEditingController controller,
      required IconData icon,
      required Color cardColor,
      TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
          color: cardColor, borderRadius: BorderRadius.circular(16)),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF6366F1)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildMenuTile(
      {required String title,
      String? subtitle,
      required IconData icon,
      required VoidCallback onTap,
      Color? color,
      Color? iconColor,
      Color? textColor,
      required Color cardColor}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color ?? cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color:
                        (iconColor ?? const Color(0xFF6366F1)).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon,
                    color: iconColor ?? const Color(0xFF6366F1), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 16, color: (textColor ?? Colors.grey).withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
      {required String title,
      required IconData icon,
      required bool value,
      required Function(bool) onChanged,
      required Color cardColor,
      required Color textColor}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: const Color(0xFF6366F1), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF6366F1),
          ),
        ],
      ),
    );
  }
}
