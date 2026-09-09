import 'package:drinkopedia/features/spirits/domain/entities/spirit_category.dart';
import 'package:flutter/material.dart';

/// Colour tokens for the "neo-brutalist pop" direction.
///
/// See `docs/design-directions.md`. Two rules hold the direction together:
/// every border and every shadow is drawn in the foreground ink, and the three
/// accents are never tinted or blended — they are flat, full-strength blocks.
///
/// Deliberately not derived with `ColorScheme.fromSeed`: tonal derivation pulls
/// [acid] toward olive, which is the one thing this palette cannot lose.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------- light --

  /// Foreground: all text, all borders, all shadows.
  static const Color ink = Color(0xFF0A0A0A);

  /// Screen background.
  static const Color paper = Color(0xFFF5F1E8);

  /// Fill for cards and input fields, which sit above [paper].
  static const Color panel = Color(0xFFFFFFFF);

  /// Secondary text. Still readable on [paper]; never used for borders.
  static const Color mutedInk = Color(0xFF5A564D);

  /// Loading-skeleton blocks, and the tone the shimmer pulses to.
  ///
  /// Both are darker than [panel] on purpose: the skeleton sits *inside* a
  /// white card, so a highlight that reaches white makes the blocks vanish and
  /// the card read as loaded-but-empty.
  static const Color skeleton = Color(0xFFDCD6C7);
  static const Color skeletonHighlight = Color(0xFFEBE7DC);

  // ----------------------------------------------------------------- dark --
  //
  // The direction inverts rather than dimming: the ground becomes ink and the
  // ink becomes paper, so borders stay at full contrast instead of turning into
  // the grey smudge a naive dark mode produces. Accents are unchanged — they
  // were picked to hold up on both grounds.

  static const Color inkDark = Color(0xFFF5F1E8);
  static const Color paperDark = Color(0xFF0A0A0A);
  static const Color panelDark = Color(0xFF16160F);
  static const Color mutedInkDark = Color(0xFFA7A196);
  static const Color skeletonDark = Color(0xFF2A2A23);
  static const Color skeletonHighlightDark = Color(0xFF3A3A31);

  // -------------------------------------------------------------- accents --

  static const Color acid = Color(0xFFCCFF00);
  static const Color hotPink = Color(0xFFFF4FD8);
  static const Color electricBlue = Color(0xFF2B6BFF);

  /// Error state. Loud enough to belong to this palette rather than to
  /// Material's defaults.
  static const Color alert = Color(0xFFE5233D);

  /// Grounds for image wells.
  static const List<Color> wells = <Color>[acid, hotPink, electricBlue];

  /// The accent a category is drawn in.
  ///
  /// Keyed off the category itself rather than its position in a list, so a
  /// category keeps its colour wherever it appears — the picker, the summary,
  /// and anywhere it turns up later. Position-based rotation would recolour
  /// everything the moment a category is added or reordered.
  static Color accentForCategory(SpiritCategory category) =>
      wells[category.index % wells.length];

  /// The well a spirit's artwork sits on.
  ///
  /// Keyed off the id rather than the grid index so a spirit keeps the same
  /// ground however it was reached: the hero flight from card to detail would
  /// otherwise change colour mid-flip, and a deep link has no grid position to
  /// rotate from. `String.hashCode` is not stable across runs, so this sums
  /// code units instead — the same spirit must not change colour between
  /// launches.
  static Color wellForId(String id) {
    int sum = 0;
    for (int i = 0; i < id.length; i++) {
      sum += id.codeUnitAt(i);
    }
    return wells[sum % wells.length];
  }
}
