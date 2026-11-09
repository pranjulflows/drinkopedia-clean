import 'package:dartz/dartz.dart';
import 'package:drinkopedia/core/error/failure.dart';
import 'package:drinkopedia/core/presentation/view_state.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit_category.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit_filter.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit_page.dart';
import 'package:drinkopedia/features/spirits/domain/usecases/get_spirits_page.dart';
import 'package:flutter/foundation.dart';

/// Drives the catalogue screen.
///
/// Holds no widgets and no BuildContext, so it is testable without pumping.
///
/// The catalogue arrives a page at a time: [load] fetches the first page and
/// [loadMore] each one after, as the list is scrolled. [state] always holds
/// everything loaded so far, so search, the filter and taste ordering work on
/// it unchanged — over what has been loaded, not the whole catalogue. The one
/// exception is a sort other than the catalogue's own, which needs every page
/// and fetches the rest itself; see [applyFilter].
class SpiritsProvider extends ChangeNotifier {
  SpiritsProvider({
    required this.getSpiritsPage,
    this.pageSize = defaultPageSize,
  });

  /// Entries fetched per page. Roughly five screens of grid on a phone, and at
  /// six requests in flight, about four round trips.
  static const int defaultPageSize = 20;

  final GetSpiritsPage getSpiritsPage;
  final int pageSize;

  ViewState<List<Spirit>> _state = const InitialState<List<Spirit>>();
  ViewState<List<Spirit>> get state => _state;

  List<Spirit> _items = const <Spirit>[];
  int _nextOffset = 0;

  /// Which page each loaded spirit arrived on, for [visibleFor].
  Map<String, int> _pageOf = const <String, int>{};

  /// Size of the whole catalogue, once the first page has reported it.
  int? _total;
  int? get total => _total;

  /// How many spirits have loaded so far, before search or filter.
  int get loadedCount => _items.length;

  bool _hasMore = false;

  /// Whether pages remain beyond what has loaded.
  bool get hasMore => _hasMore;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  /// The page request in flight, if any, so a second caller can wait on it
  /// instead of being turned away with nothing to wait for.
  Future<void>? _pendingPage;

  /// Why the last [loadMore] failed, if it did.
  ///
  /// While this is set, [loadMore] stops. Loading is driven by the end of the
  /// list being in view, which it still is after a failure — so without this
  /// an offline device would retry every frame. [retryLoadMore] clears it.
  Failure? _loadMoreFailure;
  Failure? get loadMoreFailure => _loadMoreFailure;

  /// Carried from [refresh] to every page fetched after it, so a pull to
  /// refresh refreshes the pages scrolled to next and not only the first.
  bool _forceRefresh = false;

  /// Bumped by every [load], so a page still in flight from before a refresh
  /// is discarded instead of being appended to the new list.
  int _generation = 0;

  String _query = '';
  String get query => _query;

  /// What the shelf is narrowed to and how it is ordered.
  ///
  /// The chip row sets one category at a time; the filter sheet can combine
  /// several, with strength bands, stories-only and a sort. Unlike the taste
  /// intro, which orders and never hides, this is a filter: it hides.
  SpiritFilter _filter = const SpiritFilter();
  SpiritFilter get filter => _filter;

  /// Whether a sort is waiting on pages that have not loaded yet.
  ///
  /// Only the catalogue sort can be shown a page at a time. Any other would
  /// reshuffle the cards already on screen as each page arrived, so the screen
  /// waits for the whole shelf instead.
  bool get needsWholeShelf => _filter.sort != SpiritSort.catalogue && _hasMore;

  /// How many loaded spirits fall in each category, in display order.
  ///
  /// Counted over the whole catalogue rather than the current search, so the
  /// filter row stays put while typing instead of chips vanishing mid-word.
  /// Only categories that actually have something in them appear: a chip that
  /// can only ever lead to an empty grid is not worth offering.
  Map<SpiritCategory, int> get categoryCounts {
    final List<Spirit>? all = _state.valueOrNull;
    if (all == null) return const <SpiritCategory, int>{};
    final Map<SpiritCategory, int> counts = <SpiritCategory, int>{};
    for (final Spirit spirit in all) {
      counts.update(spirit.category, (int n) => n + 1, ifAbsent: () => 1);
    }
    return <SpiritCategory, int>{
      for (final SpiritCategory c in SpiritCategory.values)
        if (counts.containsKey(c)) c: counts[c]!,
    };
  }

  /// Narrows the shelf to [category] alone — a tap on the chip row. Tapping
  /// the only selected category again clears it, so a chip toggles the way it
  /// looks like it should.
  void filterBy(SpiritCategory? category) =>
      applyFilter(_filter.withOnlyCategory(category));

  /// Replaces the whole filter — what the sheet's Show button does.
  ///
  /// A sort other than the catalogue's own needs every page, so applying one
  /// fetches whatever has not loaded yet.
  void applyFilter(SpiritFilter next) {
    if (next == _filter) return;
    _filter = next;
    notifyListeners();
    if (needsWholeShelf) loadAll();
  }

  void resetFilter() => applyFilter(const SpiritFilter());

  /// How many loaded spirits [draft] would show under the current search — the
  /// count on the sheet's Show button, before anything is applied.
  int countMatching(SpiritFilter draft) =>
      _searched().where(draft.matches).length;

  /// Catalogue after the active search filter, with the categories the user
  /// picked in the taste intro floated to the top of each page.
  ///
  /// Ordering, not filtering: nothing is ever hidden, because the intro is a
  /// preference and not a subscription. An empty [preferred] leaves the list
  /// untouched, which is what skipping the intro produces.
  ///
  /// Per page rather than across the whole list, because the list grows while
  /// it is being read. Floated globally, a picked spirit arriving on page two
  /// would sort above cards already scrolled past and push everything on
  /// screen down mid-read. Per page, a loaded card never moves.
  ///
  /// Only under the catalogue sort: a sort the person chose outranks the
  /// preference they gave once at the start.
  List<Spirit> visibleFor(Set<SpiritCategory> preferred) {
    final List<Spirit> visible = visibleSpirits;
    if (preferred.isEmpty || _filter.sort != SpiritSort.catalogue) {
      return visible;
    }

    final List<Spirit> ordered = List<Spirit>.of(visible);
    // Dart's sort is not stable, so ties are broken on the original index
    // rather than left to chance.
    final Map<String, int> position = <String, int>{
      for (int i = 0; i < ordered.length; i++) ordered[i].id: i,
    };
    ordered.sort((Spirit a, Spirit b) {
      final int byPage = (_pageOf[a.id] ?? 0).compareTo(_pageOf[b.id] ?? 0);
      if (byPage != 0) return byPage;
      final bool aWanted = preferred.contains(a.category);
      final bool bWanted = preferred.contains(b.category);
      if (aWanted != bWanted) return aWanted ? -1 : 1;
      return position[a.id]!.compareTo(position[b.id]!);
    });
    return ordered;
  }

  /// Catalogue after the search and the filter, in the filter's sort order.
  ///
  /// The two compose — "Liqueur" plus "gin" is Sloe Gin — rather than one
  /// overriding the other.
  List<Spirit> get visibleSpirits {
    final List<Spirit> searched = _searched();
    return _filter.isDefault ? searched : _filter.apply(searched);
  }

  /// Loaded spirits whose name or type contains the search, case-insensitively.
  List<Spirit> _searched() {
    final List<Spirit>? all = _state.valueOrNull;
    if (all == null) return const <Spirit>[];

    final String needle = _query.trim().toLowerCase();
    if (needle.isEmpty) return all;

    return all.where((Spirit s) {
      return s.name.toLowerCase().contains(needle) ||
          (s.type?.toLowerCase().contains(needle) ?? false);
    }).toList();
  }

  Future<void> load({bool forceRefresh = false}) async {
    final int generation = ++_generation;
    _forceRefresh = forceRefresh;
    _isLoadingMore = false;
    _loadMoreFailure = null;
    _state = LoadingState<List<Spirit>>(previous: _state.valueOrNull);
    notifyListeners();

    final Either<Failure?, SpiritPage> result = await getSpiritsPage(
      GetSpiritsPageParams(
        offset: 0,
        limit: pageSize,
        forceRefresh: forceRefresh,
      ),
    );
    if (generation != _generation) return;

    result.fold(
      (Failure? failure) {
        _hasMore = false;
        _state = ErrorState<List<Spirit>>(failure ?? const ServerFailure());
      },
      (SpiritPage page) {
        _items = List<Spirit>.unmodifiable(page.items);
        _pageOf = <String, int>{for (final Spirit s in page.items) s.id: 0};
        _nextOffset = page.nextOffset;
        _total = page.total;
        _hasMore = page.hasMore;
        _state = _items.isEmpty
            ? const EmptyState<List<Spirit>>('No spirits in the catalogue yet')
            : SuccessState<List<Spirit>>(_items);
      },
    );
    notifyListeners();
  }

  /// Fetches the next page and appends it.
  ///
  /// Safe to call as often as the screen likes: it does nothing once
  /// everything has loaded, before the first page is up, or after a failure
  /// until [retryLoadMore]. While a page is already loading it starts nothing
  /// new and returns that page's future, so a caller can wait for it.
  Future<void> loadMore() {
    if (_isLoadingMore) return _pendingPage ?? Future<void>.value();
    if (!_hasMore || _loadMoreFailure != null) return Future<void>.value();
    if (_state is! SuccessState<List<Spirit>>) return Future<void>.value();

    return _pendingPage = _fetchNextPage().whenComplete(
      () => _pendingPage = null,
    );
  }

  /// Loads every remaining page, one after another, until the catalogue runs
  /// out, a page fails, or a refresh replaces the list.
  Future<void> loadAll() async {
    final int generation = _generation;
    while (_hasMore &&
        _loadMoreFailure == null &&
        generation == _generation &&
        _state is SuccessState<List<Spirit>>) {
      await loadMore();
    }
  }

  Future<void> _fetchNextPage() async {
    final int generation = _generation;
    _isLoadingMore = true;
    notifyListeners();

    final Either<Failure?, SpiritPage> result = await getSpiritsPage(
      GetSpiritsPageParams(
        offset: _nextOffset,
        limit: pageSize,
        forceRefresh: _forceRefresh,
      ),
    );
    // A refresh started while this page was in flight; it belongs to a list
    // that no longer exists.
    if (generation != _generation) return;

    result.fold(
      (Failure? failure) => _loadMoreFailure = failure ?? const ServerFailure(),
      (SpiritPage page) {
        final int pageIndex = _pageOf.isEmpty
            ? 0
            : _pageOf.values.reduce((int a, int b) => a > b ? a : b) + 1;
        _items = List<Spirit>.unmodifiable(<Spirit>[..._items, ...page.items]);
        _pageOf = <String, int>{
          ..._pageOf,
          for (final Spirit s in page.items) s.id: pageIndex,
        };
        _nextOffset = page.nextOffset;
        _total = page.total;
        _hasMore = page.hasMore;
        _state = SuccessState<List<Spirit>>(_items);
      },
    );
    _isLoadingMore = false;
    notifyListeners();
  }

  /// Clears a failed page and tries it again — and, when a sort is waiting
  /// on the whole shelf, carries on through the rest.
  Future<void> retryLoadMore() {
    _loadMoreFailure = null;
    return needsWholeShelf ? loadAll() : loadMore();
  }

  Future<void> refresh() => load(forceRefresh: true);

  void search(String value) {
    if (value == _query) return;
    _query = value;
    notifyListeners();
  }
}
