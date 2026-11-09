import 'package:drinkopedia/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:drinkopedia/routing/app_router.dart';
import 'package:go_router/go_router.dart';

/// Owns the application's [GoRouter].
///
/// Registered in the injector like every other collaborator, so the router is
/// composed once in the object graph instead of being constructed inside a
/// widget. That matters more here than it looks: rebuilding a [GoRouter] resets
/// the navigation stack, and a widget's `build` is the one place that can
/// happen by accident.
abstract class RouterService {
  GoRouter get router;
}

class GoRouterService implements RouterService {
  GoRouterService({
    required OnboardingProvider onboarding,
    String? initialLocation,
  }) : router = buildAppRouter(
         onboarding: onboarding,
         initialLocation: initialLocation,
       );

  @override
  final GoRouter router;
}
