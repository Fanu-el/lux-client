import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/data/auth_api.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = AuthApi();

  String _name = '';
  String _initials = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final res = await _api.getMe();
      final data = res.data as Map<String, dynamic>;
      final name = (data['name'] as String?) ?? '';
      if (mounted) {
        setState(() {
          _name = name;
          _initials = _toInitials(name);
        });
      }
    } catch (_) {
      // Non-critical — avatar just stays empty
    }
  }

  String _toInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lux',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () async {
                await context.push('/settings/profile', extra: _name);
                // Reload in case the name was updated in settings
                _loadUser();
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: cs.primaryContainer,
                child: Text(
                  _initials,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: const Center(
        child: Text('Home'),
      ),
    );
  }
}
