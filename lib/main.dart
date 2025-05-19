import 'package:flutter/material.dart';
import 'package:botko/ui/themes/app_theme.dart';
import 'package:botko/ui/screens/home_screen.dart';

void main() {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const BotkoApp());
}

class BotkoApp extends StatelessWidget {
  const BotkoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Botko',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}