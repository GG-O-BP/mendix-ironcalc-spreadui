//// Connects the Mendix runtime to the IronCalc SpreadUI component.

import glendix/lustre as glendix_lustre
import mendraw/mendix
import redraw
import spread_ui

/// Renders the IronCalc SpreadUI as a Mendix functional component.
pub fn widget(props props: mendix.JsProps) -> redraw.Element {
  keyed_host(props, props_revision(props), tea_application)
}

fn tea_application(props: mendix.JsProps) -> redraw.Element {
  glendix_lustre.use_tea(
    spread_ui.init(props),
    spread_ui.update,
    spread_ui.view,
  )
}

@external(javascript, "./spread_ui_ffi.mjs", "props_revision")
fn props_revision(props: mendix.JsProps) -> String

@external(javascript, "./spread_ui_ffi.mjs", "keyed_host")
fn keyed_host(
  props: mendix.JsProps,
  revision: String,
  render: fn(mendix.JsProps) -> redraw.Element,
) -> redraw.Element
