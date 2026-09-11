import 'package:flutter/material.dart';

import '../models/station.dart';

class StationCard extends StatelessWidget {
  final Station station;
  final String carburant;

  const StationCard({
    super.key,
    required this.station,
    required this.carburant,
  });

  @override
  Widget build(BuildContext context) {
    final double? prix = station.getPrix(carburant);

    String prixText = 'Prix indisponible';
    if (prix != null) {
      prixText = '${prix.toStringAsFixed(3)} €/L';
    }

    String subtitleInfo = '${station.distanceKm.toStringAsFixed(1)} km';

    if (station.automate2424) {
      subtitleInfo += ' · 24/7';
    } else if (station.horaires != null && station.horaires!.isNotEmpty) {
      subtitleInfo += ' · ouvert ${station.horaires}';
    } else if (station.ferme) {
      subtitleInfo += ' · fermé';
    } else {
      subtitleInfo += ' · aucune info';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 27,
              child: Icon(Icons.local_gas_station),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    station.adresse,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(station.ville),

                  const SizedBox(height: 6),

                  Text(
                    subtitleInfo,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  carburant,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  prixText,
                  style: TextStyle(
                    fontSize: prix != null ? 17 : 12,
                    fontWeight: FontWeight.bold,
                    color: prix != null ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
