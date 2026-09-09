import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import 'auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _fullName = TextEditingController();
  bool _isRegister = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _fullName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = ref.read(authControllerProvider.notifier);
    final ok = _isRegister
        ? await auth.register(
            email: _email.text.trim(),
            fullName: _fullName.text.trim(),
            password: _password.text,
            role: 'CUSTOMER',
          )
        : await auth.login(_email.text.trim(), _password.text);
    if (!ok && mounted) {
      final error = ref.read(authControllerProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.hasError
              ? error.error.toString()
              : 'Error de autenticacion'),
          backgroundColor: AppColors.destructive,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Imagine Delivery',
                        style: theme.textTheme.displaySmall),
                    const SizedBox(height: 8),
                    Text(
                      _isRegister
                          ? 'Crea tu cuenta de cliente'
                          : 'Inicia sesion para pedir',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),
                    if (_isRegister) ...[
                      TextFormField(
                        controller: _fullName,
                        decoration:
                            const InputDecoration(labelText: 'Nombre completo'),
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || v.trim().length < 2)
                            ? 'Ingresa tu nombre'
                            : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'Email invalido'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      decoration: InputDecoration(
                        labelText: 'Contrasena',
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) => (v == null || v.length < 8)
                          ? 'Minimo 8 caracteres'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: loading ? null : _submit,
                      child: loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.onPrimary),
                            )
                          : Text(_isRegister ? 'Registrarme' : 'Ingresar'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: loading
                          ? null
                          : () => setState(() => _isRegister = !_isRegister),
                      child: Text(
                        _isRegister
                            ? 'Ya tengo cuenta, ingresar'
                            : 'Crear cuenta nueva',
                        style: const TextStyle(color: AppColors.accent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
