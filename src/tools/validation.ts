import {
  CochraneDataset,
  CochraneDatasetSchema,
  ValidationResult,
  BinaryOutcome,
  ContinuousOutcome,
} from "../schemas/cochrane.js";
import { logger } from "../utils/logger.js";

interface ValidateDataArgs {
  data: unknown;
  validation_level?: "basic" | "comprehensive";
}

/**
 * Validate study data against Cochrane standards
 */
export async function validateDataTool(args: unknown) {
  const { data, validation_level = "comprehensive" } =
    args as ValidateDataArgs;

  logger.info(`Validating data (level: ${validation_level})`);

  try {
    // Parse and validate schema
    const dataset = CochraneDatasetSchema.parse(data);

    const result: ValidationResult = {
      valid: true,
      warnings: [],
      errors: [],
      suggestions: [],
    };

    // Basic validation
    validateBasicRequirements(dataset, result);

    if (validation_level === "comprehensive") {
      validateStudyQuality(dataset, result);
      validateStatisticalRequirements(dataset, result);
      validateCochraneStandards(dataset, result);
    }

    // Set overall validity
    result.valid = result.errors.length === 0;

    return {
      content: [
        {
          type: "text",
          text: JSON.stringify(
            {
              validation_result: result,
              summary: {
                valid: result.valid,
                n_errors: result.errors.length,
                n_warnings: result.warnings.length,
                n_suggestions: result.suggestions.length,
              },
            },
            null,
            2
          ),
        },
      ],
    };
  } catch (error) {
    logger.error("Validation error:", error);
    throw error;
  }
}

/**
 * Validate basic data requirements
 */
function validateBasicRequirements(
  dataset: CochraneDataset,
  result: ValidationResult
) {
  // Check minimum number of studies
  if (dataset.studies.length < 2) {
    result.errors.push(
      "Meta-analysis requires at least 2 studies. Current: " +
        dataset.studies.length
    );
  }

  // Check that all studies have corresponding outcome data
  const studyIds = new Set(dataset.studies.map((s) => s.id));
  const outcomeStudyIds = new Set(
    dataset.outcomes.map((o: any) => o.study_id)
  );

  studyIds.forEach((id) => {
    if (!outcomeStudyIds.has(id)) {
      result.errors.push(`Study ${id} is missing outcome data`);
    }
  });

  // Check for duplicate studies
  const duplicates = findDuplicates(dataset.studies.map((s) => s.id));
  if (duplicates.length > 0) {
    result.errors.push(`Duplicate study IDs found: ${duplicates.join(", ")}`);
  }
}

/**
 * Validate study quality indicators
 */
function validateStudyQuality(
  dataset: CochraneDataset,
  result: ValidationResult
) {
  // Check sample sizes
  dataset.outcomes.forEach((outcome: any) => {
    const study = dataset.studies.find((s) => s.id === outcome.study_id);
    const studyLabel = study ? `${study.authors} (${study.year})` : outcome.study_id;

    if (outcome.n_treatment < 10) {
      result.warnings.push(
        `${studyLabel}: Small treatment group (n=${outcome.n_treatment}). Consider sensitivity analysis.`
      );
    }

    if (outcome.n_control < 10) {
      result.warnings.push(
        `${studyLabel}: Small control group (n=${outcome.n_control}). Consider sensitivity analysis.`
      );
    }

    // Check for zero events in binary outcomes
    if (dataset.outcome_type === "binary") {
      const binaryOutcome = outcome as BinaryOutcome;
      if (binaryOutcome.events_treatment === 0 || binaryOutcome.events_control === 0) {
        result.warnings.push(
          `${studyLabel}: Zero events detected. Continuity correction will be applied.`
        );
      }

      // Check for double-zero studies
      if (binaryOutcome.events_treatment === 0 && binaryOutcome.events_control === 0) {
        result.suggestions.push(
          `${studyLabel}: Double-zero study. Consider excluding from analysis per Cochrane Handbook 10.4.4.`
        );
      }
    }

    // Check for very small standard deviations in continuous outcomes
    if (dataset.outcome_type === "continuous") {
      const contOutcome = outcome as ContinuousOutcome;
      if (contOutcome.sd_treatment === 0 || contOutcome.sd_control === 0) {
        result.errors.push(
          `${studyLabel}: Standard deviation cannot be zero`
        );
      }

      // Check for unreasonably small SDs
      const meanTreatment = Math.abs(contOutcome.mean_treatment);
      const meanControl = Math.abs(contOutcome.mean_control);

      if (contOutcome.sd_treatment < meanTreatment * 0.01) {
        result.warnings.push(
          `${studyLabel}: Suspiciously small SD in treatment group. Please verify.`
        );
      }

      if (contOutcome.sd_control < meanControl * 0.01) {
        result.warnings.push(
          `${studyLabel}: Suspiciously small SD in control group. Please verify.`
        );
      }
    }
  });
}

/**
 * Validate statistical requirements
 */
function validateStatisticalRequirements(
  dataset: CochraneDataset,
  result: ValidationResult
) {
  // Calculate total participants
  const totalParticipants = dataset.outcomes.reduce(
    (sum: number, outcome: any) => sum + outcome.n_treatment + outcome.n_control,
    0
  );

  result.suggestions.push(
    `Total participants across all studies: ${totalParticipants}`
  );

  // Check for adequate power
  if (totalParticipants < 100) {
    result.warnings.push(
      "Small total sample size (n<100). Meta-analysis may be underpowered."
    );
  }

  // Check study distribution
  const medianYear =
    dataset.studies.length > 0
      ? dataset.studies.sort((a, b) => a.year - b.year)[
          Math.floor(dataset.studies.length / 2)
        ].year
      : 2000;

  const oldStudies = dataset.studies.filter((s) => s.year < medianYear - 10);
  if (oldStudies.length > 0) {
    result.suggestions.push(
      `${oldStudies.length} studies are >10 years older than median. Consider subgroup analysis by publication year.`
    );
  }
}

/**
 * Validate Cochrane-specific standards
 */
function validateCochraneStandards(
  dataset: CochraneDataset,
  result: ValidationResult
) {
  // Check for adequate intervention description
  if (!dataset.intervention || dataset.intervention === "Intervention") {
    result.suggestions.push(
      "Provide detailed intervention description for PICO framework"
    );
  }

  if (!dataset.comparison || dataset.comparison === "Control") {
    result.suggestions.push(
      "Provide detailed comparison/control description for PICO framework"
    );
  }

  // Check for DOIs
  const studiesWithoutDOI = dataset.studies.filter((s) => !s.doi);
  if (studiesWithoutDOI.length > 0) {
    result.suggestions.push(
      `${studiesWithoutDOI.length} studies missing DOI. Add DOIs for better traceability.`
    );
  }

  // Suggest risk of bias assessment
  result.suggestions.push(
    "Perform risk of bias assessment using Cochrane RoB 2 tool for RCTs or ROBINS-I for non-randomized studies"
  );

  // Suggest GRADE assessment
  result.suggestions.push(
    "Consider GRADE assessment to evaluate certainty of evidence"
  );
}

/**
 * Find duplicate values in array
 */
function findDuplicates(arr: string[]): string[] {
  const seen = new Set<string>();
  const duplicates = new Set<string>();

  arr.forEach((item) => {
    if (seen.has(item)) {
      duplicates.add(item);
    }
    seen.add(item);
  });

  return Array.from(duplicates);
}
