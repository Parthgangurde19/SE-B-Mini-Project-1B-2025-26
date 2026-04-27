import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import 'customer/customer_menu_screen.dart';
import 'customer/customer_orders_screen.dart';
import 'customer/customer_profile_screen.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _currentIndex = 0;

  static const _titles = ['Menu', 'My Orders', 'Profile'];

  final _screens = const [
    CustomerMenuScreen(),
    CustomerOrdersScreen(),
    CustomerProfileScreen(),
  ];

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
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Clear Cart',
              onPressed: () => context.read<OrderProvider>().clearCart(),
            ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.restaurant_menu_rounded), label: 'Menu'),
          NavigationDestination(icon: Icon(Icons.receipt_long_rounded), label: 'My Orders'),
          NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
