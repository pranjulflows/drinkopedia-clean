import 'package:drinkopedia/core/network/endpoints/api_sources.dart';
import 'package:drinkopedia/core/network/json_converters.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit.dart';
import 'package:json_annotation/json_annotation.dart';

part 'spirit_dto.g.dart';

/// One TheCocktailDB ingredient, as it arrives on the wire.
///
/// Every field is nullable because the upstream data genuinely is: `strABV` is
/// absent for most entries and some carry an empty `strDescription`. The
/// [LooseString] / [LooseDouble] converters absorb the API's inconsistent
/// spelling of "absent" and its string-typed numbers.
@JsonSerializable(createToJson: false)
class SpiritDto {
  const SpiritDto({
    this.id,
    this.name,
    this.type,
    this.abv,
    this.description,
    this.alcohol,
  });

  factory SpiritDto.fromJson(Map<String, dynamic> json) =>
      _$SpiritDtoFromJson(json);

  @JsonKey(name: 'idIngredient')
  @LooseString()
  final String? id;

  @JsonKey(name: 'strIngredient')
  @LooseString()
  final String? name;

  @JsonKey(name: 'strType')
  @LooseLabel()
  final String? type;

  @JsonKey(name: 'strABV')
  @LooseDouble()
  final double? abv;

  @JsonKey(name: 'strDescription')
  @LooseString()
  final String? description;

  @JsonKey(name: 'strAlcohol')
  @LooseString()
  final String? alcohol;

  /// A record without an id or a name cannot be shown or linked to.
  bool get isUsable => (id?.isNotEmpty ?? false) && (name?.isNotEmpty ?? false);

  Spirit toEntity() {
    final String resolvedName = name ?? '';
    return Spirit(
      id: id ?? '',
      name: resolvedName,
      type: type,
      abv: abv,
      story: description,
      imageUrl: resolvedName.isEmpty
          ? null
          : CocktailDbEndpoints.ingredientImage(resolvedName),
      // Anything but an explicit "no" counts as alcoholic; a missing flag
      // should not hide an entry from a catalogue seeded with spirits.
      isAlcoholic: alcohol?.toLowerCase() != 'no',
    );
  }
}

/// Envelope wrapping every ingredient response.
///
/// `ingredients` is null when nothing matched — an empty result, never an
/// error. Modelling it explicitly is what stops that becoming a thrown
/// exception downstream.
@JsonSerializable(createToJson: false)
class IngredientResponse {
  const IngredientResponse({this.ingredients});

  factory IngredientResponse.fromJson(Map<String, dynamic> json) =>
      _$IngredientResponseFromJson(json);

  final List<SpiritDto>? ingredients;

  List<SpiritDto> get items =>
      ingredients?.where((SpiritDto d) => d.isUsable).toList() ??
      const <SpiritDto>[];
}
