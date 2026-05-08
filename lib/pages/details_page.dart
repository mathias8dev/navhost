import 'package:flutter/material.dart';

class DetailsPage extends StatelessWidget {
  final String itemId;

  const DetailsPage({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Details — Item $itemId'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Text(
          'Item $itemId',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
      ),
    );
  }
}
