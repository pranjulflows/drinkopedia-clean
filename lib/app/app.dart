import 'package:drinkopedia/app/di/injector.dart';
import 'package:drinkopedia/app/theme/app_theme.dart';
import 'package:drinkopedia/core/database/app_database.dart';
import 'package:drinkopedia/features/spirits/data/datasources/cocktail_db_api.dart';
import 'package:drinkopedia/l10n/app_localizations.dart';
import 'package:drinkopedia/routing/router_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
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
    this.imageCacheManager,
  });

  final AppDatabase? database;
  final String? initialLocation;

  /// Stubbed in tests so no suite touches the network.
  final CocktailDbApi? cocktailDbApi;

  /// Stubbed in tests so no suite needs sqflite, which the default one uses.
  final BaseCacheManager? imageCacheManager;

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
        imageCacheManager: widget.imageCacheManager,
      ),
      child: ScreenUtilInit(
        designSize: DrinkopediaApp.designSize,
        minTextAdapt: true,
        splitScreenMode: true,
        // The router comes from the injector rather than being built here: a
        // GoRouter rebuilt during a `build` silently resets the navigation
        // stack. A cold start lands on the splash route, which resolves the
        // taste preference before handing over to the catalogue.
        builder: (BuildContext context, Widget? child) => MaterialApp.router(
          onGenerateTitle: (BuildContext context) =>
              AppLocalizations.of(context)!.appTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: context.read<RouterService>().router,
        ),
      ),
    );
  }
}
