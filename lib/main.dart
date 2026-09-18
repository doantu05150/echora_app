import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'core/strings.dart';
import 'ui/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: EchoraApp()));
}

class EchoraApp extends StatelessWidget {
  const EchoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: Strings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: appRouter,
    );
  }
}
