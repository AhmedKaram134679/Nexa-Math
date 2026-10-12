import 'package:flutter/material.dart';

/// NexaMath root application widget.
///
/// Serves as the presentation foundation shell for the platform.
class NexaMathApp extends StatelessWidget {
  const NexaMathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NexaMath',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          brightness: Brightness.dark,
        ),
      ),
      home: const Scaffold(
        body: Center(
          child: Text(
            'NexaMath',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
