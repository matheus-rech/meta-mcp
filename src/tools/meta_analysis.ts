import { readFileSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";
import { rExecutor } from "../r_bridge/executor.js";
import { logger } from "../utils/logger.js";
import { MetaAnalysisResultSchema } from "../schemas/cochrane.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

interface PerformMetaAnalysisArgs {
  data: any;
  effect_measure: "OR" | "RR" | "MD" | "SMD" | "HR";
  model?: "fixed" | "random";
  heterogeneity_test?: boolean;
}

/**
 * Perform meta-analysis using R metafor/meta packages
 */
export async function performMetaAnalysisTool(args: unknown) {
  const {
    data,
    effect_measure,
    model = "random",
    heterogeneity_test = true,
  } = args as PerformMetaAnalysisArgs;

  logger.info(
    `Performing meta-analysis (effect: ${effect_measure}, model: ${model})`
  );

  try {
    // Prepare R script
    const rScriptPath = join(
      __dirname,
      "../r_bridge/scripts/meta_analysis.R"
    );
    const rScript = readFileSync(rScriptPath, "utf-8");

    // Prepare input data for R
    const inputData = {
      effect_measure,
      model,
      outcome_type: data.outcome_type,
      outcomes: data.outcomes,
      studies: data.studies,
    };

    // Build R command
    const rCode = `
${rScript}

# Execute with data
input_json <- '${JSON.stringify(inputData).replace(/'/g, "\\'")}'
result <- fromJSON(input_json)

# Perform analysis
if (result$outcome_type == "binary") {
  analysis_result <- perform_binary_meta(
    result$outcomes,
    result$model,
    result$effect_measure
  )
} else {
  analysis_result <- perform_continuous_meta(
    result$outcomes,
    result$model,
    result$effect_measure
  )
}

# Output result
cat(toJSON(analysis_result, auto_unbox = TRUE, pretty = TRUE))
    `;

    // Execute R code
    const result = await rExecutor.execute(rCode);

    // Validate result
    const validatedResult = MetaAnalysisResultSchema.parse(result);

    // Interpret heterogeneity
    const heterogeneityInterpretation = interpretHeterogeneity(
      validatedResult.heterogeneity.I2
    );

    return {
      content: [
        {
          type: "text",
          text: JSON.stringify(
            {
              success: true,
              results: validatedResult,
              interpretation: {
                heterogeneity: heterogeneityInterpretation,
                recommendation: getRecommendation(validatedResult),
              },
            },
            null,
            2
          ),
        },
      ],
    };
  } catch (error) {
    logger.error("Meta-analysis error:", error);
    throw error;
  }
}

/**
 * Interpret I² statistic
 * Per Cochrane Handbook Section 10.10.2
 */
function interpretHeterogeneity(i2: number): string {
  if (i2 <= 40) {
    return "Low heterogeneity (I² ≤ 40%). Heterogeneity might not be important.";
  } else if (i2 <= 60) {
    return "Moderate heterogeneity (40% < I² ≤ 60%). May represent moderate heterogeneity.";
  } else if (i2 <= 75) {
    return "Substantial heterogeneity (60% < I² ≤ 75%). May represent substantial heterogeneity.";
  } else {
    return "Considerable heterogeneity (I² > 75%). Represents considerable heterogeneity. Consider not pooling studies or using a random-effects model.";
  }
}

/**
 * Provide recommendations based on results
 */
function getRecommendation(result: any): string[] {
  const recommendations: string[] = [];

  // Heterogeneity recommendations
  if (result.heterogeneity.I2 > 75) {
    recommendations.push(
      "High heterogeneity detected. Consider:"
    );
    recommendations.push(
      "  - Investigating sources of heterogeneity through subgroup analysis"
    );
    recommendations.push(
      "  - Using meta-regression to explore covariates"
    );
    recommendations.push(
      "  - Examining whether pooling is appropriate"
    );
  }

  if (result.heterogeneity.p_value < 0.10) {
    recommendations.push(
      `Significant heterogeneity (Q-test p=${result.heterogeneity.p_value.toFixed(3)}). Random-effects model is recommended.`
    );
  }

  // Sample size recommendations
  if (result.n_studies < 5) {
    recommendations.push(
      "Small number of studies (n<5). Interpret results with caution."
    );
    recommendations.push(
      "Publication bias assessment may not be reliable with few studies."
    );
  }

  // Effect size interpretation
  const estimate = result.pooled_effect.estimate;
  const ci_lower = result.pooled_effect.lower_ci;
  const ci_upper = result.pooled_effect.upper_ci;

  if (result.effect_measure === "OR" || result.effect_measure === "RR") {
    if (ci_lower < 1 && ci_upper > 1) {
      recommendations.push(
        "Confidence interval crosses 1.0, suggesting no statistically significant effect."
      );
    }
  } else if (result.effect_measure === "MD" || result.effect_measure === "SMD") {
    if (ci_lower < 0 && ci_upper > 0) {
      recommendations.push(
        "Confidence interval crosses 0, suggesting no statistically significant effect."
      );
    }
  }

  // Power considerations
  if (result.n_participants < 100) {
    recommendations.push(
      "Small total sample size. Meta-analysis may be underpowered to detect meaningful effects."
    );
  }

  return recommendations;
}
