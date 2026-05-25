import 'package:flutter/material.dart';

import '../../models/llm_model.dart';

/// Compact pill button in the app bar — tapping opens a bottom sheet.
class ModelPickerButton extends StatelessWidget {
  const ModelPickerButton({
    super.key,
    required this.selected,
    required this.onChanged,
  });
  final LlmModel selected;
  final ValueChanged<LlmModel> onChanged;

  // Provider accent colors
  static Color _providerColor(String provider, ColorScheme cs) {
    switch (provider) {
      case 'Google':
        return const Color(0xFF4285F4);
      case 'OpenAI':
        return const Color(0xFF10A37F);
      case 'Anthropic':
        return const Color(0xFFD97706);
      default:
        return cs.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _providerColor(selected.provider, cs);

    return GestureDetector(
      onTap: () => _showPicker(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              selected.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 15, color: color),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ModelPickerSheet(
        selected: selected,
        onChanged: (m) {
          onChanged(m);
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _ModelPickerSheet extends StatelessWidget {
  const _ModelPickerSheet({required this.selected, required this.onChanged});
  final LlmModel selected;
  final ValueChanged<LlmModel> onChanged;

  Map<String, List<LlmModel>> get _grouped {
    final map = <String, List<LlmModel>>{};
    for (final m in LlmModel.all) {
      map.putIfAbsent(m.provider, () => []).add(m);
    }
    return map;
  }

  static Color _providerColor(String provider) {
    switch (provider) {
      case 'Google':
        return const Color(0xFF4285F4);
      case 'OpenAI':
        return const Color(0xFF10A37F);
      case 'Anthropic':
        return const Color(0xFFD97706);
      default:
        return Colors.grey;
    }
  }

  static IconData _providerIcon(String provider) {
    switch (provider) {
      case 'Google':
        return Icons.auto_awesome_rounded;
      case 'OpenAI':
        return Icons.psychology_rounded;
      case 'Anthropic':
        return Icons.hub_rounded;
      default:
        return Icons.smart_toy_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final groups = _grouped;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Icon(Icons.tune_rounded, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'Choose model',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Select the AI model for this conversation.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 20),

            ...groups.entries.map((entry) {
              final providerColor = _providerColor(entry.key);
              final providerIcon = _providerIcon(entry.key);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Provider header
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: providerColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(providerIcon,
                              size: 14, color: providerColor),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          entry.key,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: providerColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Model tiles
                  ...entry.value.map((model) {
                    final isSelected = model.id == selected.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Material(
                        color: isSelected
                            ? providerColor.withOpacity(0.08)
                            : cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => onChanged(model),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        model.label,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? providerColor
                                              : cs.onSurface,
                                        ),
                                      ),
                                      Text(
                                        model.id,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                                color: cs.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check_circle_rounded,
                                      color: providerColor, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
