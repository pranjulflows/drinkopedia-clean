import 'package:drinkopedia/core/presentation/view_state.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit.dart';
import 'package:drinkopedia/features/spirits/presentation/providers/spirits_provider.dart';
import 'package:drinkopedia/features/spirits/presentation/widgets/spirit_card.dart';
import 'package:drinkopedia/features/spirits/presentation/widgets/spirit_card_skeleton.dart';
import 'package:drinkopedia/l10n/app_localizations.dart';
import 'package:drinkopedia/routing/navigation_service.dart';
import 'package:drinkopedia/shared/animations/staggered_entrance.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final SpiritsProvider provider = context.watch<SpiritsProvider>();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: provider.refresh,
        child: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar.large(
              title: Text(l10n.catalogueTitle),
              actions: <Widget>[
                IconButton(
                  onPressed: provider.refresh,
                  icon: const Icon(Icons.refresh),
                  tooltip: l10n.refresh,
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              sliver: SliverToBoxAdapter(
                child: SearchBar(
                  hintText: l10n.searchSpirits,
                  leading: const Icon(Icons.search),
                  onChanged: provider.search,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              sliver: _SpiritsBody(provider: provider),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpiritsBody extends StatelessWidget {
  const _SpiritsBody({required this.provider});

  final SpiritsProvider provider;

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
        spirits: provider.visibleSpirits,
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
      return _MessageSliver(
        icon: Icons.search_off,
        title: emptyLabel!,
        message: null,
      );
    }

    final NavigationService navigator = context.read<NavigationService>();

    return SliverGrid.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.78,
      ),
      itemCount: spirits.length,
      itemBuilder: (BuildContext context, int index) {
        final Spirit spirit = spirits[index];
        return StaggeredEntrance(
          index: index,
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
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.78,
      ),
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
    required this.message,
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
    final ThemeData theme = Theme.of(context);
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 44, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: 20),
              FilledButton.tonal(
                onPressed: onRetry,
                child: Text(retryLabel ?? 'Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
