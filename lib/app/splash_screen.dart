import 'dart:async';

import 'package:drinkopedia/app/theme/app_colors.dart';
import 'package:drinkopedia/app/theme/app_edges.dart';
import 'package:drinkopedia/app/theme/app_motion.dart';
import 'package:drinkopedia/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:drinkopedia/l10n/app_localizations.dart';
import 'package:drinkopedia/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Shown while the app works out where to open.
///
/// This is not decoration for its own sake: the app has to read the taste
/// preference from disk before it can build the router, and something has to
/// occupy that moment. Saying what the app *is* is a better use of it than a
/// blank screen or a spinner.
///
/// It is held for [minimumDuration] even when the read finishes sooner —
/// a splash that appears for 80ms is worse than none at all, because it reads
/// as a flicker rather than as a screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({this.next, super.key});

  /// Where to go once the preference is known.
  ///
  /// Set when a deep link arrived before the app could decide whether to gate
  /// it. Null on an ordinary launch, which lands on the catalogue.
  final String? next;

  /// Long enough to register as deliberate, short enough not to be a toll on
  /// every launch.
  ///
  /// Mutable only so suites can drop it to zero; a real launch never changes
  /// it. Without that seam every widget test would pay it.
  @visibleForTesting
  static Duration minimumDuration = const Duration(milliseconds: 900);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (AppMotion.reduced(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }

    unawaited(_bootstrap());
  }

  /// Resolves the taste preference, then hands over to the catalogue.
  ///
  /// The router's guard bounces that to the intro when it has not been
  /// answered, so this does not need to know which screen comes next — only
  /// that the answer is now on hand.
  Future<void> _bootstrap() async {
    await Future.wait(<Future<void>>[
      context.read<OnboardingProvider>().load(),
      Future<void>.delayed(SplashScreen.minimumDuration),
    ]);
    if (!mounted) return;
    final String? next = widget.next;
    if (next == null) {
      const SpiritsRoute().go(context);
    } else {
      GoRouter.of(context).go(next);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    final Animation<double> curved = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.enter,
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Spacer(),
              // The acid block reads as the app's mark at this size, and is the
              // one piece of the direction that survives being seen for under
              // a second.
              FadeTransition(
                opacity: curved,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.acid,
                    border: Border.all(
                      color: theme.colorScheme.outline,
                      width: AppEdges.border,
                    ),
                    boxShadow: AppEdges.hard(
                      theme.colorScheme.outline,
                      AppEdges.shadow,
                    ),
                  ),
                  child: const Icon(
                    Icons.local_bar_outlined,
                    size: 30,
                    // Fixed ink: the acid ground is identical in both themes.
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.12),
                  end: Offset.zero,
                ).animate(curved),
                child: FadeTransition(
                  opacity: curved,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.appTitle.toUpperCase(),
                        style: theme.textTheme.displayMedium,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        l10n.appTagline,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              FadeTransition(
                opacity: curved,
                child: Container(
                  height: AppEdges.borderHeavy,
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
