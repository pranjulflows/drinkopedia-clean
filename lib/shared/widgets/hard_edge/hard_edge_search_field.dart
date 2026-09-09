import 'package:drinkopedia/app/theme/app_edges.dart';
import 'package:drinkopedia/shared/widgets/hard_edge/hard_edge_panel.dart';
import 'package:flutter/material.dart';

/// The catalogue search field.
///
/// Material's [SearchBar] is a rounded, elevated surface with a ripple, none of
/// which survives this direction, so the field is built from the same panel
/// primitive as everything else and wraps a plain [TextField].
class HardEdgeSearchField extends StatelessWidget {
  const HardEdgeSearchField({
    required this.hintText,
    required this.onChanged,
    super.key,
  });

  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return HardEdgePanel(
      shadowOffset: AppEdges.shadowField,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        height: 48,
        child: Row(
          children: <Widget>[
            Icon(Icons.search, size: 18, color: theme.colorScheme.onSurface),
            const SizedBox(width: 9),
            Expanded(
              child: TextField(
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                style: theme.textTheme.bodyLarge,
                cursorColor: theme.colorScheme.onSurface,
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: hintText,
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
