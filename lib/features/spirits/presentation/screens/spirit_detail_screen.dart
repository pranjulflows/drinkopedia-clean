import 'package:drinkopedia/app/theme/app_colors.dart';
import 'package:drinkopedia/app/theme/app_edges.dart';
import 'package:drinkopedia/app/theme/app_motion.dart';
import 'package:drinkopedia/core/presentation/view_state.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit.dart';
import 'package:drinkopedia/features/spirits/domain/usecases/get_spirit_detail.dart';
import 'package:drinkopedia/features/spirits/presentation/providers/spirit_detail_provider.dart';
import 'package:drinkopedia/features/spirits/presentation/widgets/spirit_card.dart';
import 'package:drinkopedia/features/spirits/presentation/widgets/spirit_message.dart';
import 'package:drinkopedia/l10n/app_localizations.dart';
import 'package:drinkopedia/shared/widgets/hard_edge/hard_edge_button.dart';
import 'package:drinkopedia/shared/widgets/hard_edge/hard_edge_chip.dart';
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
          ErrorState<Spirit>(:final failure) => _DetailMessage(
            key: const ValueKey<String>('error'),
            title: l10n.somethingWentWrong,
            message: failure.message,
            onRetry: provider.load,
            retryLabel: l10n.retry,
          ),
          EmptyState<Spirit>() => _DetailMessage(
            key: const ValueKey<String>('empty'),
            title: l10n.nothingHere,
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
          expandedHeight: _expandedHeight,
          pinned: true,
          automaticallyImplyLeading: false,
          leading: Padding(
            // Left inset only. A top inset pushed the button past the bar's
            // bottom rule; letting the app bar centre it keeps the two apart.
            padding: const EdgeInsets.only(left: _backInset),
            child: HardEdgeIconButton(
              icon: Icons.arrow_back,
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              background: theme.colorScheme.surface,
            ),
          ),
          leadingWidth: _backExtent + 8,
          flexibleSpace: _CollapsingHeader(spirit: spirit),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 56),
          sliver: SliverList.list(
            children: <Widget>[
              Text(
                spirit.name.toUpperCase(),
                style: theme.textTheme.displayLarge,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  if (spirit.hasType)
                    HardEdgeChip.filled(
                      label: spirit.type!,
                      background: AppColors.hotPink,
                      // Ink rather than white: white on this pink falls under
                      // 3:1, which small caps cannot afford.
                      foreground: AppColors.ink,
                    ),
                  // Absent for more than half the catalogue, so it appears only
                  // when real rather than as an empty slot.
                  if (spirit.hasAbv)
                    HardEdgeChip.filled(
                      label: l10n.abvValue(spirit.abv!.toStringAsFixed(0)),
                      background: theme.colorScheme.primary,
                      foreground: theme.colorScheme.onPrimary,
                    ),
                ],
              ),
              const SizedBox(height: 26),
              _StoryHeading(label: l10n.theStory),
              const SizedBox(height: 14),
              if (spirit.hasStory)
                Text(spirit.story!, style: theme.textTheme.bodyLarge)
              else
                // Some entries genuinely have no description upstream; say so
                // rather than rendering an empty column.
                Text(
                  l10n.noStoryYet,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// How tall the artwork header is before any scrolling.
const double _expandedHeight = 300;

/// Where the back button sits, and how much room it needs.
///
/// The collapsed title is a separate overlay rather than the app bar's own
/// `title`, so nothing lays the two out together — the gap between them has to
/// be derived rather than guessed, or the title creeps up against the button.
const double _backInset = 16;
const double _backSize = 46;

/// The button's right edge, shadow included.
final double _backExtent = _backInset + _backSize + AppEdges.shadowCompact.dx;

/// Breathing room between the button and the title. Generous on purpose: the
/// button is a filled block with a shadow, so a tight gap reads as a collision.
const double _titleGap = 22;

/// The artwork, and the name sliding into the bar as it collapses.
///
/// The name is set below the header at display size, so once it scrolls away
/// the bar would otherwise be an empty strip with a back button in it. This
/// brings the name up into that strip instead.
///
/// Driven by the header's own height rather than by a scroll controller: the
/// flexible space is rebuilt with fresh constraints on every frame of the
/// collapse, so the fade tracks the finger continuously instead of snapping at
/// a threshold.
class _CollapsingHeader extends StatelessWidget {
  const _CollapsingHeader({required this.spirit});

  final Spirit spirit;

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.paddingOf(context).top;
    final double collapsedHeight = topInset + kToolbarHeight;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double range = _expandedHeight - collapsedHeight;
        // 1 fully open, 0 fully collapsed.
        final double openness = range <= 0
            ? 0
            : ((constraints.maxHeight - collapsedHeight) / range).clamp(
                0.0,
                1.0,
              );

        // Held back until the header is nearly shut, so the small name arrives
        // as the display-size one goes under the bar rather than the two
        // sitting there together.
        const double startAt = 0.3;
        final double t = ((startAt - openness) / startAt).clamp(0.0, 1.0);

        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Hero(
              tag: SpiritCard.heroTag(spirit.id),
              child: SpiritArtwork(
                spirit: spirit,
                padding: const EdgeInsets.fromLTRB(40, 64, 40, 20),
                fallbackIconSize: 64,
              ),
            ),
            if (t > 0)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: collapsedHeight,
                child: Opacity(
                  opacity: t,
                  child: _CollapsedTitleBar(
                    name: spirit.name,
                    topInset: topInset,
                    // Rises the last few pixels into place as it fades in.
                    offset: (1 - t) * 10,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CollapsedTitleBar extends StatelessWidget {
  const _CollapsedTitleBar({
    required this.name,
    required this.topInset,
    required this.offset,
  });

  final String name;
  final double topInset;
  final double offset;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        // Opaque, so the artwork it slides over never shows through the name.
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline,
            width: AppEdges.border,
          ),
        ),
      ),
      child: Padding(
        // Clears the back button, which sits above this in the app bar.
        padding: EdgeInsets.only(
          top: topInset,
          left: _backExtent + _titleGap,
          right: 20,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Transform.translate(
            offset: Offset(0, offset),
            child: Text(
              name.toUpperCase(),
              // A bar title, not a caption: the card-name size disappeared
              // beside a 46pt button in a direction built on heavy type.
              style: theme.textTheme.headlineSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

/// Section heading with a rule running out to the edge of the measure.
class _StoryHeading extends StatelessWidget {
  const _StoryHeading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(label.toUpperCase(), style: theme.textTheme.headlineSmall),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: AppEdges.borderHeavy,
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

class _DetailMessage extends StatelessWidget {
  const _DetailMessage({
    required this.title,
    required this.onRetry,
    required this.retryLabel,
    this.message,
    super.key,
  });

  final String title;
  final String? message;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: SpiritMessage(
          icon: Icons.cloud_off_outlined,
          title: title,
          message: message,
          onRetry: onRetry,
          retryLabel: retryLabel,
        ),
      ),
    );
  }
}
