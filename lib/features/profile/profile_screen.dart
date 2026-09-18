import 'package:flutter/material.dart';

import '../../core/strings.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/echora_scaffold.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EchoraScaffold(
      slivers: [
        SliverToBoxAdapter(
          child: Text(
            Strings.profileTitle,
            style: context.typography.displayLarge,
          ),
        ),
      ],
    );
  }
}
