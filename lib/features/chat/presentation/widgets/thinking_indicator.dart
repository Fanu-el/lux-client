import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Animated "Lux is thinking" indicator shown while waiting for the AI response.
class ThinkingIndicator extends StatefulWidget {
  const ThinkingIndicator({super.key});

  @override
  State<ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<ThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.transparent,
            child: ClipOval(
              child: SizedBox.square(
                dimension: 28,
                child: SvgPicture.asset(
                  'lib/assets/images/logos/logo-no-text-svg.svg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => _GlowDot(controller: _ctrl, index: i, color: cs.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Glowing pulse dot ────────────────────────────────────────────────────────

class _GlowDot extends StatelessWidget {
  const _GlowDot({
    required this.controller,
    required this.index,
    required this.color,
  });

  final AnimationController controller;
  final int index;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        // Each dot is offset by 1/3 of the cycle (0°, 120°, 240°)
        final phase = (controller.value - index / 3.0 + 1.0) % 1.0;

        // sin maps phase 0→1 into a smooth 0→1→0 pulse
        final t = sin(phase * pi).clamp(0.0, 1.0);

        final scale     = 1.0 + 0.50 * t;
        final glowBlur  = 12.0 * t;
        final glowSpread = 2.5 * t;
        final opacity   = 0.40 + 0.60 * t;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(opacity),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.75 * t),
                    blurRadius: glowBlur,
                    spreadRadius: glowSpread,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
