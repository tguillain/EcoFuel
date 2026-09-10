import 'package:flutter/material.dart';

class StationList extends StatelessWidget {
  const StationList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Station List')),
      body: ListView(
        children: <Widget>[
          Card(
            shadowColor: const Color.fromRGBO(10, 132, 255, 1),
            elevation: 5,
            color: const Color.fromRGBO(10, 132, 255, 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: ListTile(
              textColor: Colors.white,
              title: Text('Intermarché Rezé'),
              subtitle: Text('1,2 km - ouvert jusqu\'à 20h'),
              trailing: Text('1,45 €/L'),
            ),
          ),
          Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: ListTile(
              title: Text('Leclerc Atlantis'),
              subtitle: Text('2,8 km'),
            ),
          ),
          Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: ListTile(
              title: Text('Total Access Pirmil'),
              subtitle: Text('0.6 km'),
            ),
          ),
          Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: ListTile(
              title: Text('Avia Saint-Herblain'),
              subtitle: Text('4,1 km'),
            ),
          ),
        ],
      ),
    );
  }
}
