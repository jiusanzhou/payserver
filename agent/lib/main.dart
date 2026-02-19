import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/servers_page.dart';
import 'presentation/pages/settings_page.dart';
import 'presentation/pages/analytics_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );
  }

  runApp(const ProviderScope(child: PayAgentApp()));
}

class PayAgentApp extends StatelessWidget {
  const PayAgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '易付',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const HomePage(),
      routes: {
        '/servers': (context) => const ServersPage(),
        '/settings': (context) => const SettingsPage(),
        '/analytics': (context) => const AnalyticsPage(),
      },
    );
  }
}
