import 'package:flutter/material.dart';

/// Border, radius and shadow tokens for the "neo-brutalist pop" direction.
///
/// The shadow is the direction's signature and is *not* an elevation shadow:
/// zero blur, no spread, a hard offset block of solid ink. Material's
/// `elevation` cannot express it, which is why cards here are decorated
/// containers rather than [Card]s.
class AppEdges {
  AppEdges._();

  /// Corners are square on purpose. Kept as a named token so the intent reads
  /// as a decision rather than an omission.
  static const double radius = 0;

  static const double border = 3;
  static const double borderHairline = 2;
  static const double borderHeavy = 4;

  /// Cards, and the primary button.
  static const Offset shadow = Offset(5, 5);

  /// Input fields.
  static const Offset shadowField = Offset(4, 4);

  /// Icon buttons, which are small enough that the full offset overwhelms them.
  static const Offset shadowCompact = Offset(3, 3);

  /// Minimum tap target. Matched by every interactive element in this
  /// direction — the icon buttons are 46 rather than 44 so they align with the
  /// field height beside them.
  static const double minTapTarget = 44;

  static List<BoxShadow> hard(Color color, Offset offset) => <BoxShadow>[
    BoxShadow(color: color, offset: offset),
  ];
}
