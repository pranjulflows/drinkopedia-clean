import 'package:drinkopedia/app/theme/app_edges.dart';
import 'package:drinkopedia/core/presentation/view_state.dart';
import 'package:drinkopedia/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit.dart';
import 'package:drinkopedia/features/spirits/presentation/providers/spirits_provider.dart';
import 'package:drinkopedia/features/spirits/presentation/widgets/category_filter_bar.dart';
import 'package:drinkopedia/features/spirits/presentation/widgets/spirit_card.dart';
import 'package:drinkopedia/features/spirits/presentation/widgets/spirit_card_skeleton.dart';
import 'package:drinkopedia/features/spirits/presentation/widgets/spirit_message.dart';
import 'package:drinkopedia/l10n/app_localizations.dart';
import 'package:drinkopedia/routing/navigation_service.dart';
import 'package:drinkopedia/shared/animations/staggered_entrance.dart';
import 'package:drinkopedia/shared/widgets/hard_edge/hard_edge_button.dart';
import 'package:drinkopedia/shared/widgets/hard_edge/hard_edge_search_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Grid geometry, shared by the real grid and its skeleton so the layout does
/// not shift when data lands.
///
/// The spacing has to clear the cards' offset shadow, or neighbours paint over
/// it. The aspect ratio is set by the card's own anatomy: a square-ish artwork
/// well above a fixed two-line text block.
const SliverGridDelegateWithMaxCrossAxisExtent _gridDelegate =
    SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 220,
      mainAxisSpacing: 18,
      crossAxisSpacing: 16,
      childAspectRatio: 0.86,
    );

/// The catalogue: every spirit in the database, with its story one tap away.
class SpiritsScreen extends StatefulWidget {
  const SpiritsScreen({super.key});

  @override
  State<SpiritsScreen> createState() => _SpiritsScreenState();
}

class _SpiritsScreenState extends State<SpiritsScreen> {
  /// How close to the end of the list, in pixels, the next page is requested.
  /// About two rows of cards: far enough ahead that it has usually landed by
  /// the time the finger gets there.
  static const double _loadAheadExtent = 600;

  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
    // Deferred: providers must not be mutated during the first build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SpiritsProvider>().load();
    });
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_maybeLoadMore)
      ..dispose();
    super.dispose();
  }

  /// Asks for the next page once the end of the list is near.
  ///
  /// Also run after every build, not only on scroll. A list shorter than the
  /// screen never scrolls — which is exactly what a category filter produces
  /// before its spirits have loaded — and without this it would sit there
  /// empty with nothing to drag. Checking after each build keeps loading until
  /// the screen fills or the catalogue runs out. [SpiritsProvider.loadMore]
  /// ignores calls it cannot act on, so calling it freely is safe.
  void _maybeLoadMore() {
    if (!mounted || !_scroll.hasClients) return;
    final ScrollPosition position = _scroll.position;
    // Attached but not yet laid out, so it has no extent to measure. This is
    // the catalogue built underneath a deep-linked detail screen: it exists in
    // the route stack but has never been sized, and asking its extent throws.
    if (!position.hasContentDimensions) return;
    if (position.extentAfter < _loadAheadExtent) {
      context.read<SpiritsProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final SpiritsProvider provider = context.watch<SpiritsProvider>();
    // Ordering only — the taste intro floats what was picked to the top and
    // never hides the rest.
    final List<Spirit> visible = provider.visibleFor(
      context.watch<OnboardingProvider>().categories,
    );
    // Search filters what the catalogue loaded, so it needs a catalogue. This
    // is null only when the cache was empty *and* the refresh failed — the
    // repository falls back to stale data whenever it has any — so there is
    // genuinely nothing to search, and searching upstream would fail too.
    final bool canSearch = provider.state.valueOrNull != null;
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoadMore());

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: provider.refresh,
          color: theme.colorScheme.onSurface,
          backgroundColor: theme.colorScheme.surfaceContainer,
          child: CustomScrollView(
            controller: _scroll,
            // Dragging the results puts the keyboard away. On a phone it covers
            // half the catalogue, so scrolling to look at what you searched for
            // is the most natural way to ask for it to go.
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: <Widget>[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              l10n.catalogueTitle.toUpperCase(),
                              style: theme.textTheme.displayMedium,
                            ),
                          ),
                          const SizedBox(width: 12),
                          HardEdgeIconButton(
                            icon: Icons.refresh,
                            onPressed: provider.refresh,
                            tooltip: l10n.refresh,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      HardEdgeSearchField(
                        hintText: l10n.searchSpirits,
                        onChanged: provider.search,
                        clearTooltip: l10n.clearSearch,
                        enabled: canSearch,
                      ),
                      // Hidden rather than disabled when nothing loaded: a row
                      // of chips all counting zero is noise, not a control.
                      if (canSearch) ...<Widget>[
                        const SizedBox(height: 14),
                        CategoryFilterBar(
                          counts: provider.categoryCounts,
                          selected: provider.category,
                          onSelected: provider.filterBy,
                          // Every category, not only those loaded so far:
                          // otherwise nothing further down the catalogue could
                          // be filtered to until it had been scrolled to.
                          showAll: true,
                        ),
                      ],
                      const SizedBox(height: 14),
                      _CountLabel(
                        count: visible.length,
                        // "20 of 145" only while browsing unfiltered: under a
                        // filter or search the total would count spirits that
                        // could never appear in this list.
                        total:
                            provider.hasMore &&
                                provider.category == null &&
                                provider.query.trim().isEmpty
                            ? provider.total
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
                sliver: _SpiritsBody(provider: provider, visible: visible),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// How many spirits are on screen. Hidden until there is a real number, so it
/// never flashes a zero while the first load is in flight.
class _CountLabel extends StatelessWidget {
  const _CountLabel({required this.count, this.total});

  final int count;

  /// The whole catalogue's size, when it is worth saying how much is left.
  final int? total;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox(height: 4);

    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final int? total = this.total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        (total == null
                ? l10n.spiritCount(count)
                : l10n.spiritCountOf(count, total))
            .toUpperCase(),
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _SpiritsBody extends StatelessWidget {
  const _SpiritsBody({required this.provider, required this.visible});

  final SpiritsProvider provider;

  /// The catalogue after search and taste ordering, resolved by the screen so
  /// the grid and the count row can never disagree.
  final List<Spirit> visible;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    // Exhaustive by construction: ViewState is sealed, so a new state becomes a
    // compile error here rather than an unhandled blank screen.
    return switch (provider.state) {
      InitialState<List<Spirit>>() ||
      LoadingState<List<Spirit>>(previous: null) => const _SkeletonGrid(),
      ErrorState<List<Spirit>>(:final failure) => _MessageSliver(
        icon: Icons.cloud_off_outlined,
        title: l10n.somethingWentWrong,
        message: failure.message,
        onRetry: provider.refresh,
        retryLabel: l10n.retry,
      ),
      EmptyState<List<Spirit>>(:final message) => _MessageSliver(
        icon: Icons.liquor_outlined,
        title: l10n.nothingHere,
        message: message,
      ),
      LoadingState<List<Spirit>>() ||
      SuccessState<List<Spirit>>() => _SpiritsGrid(
        spirits: visible,
        provider: provider,
        // "No matches" only once there is nothing left to look through. While
        // pages remain, an empty filtered grid is still searching — the footer
        // shows it loading — and saying "no matches" would be premature.
        emptyLabel: _isFiltering(provider) && !provider.hasMore
            ? l10n.noMatches
            : null,
      ),
    };
  }
}

bool _isFiltering(SpiritsProvider provider) =>
    provider.category != null || provider.query.trim().isNotEmpty;

class _SpiritsGrid extends StatelessWidget {
  const _SpiritsGrid({
    required this.spirits,
    required this.provider,
    this.emptyLabel,
  });

  final List<Spirit> spirits;
  final SpiritsProvider provider;
  final String? emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (spirits.isEmpty && emptyLabel != null) {
      return _MessageSliver(icon: Icons.search_off, title: emptyLabel!);
    }

    final NavigationService navigator = context.read<NavigationService>();

    return SliverMainAxisGroup(
      slivers: <Widget>[
        SliverGrid.builder(
          gridDelegate: _gridDelegate,
          itemCount: spirits.length,
          itemBuilder: (BuildContext context, int index) {
            final Spirit spirit = spirits[index];
            return StaggeredEntrance(
              // Staggered within a page, so a page arriving deep in the list
              // cascades in like the first one rather than all at once after
              // the stagger cap.
              index: index % provider.pageSize,
              // Hard edges do not fade in; see StaggeredEntrance.fade.
              fade: false,
              child: SpiritCard(
                spirit: spirit,
                onTap: () => navigator.goToSpiritDetail(
                  context,
                  spirit.id,
                  preloaded: spirit,
                ),
              ),
            );
          },
        ),
        _LoadMoreFooter(provider: provider, hasItems: spirits.isNotEmpty),
      ],
    );
  }
}

/// What sits under the grid: the next page loading, a failed page to retry, or
/// word that the shelf has run out.
class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({required this.provider, required this.hasItems});

  final SpiritsProvider provider;
  final bool hasItems;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    if (provider.isLoadingMore) {
      // Skeleton cards rather than a spinner, in the grid's own geometry, so
      // the arriving page lands exactly where its placeholders were.
      return SliverPadding(
        padding: EdgeInsets.only(top: hasItems ? 18 : 0),
        sliver: SliverGrid.builder(
          gridDelegate: _gridDelegate,
          itemCount: 2,
          itemBuilder: (BuildContext context, int index) =>
              const SpiritCardSkeleton(),
        ),
      );
    }

    if (provider.loadMoreFailure != null) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 28),
          child: Column(
            children: <Widget>[
              Text(
                l10n.loadMoreFailed,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              HardEdgeButton(
                label: l10n.retry,
                onPressed: provider.retryLoadMore,
              ),
            ],
          ),
        ),
      );
    }

    // Only for the unfiltered shelf: under a filter, running out of pages is
    // what the grid itself already shows.
    if (!provider.hasMore && hasItems && !_isFiltering(provider)) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 36),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Container(
                  height: AppEdges.borderHairline,
                  color: theme.colorScheme.outline,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  l10n.endOfShelf.toUpperCase(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: AppEdges.borderHairline,
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }
}

class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return SliverGrid.builder(
      gridDelegate: _gridDelegate,
      itemCount: 8,
      itemBuilder: (BuildContext context, int index) =>
          const SpiritCardSkeleton(),
    );
  }
}

class _MessageSliver extends StatelessWidget {
  const _MessageSliver({
    required this.icon,
    required this.title,
    this.message,
    this.onRetry,
    this.retryLabel,
  });

  final IconData icon;
  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: SpiritMessage(
        icon: icon,
        title: title,
        message: message,
        onRetry: onRetry,
        retryLabel: retryLabel,
      ),
    );
  }
}
