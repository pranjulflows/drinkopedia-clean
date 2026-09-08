import 'package:drinkopedia/features/spirits/domain/entities/spirit.dart';
import 'package:drinkopedia/routing/app_routes.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Navigation contract.
///
/// Widgets depend on this rather than on `GoRouter` directly, which keeps
/// go_router out of the presentation layer and makes navigation mockable.
abstract class NavigationService {
  void goToSpirits(BuildContext context);

  /// Opens a spirit's detail screen.
  ///
  /// [preloaded] is a rendering optimisation only — passing it lets the detail
  /// screen paint before any fetch resolves. The destination works identically
  /// without it, which is what a deep link relies on.
  void goToSpiritDetail(BuildContext context, String id, {Spirit? preloaded});

  void back(BuildContext context);
}

class GoRouterNavigationService implements NavigationService {
  const GoRouterNavigationService();

  @override
  void goToSpirits(BuildContext context) => const SpiritsRoute().go(context);

  @override
  void goToSpiritDetail(BuildContext context, String id, {Spirit? preloaded}) =>
      SpiritDetailRoute(id: id, $extra: preloaded).push<void>(context);

  @override
  void back(BuildContext context) {
    final GoRouter router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      // Reached directly by deep link, so there is no back stack to unwind.
      goToSpirits(context);
    }
  }
}
