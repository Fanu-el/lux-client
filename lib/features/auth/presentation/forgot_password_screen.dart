import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../controller/auth_controller.dart';
import '../../../../core/utils/app_notification.dart';
import 'widgets/auth_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _controller = AuthController();
  final _emailCtrl = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      AppNotification.showError('Please enter your email address.');
      return;
    }

    setState(() => _loading = true);

    try {
      await _controller.forgotPassword(email);
      if (!mounted) return;
      context.push('/reset', extra: email);
    } on DioException catch (e) {
      if (!mounted) return;
      AppNotification.showError(e.error as String? ?? 'Request failed.');
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
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.lock_reset_outlined,
                      size: 36, color: cs.onPrimaryContainer),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Reset your password',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Enter your email and we'll send you a code to reset your password.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 40),

              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'you@example.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),

              const SizedBox(height: 24),

              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const ButtonSpinner()
                    : const Text('Send Reset Code'),
              ),

              const SizedBox(height: 16),

              Center(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Back to Sign In'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
