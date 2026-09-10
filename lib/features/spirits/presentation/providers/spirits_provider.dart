import 'package:dartz/dartz.dart';
import 'package:drinkopedia/core/error/failure.dart';
import 'package:drinkopedia/core/presentation/view_state.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit_category.dart';
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
  /// picked in the taste intro floated to the top.
  ///
  /// Ordering, not filtering: nothing is ever hidden, because the intro is a
  /// preference and not a subscription. A stable sort keeps the alphabetical
  /// order inside each group. An empty [preferred] leaves the list untouched,
  /// which is what skipping the intro produces.
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
