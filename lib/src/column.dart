import 'package:flutter/material.dart';

/// Controls the vertical height of data/heading rows.
///
/// - [compact]   → shortest rows, fits many rows in view.
/// - [comfy]     → default, balanced density.
/// - [spacious]  → taller rows, easier to read on touch devices.
enum SmartRowDensity { compact, comfy, spacious }

/// Describes the type of filter UI and matching behavior for a column.
///
/// - [none]        → no filter displayed for this column.
/// - [text]        → a single text field, supports `contains(...)`.
/// - [numberRange] → two numeric fields: Min / Max.
/// - [dateRange]   → two date fields, expects `YYYY-MM-DD` input.
enum SmartFilterKind { none, text, numberRange, dateRange }

/// Column configuration for [SmartDataTable].
///
/// This describes how a column should:
/// - Render its header label.
/// - Build its cell widget from a row item [T].
/// - Provide values for sorting, CSV export, and filtering.
///
/// All behavior is defined from the outside so the table can remain generic.
class SmartColumn<T> {
  const SmartColumn({
    required this.label,
    required this.cellBuilder,
    this.numeric = false,
    this.sortable = false,
    this.sortBy,
    this.csvValue,
    this.filterKind = SmartFilterKind.none,
    this.filterText,
    this.filterNumber,
    this.filterDate,
  });

  /// Column header text.
  final String label;

  /// Builds the cell widget for this column from a given row item [T].
  final Widget Function(T) cellBuilder;

  /// Whether the column should be right-aligned like numeric columns usually are.
  final bool numeric;

  /// Whether the column supports sorting via [sortBy].
  final bool sortable;

  /// Accessor used for sorting when [sortable] is true.
  ///
  /// The returned value must be [Comparable]. Example:
  ///
  ///   sortBy: (user) => user.name
  final Comparable<dynamic> Function(T)? sortBy;

  /// Accessor used when exporting to CSV.
  ///
  /// If `null`, `sortBy` is used as a fallback, otherwise an empty string.
  final String Function(T)? csvValue;

  /// Type of filter control to show for this column.
  final SmartFilterKind filterKind;

  /// Getter used for text filtering (contains, case-insensitive).
  ///
  /// Only used when [filterKind] == [SmartFilterKind.text].
  final String Function(T)? filterText;

  /// Getter used for numeric range filtering.
  ///
  /// Only used when [filterKind] == [SmartFilterKind.numberRange].
  final num Function(T)? filterNumber;

  /// Getter used for date range filtering.
  ///
  /// Only used when [filterKind] == [SmartFilterKind.dateRange].
  final DateTime Function(T)? filterDate;
}
