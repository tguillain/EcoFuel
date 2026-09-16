import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:flutter/material.dart';

/// Ouvre le panneau d'information d'une station.
///
/// Le bouton "Itinéraire" ferme le panneau puis demande
/// à la carte d'afficher la route jusqu'à cette station.
void showGasStationDetailsSheet({
  required BuildContext context,
  required GasStation station,
  required FuelType fuel,
  required VoidCallback onShowRoute,
}) {
  final double? price =
      station.priceFor(fuel);

  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            0,
            20,
            24,
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // =============================
              // ADRESSE
              // =============================
              Row(
                children: [
                  const Icon(
                    Icons.local_gas_station,
                    size: 30,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Text(
                      station.address,
                      style:
                          const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 6,
              ),

              Text(
                station.city,
                style: TextStyle(
                  color:
                      Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              // =============================
              // DISTANCE À VOL D'OISEAU / API
              // =============================
              _InfoLine(
                icon: Icons.near_me,
                text:
                    '${station.distanceInKm.toStringAsFixed(1)} km',
              ),

              const SizedBox(
                height: 12,
              ),

              // =============================
              // PRIX
              // =============================
              _InfoLine(
                icon: Icons.euro,
                text:
                    '${fuel.label} : '
                    '${price?.toStringAsFixed(3) ?? '--'} €/L',
                bold: true,
              ),

              const SizedBox(
                height: 12,
              ),

              // =============================
              // HORAIRES
              // =============================
              _OpeningInfo(
                station: station,
              ),

              const SizedBox(
                height: 22,
              ),

              // =============================
              // ITINÉRAIRE
              // =============================
              SizedBox(
                width: double.infinity,
                child:
                    FilledButton.icon(
                  onPressed: () {
                    // Ferme d'abord le panneau.
                    Navigator.of(
                      sheetContext,
                    ).pop();

                    // Lance ensuite le calcul de route.
                    onShowRoute();
                  },
                  icon: const Icon(
                    Icons.directions,
                  ),
                  label: const Text(
                    'Afficher l’itinéraire',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Ligne générique composée d'une icône
/// et d'un texte.
class _InfoLine
    extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.text,
    this.bold = false,
  });

  final IconData icon;
  final String text;
  final bool bold;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 19,
        ),
        const SizedBox(
          width: 8,
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize:
                  bold ? 18 : 14,
              fontWeight:
                  bold
                      ? FontWeight.bold
                      : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}

/// Affiche l'état d'ouverture de la station.
class _OpeningInfo
    extends StatelessWidget {
  const _OpeningInfo({
    required this.station,
  });

  final GasStation station;

  @override
  Widget build(
    BuildContext context,
  ) {
    String text;

    if (station.isOpen24h) {
      text = 'Ouvert 24h/24';
    } else if (station.isClosed) {
      text = 'Fermé';
    } else if (
        station.closingTime != null) {
      text =
          'Ferme à '
          '${station.closingTime}';
    } else {
      text =
          'Horaires indisponibles';
    }

    return _InfoLine(
      icon: Icons.access_time,
      text: text,
    );
  }
}