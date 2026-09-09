import 'package:drinkopedia/app/theme/app_edges.dart';
import 'package:drinkopedia/shared/widgets/hard_edge/hard_edge_button.dart';
import 'package:flutter/material.dart';

/// The empty, error and no-matches states.
///
/// Extracted because both screens need all three and had grown private copies
/// that drifted apart. The icon sits in a bordered block rather than floating,
/// so a state screen still reads as part of the same direction as the cards.
class SpiritMessage extends StatelessWidget {
  const SpiritMessage({
    required this.icon,
    required this.title,
    this.message,
    this.onRetry,
    this.retryLabel,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.outline,
                width: AppEdges.border,
              ),
              boxShadow: AppEdges.hard(
                theme.colorScheme.outline,
                AppEdges.shadowCompact,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Icon(icon, size: 32, color: theme.colorScheme.onSurface),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            title.toUpperCase(),
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          if (message != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (onRetry != null && retryLabel != null) ...<Widget>[
            const SizedBox(height: 26),
            HardEdgeButton(label: retryLabel!, onPressed: onRetry!),
          ],
        ],
      ),
    );
  }
}
