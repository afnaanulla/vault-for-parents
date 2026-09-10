import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/entries_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/splash_screen.dart';
import 'services/biometric_service.dart';
import 'services/storage_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation for consistent security keypad UX
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // System UI style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  final sharedPreferences = await SharedPreferences.getInstance();
  final storageService = StorageService(sharedPreferences);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(storageService)),
        ChangeNotifierProvider(create: (_) => EntriesProvider(storageService)),
      ],
      child: const SecureVaultApp(),
    ),
  );
}

class SecureVaultApp extends StatefulWidget {
  const SecureVaultApp({super.key});

  @override
  State<SecureVaultApp> createState() => _SecureVaultAppState();
}

class _SecureVaultAppState extends State<SecureVaultApp>
    with WidgetsBindingObserver {
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
    // Critical: Do NOT lock while the system biometric dialog or camera/gallery picker is active!
    if (BiometricService.isAuthenticating || StorageService.isPickingMedia) {
      return;
    }

    // Auto-lock when app is minimized or sent to background
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      final auth = context.read<AuthProvider>();
      final entries = context.read<EntriesProvider>();
      if (auth.isAuthenticated) {
        entries.clear();
        auth.lockVault();
      }
    } else if (state == AppLifecycleState.resumed) {
      // Re-prompt auth immediately upon resume if vault is locked
      final auth = context.read<AuthProvider>();
      if (auth.status == AuthStatus.locked && !auth.isAuthenticated) {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'SecureVault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
