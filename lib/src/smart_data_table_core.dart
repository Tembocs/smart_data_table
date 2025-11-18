// lib/ui/widgets/smart_data_table.dart
// -----------------------------------------------------------------------------
// Reusable, scroll-friendly PaginatedDataTable wrapper.
//
// Key ideas:
// • Generic over <T> so any list of models can be rendered.
// • SmartColumn describes the header, cellBuilder, optional sort getter, CSV
//   accessor and filtering behavior.
// • LayoutBuilder measures viewport; tableWidth = max(viewport, minWidth) to
//   avoid “infinite width” constraint issues.
// • PaginatedDataTable is wrapped in a SizedBox(width: tableWidth) inside a
//   horizontal SingleChildScrollView to work well on desktop and responsive
//   layouts.
// • Optional toolbar: CSV export (clipboard + file), clear filters, row density.
// • Optional filter row: text / numeric range / date range.
//
// Example:
//   SmartDataTable<SaleSummary>(
//     data: items,
//     columns: [
//       SmartColumn(
//         label: 'ID',
//         numeric: true,
//         cellBuilder: (s) => Text('${s.id}'),
//         sortable: true,
//         sortBy: (s) => s.id,
//       ),
//       // ...
//     ],
//     onRowTap: (s) => Navigator.push(...),
//     showFilters: true,
//     showToolbar: true,
//   );
// -----------------------------------------------------------------------------

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'column.dart';
import 'data_source.dart';

/// A generic, desktop-friendly, paginated data table with:
///
/// - Sorting
/// - Text / numeric / date filtering
/// - CSV export (clipboard + file)
/// - Row density controls
/// - Keyboard navigation (optional)
///
/// The widget is generic over `<T>` and uses [SmartColumn] to describe how
/// to render each column and how to read values for sorting/export/filtering.
class SmartDataTable<T> extends StatefulWidget {
  const SmartDataTable({
    super.key,
    required this.data,
    required this.columns,
    this.rowsPerPage = 10,
    this.onRowTap,
    this.minColWidth = 160,
    this.showFilters = false,
    this.showToolbar = false,
    this.rowDensity = SmartRowDensity.comfy,
    this.enableKeyboardNavigation = false,
  });

  /// Full list of items to display before filtering/sorting.
  final List<T> data;

  /// Column definitions that describe rendering, sorting and filtering.
  final List<SmartColumn<T>> columns;

  /// Number of rows per page in the underlying [PaginatedDataTable].
  final int rowsPerPage;

  /// Called when a row is activated (enter key or second click on selected row).
  final void Function(T)? onRowTap;

  /// Minimum width for each column, used to compute table width.
  final double minColWidth;

  /// Whether to show the filter controls row above the table.
  final bool showFilters;

  /// Whether to show the toolbar (CSV export, clear filters, density selector).
  final bool showToolbar;

  /// Initial row density (affects row heights).
  final SmartRowDensity rowDensity;

  /// Whether to enable basic keyboard navigation:
  /// up/down arrows, page up/down, enter to activate row.
  final bool enableKeyboardNavigation;

  @override
  State<SmartDataTable<T>> createState() => _SmartDataTableState<T>();
}

class _SmartDataTableState<T> extends State<SmartDataTable<T>> {
  /// Current index of the sorted column.
  int _sortColumnIndex = 0;

  /// Whether the current sort is ascending.
  bool _ascending = true;

  /// Current view after applying filters and sorting.
  late List<T> _viewData;

  /// Currently selected row index in the full view (not just within a page).
  int? _selectedIndex;

  /// Current row density used to compute row heights.
  late SmartRowDensity _rowDensity;

  // Filtering state (as controllers; we store raw text here, then interpret
  // it when recomputing the view).
  late final List<TextEditingController?> _textFilters;
  late final List<TextEditingController?> _numberMinFilters;
  late final List<TextEditingController?> _numberMaxFilters;
  late final List<TextEditingController?> _dateMinFilters;
  late final List<TextEditingController?> _dateMaxFilters;

  @override
  void initState() {
    super.initState();
    _viewData = List<T>.from(widget.data);
    _rowDensity = widget.rowDensity;

    // Initialize text controllers only for columns that support that filter type.
    _textFilters = [
      for (final c in widget.columns)
        c.filterKind == SmartFilterKind.text ? TextEditingController() : null,
    ];
    _numberMinFilters = [
      for (final c in widget.columns)
        c.filterKind == SmartFilterKind.numberRange
            ? TextEditingController()
            : null,
    ];
    _numberMaxFilters = [
      for (final c in widget.columns)
        c.filterKind == SmartFilterKind.numberRange
            ? TextEditingController()
            : null,
    ];
    _dateMinFilters = [
      for (final c in widget.columns)
        c.filterKind == SmartFilterKind.dateRange
            ? TextEditingController()
            : null,
    ];
    _dateMaxFilters = [
      for (final c in widget.columns)
        c.filterKind == SmartFilterKind.dateRange
            ? TextEditingController()
            : null,
    ];
  }

  @override
  void didUpdateWidget(covariant SmartDataTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the data list instance changes, recompute filtered/sorted view.
    if (!identical(oldWidget.data, widget.data)) {
      _recomputeView();
    }
  }

  /// Sorts [_viewData] by the specified column index [colIndex].
  ///
  /// Uses the [SmartColumn.sortBy] accessor. If it is null, no sort is applied.
  void _doSort(int colIndex, bool asc) {
    final getField = widget.columns[colIndex].sortBy;
    if (getField == null) return;
    _viewData.sort((a, b) {
      final cmp = Comparable.compare(getField(a), getField(b));
      return asc ? cmp : -cmp;
    });
  }

  /// Rebuilds [_viewData] from [widget.data] applying:
  /// 1. All active filters
  /// 2. The current sort column & direction
  void _recomputeView() {
    _viewData = List<T>.from(widget.data);

    // --- Apply filters column by column ---
    for (int i = 0; i < widget.columns.length; i++) {
      final col = widget.columns[i];
      switch (col.filterKind) {
        case SmartFilterKind.text:
          final c = _textFilters[i];
          final q = c?.text.trim().toLowerCase() ?? '';
          if (q.isNotEmpty) {
            final getter = col.filterText;
            if (getter != null) {
              _viewData = _viewData
                  .where((e) => (getter(e).toLowerCase()).contains(q))
                  .toList();
            }
          }
          break;

        case SmartFilterKind.numberRange:
          final minT = _numberMinFilters[i]?.text.trim();
          final maxT = _numberMaxFilters[i]?.text.trim();
          final getter = col.filterNumber;
          if (getter != null &&
              ((minT?.isNotEmpty ?? false) || (maxT?.isNotEmpty ?? false))) {
            final minV = (minT != null && minT.isNotEmpty)
                ? num.tryParse(minT)
                : null;
            final maxV = (maxT != null && maxT.isNotEmpty)
                ? num.tryParse(maxT)
                : null;
            _viewData = _viewData.where((e) {
              final v = getter(e);
              if (minV != null && v < minV) return false;
              if (maxV != null && v > maxV) return false;
              return true;
            }).toList();
          }
          break;

        case SmartFilterKind.dateRange:
          final minT = _dateMinFilters[i]?.text.trim();
          final maxT = _dateMaxFilters[i]?.text.trim();
          final getter = col.filterDate;

          DateTime? parse(String? s) {
            if (s == null || s.isEmpty) return null;
            // Accept simple YYYY-MM-DD format.
            try {
              final parts = s.split('-');
              if (parts.length == 3) {
                return DateTime(
                  int.parse(parts[0]),
                  int.parse(parts[1]),
                  int.parse(parts[2]),
                );
              }
            } catch (_) {
              // Silently ignore parsing errors and treat as no bound.
            }
            return null;
          }

          if (getter != null &&
              ((minT?.isNotEmpty ?? false) || (maxT?.isNotEmpty ?? false))) {
            final minD = parse(minT);
            final maxD = parse(maxT);
            _viewData = _viewData.where((e) {
              final v = getter(e);
              if (minD != null && v.isBefore(minD)) return false;
              if (maxD != null && v.isAfter(maxD)) return false;
              return true;
            }).toList();
          }
          break;

        case SmartFilterKind.none:
          // No filter for this column.
          break;
      }
    }

    // --- Apply current sort (if the column is sortable) ---
    if (widget.columns[_sortColumnIndex].sortable) {
      _doSort(_sortColumnIndex, _ascending);
    }

    setState(() {});
  }

  @override
  void dispose() {
    // Dispose all filter controllers.
    for (final c in _textFilters) {
      c?.dispose();
    }
    for (final c in _numberMinFilters) {
      c?.dispose();
    }
    for (final c in _numberMaxFilters) {
      c?.dispose();
    }
    for (final c in _dateMinFilters) {
      c?.dispose();
    }
    for (final c in _dateMaxFilters) {
      c?.dispose();
    }
    super.dispose();
  }

  /// Height of data rows based on the current [SmartRowDensity].
  double get _dataRowHeight => switch (_rowDensity) {
    SmartRowDensity.compact => 36,
    SmartRowDensity.comfy => 48,
    SmartRowDensity.spacious => 56,
  };

  /// Height of heading row based on the current [SmartRowDensity].
  double get _headingRowHeight => switch (_rowDensity) {
    SmartRowDensity.compact => 40,
    SmartRowDensity.comfy => 52,
    SmartRowDensity.spacious => 60,
  };

  /// Optional toolbar with:
  /// - Export CSV (clipboard)
  /// - Save CSV to file (Downloads / temp)
  /// - Clear all filters
  /// - Row density selector
  Widget _buildToolbar() {
    if (!widget.showToolbar) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Tooltip(
                message: 'Export visible rows to CSV (copied to clipboard)',
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Export CSV'),
                  onPressed: _exportCsv,
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Save visible rows to CSV file (Downloads folder)',
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.save_alt),
                  label: const Text('Save CSV'),
                  onPressed: _saveCsv,
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Clear all active filters',
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.filter_alt_off),
                  label: const Text('Clear filters'),
                  onPressed: _clearFilters,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Text('Density:'),
              const SizedBox(width: 8),
              DropdownButton<SmartRowDensity>(
                value: _rowDensity,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _rowDensity = v;
                  });
                },
                items: const [
                  DropdownMenuItem(
                    value: SmartRowDensity.compact,
                    child: Text('Compact'),
                  ),
                  DropdownMenuItem(
                    value: SmartRowDensity.comfy,
                    child: Text('Comfy'),
                  ),
                  DropdownMenuItem(
                    value: SmartRowDensity.spacious,
                    child: Text('Spacious'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Clears all filter fields (text/number/date) and recomputes the view
  /// if any filter actually changed.
  void _clearFilters() {
    bool changed = false;

    for (final c in _textFilters) {
      if (c != null && c.text.isNotEmpty) {
        c.clear();
        changed = true;
      }
    }
    for (final c in _numberMinFilters) {
      if (c != null && c.text.isNotEmpty) {
        c.clear();
        changed = true;
      }
    }
    for (final c in _numberMaxFilters) {
      if (c != null && c.text.isNotEmpty) {
        c.clear();
        changed = true;
      }
    }
    for (final c in _dateMinFilters) {
      if (c != null && c.text.isNotEmpty) {
        c.clear();
        changed = true;
      }
    }
    for (final c in _dateMaxFilters) {
      if (c != null && c.text.isNotEmpty) {
        c.clear();
        changed = true;
      }
    }

    if (changed) {
      _recomputeView();
    }
  }

  /// Builds a CSV string from the current [_viewData] and [widget.columns].
  ///
  /// - First row: headers (column labels).
  /// - Subsequent rows: values from [SmartColumn.csvValue] or [SmartColumn.sortBy].
  String _buildCsvString() {
    final headers = widget.columns.map((c) => c.label).toList();
    final rows = <List<String>>[];

    for (final item in _viewData) {
      rows.add([
        for (final c in widget.columns)
          c.csvValue?.call(item) ??
              (c.sortBy != null ? '${c.sortBy!(item)}' : ''),
      ]);
    }

    String escape(String s) {
      final needsQuotes =
          s.contains(',') || s.contains('"') || s.contains('\n');
      var v = s.replaceAll('"', '""');
      return needsQuotes ? '"$v"' : v;
    }

    final csv = StringBuffer()..writeln(headers.map(escape).join(','));
    for (final r in rows) {
      csv.writeln(r.map(escape).join(','));
    }
    return csv.toString();
  }

  /// Copies the current view to the clipboard as CSV and shows a SnackBar.
  void _exportCsv() {
    final csv = _buildCsvString();
    Clipboard.setData(ClipboardData(text: csv));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('CSV copied to clipboard')));
  }

  /// Saves the current view as a CSV file into the Downloads (or temp)
  /// directory and shows a SnackBar with the file path.
  Future<void> _saveCsv() async {
    try {
      final csv = _buildCsvString();
      final dir = await getDownloadsDirectory();
      final folder = dir ?? await getTemporaryDirectory();
      final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
      final file = File('${folder.path}/table_export_$ts.csv');
      await file.writeAsString(csv, flush: true);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved CSV to ${file.path}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save CSV: $e')));
    }
  }

  /// Builds the horizontal row of filter controls based on [SmartFilterKind]
  /// for each column.
  Widget _buildFilters() {
    if (!widget.showFilters) return const SizedBox.shrink();
    final children = <Widget>[];

    for (int i = 0; i < widget.columns.length; i++) {
      final col = widget.columns[i];
      switch (col.filterKind) {
        case SmartFilterKind.text:
          children.add(
            SizedBox(
              width: widget.minColWidth,
              child: TextField(
                controller: _textFilters[i],
                decoration: InputDecoration(
                  labelText: col.label,
                  hintText: 'Filter…',
                  isDense: true,
                ),
                onChanged: (_) => _recomputeView(),
              ),
            ),
          );
          break;

        case SmartFilterKind.numberRange:
          children.add(
            SizedBox(
              width: widget.minColWidth,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _numberMinFilters[i],
                      decoration: const InputDecoration(
                        labelText: 'Min',
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _recomputeView(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _numberMaxFilters[i],
                      decoration: const InputDecoration(
                        labelText: 'Max',
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _recomputeView(),
                    ),
                  ),
                ],
              ),
            ),
          );
          break;

        case SmartFilterKind.dateRange:
          children.add(
            SizedBox(
              width: widget.minColWidth,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _dateMinFilters[i],
                      decoration: const InputDecoration(
                        labelText: 'From (YYYY-MM-DD)',
                        isDense: true,
                      ),
                      onChanged: (_) => _recomputeView(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _dateMaxFilters[i],
                      decoration: const InputDecoration(
                        labelText: 'To (YYYY-MM-DD)',
                        isDense: true,
                      ),
                      onChanged: (_) => _recomputeView(),
                    ),
                  ),
                ],
              ),
            ),
          );
          break;

        case SmartFilterKind.none:
          // No filter controls for this column.
          break;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: children),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final minTableWidth = widget.columns.length * widget.minColWidth;

    // Main table widget wrapped in LayoutBuilder to derive finite width.
    final table = LayoutBuilder(
      builder: (context, constraints) {
        final viewport =
            constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : minTableWidth;
        final tableWidth = viewport < minTableWidth ? minTableWidth : viewport;

        final tableWidget = SingleChildScrollView(
          primary: false,
          child: SingleChildScrollView(
            primary: false,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: PaginatedDataTable(
                columns: [
                  for (int i = 0; i < widget.columns.length; i++)
                    DataColumn(
                      label: Text(widget.columns[i].label),
                      numeric: widget.columns[i].numeric,
                      onSort: widget.columns[i].sortable
                          ? (index, asc) {
                              setState(() {
                                _sortColumnIndex = index;
                                _ascending = asc;
                                _doSort(index, asc);
                              });
                            }
                          : null,
                    ),
                ],
                source: SmartTableSource<T>(
                  _viewData,
                  widget.columns,
                  widget.onRowTap,
                  selectedRowIndex: _selectedIndex,
                  onSelectRow: (idx) => setState(() => _selectedIndex = idx),
                ),
                rowsPerPage: widget.rowsPerPage,
                sortColumnIndex: _sortColumnIndex,
                sortAscending: _ascending,
                columnSpacing: 12,
                dataRowMinHeight: _dataRowHeight,
                dataRowMaxHeight: _dataRowHeight,
                headingRowHeight: _headingRowHeight,
              ),
            ),
          ),
        );

        // Ensure vertical area doesn't overflow by constraining the
        // scrollable to available height when inside unbounded parents.
        return SizedBox(
          height: constraints.maxHeight.isFinite ? constraints.maxHeight : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Data first (so it gets the bulk of the height).
              Expanded(child: tableWidget),
              // Controls below to reduce initial cognitive load.
              _buildFilters(),
              _buildToolbar(),
            ],
          ),
        );
      },
    );

    if (!widget.enableKeyboardNavigation) return table;

    // Wrap with keyboard navigation: arrows, page up/down, enter.
    return FocusTraversalGroup(
      child: Focus(
        autofocus: false,
        child: Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.arrowDown):
                DirectionalFocusIntent(TraversalDirection.down),
            SingleActivator(LogicalKeyboardKey.arrowUp): DirectionalFocusIntent(
              TraversalDirection.up,
            ),
            SingleActivator(LogicalKeyboardKey.pageDown): ScrollIntent(
              direction: AxisDirection.down,
            ),
            SingleActivator(LogicalKeyboardKey.pageUp): ScrollIntent(
              direction: AxisDirection.up,
            ),
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              DirectionalFocusIntent: CallbackAction<DirectionalFocusIntent>(
                onInvoke: (intent) {
                  setState(() {
                    final rowsPerPage = widget.rowsPerPage;
                    final maxIndex = (_viewData.length - 1).clamp(
                      0,
                      _viewData.length - 1,
                    );
                    int idx = _selectedIndex ?? 0;
                    if (intent.direction == TraversalDirection.down) {
                      idx = (idx + 1).clamp(0, maxIndex);
                    } else if (intent.direction == TraversalDirection.up) {
                      idx = (idx - 1).clamp(0, maxIndex);
                    }
                    // keep within current page bounds
                    final pageStart = ((idx ~/ rowsPerPage) * rowsPerPage);
                    final inPageIdx = idx - pageStart;
                    _selectedIndex = pageStart + inPageIdx;
                  });
                  return null;
                },
              ),
              ScrollIntent: CallbackAction<ScrollIntent>(
                onInvoke: (intent) {
                  setState(() {
                    final rowsPerPage = widget.rowsPerPage;
                    final maxIndex = (_viewData.length - 1).clamp(
                      0,
                      _viewData.length - 1,
                    );
                    int idx = _selectedIndex ?? 0;
                    if (intent.direction == AxisDirection.down) {
                      idx = (idx + rowsPerPage).clamp(0, maxIndex);
                    } else if (intent.direction == AxisDirection.up) {
                      idx = (idx - rowsPerPage).clamp(0, maxIndex);
                    }
                    // clamp to start of the current page
                    final pageStart = ((idx ~/ rowsPerPage) * rowsPerPage);
                    _selectedIndex = pageStart; // top of page
                  });
                  return null;
                },
              ),
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) {
                  final idx = _selectedIndex;
                  if (idx != null && idx >= 0 && idx < _viewData.length) {
                    final item = _viewData[idx];
                    widget.onRowTap?.call(item);
                  }
                  return null;
                },
              ),
            },
            child: table,
          ),
        ),
      ),
    );
  }
}
