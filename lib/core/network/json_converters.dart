import 'package:json_annotation/json_annotation.dart';

/// Normalises the three ways TheCocktailDB spells "no value".
///
/// The same field may arrive as JSON `null`, the four-character string
/// `"null"`, or an empty string. Without this every consumer would have to
/// re-check all three.
class LooseString implements JsonConverter<String?, Object?> {
  const LooseString();

  @override
  String? fromJson(Object? json) {
    if (json == null) return null;
    final String text = json.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return null;
    return text;
  }

  @override
  Object? toJson(String? object) => object;
}

/// A [LooseString] for category labels that also corrects upstream's known
/// misspellings.
///
/// TheCocktailDB types 23 of its liqueurs as `"Liquer"`. Corrected here, at
/// the boundary, it never reaches the cache or a card; left alone, every
/// consumer that shows or matches the type would have to know about it.
class LooseLabel implements JsonConverter<String?, Object?> {
  const LooseLabel();

  static const Map<String, String> _corrections = <String, String>{
    'liquer': 'Liqueur',
  };

  @override
  String? fromJson(Object? json) {
    final String? text = const LooseString().fromJson(json);
    if (text == null) return null;
    return _corrections[text.toLowerCase()] ?? text;
  }

  @override
  Object? toJson(String? object) => object;
}

/// Parses a numeric field that arrives as a string (`"strABV": "40"`), and
/// yields null rather than throwing on values like `"about 40"`.
class LooseDouble implements JsonConverter<double?, Object?> {
  const LooseDouble();

  @override
  double? fromJson(Object? json) {
    if (json == null) return null;
    if (json is num) return json.toDouble();
    return double.tryParse(json.toString().trim());
  }

  @override
  Object? toJson(double? object) => object;
}
