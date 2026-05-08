import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/home_shell.dart';

void main() {
  runApp(const ProviderScope(child: BousselhaApp()));
}

class BousselhaApp extends StatelessWidget {
  const BousselhaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BOUSSELHA CARS',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const HomeShell(),
    );
  }
}
