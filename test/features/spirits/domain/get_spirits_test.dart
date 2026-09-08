import 'package:dartz/dartz.dart';
import 'package:drinkopedia/core/error/failure.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit.dart';
import 'package:drinkopedia/features/spirits/domain/repositories/spirit_repository.dart';
import 'package:drinkopedia/features/spirits/domain/usecases/get_spirits.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements SpiritRepository {}

void main() {
  test('entries with a story sort ahead of those without', () async {
    final _MockRepo repo = _MockRepo();
    when(
      () => repo.getSpirits(forceRefresh: any(named: 'forceRefresh')),
    ).thenAnswer(
      (_) async => const Right<Failure, List<Spirit>>(<Spirit>[
        Spirit(id: '1', name: 'Zubrowka'),
        Spirit(id: '2', name: 'Absinthe', story: 'A long history...'),
        Spirit(id: '3', name: 'Aperol'),
        Spirit(id: '4', name: 'Bourbon', story: 'Kentucky...'),
      ]),
    );

    final Either<Failure?, List<Spirit>> result = await GetSpirits(repo)(
      const GetSpiritsParams(),
    );

    final List<String> names = result
        .getOrElse(() => <Spirit>[])
        .map((Spirit s) => s.name)
        .toList();

    // Storied entries first, each group alphabetical.
    expect(names, <String>['Absinthe', 'Bourbon', 'Aperol', 'Zubrowka']);
  });

  test('propagates a failure untouched', () async {
    final _MockRepo repo = _MockRepo();
    when(
      () => repo.getSpirits(forceRefresh: any(named: 'forceRefresh')),
    ).thenAnswer(
      (_) async => const Left<Failure, List<Spirit>>(NetworkFailure('offline')),
    );

    final Either<Failure?, List<Spirit>> result = await GetSpirits(repo)(
      const GetSpiritsParams(),
    );

    expect(result.isLeft(), isTrue);
  });
}
