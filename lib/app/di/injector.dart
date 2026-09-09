import 'package:dio/dio.dart';
import 'package:drinkopedia/core/database/app_database.dart';
import 'package:drinkopedia/core/database/daos/preferences_dao.dart';
import 'package:drinkopedia/core/database/daos/spirits_dao.dart';
import 'package:drinkopedia/core/network/dio_factory.dart';
import 'package:drinkopedia/core/network/endpoints/api_sources.dart';
import 'package:drinkopedia/features/onboarding/data/repositories/taste_repository_impl.dart';
import 'package:drinkopedia/features/onboarding/domain/repositories/taste_repository.dart';
import 'package:drinkopedia/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:drinkopedia/features/spirits/data/datasources/cocktail_db_api.dart';
import 'package:drinkopedia/features/spirits/data/datasources/spirit_remote_data_source.dart';
import 'package:drinkopedia/features/spirits/data/repositories/spirit_repository_impl.dart';
import 'package:drinkopedia/features/spirits/domain/repositories/spirit_repository.dart';
import 'package:drinkopedia/features/spirits/domain/usecases/get_spirit_detail.dart';
import 'package:drinkopedia/features/spirits/domain/usecases/get_spirits.dart';
import 'package:drinkopedia/features/spirits/presentation/providers/spirits_provider.dart';
import 'package:drinkopedia/routing/navigation_service.dart';
import 'package:drinkopedia/routing/router_service.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// The one place the object graph is assembled.
///
/// Everything is registered against its *interface* — `SpiritRemoteDataSource`,
/// `SpiritRepository`, `NavigationService` — so consumers depend on contracts
/// and any of them can be swapped in a test without touching a screen.
///
/// [database] and [cocktailDbApi] are injectable so tests can supply an
/// in-memory database and a stubbed API. [initialLocation] is threaded through
/// to the router for deep links and for tests that open a specific screen.
List<SingleChildWidget> buildProviders({
  AppDatabase? database,
  CocktailDbApi? cocktailDbApi,
  String? initialLocation,
}) {
  final AppDatabase db = database ?? AppDatabase();

  return <SingleChildWidget>[
    Provider<AppDatabase>.value(value: db),
    Provider<SpiritsDao>(create: (_) => SpiritsDao(db)),
    Provider<PreferencesDao>(create: (_) => PreferencesDao(db)),

    // One Dio per upstream source: different base URLs and header
    // requirements, so a shared instance would leak headers across sources.
    Provider<Dio>(
      create: (_) => DioFactory.create(baseUrl: ApiSources.cocktailDbBaseUrl),
    ),
    Provider<CocktailDbApi>(
      create: (BuildContext context) =>
          cocktailDbApi ?? CocktailDbApi(context.read<Dio>()),
    ),

    Provider<SpiritRemoteDataSource>(
      create: (BuildContext context) =>
          CocktailDbSpiritDataSource(api: context.read<CocktailDbApi>()),
    ),
    Provider<SpiritRepository>(
      create: (BuildContext context) => SpiritRepositoryImpl(
        remoteDataSource: context.read<SpiritRemoteDataSource>(),
        dao: context.read<SpiritsDao>(),
      ),
    ),

    Provider<GetSpirits>(
      create: (BuildContext context) =>
          GetSpirits(context.read<SpiritRepository>()),
    ),
    Provider<GetSpiritDetail>(
      create: (BuildContext context) =>
          GetSpiritDetail(context.read<SpiritRepository>()),
    ),

    Provider<NavigationService>(
      create: (_) => const GoRouterNavigationService(),
    ),

    Provider<TasteRepository>(
      create: (BuildContext context) =>
          TasteRepositoryImpl(dao: context.read<PreferencesDao>()),
    ),

    // Catalogue state is app-scoped so it survives navigation; detail state is
    // created per screen instead.
    ChangeNotifierProvider<SpiritsProvider>(
      create: (BuildContext context) =>
          SpiritsProvider(getSpirits: context.read<GetSpirits>()),
    ),

    // App-scoped: the intro writes the taste preference, and the catalogue
    // reads it back to decide what to show first, so it outlives the screen.
    ChangeNotifierProvider<OnboardingProvider>(
      create: (BuildContext context) =>
          OnboardingProvider(repository: context.read<TasteRepository>()),
    ),

    // Composed here rather than inside a widget: a GoRouter rebuilt during a
    // `build` silently resets the navigation stack. Provider creates it lazily
    // and holds it, so it is built exactly once — and by the time anything
    // reads it, the taste preference its guard depends on has resolved.
    Provider<RouterService>(
      create: (BuildContext context) => GoRouterService(
        onboarding: context.read<OnboardingProvider>(),
        initialLocation: initialLocation,
      ),
    ),
  ];
}
