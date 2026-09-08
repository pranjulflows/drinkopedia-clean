import 'package:dio/dio.dart';
import 'package:drinkopedia/core/database/app_database.dart';
import 'package:drinkopedia/core/database/daos/spirits_dao.dart';
import 'package:drinkopedia/core/network/dio_factory.dart';
import 'package:drinkopedia/core/network/endpoints/api_sources.dart';
import 'package:drinkopedia/features/spirits/data/datasources/cocktail_db_api.dart';
import 'package:drinkopedia/features/spirits/data/datasources/spirit_remote_data_source.dart';
import 'package:drinkopedia/features/spirits/data/repositories/spirit_repository_impl.dart';
import 'package:drinkopedia/features/spirits/domain/repositories/spirit_repository.dart';
import 'package:drinkopedia/features/spirits/domain/usecases/get_spirit_detail.dart';
import 'package:drinkopedia/features/spirits/domain/usecases/get_spirits.dart';
import 'package:drinkopedia/features/spirits/presentation/providers/spirits_provider.dart';
import 'package:drinkopedia/routing/navigation_service.dart';
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
/// in-memory database and a stubbed API.
List<SingleChildWidget> buildProviders({
  AppDatabase? database,
  CocktailDbApi? cocktailDbApi,
}) {
  final AppDatabase db = database ?? AppDatabase();

  return <SingleChildWidget>[
    Provider<AppDatabase>.value(value: db),
    Provider<SpiritsDao>(create: (_) => SpiritsDao(db)),

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

    // Catalogue state is app-scoped so it survives navigation; detail state is
    // created per screen instead.
    ChangeNotifierProvider<SpiritsProvider>(
      create: (BuildContext context) =>
          SpiritsProvider(getSpirits: context.read<GetSpirits>()),
    ),
  ];
}
