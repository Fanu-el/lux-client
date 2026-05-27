import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/storage/app_prefs.dart';
import '../auth/auth_state.dart';

// ─── Data ─────────────────────────────────────────────────────────────────────

class _PageData {
  const _PageData({
    required this.bgColor,
    required this.illustration,
    required this.title,
    required this.description,
  });
  final Color bgColor;
  final Widget illustration;
  final String title;
  final String description;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _pageCtrl = PageController();
  int _page = 0;
  double _pageValue = 0;

  static const _bgColors = [
    Color(0xFFEEF2FF), // indigo tint
    Color(0xFFF5F0FF), // purple tint
    Color(0xFFE6FAF8), // teal tint
  ];

  @override
  void initState() {
    super.initState();
    _pageCtrl.addListener(() {
      if (mounted) setState(() => _pageValue = _pageCtrl.page ?? 0);
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Color get _bgColor {
    final i = _pageValue.floor().clamp(0, _bgColors.length - 2);
    final t = (_pageValue - i).clamp(0.0, 1.0);
    return Color.lerp(_bgColors[i], _bgColors[i + 1], t)!;
  }

  void _next() {
    if (_page < 2) {
      _pageCtrl.animateToPage(
        _page + 1,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await AppPrefs.markIntroSeen();
    if (!mounted) return;
    final authState = context.read<AuthState>();
    context.go(authState.isLoggedIn ? '/chats' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _PageData(
        bgColor: _bgColors[0],
        illustration: const _MeetLuxIllustration(),
        title: 'Meet Lux',
        description:
            'Your intelligent AI companion — always available, always helpful, no matter what you need.',
      ),
      _PageData(
        bgColor: _bgColors[1],
        illustration: const _ModelsIllustration(),
        title: 'Choose Your AI',
        description:
            'Switch between Gemini, GPT-4o, Claude and more in a single tap. Pick the best model for every task.',
      ),
      _PageData(
        bgColor: _bgColors[2],
        illustration: const _ChatIllustration(),
        title: 'Smart Conversations',
        description:
            'Rich markdown responses, multiple chat threads, and a history that\'s always saved.',
      ),
    ];

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip ──────────────────────────────────────────────────────
            SizedBox(
              height: 48,
              child: Align(
                alignment: Alignment.centerRight,
                child: AnimatedOpacity(
                  opacity: _page < 2 ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: TextButton(
                      onPressed: _page < 2 ? _finish : null,
                      child: const Text('Skip'),
                    ),
                  ),
                ),
              ),
            ),

            // ── Pages ─────────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (p) => setState(() => _page = p),
                itemCount: pages.length,
                itemBuilder: (context, i) => _IntroPage(data: pages[i]),
              ),
            ),

            // ── Indicator + button ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 12, 32, 36),
              child: Column(
                children: [
                  _PageIndicator(count: pages.length, current: _page),
                  const SizedBox(height: 28),
                  _NextButton(
                    isLast: _page == pages.length - 1,
                    onTap: _next,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Single intro page ────────────────────────────────────────────────────────

class _IntroPage extends StatelessWidget {
  const _IntroPage({required this.data});
  final _PageData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          // Illustration
          Expanded(
            flex: 11,
            child: Center(child: data.illustration),
          ),

          // Text
          Expanded(
            flex: 7,
            child: Column(
              children: [
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1F3C),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  data.description,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF5A6075),
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Page indicator ───────────────────────────────────────────────────────────

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.count, required this.current});
  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 28.0 : 8.0,
          height: 8,
          decoration: BoxDecoration(
            color: active ? cs.primary : cs.primary.withOpacity(0.22),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ─── Next / Get Started button ────────────────────────────────────────────────

class _NextButton extends StatelessWidget {
  const _NextButton({required this.isLast, required this.onTap});
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: ScaleTransition(scale: anim, child: child)),
      child: isLast
          ? FilledButton.icon(
              key: const ValueKey('last'),
              onPressed: onTap,
              icon: const Icon(Icons.rocket_launch_rounded, size: 18),
              label: const Text('Get Started'),
            )
          : FilledButton(
              key: const ValueKey('next'),
              onPressed: onTap,
              child: const Text('Next'),
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ILLUSTRATIONS
// ═══════════════════════════════════════════════════════════════════════════════

// ─── Page 1: Meet Lux ────────────────────────────────────────────────────────

class _MeetLuxIllustration extends StatefulWidget {
  const _MeetLuxIllustration();

  @override
  State<_MeetLuxIllustration> createState() => _MeetLuxIllustrationState();
}

class _MeetLuxIllustrationState extends State<_MeetLuxIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          ScaleTransition(
            scale: _pulse,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary.withOpacity(0.06),
              ),
            ),
          ),
          // Inner glow ring
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primary.withOpacity(0.10),
            ),
          ),
          // Logo
          Image.asset('lib/assets/images/logos/logo-no-text.png', width: 120),

          // Orbiting sparkle dots
          ..._orbitDots(cs),
        ],
      ),
    );
  }

  List<Widget> _orbitDots(ColorScheme cs) {
    const positions = [
      Offset(0, -118),
      Offset(118, 0),
      Offset(0, 118),
      Offset(-118, 0),
    ];
    final colors = [
      cs.primary,
      cs.secondary,
      cs.tertiary,
      cs.primary,
    ];
    return List.generate(4, (i) {
      final fade = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(
          parent: _ctrl,
          curve: Interval(i * 0.25, (i * 0.25 + 0.5).clamp(0, 1),
              curve: Curves.easeInOut),
        ),
      );
      return Positioned(
        left: 130 + positions[i].dx - 5,
        top: 130 + positions[i].dy - 5,
        child: AnimatedBuilder(
          animation: fade,
          builder: (_, __) => Opacity(
            opacity: fade.value,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors[i].withOpacity(0.7),
              ),
            ),
          ),
        ),
      );
    });
  }
}

// ─── Page 2: Choose Your AI ──────────────────────────────────────────────────

class _ModelsIllustration extends StatelessWidget {
  const _ModelsIllustration();

  static const _models = [
    _ModelInfo('Gemini 2.5', 'G', Color(0xFF4285F4), Color(0xFFE8F0FE), 'Google'),
    _ModelInfo('GPT-4o', 'O', Color(0xFF10A37F), Color(0xFFE6F7F3), 'OpenAI'),
    _ModelInfo('Claude 3.5', 'C', Color(0xFFD97706), Color(0xFFFEF3E2), 'Anthropic'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < _models.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _ModelCard(
            model: _models[i],
            offset: [0.0, 20.0, 0.0][i],
          ),
        ],
      ],
    );
  }
}

class _ModelInfo {
  const _ModelInfo(this.name, this.letter, this.color, this.bgColor, this.provider);
  final String name;
  final String letter;
  final Color color;
  final Color bgColor;
  final String provider;
}

class _ModelCard extends StatelessWidget {
  const _ModelCard({required this.model, required this.offset});
  final _ModelInfo model;
  final double offset;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(offset, 0),
      child: Container(
        width: 280,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: model.color.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: model.bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  model.letter,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: model.color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Name + provider
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF1A1F3C),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    model.provider,
                    style: TextStyle(
                      fontSize: 12,
                      color: model.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Check / active indicator
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: model.bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, size: 16, color: model.color),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Page 3: Smart Conversations ─────────────────────────────────────────────

class _ChatIllustration extends StatelessWidget {
  const _ChatIllustration();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: 300,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Assistant message
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: cs.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Image.asset('lib/assets/images/logos/logo-no-text.png'),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                      bottomLeft: Radius.circular(4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'Hi! I\'m Lux. What can I help you with today?',
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFF1A1F3C),
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // User message
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Text(
                'Explain quantum computing simply',
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onPrimary,
                  height: 1.45,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Assistant reply with markdown hint
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: cs.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Image.asset('lib/assets/images/logos/logo-no-text.png'),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                      bottomLeft: Radius.circular(4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '**Quantum computing** uses quantum bits (qubits) that can be 0, 1, or both at once — called *superposition*.',
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFF1A1F3C),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'qubit = |0⟩ + |1⟩',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
