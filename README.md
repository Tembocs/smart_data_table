# Smart Data Table

A flexible, responsive Flutter data table widget built on top of `PaginatedDataTable`.

This widget supports:
- Sorting on any column
- Text, number range, and date filtering
- CSV export (clipboard and file)
- Customizable row density (Compact / Comfy / Spacious)
- Keyboard navigation (Up/Down/Page Up/Down/Enter)
- Responsive layout (handles horizontal overflow gracefully)

Perfect for internal tools, admin dashboards, or desktop applications.

---

## Features

- Text and range-based filtering
- Sortable columns with type-safe `sortBy`
- CSV export (clipboard or download)
- Keyboard navigation
- Smart width handling for desktop/tablet devices
- Fully generic over your data model

---

## Usage

```dart
import 'package:smart_data_table/smart_data_table.dart';

SmartDataTable<Task>(
  data: tasks,
  columns: [
    SmartColumn(
      label: 'Title',
      cellBuilder: (t) => Text(t.name),
      filterKind: SmartFilterKind.text,
      filterText: (t) => t.name,
    ),
    SmartColumn(
      label: 'Priority',
      cellBuilder: (t) => Text('${t.priority}'),
      sortable: true,
      sortBy: (t) => t.priority,
      filterKind: SmartFilterKind.numberRange,
      filterNumber: (t) => t.priority,
    ),
  ],
  rowsPerPage: 10,
  showFilters: true,
  showToolbar: true,
  onRowTap: (task) => print(task),
);
```

## Getting Started

1. Clone the repo
```bash
git clone https://github.com/Tembocs/smart_data_table.git
```

2. Add a path dependency in pubspec.yaml:
```bash
dependencies:
  smart_data_table:
    path: ../smart_data_table
```


## Roadmap

Tests for filtering/sorting
Column resizing
Select-all and batch action?
Support sticky headers on large data