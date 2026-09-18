import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Khung màn hình chuẩn: nền giấy, padding theo token, cuộn được.
class EchoraScaffold extends StatelessWidget {
  const EchoraScaffold({
    super.key,
    required this.slivers,
    this.bottom,
  });

  final List<Widget> slivers;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.paper,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.screenTop,
                AppSpacing.screenHorizontal,
                AppSpacing.screenBottom,
              ),
              sliver: SliverMainAxisGroup(slivers: slivers),
            ),
          ],
        ),
      ),
      bottomNavigationBar: bottom,
    );
  }
}

class SliverGap extends StatelessWidget {
  const SliverGap(this.size, {super.key});

  final double size;

  @override
  Widget build(BuildContext context) =>
      SliverToBoxAdapter(child: SizedBox(height: size));
}
