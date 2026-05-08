import 'package:flutter/material.dart';
import 'package:flutter_navigator_example/navigation/bottom_sheet_config.dart';

import '../navigation/context_extensions.dart';

final List<String> items = List.generate(10, (i) => 'Item ${i + 1}');

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigator 2.0 — Home'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final id = '${index + 1}';
          return ListTile(
            title: Text(items[index]),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.navController.showBottomSheet(
              '/item/$id',
              config: const BottomSheetConfig(
                heightFactor: 0.98,
                showDragHandle: false,
                isDismissible: true,
                useSafeArea: true,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
