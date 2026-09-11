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
  /// Every name in the catalogue, in display order. Its length is the size of
  /// the whole catalogue, known before a single request is made.
  Future<List<String>> loadSeedNames();

  /// Hydrates [names], a page's worth.
  ///
  /// Never throws for a single name: one failure must not cost the rest of the
  /// page. It is reported in [Hydration.failed] instead of being dropped.
  Future<Hydration> fetchByNames(List<String> names);

  Future<SpiritDto?> fetchByName(String name);

  /// One spirit by upstream id — what a deep link needs, without hydrating the
  /// rest of the catalogue to find it.
  Future<SpiritDto?> fetchById(String id);
}

/// What hydrating a set of names produced.
///
/// A name can be missing from [spirits] for two very different reasons, and
/// they must not be confused. Upstream no longer knowing it is an answer: it
/// is gone, and skipping it is right. A request that failed — throttled,
/// offline — is no answer at all, and those names are listed in [failed].
/// Treating one like the other is how a rate-limited page silently loses
/// spirits.
class Hydration {
  const Hydration({
    this.spirits = const <SpiritDto>[],
    this.failed = const <String>[],
    this.error,
  });

  final List<SpiritDto> spirits;
  final List<String> failed;

  /// The first failure among [failed], for mapping to a `Failure`.
  final Object? error;
}

class CocktailDbSpiritDataSource implements SpiritRemoteDataSource {
  CocktailDbSpiritDataSource({required this.api, this.assetBundle});

  static const String seedAssetPath = 'assets/data/spirits_seed.json';

  /// Requests in flight while hydrating a page. Deliberately modest — this is
  /// a free public API, and firing a whole page at once would be rude. It
  /// still 429s past about ninety requests in a burst, which the Dio
  /// interceptors wait out.
  static const int _concurrency = 6;

  final CocktailDbApi api;
  final AssetBundle? assetBundle;

  AssetBundle get _bundle => assetBundle ?? rootBundle;

  @override
  Future<List<String>> loadSeedNames() async {
    final String raw = await _bundle.loadString(seedAssetPath);
    final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;
    return (json['spirits'] as List<dynamic>).cast<String>();
  }

  @override
  Future<Hydration> fetchByNames(List<String> names) async {
    final List<SpiritDto> spirits = <SpiritDto>[];
    final List<String> failed = <String>[];
    Object? firstError;

    for (int i = 0; i < names.length; i += _concurrency) {
      final List<String> batch = names.sublist(
        i,
        (i + _concurrency).clamp(0, names.length),
      );
      final List<(SpiritDto?, Object?)> settled = await Future.wait(
        batch.map((String name) async {
          try {
            return (await fetchByName(name), null);
          } catch (error) {
            return (null, error);
          }
        }),
      );
      for (int j = 0; j < batch.length; j++) {
        final (SpiritDto? dto, Object? error) = settled[j];
        if (error != null) {
          failed.add(batch[j]);
          firstError ??= error;
        } else if (dto != null) {
          spirits.add(dto);
        }
      }
    }
    return Hydration(spirits: spirits, failed: failed, error: firstError);
  }

  @override
  Future<SpiritDto?> fetchByName(String name) async {
    final IngredientResponse response = await api.searchIngredient(name);
    return response.items.isEmpty ? null : response.items.first;
  }

  @override
  Future<SpiritDto?> fetchById(String id) async {
    final IngredientResponse response = await api.lookupIngredient(id);
    return response.items.isEmpty ? null : response.items.first;
  }
}
