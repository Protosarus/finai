import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:quick_actions/quick_actions.dart';

// --- KENDİ DOSYALARIMIZ ---
import 'firebase_options.dart';
import 'core/theme/app_theme.dart'; // Tema dosyamız
import 'core/providers/theme_provider.dart'; // Tema yöneticimiz
import 'core/widgets/phoenix.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/language/presentation/screens/language_selection_screen.dart';
import 'l10n/app_localizations_delegate.dart';

// Quick Actions yönlendirmesi için gerekli
import 'features/transactions/presentation/screens/add_transaction_screen.dart';
import 'features/transactions/data/models/transaction_model.dart';

// Uygulama genelinde navigasyonu yönetmek için anahtar
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sadece dikey kullanım
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // .env yükleme
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('⚠️ .env file not found');
  }

  // Firebase başlatma
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Hive (Veritabanı) başlatma
  await Hive.initFlutter();

  runApp(
    Phoenix(
      child: const ProviderScope(
        child: FinAIApp(),
      ),
    ),
  );
}

class FinAIApp extends ConsumerStatefulWidget {
  const FinAIApp({super.key});

  @override
  ConsumerState<FinAIApp> createState() => _FinAIAppState();
}

class _FinAIAppState extends ConsumerState<FinAIApp> {
  Locale _locale = const Locale('en'); // Varsayılan dil
  final QuickActions quickActions = const QuickActions();

  @override
  void initState() {
    super.initState();
    _loadLocale();
    _setupQuickActions();
  }

  // --- DİL AYARINI YÜKLE ---
  Future<void> _loadLocale() async {
    final box = await Hive.openBox('settings');
    final languageCode = box.get('language', defaultValue: 'en');
    setState(() {
      _locale = Locale(languageCode);
    });
  }

  // --- HIZLI EYLEMLER (BASILI TUTUNCA ÇIKAN MENÜ) ---
  void _setupQuickActions() {
    quickActions.initialize((shortcutType) {
      if (shortcutType == 'voice_expense') {
        // Uygulama açılınca biraz bekle ve sayfaya git
        Future.delayed(const Duration(milliseconds: 500), () {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => const AddTransactionScreen(
                type: TransactionType.expense,
                autoStartVoice: true, // Otomatik mikrofon aç
              ),
            ),
          );
        });
      }
    });

    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
        type: 'voice_expense',
        localizedTitle: 'Sesli Gider Ekle',
        icon: 'mic',
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    // Temayı Provider'dan dinliyoruz (Canlı değişim için)
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'FinAI Coach',
      navigatorKey: navigatorKey, // Navigasyon anahtarını bağladık
      debugShowCheckedModeBanner: false,

      // --- TEMA AYARLARI ---
      themeMode: themeMode, // Sistem, Açık veya Koyu
      theme: AppTheme.lightTheme, // Aydınlık Tema
      darkTheme: AppTheme.darkTheme, // Karanlık Tema (Artık bağlı!)

      // --- DİL AYARLARI ---
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('tr'),
      ],

      // --- BAŞLANGIÇ EKRANI ---
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // 2 saniye splash göster
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      // Dil seçimi yapılmış mı kontrol et
      final box = await Hive.openBox('settings');
      final selectedLanguage = box.get('language');

      if (selectedLanguage == null) {
        // Dil seçilmemiş -> Dil Seçimi Ekranı
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
        );
      } else {
        // Dil seçilmiş -> Giriş Ekranı
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  size: 60,
                  color: Color(0xFF6366F1),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'FinAI Coach',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Yapay Zeka Destekli Finans Asistanı',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
