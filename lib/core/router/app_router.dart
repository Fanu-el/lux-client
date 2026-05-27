import 'package:go_router/go_router.dart';

import '../../features/auth/auth_state.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/chat/presentation/chat_list_screen.dart';
import '../../features/intro/intro_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/user/edit_profile_screen.dart';
import '../../features/user/profile_screen.dart';

GoRouter createRouter(AuthState authState) {
  return GoRouter(
    refreshListenable: authState,
    initialLocation: '/splash',

    redirect: (context, state) {
      if (!authState.isInitialized) return null;

      final isLoggedIn = authState.isLoggedIn;
      final loc = state.matchedLocation;

      // Splash and intro handle their own navigation
      if (loc == '/splash' || loc == '/intro') return null;

      final isPublicRoute = loc.startsWith('/login') ||
          loc.startsWith('/register') ||
          loc.startsWith('/verify') ||
          loc.startsWith('/forgot') ||
          loc.startsWith('/reset');

      if (!isLoggedIn && !isPublicRoute) return '/login';
      if (isLoggedIn && isPublicRoute) return '/chats';

      return null;
    },

    routes: [
      // ── Splash / Intro ──────────────────────────────────────────────────
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/intro',  builder: (context, state) => const IntroScreen()),

      // ── Auth ──────────────────────────────────────────────────────────────
      GoRoute(path: '/login',    builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(
        path: '/verify',
        builder: (context, state) =>
            VerifyEmailScreen(email: state.extra as String? ?? ''),
      ),
      GoRoute(path: '/forgot', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/reset',
        builder: (context, state) =>
            ResetPasswordScreen(email: state.extra as String? ?? ''),
      ),

      // ── Chats ─────────────────────────────────────────────────────────────
      GoRoute(
        path: '/chats',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/chats/:chatId',
        builder: (context, state) =>
            ChatScreen(chatId: state.pathParameters['chatId']!),
      ),

      // ── Settings ──────────────────────────────────────────────────────────
      GoRoute(
        path: '/settings/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/settings/profile/edit',
        builder: (context, state) =>
            EditProfileScreen(currentName: state.extra as String? ?? ''),
      ),
    ],
  );
}
