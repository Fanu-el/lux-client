import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'core/network/dio_client.dart';
import 'core/router/app_router.dart';
import 'core/utils/app_notification.dart';
import 'features/auth/auth_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  final authState = AuthState();
  await authState.init();

  // Wire up the forced-logout callback so DioClient can clear the session
  // when the refresh token is expired/invalid.
  DioClient.onForceLogout = () => authState.logout();

  runApp(
    ChangeNotifierProvider.value(value: authState, child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();
    final router = createRouter(authState);

    return MaterialApp.router(
      title: 'Lux',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      scaffoldMessengerKey: AppNotification.scaffoldMessengerKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          scrolledUnderElevation: 0,
        ),
      ),
    );
  }
}
