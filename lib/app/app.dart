import 'package:drinkopedia/app/di/injector.dart';
import 'package:drinkopedia/app/theme/app_theme.dart';
import 'package:drinkopedia/core/database/app_database.dart';
import 'package:drinkopedia/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:drinkopedia/features/spirits/data/datasources/cocktail_db_api.dart';
import 'package:drinkopedia/l10n/app_localizations.dart';
import 'package:drinkopedia/routing/router_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
        initialLocation: widget.initialLocation,
      ),
      child: ScreenUtilInit(
        designSize: DrinkopediaApp.designSize,
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (BuildContext context, Widget? child) => const _Bootstrap(),
      ),
    );
  }
}

/// Holds the first frame until the taste preference has been read.
///
/// Whether the intro has been answered is a local database read, so it is not
/// known when the app first builds — and the router's guard depends on it.
/// Waiting here means the router is only ever created with an accurate answer;
/// letting it build first and redirecting afterwards would paint the catalogue
/// and then yank it away, which reads as a bug.
///
/// The router itself is not built here. It comes from `RouterService` in the
/// injector, so it is composed once in the object graph rather than inside a
/// widget that could rebuild it and reset the navigation stack.
class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    // Deferred: providers must not be read while the tree is still building.
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveStart());
  }

  Future<void> _resolveStart() async {
    await context.read<OnboardingProvider>().load();
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
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
      routerConfig: context.read<RouterService>().router,
    );
  }
}
