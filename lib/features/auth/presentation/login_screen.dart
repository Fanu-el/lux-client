import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth_state.dart';
import '../controller/auth_controller.dart';
import '../../../../core/utils/app_notification.dart';
import 'widgets/auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _controller = AuthController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      AppNotification.showError('Please fill in all fields.');
      return;
    }

    setState(() => _loading = true);

    try {
      await _controller.login(email: email, password: password);
      if (!mounted) return;
      context.read<AuthState>().login();
    } on DioException catch (e) {
      if (!mounted) return;
      AppNotification.showError(e.error as String? ?? 'Login failed.');
    } catch (_) {
      if (!mounted) return;
      AppNotification.showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Text(
                'Welcome back',
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Sign in to your account',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 40),

              // Email
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'you@example.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Password
              TextField(
                controller: _passCtrl,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),

              // Forgot password link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/forgot'),
                  child: const Text('Forgot password?'),
                ),
              ),

              const SizedBox(height: 16),

              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading ? const ButtonSpinner() : const Text('Sign In'),
              ),

              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: theme.textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text('Register'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
