import 'package:cached_network_image/cached_network_image.dart';
import 'package:drinkopedia/app/theme/app_motion.dart';
import 'package:drinkopedia/core/presentation/view_state.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit.dart';
import 'package:drinkopedia/features/spirits/domain/usecases/get_spirit_detail.dart';
import 'package:drinkopedia/features/spirits/presentation/providers/spirit_detail_provider.dart';
import 'package:drinkopedia/features/spirits/presentation/widgets/spirit_card.dart';
import 'package:drinkopedia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// A single spirit and its origin story.
///
/// [preloaded] arrives only when opened from the catalogue. Reached by deep
/// link it is null and the screen fetches by [spiritId] — that path is the one
/// worth protecting, since `$extra` never survives a link or a cold start.
class SpiritDetailScreen extends StatelessWidget {
  const SpiritDetailScreen({required this.spiritId, this.preloaded, super.key});

  final String spiritId;
  final Spirit? preloaded;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SpiritDetailProvider>(
      create: (BuildContext context) {
        final SpiritDetailProvider provider = SpiritDetailProvider(
          getSpiritDetail: context.read<GetSpiritDetail>(),
          id: spiritId,
          preloaded: preloaded,
        );
        // Always refresh; when nothing was preloaded this is the only load.
        provider.load();
        return provider;
      },
      child: const _SpiritDetailView(),
    );
  }
}

class _SpiritDetailView extends StatelessWidget {
  const _SpiritDetailView();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final SpiritDetailProvider provider = context.watch<SpiritDetailProvider>();

    return Scaffold(
      body: AnimatedSwitcher(
        duration: AppMotion.resolve(context, AppMotion.standard),
        child: switch (provider.state) {
          InitialState<Spirit>() || LoadingState<Spirit>() => const Center(
            key: ValueKey<String>('loading'),
            child: CircularProgressIndicator(),
          ),
          ErrorState<Spirit>(:final failure) => _DetailError(
            key: const ValueKey<String>('error'),
            message: failure.message,
            onRetry: provider.load,
            retryLabel: l10n.retry,
          ),
          EmptyState<Spirit>() => _DetailError(
            key: const ValueKey<String>('empty'),
            message: l10n.nothingHere,
            onRetry: provider.load,
            retryLabel: l10n.retry,
          ),
          SuccessState<Spirit>(:final Spirit data) => _SpiritContent(
            key: ValueKey<String>('spirit-${data.id}'),
            spirit: data,
          ),
        },
      ),
    );
  }
}

class _SpiritContent extends StatelessWidget {
  const _SpiritContent({required this.spirit, super.key});

  final Spirit spirit;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return CustomScrollView(
      slivers: <Widget>[
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              spirit.name,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                shadows: const <Shadow>[
                  Shadow(blurRadius: 8, color: Colors.black54),
                ],
              ),
            ),
            background: Hero(
              tag: SpiritCard.heroTag(spirit.id),
              child: _HeaderImage(spirit: spirit),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
          sliver: SliverList.list(
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  if (spirit.hasType) Chip(label: Text(spirit.type!)),
                  if (spirit.hasAbv)
                    Chip(
                      avatar: const Icon(Icons.percent, size: 16),
                      label: Text(
                        l10n.abvValue(spirit.abv!.toStringAsFixed(1)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Text(l10n.theStory, style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              if (spirit.hasStory)
                Text(
                  spirit.story!,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                )
              else
                // Some entries genuinely have no description upstream; say so
                // rather than rendering an empty column.
                Text(
                  l10n.noStoryYet,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderImage extends StatelessWidget {
  const _HeaderImage({required this.spirit});

  final Spirit spirit;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(color: scheme.surfaceContainerHighest),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (spirit.imageUrl != null)
            CachedNetworkImage(
              imageUrl: spirit.imageUrl!,
              fit: BoxFit.cover,
              fadeInDuration: AppMotion.quick,
              errorWidget: (BuildContext c, String u, Object e) => Icon(
                Icons.local_bar_outlined,
                size: 64,
                color: scheme.onSurfaceVariant,
              ),
            )
          else
            Icon(
              Icons.local_bar_outlined,
              size: 64,
              color: scheme.onSurfaceVariant,
            ),
          // Keeps the collapsing title legible over arbitrary artwork.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: <Color>[Colors.transparent, Colors.black54],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({
    required this.message,
    required this.onRetry,
    required this.retryLabel,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.cloud_off_outlined,
              size: 44,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.tonal(onPressed: onRetry, child: Text(retryLabel)),
          ],
        ),
      ),
    );
  }
}
