import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import 'features/auth/auth_providers.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';

class DriverApp extends ConsumerWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authed = ref.watch(isAuthenticatedProvider);

    return MaterialApp(
      title: 'Imagine Driver',
      theme: buildAppTheme(),
      home: authed ? const HomeScreen() : const LoginScreen(),
    );
  }
}
