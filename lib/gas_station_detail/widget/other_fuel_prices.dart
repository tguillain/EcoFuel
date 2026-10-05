import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:ecofuel/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Les carburants autres que celui choisi, dans l'ordre du sélecteur. Un
/// carburant que la station ne vend pas reste listé : savoir qu'il manque
/// évite d'y aller pour rien.
class OtherFuelPrices extends StatelessWidget {
  const OtherFuelPrices({
    super.key,
    required this.station,
    required this.selectedFuel,
    required this.priceFormat,
  });

  final GasStation station;
  final FuelType selectedFuel;
  final NumberFormat priceFormat;

  @override
  Widget build(BuildContext context) {
    final fuels = FuelType.values.where((fuel) => fuel != selectedFuel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Text(
            'Autres carburants',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
        ),
        for (final (index, fuel) in fuels.indexed) ...[
          if (index > 0) const Divider(height: 1, color: AppColors.divider),
          _FuelPriceRow(
            label: fuel.label,
            price: station.priceFor(fuel),
            priceFormat: priceFormat,
          ),
        ],
      ],
    );
  }
}

class _FuelPriceRow extends StatelessWidget {
  const _FuelPriceRow({
    required this.label,
    required this.price,
    required this.priceFormat,
  });

  final String label;
  final double? price;
  final NumberFormat priceFormat;

  @override
  Widget build(BuildContext context) {
    final price = this.price;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceSubtle,
              ),
            ),
          ),
          price != null
              ? Text(
                  '${priceFormat.format(price)} €',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                )
              : const Text(
                  'Indisponible',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.onSurfaceFaint,
                  ),
                ),
        ],
      ),
    );
  }
}
