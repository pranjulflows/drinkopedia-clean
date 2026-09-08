import 'package:dartz/dartz.dart';
import 'package:drinkopedia/core/error/failure.dart';
import 'package:drinkopedia/core/presentation/view_state.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit.dart';
import 'package:drinkopedia/features/spirits/domain/usecases/get_spirit_detail.dart';
import 'package:flutter/foundation.dart';

/// Drives the detail screen.
///
/// [preloaded] is the entity handed over by a list tap so the screen can paint
/// immediately. It is always optional: arriving by deep link or after a process
/// death leaves it null, and the screen must fetch instead. That path is the
/// one that actually breaks in practice, so it is the default here.
class SpiritDetailProvider extends ChangeNotifier {
  SpiritDetailProvider({
    required this.getSpiritDetail,
    required this.id,
    Spirit? preloaded,
  }) : _state = preloaded == null
           ? const InitialState<Spirit>()
           : SuccessState<Spirit>(preloaded);

  final GetSpiritDetail getSpiritDetail;
  final String id;

  ViewState<Spirit> _state;
  ViewState<Spirit> get state => _state;

  /// True when the screen opened without a preloaded entity and must fetch.
  bool get needsFetch => _state is InitialState<Spirit>;

  Future<void> load() async {
    if (_state is! SuccessState<Spirit>) {
      _state = const LoadingState<Spirit>();
      notifyListeners();
    }

    final Either<Failure?, Spirit> result = await getSpiritDetail(
      GetSpiritDetailParams(id),
    );

    _state = result.fold((Failure? failure) {
      // A refresh failure with content already on screen should not wipe it.
      final Spirit? existing = _state.valueOrNull;
      return existing != null
          ? SuccessState<Spirit>(existing, isStale: true)
          : ErrorState<Spirit>(failure ?? const ServerFailure());
    }, SuccessState<Spirit>.new);
    notifyListeners();
  }
}
