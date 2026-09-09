import 'package:drinkopedia/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:drinkopedia/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Builds the application router.
///
/// Held for the lifetime of the app — rebuilding a [GoRouter] resets the
/// navigation stack, so it must never be constructed inside a `build`. Reach it
/// through `RouterService` from the injector rather than calling this directly.
///
/// [onboarding] gates every route behind the taste intro until that has been
/// answered. It is read, not watched: the app resolves the preference before
/// the first route is ever built, so the guard is already accurate by the time
/// it runs.
GoRouter buildAppRouter({
  required OnboardingProvider onboarding,
  String? initialLocation,
}) {
  return GoRouter(
    initialLocation: initialLocation ?? SpiritsRoute.path,
    routes: $appRoutes,
    redirect: (BuildContext context, GoRouterState state) {
      if (onboarding.isComplete) return null;
      if (state.matchedLocation == OnboardingRoute.path) return null;
      return OnboardingRoute.path;
    },
    errorBuilder: (BuildContext context, GoRouterState state) =>
        _RouteErrorScreen(location: state.uri.toString()),
  );
}

class _RouteErrorScreen extends StatelessWidget {
  const _RouteErrorScreen({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.explore_off_outlined,
                size: 48,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'That page does not exist',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                location,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => const SpiritsRoute().go(context),
                child: const Text('Back to the catalogue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
