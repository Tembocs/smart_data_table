import 'package:flutter/material.dart';
import 'column.dart';

/// [DataTableSource] implementation that drives [PaginatedDataTable]
/// for [SmartDataTable].
class SmartTableSource<T> extends DataTableSource {
  SmartTableSource(
    this._data,
    this._columns,
    this._onTap, {
    int? selectedRowIndex,
    this.onSelectRow,
  }) : _selectedRowIndex = selectedRowIndex;

  final List<T> _data;
  final List<SmartColumn<T>> _columns;
  final void Function(T)? _onTap;

  /// Called when selection changes (index in current view or null to clear).
  final void Function(int? index)? onSelectRow;

  /// Currently selected row index in the full view.
  final int? _selectedRowIndex;

  @override
  DataRow? getRow(int index) {
    if (index >= _data.length) return null;
    final item = _data[index];
    final isSelected = _selectedRowIndex == index;

    return DataRow.byIndex(
      index: index,
      selected: isSelected,
      // Checkbox click: toggle selection (select/deselect).
      onSelectChanged: (_) {
        if (isSelected) {
          // Deselect if already selected.
          onSelectRow?.call(null);
        } else {
          // Select if not selected.
          onSelectRow?.call(index);
        }
      },
      cells: [
        for (final col in _columns)
          DataCell(
            col.cellBuilder(item),
            // Row content click: navigate if selected, otherwise select.
            onTap: () {
              if (isSelected && _onTap != null) {
                // If already selected, navigate.
                _onTap(item);
              } else {
                // Otherwise, select the row.
                onSelectRow?.call(index);
              }
            },
          ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _data.length;

  @override
  int get selectedRowCount => 0;
}
