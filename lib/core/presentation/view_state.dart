import 'package:drinkopedia/core/error/failure.dart';

/// What a screen can be showing, as a closed set.
///
/// Sealed so `switch` over it is exhaustive: adding a state becomes a compile
/// error at every render site instead of a silently unhandled branch. Empty is
/// separate from success-with-no-rows on purpose — the two want different UI.
sealed class ViewState<T> {
  const ViewState();

  bool get isLoading => this is LoadingState<T>;

  /// Data to render, if this state carries any.
  T? get valueOrNull => switch (this) {
    SuccessState<T>(:final T data) => data,
    _ => null,
  };
}

class InitialState<T> extends ViewState<T> {
  const InitialState();
}

class LoadingState<T> extends ViewState<T> {
  /// Data already on screen during a refresh, so the UI can keep showing it
  /// instead of flashing a skeleton over content the user is reading.
  const LoadingState({this.previous});

  final T? previous;
}

class SuccessState<T> extends ViewState<T> {
  const SuccessState(this.data, {this.isStale = false});

  final T data;

  /// Served from cache after a failed refresh.
  final bool isStale;
}

class EmptyState<T> extends ViewState<T> {
  const EmptyState([this.message]);

  final String? message;
}

class ErrorState<T> extends ViewState<T> {
  const ErrorState(this.failure);

  final Failure failure;
}
