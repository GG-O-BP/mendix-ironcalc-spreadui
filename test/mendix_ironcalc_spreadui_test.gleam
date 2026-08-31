//// Exercises the pure SpreadUI domain behavior.

import gleeunit
import gleeunit/should
import spread_ui/domain

/// Runs the SpreadUI test suite.
pub fn main() -> Nil {
  gleeunit.main()
}

/// Verifies every supported source discriminator is preserved.
pub fn source_discriminators_are_complete_test() -> Nil {
  domain.source_from_string(source: "saved")
  |> should.equal(domain.SavedWorkbook)
  domain.source_from_string(source: "mendix")
  |> should.equal(domain.MendixData)
  domain.source_from_string(source: "sample")
  |> should.equal(domain.PracticalSample)
  domain.source_from_string(source: "empty")
  |> should.equal(domain.EmptyWorkbook)
  domain.source_from_string(source: "imported")
  |> should.equal(domain.ImportedFile)
  domain.source_from_string(source: "future-source")
  |> should.equal(domain.UnknownSource)
}

/// Verifies empty datasets have an explicit summary rather than disappearing.
pub fn empty_dataset_summary_test() -> Nil {
  domain.dataset_summary(row_count: 0, column_count: 0)
  |> should.equal("0 rows · 0 columns")
}

/// Verifies dataset ordering remains row first and column second.
pub fn populated_dataset_summary_test() -> Nil {
  domain.dataset_summary(row_count: 1250, column_count: 7)
  |> should.equal("1250 rows · 7 columns")
}

/// Verifies successful state persistence is reported with all counters.
pub fn persisted_save_summary_test() -> Nil {
  domain.save_summary_text(
    updated_count: 3,
    skipped_count: 4,
    failed_count: 1,
    state_saved: True,
  )
  |> should.equal(
    "Saved 3 cells · skipped 4 · failed 1 · workbook state persisted",
  )
}

/// Verifies a missing persistence attribute is explicit and non-fatal.
pub fn save_without_state_attribute_summary_test() -> Nil {
  domain.save_summary_text(
    updated_count: 0,
    skipped_count: 2,
    failed_count: 0,
    state_saved: False,
  )
  |> should.equal(
    "Saved 0 cells · skipped 2 · failed 0 · no workbook state attribute configured",
  )
}
