import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'data/services/admin_init_service.dart';
import 'firebase_options.dart';
import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/hackathon_provider.dart';
import 'providers/theme_provider.dart';
import 'ui/navigation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase with platform-specific options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (!kIsWeb) {
      await FirebaseAppCheck.instance.activate(
        androidProvider: kDebugMode
            ? AndroidProvider.debug
            : AndroidProvider.playIntegrity,
        appleProvider: kDebugMode
            ? AppleProvider.debug
            : AppleProvider.appAttest,
      );
    }
    if (kDebugMode) {
      debugPrint('Firebase initialized successfully');
    }

    // Initialize admin account (runs once)
    try {
      final adminInitialized = await AdminInitService()
          .initializeAdminAccount();
      if (adminInitialized) {
        AdminInitService.printAdminCredentials();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Admin initialization error: $e');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Firebase initialization error: $e');
      debugPrint('Running without Firebase - some features may not work');
    }
    // Continue without Firebase for now - you can still test the UI
  }

  // Set preferred orientations (skip on web)
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Orientation setting skipped (likely web platform): $e');
    }
  }

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  runApp(CodeClubApp(prefs: prefs));
}

class CodeClubApp extends StatelessWidget {
  final SharedPreferences prefs;

  const CodeClubApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Connectivity provider
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        // Theme provider
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // Auth provider
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Admin provider
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        // Chat provider
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        // Hackathon provider
        ChangeNotifierProvider(create: (_) => HackathonProvider()),
      ],
      child: const _AppContent(),
    );
  }
}

class _AppContent extends StatefulWidget {
  const _AppContent();

  @override
  State<_AppContent> createState() => _AppContentState();
}

class _AppContentState extends State<_AppContent> {
  late final AuthProvider _authProvider;
  late final AppRouter _appRouter;
  bool _hasShownNoInternetDialog = false;

  @override
  void initState() {
    super.initState();
    // Schedule the connectivity check after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInternetConnection();
    });
  }

  /// Check internet connection and show dialog if offline
  void _checkInternetConnection() {
    final connectivityProvider = context.read<ConnectivityProvider>();

    if (!connectivityProvider.isConnected && !_hasShownNoInternetDialog) {
      _hasShownNoInternetDialog = true;
      _showNoInternetDialog();
    }
  }

  /// Show dialog when internet is not available
  void _showNoInternetDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('No Internet Connection'),
          ],
        ),
        content: const Text(
          'Please check your internet connection. Some features may not work properly without internet.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _hasShownNoInternetDialog = false;
            },
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              _checkInternetConnection();
              Navigator.pop(context);
              _hasShownNoInternetDialog = false;
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize once - create AppRouter only once to prevent rebuilds
    if (!_isInitialized) {
      _authProvider = context.read<AuthProvider>();
      _appRouter = AppRouter(_authProvider);
      _isInitialized = true;
    }
  }

  bool _isInitialized = false;

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        try {
          return MaterialApp.router(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: _appRouter.router,
            builder: (context, child) {
              return Consumer<ConnectivityProvider>(
                builder: (context, connectivityProvider, _) {
                  return Stack(
                    children: [
                      child!,
                      // Show internet connection status overlay
                      if (!connectivityProvider.isConnected)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: Colors.orange.shade700,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: SafeArea(
                              bottom: false,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.wifi_off,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'No Internet Connection',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          );
        } catch (e) {
          // Fallback UI in case of routing issues
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'App Initialization Error',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Error: $e'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Reload the app
                        main();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
