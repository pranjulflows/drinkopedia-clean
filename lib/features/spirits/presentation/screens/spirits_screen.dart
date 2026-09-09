import 'package:drinkopedia/core/presentation/view_state.dart';
import 'package:drinkopedia/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit.dart';
import 'package:drinkopedia/features/spirits/presentation/providers/spirits_provider.dart';
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
  @override
  void initState() {
    super.initState();
    // Deferred: providers must not be mutated during the first build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SpiritsProvider>().load();
    });
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

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: provider.refresh,
          color: theme.colorScheme.onSurface,
          backgroundColor: theme.colorScheme.surfaceContainer,
          child: CustomScrollView(
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
                      ),
                      const SizedBox(height: 14),
                      _CountLabel(count: visible.length),
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
  const _CountLabel({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox(height: 4);

    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        AppLocalizations.of(context)!.spiritCount(count).toUpperCase(),
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
        emptyLabel: provider.query.trim().isEmpty ? null : l10n.noMatches,
      ),
    };
  }
}

class _SpiritsGrid extends StatelessWidget {
  const _SpiritsGrid({required this.spirits, this.emptyLabel});

  final List<Spirit> spirits;
  final String? emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (spirits.isEmpty && emptyLabel != null) {
      return _MessageSliver(icon: Icons.search_off, title: emptyLabel!);
    }

    final NavigationService navigator = context.read<NavigationService>();

    return SliverGrid.builder(
      gridDelegate: _gridDelegate,
      itemCount: spirits.length,
      itemBuilder: (BuildContext context, int index) {
        final Spirit spirit = spirits[index];
        return StaggeredEntrance(
          index: index,
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
    );
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
