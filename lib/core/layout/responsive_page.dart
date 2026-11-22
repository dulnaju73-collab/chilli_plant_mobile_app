import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Keeps page content readable on wide displays and lets it use the full
/// available width on phones and compact windows.
class ResponsivePage extends StatelessWidget {
  const ResponsivePage({
    required this.child,
    this.maxContentWidth = 1200,
    super.key,
  });

  final Widget child;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(constraints.maxWidth, maxContentWidth);

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: width, child: child),
        );
      },
    );
  }
}
