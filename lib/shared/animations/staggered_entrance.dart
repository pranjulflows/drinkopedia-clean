import 'package:drinkopedia/app/theme/app_motion.dart';
import 'package:flutter/material.dart';

/// Fades and lifts a child into place, offset by its position in a list.
///
/// Collapses to a plain child when the platform asks for reduced motion.
class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({
    required this.index,
    required this.child,
    super.key,
  });

  final int index;
  final Widget child;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.standard,
  );

  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;

    if (AppMotion.reduced(context)) {
      _controller.value = 1;
      return;
    }

    final int cappedSteps =
        AppMotion.maxStagger.inMilliseconds ~/ AppMotion.stagger.inMilliseconds;
    final Duration delay =
        AppMotion.stagger * widget.index.clamp(0, cappedSteps);

    Future<void>.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> curved = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.enter,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(curved),
        child: widget.child,
      ),
    );
  }
}
