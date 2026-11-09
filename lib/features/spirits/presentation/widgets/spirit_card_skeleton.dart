import 'package:drinkopedia/app/theme/app_colors.dart';
import 'package:drinkopedia/app/theme/app_edges.dart';
import 'package:drinkopedia/app/theme/app_motion.dart';
import 'package:drinkopedia/shared/widgets/hard_edge/hard_edge_panel.dart';
import 'package:flutter/material.dart';

/// Shimmering placeholder shaped like a [SpiritCard].
///
/// A catalogue app should never show a bare spinner — a skeleton in the shape
/// of the content keeps the layout stable when real data arrives.
class SpiritCardSkeleton extends StatefulWidget {
  const SpiritCardSkeleton({super.key});

  @override
  State<SpiritCardSkeleton> createState() => _SpiritCardSkeletonState();
}

class _SpiritCardSkeletonState extends State<SpiritCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _controller.stop();
      _controller.value = 0.5;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return HardEdgePanel(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          // Two skeleton tones rather than a scheme container role: the card
          // this sits in is already the lightest surface, so pulsing towards it
          // would fade the blocks out entirely.
          final Color base = Color.lerp(
            isDark ? AppColors.skeletonDark : AppColors.skeleton,
            isDark
                ? AppColors.skeletonHighlightDark
                : AppColors.skeletonHighlight,
            _controller.value,
          )!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: base,
                    border: Border(
                      bottom: BorderSide(
                        color: scheme.outline,
                        width: AppEdges.border,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(9, 10, 9, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _Bar(color: base, widthFactor: 0.72, height: 13),
                    const SizedBox(height: 8),
                    _Bar(color: base, widthFactor: 0.44, height: 10),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.color,
    required this.widthFactor,
    required this.height,
  });

  final Color color;
  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      // Square, like everything else in this direction — a rounded placeholder
      // would promise a rounded card.
      child: SizedBox(
        height: height,
        child: ColoredBox(color: color),
      ),
    );
  }
}
