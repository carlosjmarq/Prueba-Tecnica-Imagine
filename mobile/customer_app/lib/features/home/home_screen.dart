import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../orders/order_providers.dart';
import '../orders/orders_list_screen.dart';
import '../orders/create_order_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Activa el listener de realtime para refrescos automáticos.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(realtimeListenerProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const OrdersListScreen(),
      const CreateOrderScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined), label: 'Pedidos'),
          NavigationDestination(
              icon: Icon(Icons.add_circle_outline), label: 'Crear'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
    );
  }
}
