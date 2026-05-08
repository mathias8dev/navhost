import 'package:flutter/material.dart';
import 'package:navhost/navhost.dart';

final List<String> items = List.generate(10, (i) => 'Item ${i + 1}');

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('Home'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          floating: true,
        ),
        SliverList.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final id = '${index + 1}';
            return ListTile(
              title: Text(items[index]),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.navController.navigate('/item/$id'),
            );
          },
        ),
      ],
    );
  }
}
