import 'package:ecofuel/gas_station_list/model/brand_filter.dart';
import 'package:ecofuel/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ouvre, sous [child], le menu des enseignes présentes dans le rayon, avec
/// leur nombre de stations. « Toutes les marques » enlève le filtre.
///
/// Partagé par l'en-tête de la carte et celui de la liste, qui dessinent
/// chacun leur pastille.
class BrandMenuButton extends StatelessWidget {
  const BrandMenuButton({
    super.key,
    required this.brands,
    required this.selectedBrand,
    required this.onBrandChanged,
    required this.child,
  });

  final List<BrandCount> brands;
  final String? selectedBrand;
  final ValueChanged<String?> onBrandChanged;
  final Widget child;

  int get _total => brands.fold(0, (sum, entry) => sum + entry.count);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Marque : ${selectedBrand ?? BrandFilter.allBrands}',
      child: PopupMenuButton<String>(
        initialValue: selectedBrand ?? BrandFilter.allBrands,
        // Le menu ne transporte que des libellés : « Toutes les marques »
        // revient à n'en choisir aucune.
        onSelected: (brand) =>
            onBrandChanged(brand == BrandFilter.allBrands ? null : brand),
        tooltip: 'Choisir une marque',
        position: PopupMenuPosition.under,
        padding: EdgeInsets.zero,
        itemBuilder: (context) => [
          _item(context, BrandFilter.allBrands, _total, selectedBrand == null),
          const PopupMenuDivider(),
          for (final entry in brands)
            _item(
              context,
              entry.brand,
              entry.count,
              entry.brand == selectedBrand,
            ),
        ],
        child: child,
      ),
    );
  }

  PopupMenuItem<String> _item(
    BuildContext context,
    String brand,
    int count,
    bool isSelected,
  ) {
    return PopupMenuItem<String>(
      value: brand,
      child: Row(
        spacing: 10,
        children: [
          SizedBox(
            width: 20,
            child: isSelected
                ? Icon(Icons.check, size: 18, color: context.colors.primary)
                : null,
          ),
          Expanded(
            child: Text(
              brand,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            '$count',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 12,
              color: context.colors.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}
