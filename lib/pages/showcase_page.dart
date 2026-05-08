import 'package:flutter/material.dart';

import '../navigation/nav_controller.dart';
import '../navigation/context_extensions.dart';

class ShowcasePage extends StatelessWidget {
  const ShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.navController;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('Showcase'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          floating: true,
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList.list(
            children: [
              _SectionTitle('Declarative (stack-managed)'),
              _ActionTile(
                icon: Icons.arrow_forward,
                title: 'navigate("/item/1")',
                onTap: () => nav.navigate('/item/1'),
              ),
              _ActionTile(
                icon: Icons.widgets,
                title: 'navigateWidget(…)',
                onTap: () => nav.navigateWidget(
                  _SamplePage(title: 'Inline Widget Page'),
                ),
              ),
              _ActionTile(
                icon: Icons.vertical_align_bottom,
                title: 'showBottomSheet("/item/2")',
                onTap: () => nav.showBottomSheet(
                  '/item/2',
                  config: const BottomSheetConfig(
                    heightFactor: 0.85,
                    showDragHandle: true,
                    useSafeArea: true,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                  ),
                ),
              ),
              _ActionTile(
                icon: Icons.crop_square,
                title: 'showBottomSheetWidget(…)',
                onTap: () => nav.showBottomSheetWidget(
                  const _SampleContent(label: 'Inline Bottom Sheet'),
                  config: const BottomSheetConfig(
                    heightFactor: 0.5,
                    showDragHandle: true,
                  ),
                ),
              ),
              _ActionTile(
                icon: Icons.open_in_new,
                title: 'showDialog("/item/3")',
                onTap: () => nav.showDialog('/item/3'),
              ),
              _ActionTile(
                icon: Icons.chat_bubble_outline,
                title: 'showDialogWidget(…)',
                onTap: () => nav.showDialogWidget(
                  _buildSampleDialog(context),
                ),
              ),
              const SizedBox(height: 24),
              _SectionTitle('Imperative (returns result)'),
              _ActionTile(
                icon: Icons.arrow_forward,
                title: 'push<String>("/item/4")',
                onTap: () async {
                  final result = await nav.push<String>('/item/4');
                  if (context.mounted) {
                    _showResult(context, result);
                  }
                },
              ),
              _ActionTile(
                icon: Icons.widgets,
                title: 'pushWidget<String>(…)',
                onTap: () async {
                  final result = await nav.pushWidget<String>(
                    const _ResultPage(),
                  );
                  if (context.mounted) {
                    _showResult(context, result);
                  }
                },
              ),
              _ActionTile(
                icon: Icons.vertical_align_bottom,
                title: 'pushBottomSheet<bool>(…)',
                onTap: () async {
                  final result = await nav.pushBottomSheetWidget<bool>(
                    _buildConfirmSheet(context),
                    config: const BottomSheetConfig(
                      heightFactor: 0.35,
                      showDragHandle: true,
                    ),
                  );
                  if (context.mounted) {
                    _showResult(context, result);
                  }
                },
              ),
              _ActionTile(
                icon: Icons.chat_bubble_outline,
                title: 'pushDialogWidget<bool>(…)',
                onTap: () async {
                  final result = await nav.pushDialogWidget<bool>(
                    _buildConfirmDialog(context),
                  );
                  if (context.mounted) {
                    _showResult(context, result);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showResult(BuildContext context, Object? result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Result: $result')),
    );
  }

  Widget _buildSampleDialog(BuildContext context) {
    return AlertDialog(
      title: const Text('Sample Dialog'),
      content: const Text('This dialog was shown via showDialogWidget.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }

  Widget _buildConfirmSheet(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Confirm action?', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Confirm'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmDialog(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm'),
      content: const Text('Do you want to proceed?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('No'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Yes'),
        ),
      ],
    );
  }
}

// --- Helper widgets ---

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontSize: 14)),
        trailing: const Icon(Icons.play_arrow, size: 20),
        onTap: onTap,
      ),
    );
  }
}

class _SamplePage extends StatelessWidget {
  final String title;
  const _SamplePage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
      ),
    );
  }
}

class _SampleContent extends StatelessWidget {
  final String label;
  const _SampleContent({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child:
            Text(label, style: Theme.of(context).textTheme.headlineSmall),
      ),
    );
  }
}

class _ResultPage extends StatelessWidget {
  const _ResultPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick a value'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: ['Alpha', 'Beta', 'Gamma'].map((value) {
          return ListTile(
            title: Text(value),
            onTap: () => Navigator.pop(context, value),
          );
        }).toList(),
      ),
    );
  }
}
