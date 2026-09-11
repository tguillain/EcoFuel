import 'package:flutter/material.dart';

import 'screens/stations_screen.dart';

void main() {
  runApp(const EcoFuelApp());
}

class EcoFuelApp extends StatelessWidget {
  const EcoFuelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoFuel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
        ),
        useMaterial3: true,
      ),
      home: const StationsScreen(),
    );
  }
}