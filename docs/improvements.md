# Functional Improvements Roadmap

This document outlines potential areas for improvement for the `smart_data_table` package, ordered by estimated implementation difficulty (Easiest to Hardest).

## 1. Column Visibility Toggles (Easy)
**Goal**: Allow users to dynamically hide or show columns.
- **Why**: Users often want to declutter their view or focus on specific data points.
- **Implementation**:
    - Add a "Columns" button in the toolbar.
    - Show a multi-select dropdown or dialog.
    - Filter the `columns` list passed to the table based on the user's selection.

## 2. Enhanced Filter UI (Easy)
**Goal**: Replace generic text inputs with appropriate controls for specific data types.
- **Why**: Typing dates (e.g., "2023-10-01") or exact status strings is error-prone and slow.
- **Implementation**:
    - **Date Range**: Use `showDatePicker` for date columns.
    - **Enums/Categories**: Use a `DropdownButton` for columns with a limited set of known values.

## 3. Batch Actions Toolbar (Easy)
**Goal**: Show action buttons when rows are selected.
- **Why**: Users need to perform actions on multiple items at once (e.g., "Delete 5 items", "Approve Selected").
- **Implementation**:
    - In `_buildToolbar`, check if `_selectedIndices` is not empty.
    - If true, replace the standard tools with a set of action buttons (provided via a new callback or widget parameter).

## 4. Persist Selection (Medium)
**Goal**: Maintain row selection even when sorting or filtering changes the row indices.
- **Why**: Currently, sorting clears the selection because it relies on list indices. This is a poor user experience.
- **Implementation**:
    - Introduce a `keySelector` parameter (e.g., `(item) => item.id`).
    - Store `Set<Key>` (IDs) instead of `Set<int>` (indices).
    - Map keys back to indices when rendering the table rows.

## 5. Summary / Footer Row (Medium)
**Goal**: Display totals, averages, or counts at the bottom of the table.
- **Why**: Essential for financial or statistical data tables.
- **Implementation**:
    - Add a `footer` property or builder.
    - Calculate totals based on the current `_viewData`.
    - Display them in a pinned row at the bottom of the table.

## 6. Sticky Headers (Medium/Hard)
**Goal**: Keep column headers visible while scrolling down.
- **Why**: Essential for reading long tables where context is lost after scrolling.
- **Implementation**:
    - The current implementation wraps `PaginatedDataTable` in a vertical `SingleChildScrollView`, which breaks internal sticky headers.
    - **Fix**: Refactor the scroll behavior. Remove the outer scroll view and ensure the table handles its own scrolling, or use a `Sliver` based approach if `PaginatedDataTable` proves too rigid.

## 7. Async & Server-Side Data (Hard)
**Goal**: Support loading data lazily from a backend instead of requiring all data in memory.
- **Why**: Loading all data into memory causes performance issues or crashes with large datasets (e.g., >10,000 rows).
- **Implementation**:
    - Change the input `data` from `List<T>` to a `Future<List<T>> Function(int page, int limit, Sort sort, Filter filter)`.
    - Rewrite `SmartTableSource` to handle async loading states (loading spinners, error handling).
    - Implement debouncing for server-side filtering.
