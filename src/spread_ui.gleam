//// Implements the practical SpreadUI state machine and IronCalc presentation.
////
//// IronCalc owns spreadsheet editing and calculation. This module owns the
//// observable Mendix experience: loading, explicit persistence, reload,
//// import/export, errors, and a responsive action shell.

import gleam/int
import gleam/result
import glendix/binding
import glendix/lustre as glendix_lustre
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import lustre/event
import mendraw/mendix
import redraw
import redraw/dom/attribute as redraw_attribute
import spread_ui/domain

/// An initialized IronCalc workbook plus its Mendix row mapping.
pub type LoadedWorkbook

/// Validated widget configuration read from Mendix properties.
pub type WidgetConfig

/// A persistence result returned by the typed JavaScript boundary.
pub type SaveSummary

/// Identifies how the current workbook was created.
pub type LoadSource =
  domain.LoadSource

/// Stores the complete SpreadUI lifecycle.
pub type Model {
  Loading(config: WidgetConfig, props: mendix.JsProps, message: String)
  Ready(
    config: WidgetConfig,
    props: mendix.JsProps,
    workbook: LoadedWorkbook,
    notice: String,
    busy: Bool,
  )
  Failed(config: WidgetConfig, props: mendix.JsProps, reason: String)
}

/// Describes user actions and asynchronous boundary completions.
pub type Message {
  WorkbookLoaded(Result(LoadedWorkbook, String))
  Reload
  Save
  WorkbookSaved(Result(SaveSummary, String))
  Download
  WorkbookDownloaded(Result(Nil, String))
  Import
  WorkbookImported(Result(LoadedWorkbook, String))
}

/// Creates the initial model and starts cached WebAssembly initialization.
pub fn init(props props: mendix.JsProps) -> #(Model, effect.Effect(Message)) {
  let config = read_config(props)
  #(
    Loading(
      config: config,
      props: props,
      message: "Preparing IronCalc and Mendix data…",
    ),
    load_effect(props, config),
  )
}

/// Applies ordered state transitions and isolates every runtime effect.
pub fn update(
  model model: Model,
  message message: Message,
) -> #(Model, effect.Effect(Message)) {
  case message {
    WorkbookLoaded(Ok(workbook)) -> {
      let #(config, props) = context(model)
      #(ready(config, props, workbook, loaded_notice(workbook)), effect.none())
    }
    WorkbookLoaded(Error(reason)) -> {
      let #(config, props) = context(model)
      #(Failed(config: config, props: props, reason: reason), effect.none())
    }
    Reload -> {
      let #(config, props) = context(model)
      #(
        Loading(
          config: config,
          props: props,
          message: "Reloading the latest Mendix data…",
        ),
        load_effect(props, config),
      )
    }
    Save ->
      case model {
        Ready(config, props, workbook, notice, False) -> #(
          Ready(
            config: config,
            props: props,
            workbook: workbook,
            notice: notice,
            busy: True,
          ),
          save_effect(props, workbook),
        )
        Ready(_, _, _, _, True) -> #(model, effect.none())
        Loading(_, _, _) -> #(model, effect.none())
        Failed(_, _, _) -> #(model, effect.none())
      }
    WorkbookSaved(Ok(summary)) ->
      case model {
        Ready(config, props, workbook, _, _) -> #(
          ready(config, props, workbook, save_notice(summary)),
          effect.none(),
        )
        Loading(_, _, _) -> #(model, effect.none())
        Failed(_, _, _) -> #(model, effect.none())
      }
    WorkbookSaved(Error(reason)) ->
      case model {
        Ready(config, props, workbook, _, _) -> #(
          ready(config, props, workbook, "Save failed: " <> reason),
          effect.none(),
        )
        Loading(_, _, _) -> #(model, effect.none())
        Failed(_, _, _) -> #(model, effect.none())
      }
    Download ->
      case model {
        Ready(config, props, workbook, notice, False) -> #(
          Ready(
            config: config,
            props: props,
            workbook: workbook,
            notice: notice,
            busy: True,
          ),
          download_effect(workbook, config),
        )
        Ready(_, _, _, _, True) -> #(model, effect.none())
        Loading(_, _, _) -> #(model, effect.none())
        Failed(_, _, _) -> #(model, effect.none())
      }
    WorkbookDownloaded(Ok(Nil)) ->
      case model {
        Ready(config, props, workbook, _, _) -> #(
          ready(config, props, workbook, "Workbook downloaded as an .ic file."),
          effect.none(),
        )
        Loading(_, _, _) -> #(model, effect.none())
        Failed(_, _, _) -> #(model, effect.none())
      }
    WorkbookDownloaded(Error(reason)) ->
      case model {
        Ready(config, props, workbook, _, _) -> #(
          ready(config, props, workbook, "Download failed: " <> reason),
          effect.none(),
        )
        Loading(_, _, _) -> #(model, effect.none())
        Failed(_, _, _) -> #(model, effect.none())
      }
    Import -> {
      let #(config, props) = context(model)
      #(
        Loading(
          config: config,
          props: props,
          message: "Choose an IronCalc .ic workbook to import…",
        ),
        import_effect(config),
      )
    }
    WorkbookImported(Ok(workbook)) -> {
      let #(config, props) = context(model)
      #(
        ready(
          config,
          props,
          workbook,
          "Imported workbook ready. Press Save to persist it to Mendix.",
        ),
        effect.none(),
      )
    }
    WorkbookImported(Error(reason)) -> {
      let #(config, props) = context(model)
      #(Failed(config: config, props: props, reason: reason), effect.none())
    }
  }
}

/// Renders the complete responsive SpreadUI shell.
pub fn view(model: Model) -> element.Element(Message) {
  let config = model_config(model)
  html.section(
    [
      attribute.class("spread-ui spread-ui--" <> config_theme(config)),
      attribute.aria_label("IronCalc spreadsheet workspace"),
    ],
    [
      header_view(config, model),
      status_view(model),
      content_view(model),
    ],
  )
}

/// Converts a runtime source discriminator into the public domain type.
pub fn source_from_string(source source: String) -> LoadSource {
  domain.source_from_string(source)
}

/// Creates a stable, user-facing row/column summary.
pub fn dataset_summary(
  row_count row_count: Int,
  column_count column_count: Int,
) -> String {
  domain.dataset_summary(row_count, column_count)
}

/// Creates the save result shown after an explicit persistence operation.
pub fn save_summary_text(
  updated_count updated_count: Int,
  skipped_count skipped_count: Int,
  failed_count failed_count: Int,
  state_saved state_saved: Bool,
) -> String {
  domain.save_summary_text(
    updated_count,
    skipped_count,
    failed_count,
    state_saved,
  )
}

fn ready(
  config: WidgetConfig,
  props: mendix.JsProps,
  workbook: LoadedWorkbook,
  notice: String,
) -> Model {
  Ready(
    config: config,
    props: props,
    workbook: workbook,
    notice: notice,
    busy: False,
  )
}

fn context(model: Model) -> #(WidgetConfig, mendix.JsProps) {
  case model {
    Loading(config, props, _) -> #(config, props)
    Ready(config, props, _, _, _) -> #(config, props)
    Failed(config, props, _) -> #(config, props)
  }
}

fn model_config(model: Model) -> WidgetConfig {
  let #(config, _) = context(model)
  config
}

fn header_view(config: WidgetConfig, model: Model) -> element.Element(Message) {
  let is_busy = case model {
    Loading(_, _, _) -> True
    Ready(_, _, _, _, busy) -> busy
    Failed(_, _, _) -> False
  }
  let can_save = case model {
    Ready(_, _, _, _, False) -> !config_read_only(config)
    Loading(_, _, _) -> False
    Ready(_, _, _, _, True) -> False
    Failed(_, _, _) -> False
  }
  let can_use_workbook = case model {
    Ready(_, _, _, _, False) -> True
    Loading(_, _, _) -> False
    Ready(_, _, _, _, True) -> False
    Failed(_, _, _) -> False
  }

  html.header([attribute.class("spread-ui__header")], [
    html.div([attribute.class("spread-ui__brand")], [
      html.div(
        [attribute.class("spread-ui__mark"), attribute.aria_hidden(True)],
        [
          html.text("S"),
        ],
      ),
      html.div([], [
        html.h2([attribute.class("spread-ui__title")], [
          html.text(config_title(config)),
        ]),
        html.p([attribute.class("spread-ui__description")], [
          html.text(config_description(config)),
        ]),
      ]),
    ]),
    html.div([attribute.class("spread-ui__actions")], [
      action_button("Reload data", Reload, is_busy, "secondary"),
      action_button("Import .ic", Import, is_busy, "secondary"),
      action_button("Download", Download, !can_use_workbook, "secondary"),
      action_button("Save to Mendix", Save, !can_save, "primary"),
    ]),
  ])
}

fn action_button(
  label: String,
  message: Message,
  disabled: Bool,
  variant: String,
) -> element.Element(Message) {
  html.button(
    [
      attribute.class("spread-ui__button spread-ui__button--" <> variant),
      attribute.type_("button"),
      attribute.disabled(disabled),
      event.on_click(message),
    ],
    [html.text(label)],
  )
}

fn status_view(model: Model) -> element.Element(Message) {
  case model {
    Loading(_, _, message) ->
      html.div(
        [
          attribute.class("spread-ui__status spread-ui__status--loading"),
          attribute.role("status"),
          attribute.aria_live("polite"),
        ],
        [
          html.span([attribute.class("spread-ui__spinner")], []),
          html.text(message),
        ],
      )
    Ready(config, _, workbook, notice, busy) -> {
      let source = source_from_string(loaded_source(workbook))
      html.div(
        [
          attribute.class("spread-ui__meta"),
          attribute.role("status"),
          attribute.aria_live("polite"),
        ],
        [
          html.div([attribute.class("spread-ui__badges")], [
            badge(source_label(source), "source"),
            badge(
              dataset_summary(
                loaded_row_count(workbook),
                loaded_column_count(workbook),
              ),
              "neutral",
            ),
            badge(
              case config_read_only(config) {
                True -> "Read only"
                False -> "Editable"
              },
              case config_read_only(config) {
                True -> "neutral"
                False -> "success"
              },
            ),
            ..case busy {
              True -> [badge("Working…", "progress")]
              False -> []
            }
          ]),
          html.p([attribute.class("spread-ui__notice")], [html.text(notice)]),
        ],
      )
    }
    Failed(_, _, reason) ->
      html.div(
        [
          attribute.class("spread-ui__status spread-ui__status--error"),
          attribute.role("alert"),
        ],
        [html.text("SpreadUI could not start: " <> reason)],
      )
  }
}

fn badge(label: String, variant: String) -> element.Element(message) {
  html.span(
    [attribute.class("spread-ui__badge spread-ui__badge--" <> variant)],
    [html.text(label)],
  )
}

fn content_view(model: Model) -> element.Element(Message) {
  case model {
    Loading(_, _, _) -> loading_view()
    Ready(config, _, workbook, _, _) -> workbook_view(config, workbook)
    Failed(_, _, _) ->
      html.div([attribute.class("spread-ui__empty")], [
        html.h3([], [html.text("The workbook is unavailable")]),
        html.p([], [
          html.text(
            "Check the widget properties or datasource, then use Reload data.",
          ),
        ]),
        action_button("Try again", Reload, False, "primary"),
      ])
  }
}

fn loading_view() -> element.Element(message) {
  html.div([attribute.class("spread-ui__loading")], [
    html.div(
      [attribute.class("spread-ui__skeleton spread-ui__skeleton--toolbar")],
      [],
    ),
    html.div(
      [attribute.class("spread-ui__skeleton spread-ui__skeleton--grid")],
      [],
    ),
  ])
}

fn workbook_view(
  config: WidgetConfig,
  workbook: LoadedWorkbook,
) -> element.Element(Message) {
  case ironcalc_element(config, workbook) {
    Ok(component) ->
      html.div(
        [
          attribute.class("spread-ui__workbook"),
          attribute.style(
            "height",
            int.to_string(config_height(config)) <> "px",
          ),
        ],
        [glendix_lustre.embed(component)],
      )
    Error(reason) ->
      html.div([attribute.class("spread-ui__empty")], [
        html.h3([], [html.text("IronCalc binding is unavailable")]),
        html.p([], [html.text(reason)]),
      ])
  }
}

fn ironcalc_element(
  config: WidgetConfig,
  workbook: LoadedWorkbook,
) -> Result(redraw.Element, String) {
  use module <- result.try(
    binding.module("@ironcalc/workbook")
    |> result.map_error(binding_error_text),
  )
  use component <- result.try(
    binding.resolve(module, "IronCalc")
    |> result.map_error(binding_error_text),
  )
  binding.void_element(component, [
    redraw_attribute.attribute("model", loaded_model(workbook)),
    redraw_attribute.attribute("canEdit", !config_read_only(config)),
    redraw_attribute.attribute("themeVariables", theme_variables(config)),
  ])
  |> Ok
}

fn binding_error_text(error: binding.BindingError) -> String {
  case error {
    binding.ModuleWasNotFound(name, reason) -> name <> ": " <> reason
    binding.ExportWasNotFound(name, reason) -> name <> ": " <> reason
  }
}

fn source_label(source: LoadSource) -> String {
  case source {
    domain.SavedWorkbook -> "Saved workbook"
    domain.MendixData -> "Mendix datasource"
    domain.PracticalSample -> "Practical sample"
    domain.EmptyWorkbook -> "Empty workbook"
    domain.ImportedFile -> "Imported .ic file"
    domain.UnknownSource -> "Workbook"
  }
}

fn loaded_notice(workbook: LoadedWorkbook) -> String {
  let notice = loaded_boundary_notice(workbook)
  case notice {
    "" ->
      case source_from_string(loaded_source(workbook)) {
        domain.SavedWorkbook -> "Restored the persisted workbook state."
        domain.MendixData -> "Loaded Mendix rows in one evaluation batch."
        domain.PracticalSample ->
          "Loaded a practical operations sample. Configure Rows and Columns to use Mendix data."
        domain.EmptyWorkbook -> "Started an empty workbook."
        domain.ImportedFile -> "Imported workbook ready."
        domain.UnknownSource -> "Workbook ready."
      }
    value -> value
  }
}

fn save_notice(summary: SaveSummary) -> String {
  save_summary_text(
    save_updated_count(summary),
    save_skipped_count(summary),
    save_failed_count(summary),
    save_state_saved(summary),
  )
}

fn load_effect(
  props: mendix.JsProps,
  config: WidgetConfig,
) -> effect.Effect(Message) {
  effect.from(fn(dispatch) {
    load_workbook(
      props,
      config,
      fn(workbook) { dispatch(WorkbookLoaded(Ok(workbook))) },
      fn(reason) { dispatch(WorkbookLoaded(Error(reason))) },
    )
  })
}

fn save_effect(
  props: mendix.JsProps,
  workbook: LoadedWorkbook,
) -> effect.Effect(Message) {
  effect.from(fn(dispatch) {
    save_workbook(
      props,
      workbook,
      fn(summary) { dispatch(WorkbookSaved(Ok(summary))) },
      fn(reason) { dispatch(WorkbookSaved(Error(reason))) },
    )
  })
}

fn download_effect(
  workbook: LoadedWorkbook,
  config: WidgetConfig,
) -> effect.Effect(Message) {
  effect.from(fn(dispatch) {
    download_workbook(
      workbook,
      config_workbook_name(config),
      fn() { dispatch(WorkbookDownloaded(Ok(Nil))) },
      fn(reason) { dispatch(WorkbookDownloaded(Error(reason))) },
    )
  })
}

fn import_effect(config: WidgetConfig) -> effect.Effect(Message) {
  effect.from(fn(dispatch) {
    import_workbook(
      config,
      fn(workbook) { dispatch(WorkbookImported(Ok(workbook))) },
      fn(reason) { dispatch(WorkbookImported(Error(reason))) },
    )
  })
}

// -- FFI --
@external(javascript, "./spread_ui_ffi.mjs", "read_config")
fn read_config(props: mendix.JsProps) -> WidgetConfig

@external(javascript, "./spread_ui_ffi.mjs", "config_title")
fn config_title(config: WidgetConfig) -> String

@external(javascript, "./spread_ui_ffi.mjs", "config_description")
fn config_description(config: WidgetConfig) -> String

@external(javascript, "./spread_ui_ffi.mjs", "config_height")
fn config_height(config: WidgetConfig) -> Int

@external(javascript, "./spread_ui_ffi.mjs", "config_theme")
fn config_theme(config: WidgetConfig) -> String

@external(javascript, "./spread_ui_ffi.mjs", "config_read_only")
fn config_read_only(config: WidgetConfig) -> Bool

@external(javascript, "./spread_ui_ffi.mjs", "config_workbook_name")
fn config_workbook_name(config: WidgetConfig) -> String

@external(javascript, "./spread_ui_ffi.mjs", "theme_variables")
fn theme_variables(config: WidgetConfig) -> a

@external(javascript, "./spread_ui_ffi.mjs", "load_workbook")
fn load_workbook(
  props: mendix.JsProps,
  config: WidgetConfig,
  on_success: fn(LoadedWorkbook) -> Nil,
  on_failure: fn(String) -> Nil,
) -> Nil

@external(javascript, "./spread_ui_ffi.mjs", "save_workbook")
fn save_workbook(
  props: mendix.JsProps,
  workbook: LoadedWorkbook,
  on_success: fn(SaveSummary) -> Nil,
  on_failure: fn(String) -> Nil,
) -> Nil

@external(javascript, "./spread_ui_ffi.mjs", "download_workbook")
fn download_workbook(
  workbook: LoadedWorkbook,
  name: String,
  on_success: fn() -> Nil,
  on_failure: fn(String) -> Nil,
) -> Nil

@external(javascript, "./spread_ui_ffi.mjs", "import_workbook")
fn import_workbook(
  config: WidgetConfig,
  on_success: fn(LoadedWorkbook) -> Nil,
  on_failure: fn(String) -> Nil,
) -> Nil

@external(javascript, "./spread_ui_ffi.mjs", "loaded_model")
fn loaded_model(workbook: LoadedWorkbook) -> a

@external(javascript, "./spread_ui_ffi.mjs", "loaded_row_count")
fn loaded_row_count(workbook: LoadedWorkbook) -> Int

@external(javascript, "./spread_ui_ffi.mjs", "loaded_column_count")
fn loaded_column_count(workbook: LoadedWorkbook) -> Int

@external(javascript, "./spread_ui_ffi.mjs", "loaded_source")
fn loaded_source(workbook: LoadedWorkbook) -> String

@external(javascript, "./spread_ui_ffi.mjs", "loaded_boundary_notice")
fn loaded_boundary_notice(workbook: LoadedWorkbook) -> String

@external(javascript, "./spread_ui_ffi.mjs", "save_updated_count")
fn save_updated_count(summary: SaveSummary) -> Int

@external(javascript, "./spread_ui_ffi.mjs", "save_skipped_count")
fn save_skipped_count(summary: SaveSummary) -> Int

@external(javascript, "./spread_ui_ffi.mjs", "save_failed_count")
fn save_failed_count(summary: SaveSummary) -> Int

@external(javascript, "./spread_ui_ffi.mjs", "save_state_saved")
fn save_state_saved(summary: SaveSummary) -> Bool
