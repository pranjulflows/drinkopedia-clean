import 'package:dartz/dartz.dart';
import 'package:drinkopedia/core/error/failure.dart';
import 'package:drinkopedia/core/presentation/view_state.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit.dart';
import 'package:drinkopedia/features/spirits/domain/usecases/get_spirits.dart';
import 'package:flutter/foundation.dart';

/// Drives the catalogue screen.
///
/// Holds no widgets and no BuildContext, so it is testable without pumping.
class SpiritsProvider extends ChangeNotifier {
  SpiritsProvider({required this.getSpirits});

  final GetSpirits getSpirits;

  ViewState<List<Spirit>> _state = const InitialState<List<Spirit>>();
  ViewState<List<Spirit>> get state => _state;

  String _query = '';
  String get query => _query;

  /// Catalogue after the active search filter.
  List<Spirit> get visibleSpirits {
    final List<Spirit>? all = _state.valueOrNull;
    if (all == null) return const <Spirit>[];
    if (_query.trim().isEmpty) return all;
    final String needle = _query.trim().toLowerCase();
    return all
        .where(
          (Spirit s) =>
              s.name.toLowerCase().contains(needle) ||
              (s.type?.toLowerCase().contains(needle) ?? false),
        )
        .toList();
  }

  Future<void> load({bool forceRefresh = false}) async {
    _state = LoadingState<List<Spirit>>(previous: _state.valueOrNull);
    notifyListeners();

    final Either<Failure?, List<Spirit>> result = await getSpirits(
      GetSpiritsParams(forceRefresh: forceRefresh),
    );

    _state = result.fold(
      (Failure? failure) =>
          ErrorState<List<Spirit>>(failure ?? const ServerFailure()),
      (List<Spirit> spirits) => spirits.isEmpty
          ? const EmptyState<List<Spirit>>('No spirits in the catalogue yet')
          : SuccessState<List<Spirit>>(spirits),
    );
    notifyListeners();
  }

  Future<void> refresh() => load(forceRefresh: true);

  void search(String value) {
    if (value == _query) return;
    _query = value;
    notifyListeners();
  }
}
