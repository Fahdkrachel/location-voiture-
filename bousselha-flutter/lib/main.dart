import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/home_shell.dart';
import 'presentation/auth/login_screen.dart';
import 'shared/providers/auth_provider.dart';

void main() {
  runApp(const ProviderScope(child: BousselhaApp()));
}

class BousselhaApp extends ConsumerWidget {
  const BousselhaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (!authState.isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'BOUSSELHA CARS',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF1A2B4A)),
        home: const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_car_rounded, size: 64, color: Color(0xFF1A2B4A)),
                SizedBox(height: 16),
                Text(
                  'BOUSSELHA CARS',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2B4A),
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 24),
                CircularProgressIndicator(color: Color(0xFF1A2B4A)),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BOUSSELHA CARS',
      theme: ThemeData(
        useMaterial3: true, 
        colorSchemeSeed: const Color(0xFF1A2B4A),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: authState.token == null ? const LoginScreen() : const HomeShell(),
    );
  }
}

