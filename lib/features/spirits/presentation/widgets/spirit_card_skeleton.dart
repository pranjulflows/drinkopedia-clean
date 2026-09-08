import 'package:drinkopedia/app/theme/app_motion.dart';
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
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Card(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          final Color base = Color.lerp(
            scheme.surfaceContainerHighest,
            scheme.surfaceContainerHigh,
            _controller.value,
          )!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(child: ColoredBox(color: base)),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _Bar(color: base, widthFactor: 0.7),
                    const SizedBox(height: 8),
                    _Bar(color: base, widthFactor: 0.4),
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
  const _Bar({required this.color, required this.widthFactor});

  final Color color;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
