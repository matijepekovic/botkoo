import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:botko/ui/themes/app_theme.dart';
import 'package:botko/ui/screens/home_screen.dart';
import 'package:botko/core/providers/account_provider.dart';
import 'package:botko/core/providers/content_provider.dart';
import 'package:botko/core/providers/schedule_provider.dart';
import 'package:botko/data/local/database_helper.dart';

void main() {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize database for desktop platforms
  DatabaseHelper.initialize();

  runApp(const BotkoApp());
}

class BotkoApp extends StatelessWidget {
  const BotkoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AccountProvider()..init()),
        ChangeNotifierProvider(create: (_) => ContentProvider()..init()),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()..init()),
      ],
      child: MaterialApp(
        title: 'Botko',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
      ),
    );
  }
}