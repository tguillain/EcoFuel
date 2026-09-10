import 'package:flutter/material.dart';

import 'models/station.dart';
import 'services/api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StationsScreen(),
    );
  }
}

class StationsScreen extends StatefulWidget {
  const StationsScreen({super.key});

  @override
  State<StationsScreen> createState() => _StationsScreenState();
}

class _StationsScreenState extends State<StationsScreen> {
  List<Station> _stations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final stations = await ApiService.fetchNearbyStations();
    setState(() {
      _stations = stations;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stations (Rayon 5 km)'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData, // Bouton pour relancer la recherche
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stations.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'Aucune station trouvée dans un rayon de 5 km.\n(Vérifiez votre position GPS ou simulez une zone active).',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
          : ListView.builder(
              itemCount: _stations.length,
              itemBuilder: (context, index) {
                final station = _stations[index];
                final prixTxt = station.prix != null
                    ? '${station.prix!.toStringAsFixed(3)} €/L'
                    : 'Prix N/C';

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.local_gas_station, color: Colors.white),
                    ),
                    title: Text(
                      station.adresse,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(station.ville),
                    trailing: Text(
                      prixTxt,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
