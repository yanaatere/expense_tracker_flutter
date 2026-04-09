import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_colors_theme.dart';
import 'core/models/recurring_transaction.dart';
import 'core/services/api_client.dart';
import 'core/models/wallet.dart';
import 'core/storage/local_storage.dart';
import 'features/auth/create_account_screen.dart';
import 'features/onboarding/select_language_screen.dart';
import 'features/onboarding/setup_wallet_screen.dart';
import 'features/transactions/add_transaction_screen.dart';
import 'features/transactions/edit_transaction_screen.dart';
import 'features/transactions/recent_transaction_full_page.dart';
import 'features/transactions/transaction_detail_screen.dart';
import 'features/wallet/wallet_screen.dart';
import 'features/wallet/wallet_detail_screen.dart';
import 'features/wallet/wallet_edit_screen.dart';
import 'features/wallet/wallet_info_screen.dart';
import 'features/wallet/wallet_expense_screen.dart';
import 'features/wallet/wallet_income_screen.dart';
import 'features/wallet/wallet_transaction_screen.dart';
import 'service_locator.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/auth/pin_login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/account/account_info_screen.dart';
import 'features/account/activate_pin_screen.dart';
import 'features/account/categories_screen.dart';
import 'features/budget/budget_screen.dart';
import 'features/premium/premium_screen.dart';
import 'features/account/edit_profile_screen.dart';
import 'features/account/pin_setup_screen.dart';
import 'features/recurring/recurring_screen.dart';
import 'features/recurring/add_recurring_screen.dart';
import 'features/recurring/recurring_detail_screen.dart';
import 'features/welcome/welcome_screen.dart';
import 'features/ai/ai_chat_screen.dart';
import 'features/ai/ai_report_screen.dart';

class MonexApp extends StatefulWidget {
  const MonexApp({super.key});

  @override
  State<MonexApp> createState() => _MonexAppState();
}

class _MonexAppState extends State<MonexApp> with WidgetsBindingObserver {
  // Guard against concurrent session-expiry checks (router redirect + resume).
  bool _checkingExpiry = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ApiClient.onUnauthorized = () {
      LocalStorage.clearAll();
      _router.go('/signin');
    };
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App went to background — save timestamp
      LocalStorage.saveLastActiveAt();
    } else if (state == AppLifecycleState.resumed) {
      // App came back to foreground — check expiration
      _checkSessionExpiry();
    }
  }

  Future<void> _checkSessionExpiry() async {
    if (_checkingExpiry) return;
    _checkingExpiry = true;
    try {
      final expired = await LocalStorage.isSessionExpired();
      if (expired) {
        if (await LocalStorage.isPinEnabled()) {
          await LocalStorage.clearLastActiveAt();
          _router.go('/pin-login');
        } else {
          await LocalStorage.clearAll();
          _router.go('/signin');
        }
      }
    } finally {
      _checkingExpiry = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: ServiceLocator.localeNotifier,
      builder: (context, locale, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: ServiceLocator.themeNotifier,
          builder: (context, themeMode, _) {
            return MaterialApp.router(
              title: 'Monex Finance',
              debugShowCheckedModeBanner: false,
              locale: locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en'),
                Locale('id'),
              ],
              theme: AppColorsTheme.lightThemeData,
              darkTheme: AppColorsTheme.darkThemeData,
              themeMode: themeMode,
              routerConfig: _router,
            );
          },
        );
      },
    );
  }
}

final _router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final isAuth = await ServiceLocator.authRepository.isAuthenticated();
    final loc = state.matchedLocation;
    final isOnboarding = loc.startsWith('/onboarding');
    final isAuthScreen = loc == '/signin' || loc == '/create-account';

    if (!isAuth) return null;

    // Session expired after being killed in background
    if (await LocalStorage.isSessionExpired()) {
      if (await LocalStorage.isPinEnabled()) {
        await LocalStorage.clearLastActiveAt();
        if (loc == '/pin-login') return null;
        return '/pin-login';
      }
      await LocalStorage.clearAll();
      return '/signin';
    }

    final onboardingDone = await LocalStorage.isOnboardingCompleted();
    if (!onboardingDone && !isOnboarding) return '/onboarding/language';
    // Redirect auth / welcome screens to home when already authenticated
    if (onboardingDone && (isAuthScreen || loc == '/')) return '/home';
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/signin',
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: '/create-account',
      builder: (context, state) => const CreateAccountScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/onboarding/language',
      builder: (context, state) => const SelectLanguageScreen(),
    ),
    GoRoute(
      path: '/onboarding/wallet',
      builder: (context, state) {
        final extra = state.extra as Map<String, String?>?;
        return SetupWalletScreen(
          returnRoute: extra?['returnRoute'] ?? '/home',
          initialType: extra?['initialType'] ?? 'Bank',
        );
      },
    ),
    GoRoute(
      path: '/wallet',
      builder: (context, state) => const WalletScreen(),
    ),
    GoRoute(
      path: '/wallet/detail',
      builder: (context, state) {
        final wallet = state.extra as Wallet?;
        if (wallet == null) return const WalletScreen();
        return WalletDetailScreen(wallet: wallet);
      },
    ),
    GoRoute(
      path: '/wallet/edit',
      builder: (context, state) {
        final wallet = state.extra as Wallet?;
        if (wallet == null) return const WalletScreen();
        return WalletEditScreen(wallet: wallet);
      },
    ),
    GoRoute(
      path: '/wallet/info',
      builder: (context, state) {
        final wallet = state.extra as Wallet?;
        if (wallet == null) return const WalletScreen();
        return WalletInfoScreen(wallet: wallet);
      },
    ),
    GoRoute(
      path: '/wallet/transactions',
      builder: (context, state) {
        final wallet = state.extra as Wallet?;
        if (wallet == null) return const WalletScreen();
        return WalletTransactionScreen(wallet: wallet);
      },
    ),
    GoRoute(
      path: '/wallet/income',
      builder: (context, state) {
        final wallet = state.extra as Wallet?;
        if (wallet == null) return const WalletScreen();
        return WalletIncomeScreen(wallet: wallet);
      },
    ),
    GoRoute(
      path: '/wallet/expense',
      builder: (context, state) {
        final wallet = state.extra as Wallet?;
        if (wallet == null) return const WalletScreen();
        return WalletExpenseScreen(wallet: wallet);
      },
    ),
    GoRoute(
      path: '/account',
      builder: (context, state) => const AccountInfoScreen(),
    ),
    GoRoute(
      path: '/account/edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/account/pin',
      builder: (context, state) => const ActivatePinScreen(),
    ),
    GoRoute(
      path: '/account/categories',
      builder: (context, state) => const CategoriesScreen(),
    ),
    GoRoute(
      path: '/premium',
      builder: (context, state) => const PremiumScreen(),
    ),
    GoRoute(
      path: '/budget',
      builder: (context, state) => const BudgetScreen(),
    ),
    GoRoute(
      path: '/pin-setup',
      builder: (context, state) => const PinSetupScreen(),
    ),
    GoRoute(
      path: '/pin-login',
      builder: (context, state) => const PinLoginScreen(),
    ),
    GoRoute(
      path: '/recurring',
      builder: (context, state) => const RecurringScreen(),
    ),
    GoRoute(
      path: '/recurring/add',
      builder: (context, state) => const AddRecurringScreen(),
    ),
    GoRoute(
      path: '/recurring/detail',
      builder: (context, state) {
        final item = state.extra as RecurringTransaction?;
        if (item == null) return const RecurringScreen();
        return RecurringDetailScreen(item: item);
      },
    ),
    GoRoute(
      path: '/recurring/edit',
      builder: (context, state) {
        final item = state.extra as RecurringTransaction?;
        if (item == null) return const RecurringScreen();
        return AddRecurringScreen(initialData: item);
      },
    ),
    GoRoute(
      path: '/add-transaction',
      builder: (context, state) => const AddTransactionScreen(),
    ),
    GoRoute(
      path: '/transactions/recent',
      builder: (context, state) => const RecentTransactionFullPage(),
    ),
    GoRoute(
      path: '/transactions/detail',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>?;
        if (data == null) return const HomeScreen();
        return TransactionDetailScreen(data: data);
      },
    ),
    GoRoute(
      path: '/transactions/edit',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>?;
        if (data == null) return const HomeScreen();
        return EditTransactionScreen(data: data);
      },
    ),
    GoRoute(
      path: '/ai/chat',
      builder: (context, state) => const AiChatScreen(),
    ),
    GoRoute(
      path: '/ai/report',
      builder: (context, state) => const AiReportScreen(),
    ),
  ],
);
