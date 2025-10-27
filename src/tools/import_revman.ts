import { readFileSync } from "fs";
import { parse } from "csv-parse/sync";
import { CochraneDatasetSchema } from "../schemas/cochrane.js";
import { logger } from "../utils/logger.js";

interface ImportRevManArgs {
  file_path: string;
  format: "csv" | "xlsx" | "json";
}

/**
 * Import and parse data from CSV, Excel (XLSX), or JSON formats
 */
export async function importRevManTool(args: unknown) {
  const { file_path, format } = args as ImportRevManArgs;

  logger.info(`Importing data from ${file_path} (format: ${format})`);

  try {
    let data;

    if (format === "csv") {
      data = await parseCochraneCSV(file_path);
    } else if (format === "xlsx") {
      data = await parseExcelFile(file_path);
    } else if (format === "json") {
      data = await parseJSONFile(file_path);
    } else {
      throw new Error(`Unsupported format: ${format}`);
    }

    // Validate parsed data
    const validatedData = CochraneDatasetSchema.parse(data);

    return {
      content: [
        {
          type: "text",
          text: JSON.stringify(
            {
              success: true,
              message: `Successfully imported ${validatedData.studies.length} studies`,
              data: validatedData,
              summary: {
                n_studies: validatedData.studies.length,
                outcome_type: validatedData.outcome_type,
                outcome_name: validatedData.outcome_name,
                intervention: validatedData.intervention,
                comparison: validatedData.comparison,
              },
            },
            null,
            2
          ),
        },
      ],
    };
  } catch (error) {
    logger.error("Error importing RevMan data:", error);
    throw error;
  }
}

/**
 * Parse Excel (XLSX) file
 */
async function parseExcelFile(filePath: string) {
  // Dynamic import to avoid bundling xlsx if not needed
  const XLSX = await import("xlsx");

  const workbook = XLSX.readFile(filePath);
  const sheetName = workbook.SheetNames[0];

  if (!sheetName) {
    throw new Error("Excel file has no worksheets");
  }

  const sheet = workbook.Sheets[sheetName];
  const records = XLSX.utils.sheet_to_json(sheet);

  if (records.length === 0) {
    throw new Error("Excel file has no data");
  }

  // Convert to same format as CSV parser expects
  return parseRecords(records);
}

/**
 * Parse JSON file
 */
async function parseJSONFile(filePath: string) {
  const jsonContent = readFileSync(filePath, "utf-8");
  const data = JSON.parse(jsonContent);

  // If JSON is already in the correct structure, validate and return
  if (data.studies && data.outcomes && data.outcome_type) {
    return {
      studies: data.studies,
      outcomes: data.outcomes,
      outcome_type: data.outcome_type,
      outcome_name: data.outcome_name || "Primary outcome",
      intervention: data.intervention || "Intervention",
      comparison: data.comparison || "Control",
    };
  }

  // Otherwise, assume it's an array of records like CSV
  if (Array.isArray(data)) {
    return parseRecords(data);
  }

  throw new Error("Invalid JSON structure. Expected either a structured Cochrane dataset or an array of records.");
}

/**
 * Parse Cochrane CSV export
 */
async function parseCochraneCSV(filePath: string) {
  const csvContent = readFileSync(filePath, "utf-8");
  const records = parse(csvContent, {
    columns: true,
    skip_empty_lines: true,
    trim: true,
  });

  return parseRecords(records);
}

/**
 * Parse records from CSV, Excel, or JSON array format
 */
function parseRecords(records: any[]) {
  if (!records || records.length === 0) {
    throw new Error("No data records found");
  }

  // Detect outcome type from column headers
  const firstRecord = records[0];
  const isBinary =
    "events_treatment" in firstRecord && "events_control" in firstRecord;
  const isContinuous =
    "mean_treatment" in firstRecord && "mean_control" in firstRecord;

  if (!isBinary && !isContinuous) {
    throw new Error(
      "Cannot determine outcome type from data. Expected binary (events) or continuous (mean/SD) data."
    );
  }

  const outcome_type = isBinary ? "binary" : "continuous";

  // Extract unique studies
  const studyMap = new Map();
  records.forEach((record: any) => {
    if (!studyMap.has(record.study_id)) {
      studyMap.set(record.study_id, {
        id: record.study_id,
        authors: record.authors || "Unknown",
        year: parseInt(record.year) || 2000,
        title: record.title || "Unknown",
        journal: record.journal,
        doi: record.doi,
      });
    }
  });

  const studies = Array.from(studyMap.values());

  // Extract outcomes
  const outcomes = records.map((record: any) => {
    if (outcome_type === "binary") {
      return {
        study_id: record.study_id,
        events_treatment: parseInt(record.events_treatment),
        n_treatment: parseInt(record.n_treatment),
        events_control: parseInt(record.events_control),
        n_control: parseInt(record.n_control),
      };
    } else {
      return {
        study_id: record.study_id,
        mean_treatment: parseFloat(record.mean_treatment),
        sd_treatment: parseFloat(record.sd_treatment),
        n_treatment: parseInt(record.n_treatment),
        mean_control: parseFloat(record.mean_control),
        sd_control: parseFloat(record.sd_control),
        n_control: parseInt(record.n_control),
      };
    }
  });

  return {
    studies,
    outcomes,
    outcome_type,
    outcome_name: records[0].outcome || "Primary outcome",
    intervention: records[0].intervention || "Intervention",
    comparison: records[0].comparison || "Control",
  };
}
