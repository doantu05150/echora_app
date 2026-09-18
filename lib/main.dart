import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/strings.dart';
import 'ui/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: EchoraApp()));
}

class EchoraApp extends StatelessWidget {
  const EchoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Strings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const _Placeholder(),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: Image.asset(
                'assets/branding/logo.png',
                width: 88,
                height: 88,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(Strings.appName, style: context.typography.displayLarge),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              Strings.appTagline,
              style: context.typography.body.copyWith(color: colors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
