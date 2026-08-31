import { describe, expect, test } from "bun:test";
import { __test, read_config } from "../src/spread_ui_ffi.mjs";

describe("SpreadUI runtime boundary", () => {
  test("configuration defaults and clamps boundary values", () => {
    const config = read_config({
      title: "",
      height: 99999,
      maxRows: 0,
      theme: "unknown",
      columns: [{ header: "", width: 10 }],
    });

    expect(config.title).toBe("Operations workbook");
    expect(config.height).toBe(1600);
    expect(config.maxRows).toBe(1);
    expect(config.theme).toBe("light");
    expect(config.columns[0].header).toBe("Column 1");
    expect(config.columns[0].width).toBe(60);
  });

  test("column headers preserve order and de-duplicate deterministically", () => {
    const columns = __test.normalizeColumns([
      { header: "Amount" },
      { header: "Amount" },
      { header: "" },
      { header: "Amount" },
    ]);

    expect(columns.map(column => column.header)).toEqual([
      "Amount",
      "Amount (2)",
      "Column 3",
      "Amount (3)",
    ]);
  });

  test("formula templates expand spreadsheet row and source index", () => {
    expect(__test.formulaForRow("=C{row}*D{row}+{index}", 8, 6)).toBe(
      "=C8*D8+7",
    );
  });

  test("editable conversion handles booleans, dates, numbers, and empty cells", () => {
    expect(__test.convertForEditable(" yes ", false)).toBe(true);
    expect(__test.convertForEditable("12.5", 0)).toBe(12.5);
    expect(__test.convertForEditable("", "value")).toBeUndefined();
    expect(__test.convertForEditable("2026-08-31", new Date("2020-01-01")))
      .toEqual(new Date("2026-08-31"));
  });

  test("invalid typed edits fail instead of corrupting Mendix values", () => {
    expect(() => __test.convertForEditable("maybe", false)).toThrow();
    expect(() => __test.convertForEditable("not-a-number", 1)).toThrow();
    expect(() => __test.convertForEditable("not-a-date", new Date())).toThrow();
  });

  test("Mendix rows preserve item and column order with formulas", () => {
    const items = [
      { id: "row-1", name: "Alpha", quantity: 2 },
      { id: "row-2", name: "Beta", quantity: 3 },
    ];
    const config = {
      maxRows: 1000,
      columns: [
        { header: "Name", valueAttribute: { get: item => ({ status: "available", value: item.name }) }, formula: "" },
        { header: "Qty", valueAttribute: { get: item => ({ status: "available", value: item.quantity }) }, formula: "" },
        { header: "Double", valueAttribute: null, formula: "=B{row}*2" },
      ],
    };
    const result = __test.mendixTable(
      { dataSource: { status: "available", items } },
      config,
    );

    expect(result.items).toEqual(items);
    expect(result.table).toEqual([
      ["Name", "Qty", "Double"],
      ["Alpha", "2", "=B2*2"],
      ["Beta", "3", "=B3*2"],
    ]);
  });

  test("bulk loading uses one-based IronCalc coordinates and evaluates once", () => {
    const calls = [];
    const model = {
      pauseEvaluation: () => calls.push(["pause"]),
      resumeEvaluation: () => calls.push(["resume"]),
      evaluate: () => calls.push(["evaluate"]),
      setUserInput: (...args) => calls.push(["input", ...args]),
      setColumnsWidth: (...args) => calls.push(["width", ...args]),
      setFrozenRowsCount: (...args) => calls.push(["freeze", ...args]),
      setSelectedCell: (...args) => calls.push(["select", ...args]),
    };

    __test.writeTable(model, [["Name", "Qty"], ["Alpha", "2"]], [120, 80]);

    expect(calls.filter(call => call[0] === "evaluate")).toHaveLength(1);
    expect(calls).toContainEqual(["input", 0, 1, 1, "Name"]);
    expect(calls).toContainEqual(["input", 0, 2, 2, "2"]);
    expect(calls).toContainEqual(["width", 0, 1, 1, 120]);
    expect(calls).toContainEqual(["select", 2, 1]);
    expect(calls.indexOf(calls.find(call => call[0] === "pause")))
      .toBeLessThan(calls.indexOf(calls.find(call => call[0] === "resume")));
  });

  test("write-back updates only editable changed non-formula cells", () => {
    const changed = [];
    const item = { id: "row-1" };
    const editableColumn = {
      writeBack: true,
      formula: "",
      valueAttribute: {
        get: () => ({
          status: "available",
          value: "before",
          readOnly: false,
          setValue: value => changed.push(value),
        }),
      },
    };
    const formulaColumn = {
      writeBack: true,
      formula: "=A{row}",
      valueAttribute: editableColumn.valueAttribute,
    };
    const result = __test.writeBack(
      {
        source: "mendix",
        items: [item],
        columns: [editableColumn, formulaColumn],
        model: { getCellContent: (_sheet, _row, column) => column === 1 ? "after" : "ignored" },
      },
      false,
    );

    expect(changed).toEqual(["after"]);
    expect(result).toEqual({ updatedCount: 1, skippedCount: 1, failedCount: 0 });
  });

  test("download filenames are safe and always use the IronCalc extension", () => {
    expect(__test.safeFilename("Quarter / Sales 2026")).toBe(
      "Quarter-Sales-2026.ic",
    );
    expect(__test.safeFilename("***")).toBe("mendix-workbook.ic");
  });

  test("date and scalar equality avoids unnecessary Mendix writes", () => {
    expect(__test.sameValue(new Date("2026-08-31"), new Date("2026-08-31")))
      .toBe(true);
    expect(__test.sameValue("42", 42)).toBe(true);
    expect(__test.sameValue("42", 43)).toBe(false);
  });
});
