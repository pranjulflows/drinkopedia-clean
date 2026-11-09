class AppConstants {
  AppConstants._();

  static const int transitionDuration = 250;
  static const int popBackDelay300 = 300;
  static const String rota = "Rota";

  /// Registered as its own family, not as a weight: Rota ExtraBlack is heavier
  /// than Black, and 900 is the most `FontWeight` can express. Select it by
  /// family — setting a weight on it has no effect.
  static const String rotaExtraBlack = "Rota ExtraBlack";
  static const String currency = "\$";
}
