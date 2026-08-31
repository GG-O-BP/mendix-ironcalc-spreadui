//// Connects the Mendix runtime to the IronCalc SpreadUI component.

import glendix/lustre as glendix_lustre
import mendraw/mendix
import redraw
import spread_ui

/// Renders the IronCalc SpreadUI as a Mendix functional component.
pub fn widget(props props: mendix.JsProps) -> redraw.Element {
  glendix_lustre.use_tea(
    spread_ui.init(props),
    spread_ui.update,
    spread_ui.view,
  )
}
