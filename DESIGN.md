# Observable behavior contract

This document records the behaviors that the implementation and regression tests preserve.

## Loading priority

1. Restore a non-empty, valid persisted workbook.
2. If persistence is absent or invalid, load available Mendix rows and configured columns.
3. If rows or columns are empty, use the configured sample/empty fallback.
4. Invalid persisted bytes do not strand the user: they produce a visible fallback notice.

## Ordering and de-duplication

- Datasource item order is preserved.
- Column configuration order is preserved.
- Empty headers become `Column N`.
- Duplicate headers gain stable ` (2)`, ` (3)`, … suffixes.
- Formula placeholders are expanded per data row after ordering is fixed.

## Boundaries and performance

- Height: 320–1600 px.
- Row batch: 1–10000 available items.
- Column width: 60–600 px.
- WebAssembly initialization is shared.
- Bulk cell writes pause evaluation and evaluate exactly once after the batch.
- Only currently available datasource items are loaded; no hidden network pagination is triggered.

## Save behavior

- Save is disabled in read-only mode and while another operation is active.
- Formula, unconfigured, unavailable, read-only, and unchanged cells are skipped.
- Values are converted using the current Mendix value shape (String, number, Boolean, Date, decimal-like object).
- Empty cells clear the editable value.
- Conversion errors are isolated per cell and counted.
- Workbook persistence is optional and reported separately.
- The configured action executes after local writes and persistence.

## Failure behavior

- WASM, datasource conversion, import, download, and persistence errors become visible state.
- A failed action never reports success.
- Import cancellation reports a non-destructive error and Reload remains available.
- A restored workbook retains the current datasource row/column mapping so
  explicit Save can still write editable cells back to Mendix.
- No secret, workbook content, or datasource value is logged.
