import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'core/constants/app_colors.dart';
import 'core/storage/local_storage.dart';
import 'features/auth/create_account_screen.dart';
import 'features/onboarding/select_language_screen.dart';
import 'features/onboarding/setup_wallet_screen.dart';
import 'service_locator.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/home/home_screen.dart';
import 'features/welcome/welcome_screen.dart';

class MonexApp extends StatefulWidget {
  const MonexApp({super.key});

  @override
  State<MonexApp> createState() => _MonexAppState();
}

class _MonexAppState extends State<MonexApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    final expired = await LocalStorage.isSessionExpired();
    if (expired) {
      await LocalStorage.clearAll();
      _router.go('/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: ServiceLocator.localeNotifier,
      builder: (context, locale, _) {
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
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
            useMaterial3: true,
          ),
          routerConfig: _router,
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
      await LocalStorage.clearAll();
      return '/signin';
    }

    final onboardingDone = await LocalStorage.isOnboardingCompleted();
    if (!onboardingDone && !isOnboarding) return '/onboarding/language';
    if (onboardingDone && !isOnboarding && loc != '/' && loc != '/home' && !isAuthScreen) {
      return '/home';
    }
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
      builder: (context, state) => const SetupWalletScreen(),
    ),
  ],
);
