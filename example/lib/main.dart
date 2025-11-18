import 'package:flutter/material.dart';
import 'package:smart_data_table/smart_data_table.dart';

import 'sample_data.dart';

void main() {
  runApp(const SmartDataTableExampleApp());
}

class SmartDataTableExampleApp extends StatelessWidget {
  const SmartDataTableExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Data Table Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const ExampleHomePage(),
    );
  }
}

class ExampleHomePage extends StatelessWidget {
  const ExampleHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SmartDataTable Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SmartDataTable<ExampleTask>(
          data: kExampleTasks,
          columns: [
            SmartColumn<ExampleTask>(
              label: 'ID',
              numeric: true,
              cellBuilder: (t) => Text('${t.id}'),
              sortable: true,
              sortBy: (t) => t.id,
            ),
            SmartColumn<ExampleTask>(
              label: 'Title',
              cellBuilder: (t) => Text(t.title),
              filterKind: SmartFilterKind.text,
              filterText: (t) => t.title,
            ),
            SmartColumn<ExampleTask>(
              label: 'Priority',
              numeric: true,
              cellBuilder: (t) => Text('${t.priority}'),
              sortable: true,
              sortBy: (t) => t.priority,
              filterKind: SmartFilterKind.numberRange,
              filterNumber: (t) => t.priority,
            ),
            SmartColumn<ExampleTask>(
              label: 'Created',
              cellBuilder: (t) => Text(
                '${t.createdAt.year}-${t.createdAt.month.toString().padLeft(2, '0')}-${t.createdAt.day.toString().padLeft(2, '0')}',
              ),
              sortable: true,
              sortBy: (t) => t.createdAt,
              filterKind: SmartFilterKind.dateRange,
              filterDate: (t) => t.createdAt,
            ),
          ],
          rowsPerPage: 5,
          showFilters: true,
          showToolbar: true,
          enableKeyboardNavigation: true,
          onRowTap: (task) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Tapped: ${task.title}')));
          },
        ),
      ),
    );
  }
}
