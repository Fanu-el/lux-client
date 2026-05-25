import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/app_notification.dart';
import '../auth/presentation/widgets/auth_widgets.dart';
import 'user_api.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.currentName});
  final String currentName;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _api = UserApi();
  late final TextEditingController _nameCtrl;

  bool _loading = false;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();

    if (name.isEmpty) {
      setState(() => _nameError = 'Name cannot be empty.');
      return;
    }
    if (name == widget.currentName) {
      context.pop();
      return;
    }

    setState(() {
      _loading = true;
      _nameError = null;
    });

    try {
      await _api.updateProfile(name: name);
      if (!mounted) return;
      AppNotification.showSuccess('Profile updated successfully.');
      context.pop(name);
    } on DioException catch (e) {
      setState(() => _nameError = e.error as String? ?? 'Update failed.');
    } catch (_) {
      AppNotification.showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          // Save button in the app bar for quick access
          TextButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          children: [
            Text(
              'Display name',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                hintText: 'Your full name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            if (_nameError != null) ...[
              const SizedBox(height: 10),
              ErrorBanner(message: _nameError!),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading ? const ButtonSpinner() : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
