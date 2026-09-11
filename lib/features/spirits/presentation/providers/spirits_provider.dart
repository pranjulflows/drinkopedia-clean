import 'package:dartz/dartz.dart';
import 'package:drinkopedia/core/error/failure.dart';
import 'package:drinkopedia/core/presentation/view_state.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit_category.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit_page.dart';
import 'package:drinkopedia/features/spirits/domain/usecases/get_spirits_page.dart';
import 'package:flutter/foundation.dart';

/// Drives the catalogue screen.
///
/// Holds no widgets and no BuildContext, so it is testable without pumping.
///
/// The catalogue arrives a page at a time: [load] fetches the first page and
/// [loadMore] each one after, as the list is scrolled. [state] always holds
/// everything loaded so far, so search, the category filter and taste ordering
/// work on it unchanged — over what has been loaded, not the whole catalogue.
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

  bool _hasMore = false;

  /// Whether pages remain beyond what has loaded.
  bool get hasMore => _hasMore;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

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

  /// The category the catalogue is narrowed to, or null for everything.
  ///
  /// Single choice on purpose. Unlike the taste intro, which orders and never
  /// hides, this is a filter: people reach for it to see *only* one thing, and
  /// a multi-select filter that can quietly combine into an empty grid is a
  /// worse answer to that than one tap per category.
  SpiritCategory? _category;
  SpiritCategory? get category => _category;

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

  /// Narrows the catalogue to [category]. Choosing the active one again clears
  /// it, so a chip toggles the way it looks like it should.
  void filterBy(SpiritCategory? category) {
    final SpiritCategory? next = category == _category ? null : category;
    if (next == _category) return;
    _category = next;
    notifyListeners();
  }

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
  List<Spirit> visibleFor(Set<SpiritCategory> preferred) {
    final List<Spirit> visible = visibleSpirits;
    if (preferred.isEmpty) return visible;

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

  /// Catalogue after the active category and search filters.
  ///
  /// The two compose — "Liqueur" plus "gin" is Sloe Gin — rather than one
  /// overriding the other.
  List<Spirit> get visibleSpirits {
    final List<Spirit>? all = _state.valueOrNull;
    if (all == null) return const <Spirit>[];

    final SpiritCategory? category = _category;
    final String needle = _query.trim().toLowerCase();
    if (category == null && needle.isEmpty) return all;

    return all.where((Spirit s) {
      if (category != null && s.category != category) return false;
      if (needle.isEmpty) return true;
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
  /// Safe to call as often as the screen likes: it does nothing while a page
  /// is already loading, once everything has loaded, before the first page is
  /// up, or after a failure until [retryLoadMore].
  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore || _loadMoreFailure != null) return;
    if (_state is! SuccessState<List<Spirit>>) return;

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

  /// Clears a failed page and tries it again.
  Future<void> retryLoadMore() {
    _loadMoreFailure = null;
    return loadMore();
  }

  Future<void> refresh() => load(forceRefresh: true);

  void search(String value) {
    if (value == _query) return;
    _query = value;
    notifyListeners();
  }
}
