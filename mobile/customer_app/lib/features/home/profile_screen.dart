import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../auth/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.account_circle,
                size: 72, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Cliente',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 32),
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => ref.read(authControllerProvider.notifier).logout(),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.logout, color: AppColors.destructive),
                      const SizedBox(width: 12),
                      Text('Cerrar sesion', style: theme.textTheme.titleLarge),
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(),
            Text(
              'Imagine Delivery v1.0.0',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
