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
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/branding/bousselha_logo.png',
                  height: 120,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 40),
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    color: Color(0xFF1A2B4A),
                    strokeWidth: 3,
                  ),
                ),
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

