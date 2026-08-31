//// Provides pure SpreadUI labels and summaries without browser dependencies.

import gleam/int

/// Identifies how the current workbook was created.
pub type LoadSource {
  SavedWorkbook
  MendixData
  PracticalSample
  EmptyWorkbook
  ImportedFile
  UnknownSource
}

/// Converts a runtime source discriminator into the public domain type.
pub fn source_from_string(source source: String) -> LoadSource {
  case source {
    "saved" -> SavedWorkbook
    "mendix" -> MendixData
    "sample" -> PracticalSample
    "empty" -> EmptyWorkbook
    "imported" -> ImportedFile
    _ -> UnknownSource
  }
}

/// Creates a stable, user-facing row/column summary.
pub fn dataset_summary(
  row_count row_count: Int,
  column_count column_count: Int,
) -> String {
  int.to_string(row_count)
  <> " rows · "
  <> int.to_string(column_count)
  <> " columns"
}

/// Creates the save result shown after an explicit persistence operation.
pub fn save_summary_text(
  updated_count updated_count: Int,
  skipped_count skipped_count: Int,
  failed_count failed_count: Int,
  state_saved state_saved: Bool,
) -> String {
  let state_text = case state_saved {
    True -> "workbook state persisted"
    False -> "no workbook state attribute configured"
  }
  "Saved "
  <> int.to_string(updated_count)
  <> " cells · skipped "
  <> int.to_string(skipped_count)
  <> " · failed "
  <> int.to_string(failed_count)
  <> " · "
  <> state_text
}
