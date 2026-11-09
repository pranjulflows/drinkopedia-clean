import 'package:drinkopedia/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

/// The type ramp for the "neo-brutalist pop" direction.
///
/// Display sizes use [AppConstants.rotaExtraBlack], which is a separate font
/// *family* rather than a weight: Rota ExtraBlack is heavier than Black, and
/// Flutter caps `FontWeight` at 900, so `pubspec.yaml` registers it on its own.
/// Setting a `fontWeight` on these styles would do nothing.
///
/// Letter spacing is in logical pixels, so the em values from the design are
/// multiplied by the size here — `-0.04em` at 34px is `-1.36`.
class AppTypography {
  AppTypography._();

  static TextTheme of(Color onSurface, Color muted) {
    const String display = AppConstants.rotaExtraBlack;

    return TextTheme(
      // Detail hero. Long names ("Chambord Raspberry Liqueur") wrap to three
      // lines at this size, which the direction wants rather than avoids.
      displayLarge: TextStyle(
        fontFamily: display,
        fontSize: 44,
        height: 0.86,
        letterSpacing: -1.98,
        color: onSurface,
      ),
      // Screen titles. Sized so the longest localised app name still sets on
      // one line inside the screen's horizontal padding.
      displayMedium: TextStyle(
        fontFamily: display,
        fontSize: 34,
        height: 0.9,
        letterSpacing: -1.36,
        color: onSurface,
      ),
      // Section headings, e.g. "THE STORY".
      headlineSmall: TextStyle(
        fontFamily: display,
        fontSize: 20,
        height: 1,
        letterSpacing: -0.4,
        color: onSurface,
      ),
      // Card names.
      titleMedium: TextStyle(
        fontFamily: display,
        fontSize: 16,
        height: 1,
        letterSpacing: -0.4,
        color: onSurface,
      ),
      // Long-form story text. The one place in the direction that is set for
      // reading rather than for impact.
      bodyLarge: TextStyle(fontSize: 15, height: 1.62, color: onSurface),
      bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: onSurface),
      bodySmall: TextStyle(fontSize: 13, height: 1.5, color: muted),
      // Meta rows: "44 SPIRITS".
      labelLarge: TextStyle(
        fontSize: 11,
        height: 1,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.54,
        color: onSurface,
      ),
      // Chip labels.
      labelSmall: TextStyle(
        fontSize: 10,
        height: 1,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
        color: onSurface,
      ),
    );
  }
}
