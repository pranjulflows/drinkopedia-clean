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
