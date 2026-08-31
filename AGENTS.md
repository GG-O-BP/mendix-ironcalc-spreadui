# Mendix IronCalc SpreadUI instructions

- Keep widget UI and state transitions in Gleam. JavaScript is limited to the typed IronCalc/Mendix runtime boundary in `src/spread_ui_ffi.mjs`.
- Keep Glendix pinned to 5.2.0 and preserve published Hex dependencies.
- Never edit generated `build/`, `dist/`, or Glendix binding files manually.
- Never commit Mendix tokens, API keys, workbook data, or generated test projects.
- Validate formatting, type checking, warning-free build, docs, tests, and a production MPK before claiming compatibility.
