import 'package:drinkopedia/app/theme/app_colors.dart';
import 'package:drinkopedia/app/theme/app_edges.dart';
import 'package:drinkopedia/app/theme/app_typography.dart';
import 'package:drinkopedia/core/constants/app_constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Material 3 themes for the "neo-brutalist pop" direction.
///
/// The scheme is written out rather than seeded. `ColorScheme.fromSeed` derives
/// a tonal palette, which turns [AppColors.acid] into an olive and softens the
/// flat blocks the direction is built on — so every role is assigned here, and
/// `surfaceTint` is cleared so Material never washes a surface with primary.
class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    final Color ink = isDark ? AppColors.inkDark : AppColors.ink;
    final Color paper = isDark ? AppColors.paperDark : AppColors.paper;
    final Color panel = isDark ? AppColors.panelDark : AppColors.panel;
    final Color muted = isDark ? AppColors.mutedInkDark : AppColors.mutedInk;
    final Color skeleton = isDark ? AppColors.skeletonDark : AppColors.skeleton;

    final ColorScheme scheme = ColorScheme(
      brightness: brightness,
      // "Primary" here is the ink the whole direction is drawn in, so filled
      // controls read as solid blocks. The label on them is acid in light mode;
      // in dark mode the block inverts to near-white, where acid would fall to
      // roughly 1.3:1 — so it inverts too and the label goes dark.
      primary: ink,
      onPrimary: isDark ? paper : AppColors.acid,
      secondary: AppColors.hotPink,
      onSecondary: AppColors.ink,
      tertiary: AppColors.electricBlue,
      onTertiary: AppColors.paper,
      error: AppColors.alert,
      onError: AppColors.paper,
      surface: paper,
      onSurface: ink,
      // Cards and fields sit above the page.
      surfaceContainer: panel,
      surfaceContainerHigh: panel,
      surfaceContainerHighest: skeleton,
      onSurfaceVariant: muted,
      // Borders are never a tint of the background — they are the ink itself.
      outline: ink,
      outlineVariant: muted,
      surfaceTint: const Color(0x00000000),
      shadow: ink,
    );

    final TextTheme textTheme = AppTypography.of(ink, muted);

    return ThemeData(
      colorScheme: scheme,
      textTheme: textTheme,
      fontFamily: AppConstants.rota,
      scaffoldBackgroundColor: paper,
      // Cupertino-style page transitions on both platforms, replacing the
      // GetX `Transition.cupertino` default the project used to set.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      // The offset shadow cannot be expressed as elevation, so cards in this
      // app are decorated containers (see `HardEdgePanel`). This theme only
      // keeps any stray [Card] from reverting to rounded Material defaults.
      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        color: panel,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppEdges.radius),
          side: BorderSide(color: ink, width: AppEdges.border),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0x00000000),
        labelStyle: textTheme.labelSmall,
        side: BorderSide(color: ink, width: AppEdges.borderHairline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppEdges.radius),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: paper,
        foregroundColor: ink,
        surfaceTintColor: const Color(0x00000000),
        titleTextStyle: textTheme.titleMedium,
      ),
      iconTheme: IconThemeData(color: ink),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: ink),
      dividerTheme: DividerThemeData(color: ink, thickness: AppEdges.border),
      // Ripples belong to a softer language than this one. Presses read as a
      // flat tint instead; see `HardEdgePanel`.
      splashFactory: NoSplash.splashFactory,
    );
  }
}
