import 'package:flutter/material.dart';

class SortViewToolbar<T> extends StatelessWidget {
  const SortViewToolbar({
    super.key,
    required this.sortOptions,
    required this.selectedSort,
    required this.onSortSelected,
    required this.sortButtonLabel,
    required this.sortTooltip,
    required this.isGridView,
    required this.onToggleView,
    required this.gridTooltip,
    required this.listTooltip,
    this.useSafeArea = false,
  });

  final List<({T value, String label})> sortOptions;
  final T selectedSort;
  final ValueChanged<T> onSortSelected;
  final String sortButtonLabel;
  final String sortTooltip;
  final bool isGridView;
  final VoidCallback onToggleView;
  final String gridTooltip;
  final String listTooltip;
  final bool useSafeArea;

  @override
  Widget build(BuildContext context) {
    Widget bar = Material(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            PopupMenuButton<T>(
              tooltip: sortTooltip,
              onSelected: onSortSelected,
              itemBuilder: (context) {
                final scheme = Theme.of(context).colorScheme;
                PopupMenuItem<T> item(T value, String label) {
                  final selected = selectedSort == value;
                  return PopupMenuItem(
                    value: value,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          child: selected ? Icon(Icons.check, size: 20, color: scheme.primary) : null,
                        ),
                        Expanded(child: Text(label)),
                      ],
                    ),
                  );
                }

                return [
                  for (final option in sortOptions) item(option.value, option.label),
                ];
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sort),
                    const SizedBox(width: 6),
                    Text(sortButtonLabel),
                  ],
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(isGridView ? Icons.view_list : Icons.grid_view),
              tooltip: isGridView ? listTooltip : gridTooltip,
              onPressed: onToggleView,
            ),
          ],
        ),
      ),
    );

    if (!useSafeArea) return bar;
    return SafeArea(
      top: false,
      bottom: false,
      child: bar,
    );
  }
}
