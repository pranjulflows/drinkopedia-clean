import 'package:dio/dio.dart';
import 'package:drinkopedia/core/network/endpoints/api_sources.dart';
import 'package:drinkopedia/features/spirits/data/models/spirit_dto.dart';
import 'package:retrofit/retrofit.dart';

part 'cocktail_db_api.g.dart';

/// Typed TheCocktailDB client.
///
/// retrofit generates the implementation, so paths, query names and response
/// types are declared once here instead of being spelled out at each call site.
@RestApi()
abstract class CocktailDbApi {
  factory CocktailDbApi(Dio dio, {String? baseUrl}) = _CocktailDbApi;

  /// Ingredient lookup by name — the source of the origin/production story.
  ///
  /// Unlike the bulk endpoints this is **not** subject to the free key's
  /// 100-row cap, which is why the catalogue is hydrated name by name.
  @GET(CocktailDbEndpoints.searchIngredient)
  Future<IngredientResponse> searchIngredient(@Query('i') String name);

  /// Ingredient lookup by id.
  @GET(CocktailDbEndpoints.lookupIngredient)
  Future<IngredientResponse> lookupIngredient(@Query('iid') String id);
}
