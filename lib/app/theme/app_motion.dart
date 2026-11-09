import 'package:flutter/widgets.dart';

/// Motion tokens.
///
/// Durations and curves live here rather than as literals at call sites, so the
/// whole app can be retimed in one place and nothing drifts out of step.
class AppMotion {
  AppMotion._();

  static const Duration instant = Duration(milliseconds: 120);
  static const Duration quick = Duration(milliseconds: 220);
  static const Duration standard = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 480);

  /// Gap between consecutive items in a staggered list.
  static const Duration stagger = Duration(milliseconds: 45);

  /// Cap on total stagger delay: across a 20-card page an uncapped stagger
  /// would leave the last card nearly a second behind the first.
  static const Duration maxStagger = Duration(milliseconds: 400);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;

  /// Honours the platform "reduce motion" accessibility setting.
  ///
  /// Animation here is decoration; it must never be required to understand or
  /// operate a screen.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  static Duration resolve(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;
}
