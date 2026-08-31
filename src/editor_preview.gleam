//// Renders a lightweight Studio Pro preview without starting WebAssembly.

import glendix/lustre as glendix_lustre
import lustre/attribute
import lustre/element/html
import mendraw/mendix
import redraw

/// Shows the configured title and the practical spreadsheet structure.
pub fn preview(props props: mendix.JsProps) -> redraw.Element {
  let title = mendix.get_string_prop(props, "title")
  html.section([attribute.class("spread-ui spread-ui--preview")], [
    html.header([attribute.class("spread-ui__header")], [
      html.div([attribute.class("spread-ui__brand")], [
        html.div([attribute.class("spread-ui__mark")], [html.text("S")]),
        html.div([], [
          html.h2([attribute.class("spread-ui__title")], [html.text(title)]),
          html.p([attribute.class("spread-ui__description")], [
            html.text("IronCalc spreadsheet connected to Mendix data"),
          ]),
        ]),
      ]),
    ]),
    html.div([attribute.class("spread-ui__preview-grid")], [
      html.div([], [html.text("Mendix data")]),
      html.div([], [html.text("Spreadsheet formulas")]),
      html.div([], [html.text("Explicit save")]),
    ]),
  ])
  |> glendix_lustre.render(fn(_message) { Nil })
}
