import 'package:equatable/equatable.dart';

/// A category of alcohol — vodka, bourbon, mezcal — and the story behind it.
///
/// Everything but [id] and [name] is optional because the upstream data is
/// genuinely incomplete: `strABV` is absent for most entries and some, like
/// Mezcal, carry an empty description. Screens branch on the `has*` getters
/// rather than null-checking fields, so "missing" is a domain concept instead
/// of a UI concern.
class Spirit extends Equatable {
  const Spirit({
    required this.id,
    required this.name,
    this.type,
    this.abv,
    this.story,
    this.imageUrl,
    this.isAlcoholic = true,
  });

  final String id;
  final String name;

  /// Upstream family, e.g. "Whiskey", "Fortified Wine". Not a fixed taxonomy.
  final String? type;

  /// Alcohol by volume, as a percentage.
  final double? abv;

  /// Long-form origin and production narrative. The centrepiece of the app —
  /// runs to several thousand characters for the well-documented spirits.
  final String? story;

  final String? imageUrl;
  final bool isAlcoholic;

  bool get hasStory => story != null && story!.trim().isNotEmpty;
  bool get hasAbv => abv != null;
  bool get hasType => type != null && type!.trim().isNotEmpty;

  /// Enough detail to be worth opening a detail screen for.
  bool get isComplete => hasStory && hasType;

  /// First paragraph of [story], for card summaries.
  String? get storyExcerpt {
    if (!hasStory) return null;
    final String text = story!.trim();
    final int breakAt = text.indexOf('\n\n');
    final String firstBlock = breakAt == -1 ? text : text.substring(0, breakAt);
    return firstBlock.length <= 240
        ? firstBlock
        : '${firstBlock.substring(0, 237).trimRight()}…';
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    name,
    type,
    abv,
    story,
    imageUrl,
    isAlcoholic,
  ];
}
