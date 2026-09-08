import 'dart:convert';

import 'package:drinkopedia/features/spirits/data/datasources/cocktail_db_api.dart';
import 'package:drinkopedia/features/spirits/data/models/spirit_dto.dart';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;

/// Catalogue access, above the raw HTTP client.
///
/// Kept separate from [CocktailDbApi] on purpose: that class is only concerned
/// with the wire protocol, while the seed-list hydration and batching here are
/// application policy.
abstract class SpiritRemoteDataSource {
  Future<List<SpiritDto>> fetchCatalogue();

  Future<SpiritDto?> fetchByName(String name);
}

class CocktailDbSpiritDataSource implements SpiritRemoteDataSource {
  CocktailDbSpiritDataSource({required this.api, this.assetBundle});

  static const String seedAssetPath = 'assets/data/spirits_seed.json';

  /// Requests in flight while hydrating. Deliberately modest — this is a free
  /// public API, and 44 parallel requests would be both rude and 429-prone.
  static const int _concurrency = 6;

  final CocktailDbApi api;
  final AssetBundle? assetBundle;

  AssetBundle get _bundle => assetBundle ?? rootBundle;

  Future<List<String>> loadSeedNames() async {
    final String raw = await _bundle.loadString(seedAssetPath);
    final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;
    return (json['spirits'] as List<dynamic>).cast<String>();
  }

  @override
  Future<List<SpiritDto>> fetchCatalogue() async {
    final List<String> names = await loadSeedNames();
    final List<SpiritDto> results = <SpiritDto>[];

    for (int i = 0; i < names.length; i += _concurrency) {
      final List<String> batch = names.sublist(
        i,
        (i + _concurrency).clamp(0, names.length),
      );
      final List<SpiritDto?> settled = await Future.wait(
        batch.map((String name) async {
          try {
            return await fetchByName(name);
          } catch (_) {
            // One bad name must not sink the whole catalogue; the seed is
            // verified, but upstream data does change.
            return null;
          }
        }),
      );
      results.addAll(settled.whereType<SpiritDto>());
    }
    return results;
  }

  @override
  Future<SpiritDto?> fetchByName(String name) async {
    final IngredientResponse response = await api.searchIngredient(name);
    return response.items.isEmpty ? null : response.items.first;
  }
}
