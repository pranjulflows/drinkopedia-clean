import 'package:drinkopedia/features/spirits/domain/entities/spirit.dart';
import 'package:drinkopedia/features/spirits/presentation/screens/spirit_detail_screen.dart';
import 'package:drinkopedia/features/spirits/presentation/screens/spirits_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

part 'app_routes.g.dart';

/// Typed route table.
///
/// Each route is a class, so its parameters are checked at compile time and a
/// missing or misspelled argument is a build error rather than a runtime crash.
///
/// Path parameters carry everything a route genuinely needs; `$extra` only ever
/// carries an optimisation. `$extra` does not survive a deep link, an app
/// restart, or a process death, so every screen must still work without it.
@TypedGoRoute<SpiritsRoute>(
  path: SpiritsRoute.path,
  routes: <TypedGoRoute<GoRouteData>>[
    TypedGoRoute<SpiritDetailRoute>(path: SpiritDetailRoute.relativePath),
  ],
)
class SpiritsRoute extends GoRouteData with $SpiritsRoute {
  const SpiritsRoute();

  static const String path = '/spirits';

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SpiritsScreen();
}

/// `/spirits/:id` — deep-linkable.
///
/// [$extra] is the already-loaded entity when arriving from the catalogue, so
/// the hero transition has something to paint immediately. When it is null the
/// screen fetches by [id] instead.
class SpiritDetailRoute extends GoRouteData with $SpiritDetailRoute {
  const SpiritDetailRoute({required this.id, this.$extra});

  static const String relativePath = ':id';

  final String id;
  final Spirit? $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      SpiritDetailScreen(spiritId: id, preloaded: $extra);
}
