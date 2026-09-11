import 'package:flutter/material.dart';

class FiltersBar extends StatelessWidget {
  final String carburant;
  final int rayon;
  final String tri;

  final ValueChanged<String> onCarburantChanged;
  final ValueChanged<int> onRayonChanged;
  final ValueChanged<String> onTriChanged;

  const FiltersBar({
    super.key,
    required this.carburant,
    required this.rayon,
    required this.tri,
    required this.onCarburantChanged,
    required this.onRayonChanged,
    required this.onTriChanged,
  });

  static const List<String> carburants = [
    'Gazole',
    'SP95',
    'SP98',
    'E10',
    'E85',
    'GPLc',
  ];

  static const List<int> rayons = [5, 10, 25, 50];

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Carburant',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: carburant, // Corrigé ici (valeur actuelle au lieu de initialValue)
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_gas_station),
              ),
              items: carburants.map((String item) {
                return DropdownMenuItem<String>(value: item, child: Text(item));
              }).toList(),
              onChanged: (String? value) {
                if (value != null) {
                  onCarburantChanged(value);
                }
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Rayon de recherche',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: rayons.map((int rayonValue) {
                return ChoiceChip(
                  label: Text('$rayonValue km'),
                  selected: rayon == rayonValue,
                  onSelected: (_) {
                    onRayonChanged(rayonValue);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text(
              'Trier par',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(
                  value: 'prix',
                  icon: Icon(Icons.euro),
                  label: Text('Moins cher'),
                ),
                ButtonSegment<String>(
                  value: 'distance',
                  icon: Icon(Icons.near_me),
                  label: Text('Plus proche'),
                ),
              ],
              selected: {tri},
              onSelectionChanged: (Set<String> selection) {
                onTriChanged(selection.first);
              },
            ),
          ],
        ),
      ),
    );
  }
}
