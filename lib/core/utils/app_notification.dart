import 'package:flutter/material.dart';

enum _NotificationType { error, success, info }

/// Lightweight notification utility for showing transient feedback.
///
/// Wire [scaffoldMessengerKey] into [MaterialApp.scaffoldMessengerKey] once at
/// app startup. After that, call the static methods from anywhere — no
/// BuildContext needed, and no risk of hitting a deactivated widget.
///
/// Usage:
/// ```dart
/// AppNotification.showError('Invalid credentials.');
/// AppNotification.showSuccess('Password reset successfully.');
/// AppNotification.showInfo('A new code has been sent.');
/// ```
class AppNotification {
  AppNotification._();

  /// Assign this to [MaterialApp.scaffoldMessengerKey].
  static final scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void showError(String message) =>
      _show(message, _NotificationType.error);

  static void showSuccess(String message) =>
      _show(message, _NotificationType.success);

  static void showInfo(String message) =>
      _show(message, _NotificationType.info);

  static void _show(String message, _NotificationType type) {
    final state = scaffoldMessengerKey.currentState;
    if (state == null) return;

    // Derive colors from the current theme via the messenger's context.
    final cs = Theme.of(state.context).colorScheme;

    final (Color bg, Color fg, IconData icon) = switch (type) {
      _NotificationType.error => (
          cs.errorContainer,
          cs.onErrorContainer,
          Icons.error_outline_rounded,
        ),
      _NotificationType.success => (
          cs.secondaryContainer,
          cs.onSecondaryContainer,
          Icons.check_circle_outline_rounded,
        ),
      _NotificationType.info => (
          cs.surfaceContainerHighest,
          cs.onSurface,
          Icons.info_outline_rounded,
        ),
    };

    state
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: bg,
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: type == _NotificationType.error
              ? const Duration(seconds: 5)
              : const Duration(seconds: 3),
          content: Row(
            children: [
              Icon(icon, size: 20, color: fg),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: fg,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: fg,
            onPressed: state.hideCurrentSnackBar,
          ),
        ),
      );
  }
}
