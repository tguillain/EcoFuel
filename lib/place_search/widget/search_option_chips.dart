import 'package:ecofuel/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Un choix unique parmi quelques valeurs, en pastilles : le rayon ou le
/// carburant du panneau de recherche.
class SearchOptionChips<T> extends StatelessWidget {
  const SearchOptionChips({
    super.key,
    required this.title,
    required this.values,
    required this.labelOf,
    required this.selected,
    required this.onSelected,
  });

  final String title;
  final List<T> values;
  final String Function(T value) labelOf;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: context.colors.onSurface,
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in values)
              ChoiceChip(
                label: Text(labelOf(value)),
                selected: value == selected,
                onSelected: (_) => onSelected(value),
                showCheckmark: false,
                selectedColor: context.colors.selected,
                backgroundColor: context.colors.surfaceMuted,
                side: BorderSide.none,
                shape: const StadiumBorder(),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: value == selected
                      ? context.colors.onSelected
                      : context.colors.onSurfaceSubtle,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
