import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'providers/menu_provider.dart';
import 'providers/order_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/report_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/loyalty_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/new_order_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/login_screen.dart';
import 'screens/customer_shell.dart';
import 'screens/users_screen.dart';
import 'screens/coupons_screen.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const CoffeeApp());
}

class CoffeeApp extends StatelessWidget {
  const CoffeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => LoyaltyProvider()),
      ],
      child: MaterialApp(
        title: 'Crema',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const AuthGate(),
      ),
    );
  }

  ThemeData _buildTheme() {
    const coffeeBrown = Color(0xFF4E342E);
    const warmGold = Color(0xFFD4A574);

    final colorScheme = ColorScheme.dark(
      primary: warmGold,
      onPrimary: const Color(0xFF2C1A12),
      primaryContainer: const Color(0xFF5C4033),
      onPrimaryContainer: const Color(0xFFF5E6D3),
      secondary: const Color(0xFF8B6F47),
      onSecondary: Colors.white,
      surface: const Color(0xFF1A1210),
      onSurface: const Color(0xFFF5E6D3),
      surfaceContainerHighest: const Color(0xFF2C1A12),
      error: Colors.redAccent,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF1A1210),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A1210),
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFFF5E6D3),
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: coffeeBrown.withAlpha(80),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: coffeeBrown.withAlpha(60),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: coffeeBrown.withAlpha(100)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: warmGold, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF2C1A12),
        indicatorColor: warmGold.withAlpha(60),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: warmGold);
          }
          return TextStyle(fontSize: 12, color: const Color(0xFFF5E6D3).withAlpha(150));
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: warmGold, size: 24);
          }
          return IconThemeData(color: const Color(0xFFF5E6D3).withAlpha(150), size: 24);
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF2C1A12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: warmGold,
        foregroundColor: Color(0xFF2C1A12),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: warmGold,
          foregroundColor: const Color(0xFF2C1A12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

/// Routes based on auth state: Login → Admin shell or Customer shell.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isLoggedIn) {
      return const LoginScreen();
    }
    if (auth.isAdmin) {
      return AdminShell(key: ValueKey(auth.currentUser?.id));
    }
    return const CustomerShell();
  }
}

/// The existing admin management interface.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;
  final _couponsKey = GlobalKey<CouponsScreenState>();

  static const _titles = [
    'Dashboard',
    'New Order',
    'Menu',
    'Inventory',
    'Reports',
    'Users',
    'Coupons',
  ];

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const DashboardScreen(),
      const NewOrderScreen(),
      const MenuScreen(),
      const InventoryScreen(),
      const ReportsScreen(),
      const UsersScreen(),
      CouponsScreen(key: _couponsKey),
    ];
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(Icons.coffee_rounded, color: Theme.of(context).colorScheme.primary),
        ),
        actions: [
          if (_currentIndex == 1)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Clear Cart',
              onPressed: () => context.read<OrderProvider>().clearCart(),
            ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log Out',
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      // FAB: only on Coupons tab — opens Generate Coupon dialog
      floatingActionButton: _currentIndex == 6
          ? FloatingActionButton.extended(
              heroTag: 'coupon_fab',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => GenerateCouponDialog(
                    onCreated: () => _couponsKey.currentState?.reload(),
                  ),
                );
              },
              icon: const Icon(Icons.add_card_rounded),
              label: const Text('Generate Coupon'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.add_shopping_cart_rounded), label: 'Order'),
          NavigationDestination(icon: Icon(Icons.restaurant_menu_rounded), label: 'Menu'),
          NavigationDestination(icon: Icon(Icons.inventory_2_rounded), label: 'Inventory'),
          NavigationDestination(icon: Icon(Icons.bar_chart_rounded), label: 'Reports'),
          NavigationDestination(icon: Icon(Icons.manage_accounts_rounded), label: 'Users'),
          NavigationDestination(icon: Icon(Icons.local_offer_rounded), label: 'Coupons'),
        ],
      ),
    );
  }
}
