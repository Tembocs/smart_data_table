import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_data_table/smart_data_table.dart';

class _Task {
  _Task(this.name, this.priority, this.createdAt);

  final String name;
  final int priority;
  final DateTime createdAt;
}

void main() {
  testWidgets('SmartDataTable builds with basic configuration', (tester) async {
    final tasks = <_Task>[
      _Task('Alpha', 1, DateTime(2024, 1, 10)),
      _Task('Beta', 2, DateTime(2024, 2, 10)),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmartDataTable<_Task>(
            data: tasks,
            columns: [
              SmartColumn<_Task>(
                label: 'Title',
                cellBuilder: (t) =>
                    Text(t.name, key: const ValueKey('title-alpha')),
              ),
              SmartColumn<_Task>(
                label: 'Priority',
                cellBuilder: (t) => Text('${t.priority}'),
                sortable: true,
                sortBy: (t) => t.priority,
              ),
            ],
            rowsPerPage: 10,
            showFilters: false,
            showToolbar: false,
          ),
        ),
      ),
    );

    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Priority'), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
  });

  testWidgets('sorts rows when tapping sortable column header', (tester) async {
    final tasks = <_Task>[
      _Task('Alpha', 2, DateTime(2024, 1, 10)),
      _Task('Beta', 1, DateTime(2024, 2, 10)),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmartDataTable<_Task>(
            data: tasks,
            columns: [
              SmartColumn<_Task>(
                label: 'Title',
                cellBuilder: (t) => Text(t.name),
              ),
              SmartColumn<_Task>(
                label: 'Priority',
                cellBuilder: (t) => Text('${t.priority}'),
                sortable: true,
                sortBy: (t) => t.priority,
              ),
            ],
            rowsPerPage: 10,
          ),
        ),
      ),
    );

    // Initial order should show Alpha then Beta.
    final alphaFirst =
        tester.getTopLeft(find.text('Alpha')).dy <
        tester.getTopLeft(find.text('Beta')).dy;
    expect(alphaFirst, isTrue);

    // Tap the sortable column header to trigger sort.
    await tester.tap(find.text('Priority'));
    await tester.pumpAndSettle();

    // After sort ascending by priority, Beta (1) should appear before Alpha (2).
    final betaFirst =
        tester.getTopLeft(find.text('Beta')).dy <
        tester.getTopLeft(find.text('Alpha')).dy;
    expect(betaFirst, isTrue);
  });

  testWidgets('shows no rows when data is empty', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmartDataTable<_Task>(
            data: const <_Task>[],
            columns: [
              SmartColumn<_Task>(
                label: 'Title',
                cellBuilder: (t) => Text(t.name),
              ),
            ],
          ),
        ),
      ),
    );

    // Header is present but no data rows are rendered.
    expect(find.text('Title'), findsOneWidget);
    expect(find.byType(DataRow), findsNothing);
  });

  testWidgets('text and number filters narrow visible rows', (tester) async {
    final tasks = <_Task>[
      _Task('Alpha', 1, DateTime(2024, 1, 10)),
      _Task('Beta', 2, DateTime(2024, 2, 10)),
      _Task('Gamma', 3, DateTime(2024, 3, 10)),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmartDataTable<_Task>(
            data: tasks,
            columns: [
              SmartColumn<_Task>(
                label: 'Title',
                cellBuilder: (t) => Text(t.name),
                filterKind: SmartFilterKind.text,
                filterText: (t) => t.name,
              ),
              SmartColumn<_Task>(
                label: 'Priority',
                cellBuilder: (t) => Text('${t.priority}'),
                filterKind: SmartFilterKind.numberRange,
                filterNumber: (t) => t.priority,
              ),
            ],
            rowsPerPage: 10,
            showFilters: true,
            showToolbar: false,
          ),
        ),
      ),
    );

    // Initially all tasks are visible.
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('Gamma'), findsOneWidget);

    // Apply text filter on Title to keep only "Alpha".
    final titleFilter = find.byType(TextField).first;
    await tester.enterText(titleFilter, 'Alp');
    await tester.pumpAndSettle();

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsNothing);
    expect(find.text('Gamma'), findsNothing);

    // Clear text filter, then apply number range filter to keep priority >= 2.
    await tester.enterText(titleFilter, '');
    await tester.pumpAndSettle();

    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    // For numberRange filter we expect two fields: Min then Max.
    final minField = fields[1];
    final minFilterFinder = find.byWidget(minField);
    await tester.enterText(minFilterFinder, '2');
    await tester.pumpAndSettle();

    expect(find.text('Alpha'), findsNothing);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('Gamma'), findsOneWidget);
  });
}
