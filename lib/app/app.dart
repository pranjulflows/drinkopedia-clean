import 'package:drinkopedia/app/di/injector.dart';
import 'package:drinkopedia/app/theme/app_theme.dart';
import 'package:drinkopedia/core/database/app_database.dart';
import 'package:drinkopedia/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:drinkopedia/features/spirits/data/datasources/cocktail_db_api.dart';
import 'package:drinkopedia/l10n/app_localizations.dart';
import 'package:drinkopedia/routing/app_router.dart';
import 'package:drinkopedia/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Application root.
///
/// [database] and [initialLocation] exist so tests can run against an in-memory
/// database and start at an arbitrary route — the latter is how the deep-link
/// path gets covered.
class DrinkopediaApp extends StatefulWidget {
  const DrinkopediaApp({
    super.key,
    this.database,
    this.initialLocation,
    this.cocktailDbApi,
  });

  final AppDatabase? database;
  final String? initialLocation;

  /// Stubbed in tests so no suite touches the network.
  final CocktailDbApi? cocktailDbApi;

  /// Reference canvas the `.w` / `.h` / `.sp` values were authored against.
  static const Size designSize = Size(375, 812);

  @override
  State<DrinkopediaApp> createState() => _DrinkopediaAppState();
}

class _DrinkopediaAppState extends State<DrinkopediaApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: buildProviders(
        database: widget.database,
        cocktailDbApi: widget.cocktailDbApi,
      ),
      child: ScreenUtilInit(
        designSize: DrinkopediaApp.designSize,
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (BuildContext context, Widget? child) =>
            _Bootstrap(initialLocation: widget.initialLocation),
      ),
    );
  }
}

/// Decides where the app opens, then builds the router exactly once.
///
/// Whether the taste intro has been through is a local database read, so it is
/// not known on the first frame. The router is therefore built *after* that
/// read rather than being redirected afterwards — a redirect would paint the
/// catalogue first and yank it away, which reads as a bug.
class _Bootstrap extends StatefulWidget {
  const _Bootstrap({this.initialLocation});

  final String? initialLocation;

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    // Deferred: providers must not be read while the tree is still building.
    WidgetsBinding.instance.addPostFrameCallback((_) => _decideStart());
  }

  Future<void> _decideStart() async {
    final OnboardingProvider onboarding = context.read<OnboardingProvider>();
    await onboarding.load();
    if (!mounted) return;

    setState(() {
      // An explicit initialLocation wins: it is how deep links and tests open
      // a specific screen, and neither should be swallowed by the intro.
      _router = buildAppRouter(
        initialLocation:
            widget.initialLocation ??
            (onboarding.isComplete ? SpiritsRoute.path : OnboardingRoute.path),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final GoRouter? router = _router;
    if (router == null) {
      // Deliberately bare. This is one local read long, and anything with
      // branding on it would flash.
      return ColoredBox(
        color: AppTheme.light().scaffoldBackgroundColor,
        child: const SizedBox.expand(),
      );
    }

    return MaterialApp.router(
      onGenerateTitle: (BuildContext context) =>
          AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
