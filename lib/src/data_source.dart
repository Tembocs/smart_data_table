import 'package:flutter/material.dart';
import 'column.dart';

/// [DataTableSource] implementation that drives [PaginatedDataTable]
/// for [SmartDataTable].
class SmartTableSource<T> extends DataTableSource {
  SmartTableSource(
    this._data,
    this._columns,
    this._onTap, {
    required Set<int> selectedRowIndices,
    required this.onSetSelectedIndices,
    required List<double> columnWidths,
  }) : _selectedRowIndices = selectedRowIndices,
       _columnWidths = columnWidths;

  final List<T> _data;
  final List<SmartColumn<T>> _columns;
  final void Function(T)? _onTap;
  final List<double> _columnWidths;

  /// Called when the set of selected indices changes.
  final void Function(Set<int> indices) onSetSelectedIndices;

  /// Currently selected row indices in the full view.
  final Set<int> _selectedRowIndices;

  @override
  DataRow? getRow(int index) {
    if (index >= _data.length) return null;
    final item = _data[index];
    final isSelected = _selectedRowIndices.contains(index);

    return DataRow.byIndex(
      index: index,
      selected: isSelected,
      // Checkbox click: toggle selection (select/deselect).
      onSelectChanged: (_) {
        final next = {..._selectedRowIndices};
        if (isSelected) {
          next.remove(index);
        } else {
          next.add(index);
        }
        onSetSelectedIndices(next);
      },
      cells: [
        for (int i = 0; i < _columns.length; i++)
          DataCell(
            Container(
              constraints: BoxConstraints(
                minWidth: _columnWidths[i],
                maxWidth: _columnWidths[i],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              alignment: _columns[i].numeric
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: _columns[i].cellBuilder(item),
            ),
            // Row content click: navigate if selected, otherwise select.
            onTap: () {
              if (isSelected && _onTap != null) {
                // If already selected, navigate.
                _onTap(item);
              } else {
                // Otherwise, select the row.
                final next = {..._selectedRowIndices}..add(index);
                onSetSelectedIndices(next);
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
  int get selectedRowCount => _selectedRowIndices.length;
}
