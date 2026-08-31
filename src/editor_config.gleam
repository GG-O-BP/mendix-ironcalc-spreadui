//// Keeps all SpreadUI properties available in Mendix Studio Pro.

import glendix/editor_config
import mendraw/mendix

/// Returns the default Studio Pro property configuration unchanged.
pub fn get_properties(
  values _values: mendix.JsProps,
  default_properties default_properties: editor_config.Properties,
  platform _platform: String,
) -> editor_config.Properties {
  default_properties
}
