import 'package:drinkopedia/app/di/injector.dart';
import 'package:drinkopedia/app/theme/app_theme.dart';
import 'package:drinkopedia/core/database/app_database.dart';
import 'package:drinkopedia/features/spirits/data/datasources/cocktail_db_api.dart';
import 'package:drinkopedia/l10n/app_localizations.dart';
import 'package:drinkopedia/routing/app_router.dart';
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
  /// Built once: rebuilding a GoRouter resets the navigation stack.
  late final GoRouter _router = buildAppRouter(
    initialLocation: widget.initialLocation,
  );

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
        builder: (BuildContext context, Widget? child) {
          return MaterialApp.router(
            onGenerateTitle: (BuildContext context) =>
                AppLocalizations.of(context)!.appTitle,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
