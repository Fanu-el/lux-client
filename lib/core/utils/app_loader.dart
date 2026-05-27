import 'package:flutter/material.dart';

/// Full-screen centered activity indicator for data-fetching states.
///
/// Usage:
/// ```dart
/// if (_loading) const AppLoader()
/// ```
class AppLoader extends StatelessWidget {
  const AppLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
