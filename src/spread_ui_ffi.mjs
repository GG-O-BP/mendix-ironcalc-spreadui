import "@ironcalc/workbook/style.css";

let initialization;
let ironCalcModule;

const DEFAULT_SAMPLE = [
  ["Work item", "Status", "Owner", "Hours", "Rate", "Cost"],
  ["Discovery", "Done", "Mina", "8", "120", "=D2*E2"],
  ["Implementation", "In progress", "Jun", "24", "120", "=D3*E3"],
  ["Validation", "Planned", "Sora", "10", "110", "=D4*E4"],
  ["Total", "", "", "=SUM(D2:D4)", "", "=SUM(F2:F4)"],
];

const IRONCALC_LOCALES = new Set(["de", "en", "en-GB", "es", "fr", "it"]);

function ensureInitialized() {
  initialization ??= import("@ironcalc/workbook").then(async module => {
    ironCalcModule = module;
    await module.init();
    return module;
  });
  return initialization;
}

function asArray(value) {
  if (Array.isArray(value)) return value;
  if (value && typeof value.toArray === "function") return value.toArray();
  return [];
}

function asString(value, fallback = "") {
  return typeof value === "string" && value.trim() !== ""
    ? value.trim()
    : fallback;
}

function asBoolean(value, fallback = false) {
  return typeof value === "boolean" ? value : fallback;
}

function asInteger(value, fallback, minimum, maximum) {
  const number = Number(value);
  if (!Number.isFinite(number)) return fallback;
  return Math.min(maximum, Math.max(minimum, Math.trunc(number)));
}

function normalizeLocale(value) {
  const requested = asString(value, "en").replace("_", "-");
  if (IRONCALC_LOCALES.has(requested)) return requested;
  const language = requested.split("-")[0].toLowerCase();
  return IRONCALC_LOCALES.has(language) ? language : "en";
}

function normalizeTimezone(value) {
  const requested = asString(value, "UTC");
  try {
    new Intl.DateTimeFormat("en", { timeZone: requested }).format();
    return requested;
  } catch {
    return "UTC";
  }
}

function expressionValue(value, fallback) {
  if (value && value.value !== undefined) return value.value;
  return value ?? fallback;
}

function uniqueHeaders(columns) {
  const occurrences = new Map();
  return columns.map((column, index) => {
    const base = asString(column?.header, `Column ${index + 1}`);
    const occurrence = (occurrences.get(base) ?? 0) + 1;
    occurrences.set(base, occurrence);
    return occurrence === 1 ? base : `${base} (${occurrence})`;
  });
}

function normalizeColumns(rawColumns) {
  const columns = asArray(rawColumns).map((column, index) => ({
    index,
    header: asString(column?.header, `Column ${index + 1}`),
    valueAttribute: column?.valueAttribute ?? null,
    formula: typeof column?.formula === "string" ? column.formula.trim() : "",
    writeBack: asBoolean(column?.writeBack, true),
    width: asInteger(column?.width, 140, 60, 600),
  }));
  const headers = uniqueHeaders(columns);
  return columns.map((column, index) => ({ ...column, header: headers[index] }));
}

export function read_config(props) {
  const systemDark =
    typeof window !== "undefined" &&
    typeof window.matchMedia === "function" &&
    window.matchMedia("(prefers-color-scheme: dark)").matches;
  const requestedTheme = ["light", "dark", "system"].includes(props?.theme)
    ? props.theme
    : "light";
  return {
    title: asString(props?.title, "Operations workbook"),
    description: asString(
      props?.description,
      "Edit, calculate, persist, and reuse Mendix data in one workspace.",
    ),
    height: asInteger(props?.height, 620, 320, 1600),
    theme: requestedTheme === "system" ? (systemDark ? "dark" : "light") : requestedTheme,
    readOnly: asBoolean(props?.readOnly, false),
    workbookName: asString(props?.workbookName, "Mendix Workbook"),
    sheetName: asString(props?.sheetName, "Mendix Data"),
    locale: normalizeLocale(props?.locale),
    timezone: normalizeTimezone(props?.timezone),
    emptyMode: props?.emptyMode === "empty" ? "empty" : "sample",
    maxRows: asInteger(props?.maxRows, 1000, 1, 10000),
    columns: normalizeColumns(props?.columns),
  };
}

export const config_title = config => config.title;
export const config_description = config => config.description;
export const config_height = config => config.height;
export const config_theme = config => config.theme;
export const config_read_only = config => config.readOnly;
export const config_workbook_name = config => config.workbookName;

const DARK_THEME_VARIABLES = {
  "--palette-common-black": "#f5f2ed",
  "--palette-common-white": "#1d1b18",
  "--palette-primary-main": "#fb923c",
  "--palette-primary-light": "#fdba74",
  "--palette-primary-dark": "#c2410c",
  "--palette-primary-contrast-text": "#141311",
  "--palette-grey-50": "#26231f",
  "--palette-grey-100": "#2d2924",
  "--palette-grey-200": "#37322c",
  "--palette-grey-300": "#494139",
  "--palette-grey-400": "#665c51",
  "--palette-grey-500": "#8c8073",
  "--palette-grey-600": "#afa397",
  "--palette-grey-700": "#c9c0b7",
  "--palette-grey-800": "#e0d9d2",
  "--palette-grey-900": "#f5f2ed",
  "--palette-surface-elevated": "#26231f",
  "--palette-surface-elevated-border": "#3b352e",
  "--palette-input-background": "#26231f",
  "--palette-input-border": "#3b352e",
  "--palette-sheet-header-corner-background": "#201e1a",
  "--palette-sheet-header-text-color": "#ded7ce",
  "--palette-sheet-header-background": "#201e1a",
  "--palette-sheet-header-selected-background": "#352f29",
  "--palette-sheet-header-full-selected-background": "#4a3322",
  "--palette-sheet-header-selected-color": "#fff7ed",
  "--palette-sheet-header-border-color": "#3b352e",
  "--palette-sheet-grid-color": "#3b352e",
  "--palette-sheet-grid-separator-color": "#4a433b",
  "--palette-sheet-default-text-color": "#f5f2ed",
  "--palette-sheet-outline-color": "#fb923c",
  "--palette-sheet-outline-editing-color": "#7c2d12",
  "--palette-sheet-outline-background-color": "#f9731626",
};

export function theme_variables(config) {
  if (config.theme === "dark") return DARK_THEME_VARIABLES;
  return {
    "--palette-primary-main": "#f97316",
    "--palette-primary-light": "#fb923c",
    "--palette-primary-dark": "#c2410c",
    "--palette-sheet-outline-color": "#f97316",
    "--palette-sheet-outline-editing-color": "#fed7aa",
    "--palette-sheet-outline-background-color": "#f973161f",
  };
}

function editableValue(attribute, item) {
  if (!attribute || typeof attribute.get !== "function") return null;
  try {
    return attribute.get(item) ?? null;
  } catch {
    return null;
  }
}

function readableValue(attribute, item) {
  const editable = editableValue(attribute, item);
  if (!editable || editable.status !== "available") return "";
  const value = editable.value;
  if (value === null || value === undefined) return "";
  if (value instanceof Date) return value.toISOString();
  if (typeof value === "boolean") return value ? "TRUE" : "FALSE";
  if (typeof value === "object" && typeof value.toString === "function") {
    return value.toString();
  }
  return String(value);
}

function formulaForRow(template, spreadsheetRow, dataIndex) {
  return template
    .replaceAll("{row}", String(spreadsheetRow))
    .replaceAll("{index}", String(dataIndex + 1));
}

function datasourceItems(props, maximumRows) {
  const datasource = props?.dataSource;
  if (!datasource || datasource.status !== "available") return [];
  return asArray(datasource.items).slice(0, maximumRows);
}

function writeTable(model, table, widths = []) {
  if (table.length === 0) return;
  model.pauseEvaluation();
  try {
    table.forEach((row, rowIndex) => {
      row.forEach((value, columnIndex) => {
        if (value !== "" && value !== null && value !== undefined) {
          model.setUserInput(0, rowIndex + 1, columnIndex + 1, String(value));
        }
      });
    });
    widths.forEach((width, columnIndex) => {
      model.setColumnsWidth(0, columnIndex + 1, columnIndex + 1, width);
    });
    model.setFrozenRowsCount(0, 1);
    model.setSelectedCell(table.length > 1 ? 2 : 1, 1);
  } finally {
    model.resumeEvaluation();
  }
  model.evaluate();
}

function createModel(config) {
  const language = config.locale.split(/[-_]/)[0] || "en";
  const model = new ironCalcModule.Model(
    config.workbookName,
    config.locale,
    config.timezone,
    language,
  );
  model.renameSheet(0, config.sheetName);
  return model;
}

function fromBase64(value) {
  const binary = atob(value);
  const bytes = new Uint8Array(binary.length);
  for (let index = 0; index < binary.length; index += 1) {
    bytes[index] = binary.charCodeAt(index);
  }
  return bytes;
}

function toBase64(bytes) {
  const chunkSize = 0x8000;
  let binary = "";
  for (let offset = 0; offset < bytes.length; offset += chunkSize) {
    binary += String.fromCharCode(...bytes.subarray(offset, offset + chunkSize));
  }
  return btoa(binary);
}

function workbookStateValue(props) {
  const state = props?.workbookState;
  return state?.status === "available" && typeof state.value === "string"
    ? state.value.trim()
    : "";
}

function restoreModel(serialized, config) {
  const language = config.locale.split(/[-_]/)[0] || "en";
  const factory = ironCalcModule.Model.from_bytes ?? ironCalcModule.Model.fromBytes;
  if (typeof factory !== "function") {
    throw new Error("This IronCalc build does not expose workbook deserialization.");
  }
  return factory.call(ironCalcModule.Model, fromBase64(serialized), language);
}

function mendixTable(props, config) {
  const items = datasourceItems(props, config.maxRows);
  if (items.length === 0 || config.columns.length === 0) {
    return { items, table: [], notice: "" };
  }
  const headers = config.columns.map(column => column.header);
  const rows = items.map((item, dataIndex) =>
    config.columns.map(column => {
      if (column.formula !== "") {
        return formulaForRow(column.formula, dataIndex + 2, dataIndex);
      }
      return readableValue(column.valueAttribute, item);
    }),
  );
  const sourceCount = asArray(props?.dataSource?.items).length;
  const notice = sourceCount > items.length
    ? `Loaded the first ${items.length} of ${sourceCount} available Mendix rows.`
    : "";
  return { items, table: [headers, ...rows], notice };
}

function loaded(model, source, rows, columns, notice, items = [], columnDefinitions = []) {
  return {
    model,
    source,
    rowCount: rows,
    columnCount: columns,
    notice,
    items,
    columns: columnDefinitions,
  };
}

export function load_workbook(props, config, onSuccess, onFailure) {
  ensureInitialized()
    .then(() => {
      const serialized = workbookStateValue(props);
      if (serialized !== "") {
        try {
          const model = restoreModel(serialized, config);
          const items = datasourceItems(props, config.maxRows);
          const columns = items.length > 0 ? config.columns : [];
          onSuccess(
            loaded(
              model,
              "saved",
              items.length,
              columns.length,
              "",
              items,
              columns,
            ),
          );
          return;
        } catch (error) {
          const reason = error instanceof Error ? error.message : String(error);
          const fallback = loadFromDatasourceOrDefault(props, config);
          fallback.notice = `Saved state was invalid; loaded a safe fallback instead. ${reason}`;
          onSuccess(fallback);
          return;
        }
      }
      onSuccess(loadFromDatasourceOrDefault(props, config));
    })
    .catch(error => onFailure(error instanceof Error ? error.message : String(error)));
}

function loadFromDatasourceOrDefault(props, config) {
  const { items, table, notice } = mendixTable(props, config);
  if (table.length > 0) {
    const model = createModel(config);
    writeTable(model, table, config.columns.map(column => column.width));
    return loaded(
      model,
      "mendix",
      items.length,
      config.columns.length,
      notice,
      items,
      config.columns,
    );
  }
  if (config.emptyMode === "empty") {
    return loaded(createModel(config), "empty", 0, 0, "");
  }
  const model = createModel(config);
  writeTable(model, DEFAULT_SAMPLE, [190, 120, 120, 90, 90, 110]);
  return loaded(model, "sample", DEFAULT_SAMPLE.length - 1, DEFAULT_SAMPLE[0].length, "");
}

function parseBoolean(value) {
  const normalized = value.trim().toLowerCase();
  if (["true", "yes", "1"].includes(normalized)) return true;
  if (["false", "no", "0"].includes(normalized)) return false;
  throw new Error(`Expected a boolean but received '${value}'.`);
}

function convertForEditable(raw, currentValue) {
  const value = raw.trim();
  if (value === "") return undefined;
  if (typeof currentValue === "boolean") return parseBoolean(value);
  if (currentValue instanceof Date) {
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) throw new Error(`Invalid date '${value}'.`);
    return date;
  }
  if (typeof currentValue === "number") {
    const number = Number(value);
    if (!Number.isFinite(number)) throw new Error(`Invalid number '${value}'.`);
    return number;
  }
  if (
    currentValue &&
    typeof currentValue === "object" &&
    typeof currentValue.constructor === "function"
  ) {
    try {
      return new currentValue.constructor(value);
    } catch {
      return value;
    }
  }
  return value;
}

function sameValue(left, right) {
  if (left === right) return true;
  if (left === null || left === undefined) return right === null || right === undefined;
  if (right === null || right === undefined) return false;
  if (left instanceof Date && right instanceof Date) return left.getTime() === right.getTime();
  return String(left) === String(right);
}

function saveState(props, workbook) {
  const state = props?.workbookState;
  if (
    !state ||
    state.status !== "available" ||
    state.readOnly ||
    typeof state.setValue !== "function"
  ) {
    return false;
  }
  state.setValue(toBase64(workbook.model.toBytes()));
  return true;
}

function writeBack(workbook, readOnly) {
  if (
    readOnly ||
    workbook.items.length === 0 ||
    workbook.columns.length === 0
  ) {
    return { updatedCount: 0, skippedCount: 0, failedCount: 0 };
  }
  let updatedCount = 0;
  let skippedCount = 0;
  let failedCount = 0;
  workbook.items.forEach((item, rowIndex) => {
    workbook.columns.forEach((column, columnIndex) => {
      if (!column.writeBack || column.formula !== "" || !column.valueAttribute) {
        skippedCount += 1;
        return;
      }
      const editable = editableValue(column.valueAttribute, item);
      if (
        !editable ||
        editable.status !== "available" ||
        editable.readOnly ||
        typeof editable.setValue !== "function"
      ) {
        skippedCount += 1;
        return;
      }
      try {
        const raw = workbook.model.getCellContent(0, rowIndex + 2, columnIndex + 1);
        const nextValue = convertForEditable(raw, editable.value);
        if (sameValue(editable.value, nextValue)) {
          skippedCount += 1;
          return;
        }
        editable.setValue(nextValue);
        updatedCount += 1;
      } catch {
        failedCount += 1;
      }
    });
  });
  return { updatedCount, skippedCount, failedCount };
}

function executeAfterSave(props) {
  const action = props?.onSave;
  if (action?.canExecute && typeof action.execute === "function") action.execute();
}

export function save_workbook(props, workbook, onSuccess, onFailure) {
  Promise.resolve().then(() => {
    try {
      const readOnly = Boolean(props?.readOnly);
      const writeResult = writeBack(workbook, readOnly);
      const stateSaved = readOnly ? false : saveState(props, workbook);
      executeAfterSave(props);
      onSuccess({ ...writeResult, stateSaved });
    } catch (error) {
      onFailure(error instanceof Error ? error.message : String(error));
    }
  });
}

function safeFilename(name) {
  const safe = asString(name, "Mendix Workbook")
    .replace(/[^a-zA-Z0-9._-]+/g, "-")
    .replace(/^-+|-+$/g, "");
  return `${safe || "mendix-workbook"}.ic`;
}

export function download_workbook(workbook, name, onSuccess, onFailure) {
  try {
    const blob = new Blob([workbook.model.toBytes()], {
      type: "application/vnd.ironcalc.workbook",
    });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = safeFilename(name);
    link.style.display = "none";
    document.body.appendChild(link);
    link.click();
    link.remove();
    queueMicrotask(() => URL.revokeObjectURL(url));
    onSuccess();
  } catch (error) {
    onFailure(error instanceof Error ? error.message : String(error));
  }
}

export function import_workbook(config, onSuccess, onFailure) {
  const input = document.createElement("input");
  input.type = "file";
  input.accept = ".ic,application/vnd.ironcalc.workbook";
  input.style.display = "none";
  let settled = false;
  const cleanup = () => input.remove();
  const succeed = workbook => {
    if (settled) return;
    settled = true;
    cleanup();
    onSuccess(workbook);
  };
  const fail = reason => {
    if (settled) return;
    settled = true;
    cleanup();
    onFailure(reason);
  };
  input.addEventListener(
    "cancel",
    () => fail("No workbook was selected."),
    { once: true },
  );
  input.addEventListener(
    "change",
    async () => {
      try {
        const file = input.files?.[0];
        if (!file) {
          fail("No workbook was selected.");
          return;
        }
        await ensureInitialized();
        const language = config.locale.split(/[-_]/)[0] || "en";
        const factory = ironCalcModule.Model.from_bytes ?? ironCalcModule.Model.fromBytes;
        if (typeof factory !== "function") {
          throw new Error(
            "This IronCalc build does not expose workbook deserialization.",
          );
        }
        const model = factory.call(
          ironCalcModule.Model,
          new Uint8Array(await file.arrayBuffer()),
          language,
        );
        succeed(loaded(model, "imported", 0, 0, ""));
      } catch (error) {
        fail(error instanceof Error ? error.message : String(error));
      }
    },
    { once: true },
  );
  try {
    document.body.appendChild(input);
    input.click();
  } catch (error) {
    fail(error instanceof Error ? error.message : String(error));
  }
}

export const loaded_model = workbook => workbook.model;
export const loaded_row_count = workbook => workbook.rowCount;
export const loaded_column_count = workbook => workbook.columnCount;
export const loaded_source = workbook => workbook.source;
export const loaded_boundary_notice = workbook => workbook.notice;
export const save_updated_count = summary => summary.updatedCount;
export const save_skipped_count = summary => summary.skippedCount;
export const save_failed_count = summary => summary.failedCount;
export const save_state_saved = summary => summary.stateSaved;

export const __test = {
  asInteger,
  convertForEditable,
  formulaForRow,
  mendixTable,
  normalizeLocale,
  normalizeColumns,
  normalizeTimezone,
  safeFilename,
  sameValue,
  uniqueHeaders,
  writeBack,
  writeTable,
};
