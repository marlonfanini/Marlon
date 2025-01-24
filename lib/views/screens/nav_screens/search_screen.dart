import 'package:flutter/material.dart';

// Search Screen
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const <Widget>[
          Icon(Icons.search, size: 100),
          Text('Búsqueda'),
        ],
      ),
    );
  }
}