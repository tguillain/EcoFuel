import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:ecofuel/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GasStationCard extends StatelessWidget {
  const GasStationCard._({
    super.key,
    required this.station,
    required this.fuel,
    required this.isHighlighted,
    this.onTap,
  });

  factory GasStationCard.standard(
    GasStation station, {
    required FuelType fuel,
    Key? key,
    VoidCallback? onTap,
  }) => GasStationCard._(
    key: key,
    station: station,
    fuel: fuel,
    isHighlighted: false,
    onTap: onTap,
  );

  factory GasStationCard.highlighted(
    GasStation station, {
    required FuelType fuel,
    Key? key,
    VoidCallback? onTap,
  }) => GasStationCard._(
    key: key,
    station: station,
    fuel: fuel,
    isHighlighted: true,
    onTap: onTap,
  );

  static const double _radius = 22;
  static const double _padding = 18;
  static const double _gap = 12;

  static final NumberFormat _distanceFormat = NumberFormat('0.#', 'fr_FR');
  static final NumberFormat _priceFormat = NumberFormat('0.000', 'fr_FR');

  final GasStation station;
  final FuelType fuel;
  final bool isHighlighted;
  final VoidCallback? onTap;

  /// Le design réunit ville, distance et horaire sur une seule ligne
  /// secondaire, séparées par des points médians.
  String get _subtitle {
    final parts = [
      station.city,
      '${_distanceFormat.format(station.distanceInKm)} km',
      if (station.isOpen24h)
        '24h/24'
      else if (station.closingTime != null)
        'ouvert jusqu\'à ${station.closingTime}'
      else if (station.isClosed)
        'fermé',
    ];

    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final price = station.priceFor(fuel);
    final foreground = isHighlighted
        ? AppColors.onPrimary
        : AppColors.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: _gap),
      // Le DecoratedBox ne porte que l'ombre, aux décalages du design que
      // `Material.elevation` ne sait pas exprimer ; le Material peint le fond
      // et découpe l'ondulation de l'InkWell.
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          boxShadow: [
            isHighlighted
                ? const BoxShadow(
                    color: Color.fromRGBO(10, 132, 255, .9),
                    offset: Offset(0, 14),
                    blurRadius: 28,
                    spreadRadius: -16,
                  )
                : const BoxShadow(
                    color: Color.fromRGBO(14, 18, 17, .6),
                    offset: Offset(0, 8),
                    blurRadius: 20,
                    spreadRadius: -16,
                  ),
          ],
        ),
        child: Material(
          color: isHighlighted ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(_radius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(_padding),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      spacing: 4,
                      children: [
                        Text(
                          station.address,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: foreground,
                          ),
                        ),
                        Text(
                          _subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: isHighlighted
                                ? AppColors.onPrimary.withValues(alpha: .85)
                                : AppColors.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: price != null
                              ? _priceFormat.format(price)
                              : '—',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 26 * -0.03,
                          ),
                        ),
                        const TextSpan(
                          text: ' €/L',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    style: TextStyle(color: foreground),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
