import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../controller/auth_controller.dart';
import '../../../../core/utils/app_notification.dart';
import 'widgets/auth_widgets.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, required this.email});
  final String email;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _controller = AuthController();
  final _codeCtrl = TextEditingController();

  bool _verifying = false;
  bool _resending = false;

  // Resend cooldown
  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_cooldown <= 1) {
        t.cancel();
        setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown--);
      }
    });
  }

  Future<void> _verify() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      AppNotification.showError('Please enter the verification code.');
      return;
    }

    setState(() => _verifying = true);

    try {
      await _controller.verifyEmail(email: widget.email, code: code);
      if (!mounted) return;
      context.go('/login');
    } on DioException catch (e) {
      if (!mounted) return;
      AppNotification.showError(e.error as String? ?? 'Verification failed.');
    } catch (_) {
      if (!mounted) return;
      AppNotification.showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    if (_cooldown > 0 || _resending) return;

    setState(() => _resending = true);

    try {
      await _controller.resendCode(widget.email);
      if (!mounted) return;
      AppNotification.showSuccess('A new code has been sent to your email.');
      _startCooldown();
    } on DioException catch (e) {
      if (!mounted) return;
      AppNotification.showError(e.error as String? ?? 'Could not resend code.');
    } catch (_) {
      if (!mounted) return;
      AppNotification.showError('Something went wrong.');
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email'), centerTitle: true),
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
                  child: Icon(Icons.mark_email_unread_outlined,
                      size: 36, color: cs.onPrimaryContainer),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Check your inbox',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a verification code to\n${widget.email}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 40),

              TextField(
                controller: _codeCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 10,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _verify(),
                style: theme.textTheme.headlineSmall
                    ?.copyWith(letterSpacing: 8, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  labelText: 'Verification code',
                  counterText: '',
                ),
              ),

              const SizedBox(height: 24),

              FilledButton(
                onPressed: _verifying ? null : _verify,
                child: _verifying
                    ? const ButtonSpinner()
                    : const Text('Verify Email'),
              ),

              const SizedBox(height: 20),

              Center(
                child: _cooldown > 0
                    ? Text(
                        'Resend code in ${_cooldown}s',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      )
                    : TextButton(
                        onPressed: _resending ? null : _resend,
                        child: _resending
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text("Didn't get it? Resend code"),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
