import 'package:drinkopedia/app/theme/app_edges.dart';
import 'package:drinkopedia/shared/widgets/hard_edge/hard_edge_panel.dart';
import 'package:flutter/material.dart';

/// The catalogue search field.
///
/// Material's [SearchBar] is a rounded, elevated surface with a ripple, none of
/// which survives this direction, so the field is built from the same panel
/// primitive as everything else and wraps a plain [TextField].
///
/// Getting *out* of the field is deliberate work. On a phone the keyboard
/// covers half the catalogue, and a bare [TextField] offers no way back: there
/// is no form to submit and tapping the results does not dismiss it. So there
/// are three exits — the keyboard's own action key, the clear button, and
/// dragging the results (see `ScrollViewKeyboardDismissBehavior.onDrag` on the
/// catalogue's scroll view).
class HardEdgeSearchField extends StatefulWidget {
  const HardEdgeSearchField({
    required this.hintText,
    required this.onChanged,
    required this.clearTooltip,
    this.enabled = true,
    super.key,
  });

  final String hintText;
  final ValueChanged<String> onChanged;
  final String clearTooltip;

  /// Whether there is anything to search.
  ///
  /// Filtering is local, over whatever the catalogue managed to load. With an
  /// empty cache and a failed refresh there is nothing to filter, and a live
  /// field that silently swallows every keystroke reads as a broken app rather
  /// than as an empty one. Disabled, it sends attention to the retry button
  /// instead.
  final bool enabled;

  @override
  State<HardEdgeSearchField> createState() => _HardEdgeSearchFieldState();
}

class _HardEdgeSearchFieldState extends State<HardEdgeSearchField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncHasText);
  }

  void _syncHasText() {
    final bool hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  @override
  void didUpdateWidget(HardEdgeSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Losing the catalogue strands whatever was typed, and the query would
    // still be filtering an empty list when data returns.
    if (oldWidget.enabled && !widget.enabled && _controller.text.isNotEmpty) {
      _controller.clear();
      widget.onChanged('');
      _focusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_syncHasText)
      ..dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return HardEdgePanel(
      // Flat and in the inactive tone when there is nothing to search: in this
      // direction the offset shadow is what marks a surface as live.
      color: widget.enabled ? null : theme.colorScheme.surfaceContainerHighest,
      shadowOffset: widget.enabled ? AppEdges.shadowField : Offset.zero,
      padding: const EdgeInsets.only(left: 12),
      child: SizedBox(
        height: 48,
        child: Row(
          children: <Widget>[
            Icon(
              Icons.search,
              size: 18,
              color: widget.enabled
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: TextField(
                enabled: widget.enabled,
                controller: _controller,
                focusNode: _focusNode,
                onChanged: widget.onChanged,
                // Filtering is live, so submitting has nothing left to do
                // except get the keyboard out of the way.
                onSubmitted: (_) => _focusNode.unfocus(),
                textInputAction: TextInputAction.search,
                style: theme.textTheme.bodyLarge,
                cursorColor: theme.colorScheme.onSurface,
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: widget.hintText,
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            // Only present once there is something to clear, so the field is
            // not cluttered while it is empty.
            if (_hasText && widget.enabled)
              Tooltip(
                message: widget.clearTooltip,
                child: Semantics(
                  button: true,
                  label: widget.clearTooltip,
                  child: GestureDetector(
                    onTap: _clear,
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: AppEdges.minTapTarget,
                      height: AppEdges.minTapTarget,
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}
