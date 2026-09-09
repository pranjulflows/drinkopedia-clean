import 'package:drinkopedia/app/theme/app_colors.dart';
import 'package:drinkopedia/app/theme/app_edges.dart';
import 'package:drinkopedia/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:drinkopedia/features/onboarding/presentation/widgets/category_label.dart';
import 'package:drinkopedia/features/spirits/domain/entities/spirit_category.dart';
import 'package:drinkopedia/l10n/app_localizations.dart';
import 'package:drinkopedia/routing/app_routes.dart';
import 'package:drinkopedia/shared/widgets/hard_edge/hard_edge_button.dart';
import 'package:drinkopedia/shared/widgets/hard_edge/hard_edge_panel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The taste intro: three steps, only the middle one collects anything.
///
/// Everything it stores stays on the device — there is no account and no
/// network call anywhere in this flow, which is what the copy promises.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final OnboardingProvider provider = context.watch<OnboardingProvider>();

    Future<void> finish({bool skipped = false}) async {
      await provider.finish(skipped: skipped);
      if (context.mounted) const SpiritsRoute().go(context);
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _ProgressRow(
                step: provider.step,
                onSkip: provider.isLastStep
                    ? null
                    : () => finish(skipped: true),
                skipLabel: l10n.onboardingSkip,
              ),
              const SizedBox(height: 30),
              Expanded(
                child: switch (provider.step) {
                  0 => _WelcomeStep(l10n: l10n),
                  1 => _TasteStep(provider: provider, l10n: l10n),
                  _ => _DoneStep(provider: provider, l10n: l10n),
                },
              ),
              const SizedBox(height: 16),
              HardEdgeButton(
                label: switch (provider.step) {
                  0 => l10n.onboardingStart,
                  1 => l10n.onboardingContinue,
                  _ => l10n.onboardingBrowse,
                },
                onPressed: provider.isLastStep ? finish : provider.next,
              ),
              const SizedBox(height: 12),
              Text(
                l10n
                    .onboardingStepOf(
                      provider.step + 1,
                      OnboardingProvider.stepCount,
                    )
                    .toUpperCase(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.step,
    required this.onSkip,
    required this.skipLabel,
  });

  final int step;
  final VoidCallback? onSkip;
  final String skipLabel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Row(
          children: List<Widget>.generate(OnboardingProvider.stepCount, (
            int index,
          ) {
            return Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Container(
                width: 34,
                height: 8,
                decoration: BoxDecoration(
                  color: index <= step ? scheme.onSurface : scheme.surface,
                  border: Border.all(
                    color: scheme.outline,
                    width: AppEdges.borderHairline,
                  ),
                ),
              ),
            );
          }),
        ),
        if (onSkip != null)
          // A plain text target rather than a bordered one: skipping should be
          // findable without competing with the primary action.
          GestureDetector(
            onTap: onSkip,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              height: AppEdges.minTapTarget,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  skipLabel.toUpperCase(),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.onboardingWelcomeTitle.toUpperCase(),
          style: theme.textTheme.displayLarge,
        ),
        const SizedBox(height: 18),
        Text(l10n.onboardingWelcomeBody, style: theme.textTheme.bodyLarge),
      ],
    );
  }
}

class _TasteStep extends StatelessWidget {
  const _TasteStep({required this.provider, required this.l10n});

  final OnboardingProvider provider;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.onboardingTasteTitle.toUpperCase(),
            style: theme.textTheme.displayMedium,
          ),
          const SizedBox(height: 14),
          Text(l10n.onboardingTasteBody, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 26),
          Wrap(
            spacing: 9,
            runSpacing: 12,
            children: SpiritCategory.values.map((SpiritCategory category) {
              return _CategoryChip(
                label: categoryLabel(l10n, category),
                selected: provider.isSelected(category),
                onTap: () => provider.toggle(category),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// A selectable category. Selection is carried by fill and weight, never by
/// colour alone.
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Semantics(
      selected: selected,
      button: true,
      child: HardEdgePanel(
        color: selected ? AppColors.acid : theme.colorScheme.surfaceContainer,
        shadowOffset: selected ? AppEdges.shadowCompact : Offset.zero,
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(15, 11, 15, 12),
        child: Text(
          label.toUpperCase(),
          style: theme.textTheme.titleMedium?.copyWith(
            // The acid ground is the same in both themes, so a selected chip's
            // label has to stay dark even in dark mode.
            color: selected ? AppColors.ink : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _DoneStep extends StatelessWidget {
  const _DoneStep({required this.provider, required this.l10n});

  final OnboardingProvider provider;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool pickedNothing = provider.selection.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.onboardingDoneTitle.toUpperCase(),
          style: theme.textTheme.displayLarge,
        ),
        const SizedBox(height: 18),
        Text(
          pickedNothing
              ? l10n.onboardingDoneBodyEmpty
              : l10n.onboardingDoneBody,
          style: theme.textTheme.bodyLarge,
        ),
        if (!pickedNothing) ...<Widget>[
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: provider.selection.map((SpiritCategory category) {
              return HardEdgePanel(
                color: AppColors.acid,
                shadowOffset: Offset.zero,
                padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
                child: Text(
                  categoryLabel(l10n, category).toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.ink,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
