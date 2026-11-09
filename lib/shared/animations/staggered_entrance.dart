import 'dart:async';

import 'package:drinkopedia/app/theme/app_motion.dart';
import 'package:flutter/material.dart';

/// Lifts a child into place, offset by its position in a list.
///
/// Collapses to a plain child when the platform asks for reduced motion.
class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({
    required this.index,
    required this.child,
    this.fade = true,
    super.key,
  });

  final int index;
  final Widget child;

  /// Whether the child also fades in.
  ///
  /// Off for anything drawn with a hard border and an offset shadow: a
  /// half-opaque border reads as a rendering fault rather than as motion, so
  /// those items only slide.
  final bool fade;

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

  /// The pending start, cancelled on dispose. A card scrolled away or rebuilt
  /// before its turn otherwise leaves a live timer behind it.
  Timer? _startTimer;

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

    _startTimer = Timer(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> curved = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.enter,
    );
    final Widget slide = SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.06),
        end: Offset.zero,
      ).animate(curved),
      child: widget.child,
    );

    if (!widget.fade) return slide;
    return FadeTransition(opacity: curved, child: slide);
  }
}
