import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../ui/theme/app_theme.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key, required this.passageId});

  final String passageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passage = ref.watch(passageProvider(passageId)).value;

    return Scaffold(
      backgroundColor: context.colors.paper,
      appBar: AppBar(
        backgroundColor: context.colors.paper,
        title: Text(passage?.title ?? '', style: context.typography.title),
      ),
      body: const SizedBox.shrink(),
    );
  }
}
