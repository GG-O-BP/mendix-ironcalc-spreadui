# Mendix IronCalc SpreadUI

[한국어](README.ko.md) | **English**

A practical, open-source spreadsheet widget for Mendix. It combines the
IronCalc WebAssembly calculation engine and React workbook with a Gleam UI built
through Glendix 5.2.0.

SpreadUI is the widget's task-focused shell: it makes Mendix data immediately
usable as a workbook, keeps expensive work batched, and gives users explicit
Reload, Import, Download, and Save actions.

## What is included

- **Real Mendix data** — bind a list datasource and configure an ordered list of
  String, numeric, Boolean, DateTime, Enum, or AutoNumber attributes.
- **Optional write-back** — edited non-formula cells are written to editable
  Mendix attributes only when the user presses **Save to Mendix**.
- **Complete workbook persistence** — an optional String attribute stores the
  IronCalc `.ic` bytes as base64, preserving formulas, formatting, sheets, and
  workbook state across page visits.
- **Formula columns** — configure formulas such as `=C{row}*D{row}`. `{row}` is
  replaced by the spreadsheet row and `{index}` by the 1-based datasource index.
- **Import and export** — open and download native `.ic` workbook files.
- **Useful empty behavior** — choose a practical operations sample or a clean
  empty workbook when no datasource is configured.
- **Responsive and accessible UI** — light/dark/system themes, keyboard-visible
  focus, live status, reduced-motion support, and mobile action layout.
- **Batch performance** — WebAssembly initialization is cached, datasource cells
  are written while evaluation is paused, and the workbook is evaluated once.
- **Safe boundaries** — row count and dimensions are clamped, duplicate headers
  are made unique, typed write-back failures are counted, and read-only values
  are skipped.
- **Validated regional settings** — IronCalc locales are normalized to its
  supported `en`, `en-GB`, `fr`, `de`, `it`, or `es` values, while invalid time
  zones safely fall back to UTC.

## Baseline

- Gleam 1.17 or newer
- Glendix **5.2.0** from Hex
- Mendraw 2.x
- Lustre 5.7 and Redraw 19.2
- IronCalc workbook 0.8.3 with IronCalc WASM 0.8.4
- Mendix Pluggable Widgets Tools 11.12
- React 19.2
- Bun 1.4 for the checked-in build

Glendix 5.2.0 packages the IronCalc WebAssembly asset into both AMD and ES
widget outputs. No CDN or runtime network request is required after the widget
has been installed in a Mendix application.

## Build

```sh
bun install
gleam deps download
gleam run -m glendix/install --runtime bun
gleam format --check src test
gleam check
gleam build --warnings-as-errors
gleam test --runtime bun
bun test test/*.test.mjs
gleam run -m glendix/build --runtime bun
```

The production package is created below `dist/1.0.0/`.

## Mendix setup

1. Copy the generated `.mpk` into your Mendix project's `widgets/` directory.
2. Press **F4** in Studio Pro to synchronize the App Explorer.
3. Place **IronCalc SpreadUI** inside a data view when workbook persistence is
   needed.
4. Configure **Rows** with a list datasource.
5. Add **Columns** in the exact display order. Select a value attribute, optional
   formula template, write-back policy, and initial width.
6. Optionally bind **Workbook state** to an unlimited String attribute.
7. Optionally configure **After save** to validate, commit, refresh, or continue
   a workflow.

### Recommended domain model

A simple setup uses:

- `Workbook/State` — unlimited String for native `.ic` persistence
- `Workbook/Title` — optional page-level label
- a related list such as `WorkbookRow`
- typed row attributes selected in the widget's Columns configuration

The widget does not auto-commit Mendix objects. Use **After save** for the
microflow or nanoflow that matches your application's transaction policy.

## Data and save semantics

1. A valid persisted workbook state has highest priority.
2. Otherwise, available datasource rows and configured columns are loaded.
3. Otherwise, the configured practical sample or empty workbook is used.
4. Formula columns are evaluated but never written back to Mendix attributes.
5. Read-only, unavailable, unchanged, or unconfigured attributes are skipped.
6. Individual conversion failures do not discard successful cell updates; the
   status line reports updated, skipped, and failed counts.
7. The optional After save action runs after write-back and workbook-state
   persistence have completed.

When a persisted workbook is restored while Rows and Columns are configured,
the current datasource mapping remains active. This lets users continue editing
the restored workbook and explicitly write mapped non-formula cells back to
Mendix. Imported `.ic` files intentionally have no automatic row mapping.

## Project structure

```text
src/
├── MendixIronCalc.xml              Mendix properties
├── mendix_ironcalc_spreadui.gleam  Mendix entry point
├── spread_ui.gleam                 Gleam state machine and UI
├── spread_ui_ffi.mjs               Typed IronCalc/Mendix runtime boundary
├── editor_config.gleam             Studio Pro configuration
├── editor_preview.gleam            Lightweight design preview
├── package.xml                     MPK manifest
└── ui/MendixIronCalc.css           Responsive SpreadUI theme
```

## Licensing

This repository is licensed under the [MIT License](LICENSE).

IronCalc is a separate upstream project and its packages retain their own
MIT/Apache-2.0 licensing terms. Mendix and the Mendix Pluggable Widgets Tools
retain their respective terms and trademarks.
