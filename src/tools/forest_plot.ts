import { writeFileSync } from "fs";
import { join } from "path";
import { rExecutor } from "../r_bridge/executor.js";
import { logger } from "../utils/logger.js";

interface GenerateForestPlotArgs {
  analysis_results: any;
  plot_style?: "classic" | "modern";
  confidence_level?: number;
  output_path: string;
}

/**
 * Generate publication-ready forest plot
 */
export async function generateForestPlotTool(args: unknown) {
  const {
    analysis_results,
    plot_style = "classic",
    confidence_level = 0.95,
    output_path,
  } = args as GenerateForestPlotArgs;

  logger.info(`Generating forest plot: ${output_path}`);

  try {
    // Prepare R script for forest plot
    const rCode = `
library(metafor)
library(meta)
library(ggplot2)

# Parse input data
input_data <- fromJSON('${JSON.stringify(analysis_results).replace(/'/g, "\\'")}')

# Extract data
effect_measure <- input_data$effect_measure
model_type <- input_data$model
pooled_effect <- input_data$pooled_effect
study_effects <- input_data$study_effects

# Create data frame
n_studies <- length(study_effects)
study_ids <- sapply(study_effects, function(x) x$study_id)
estimates <- sapply(study_effects, function(x) x$effect_size$estimate)
lower_ci <- sapply(study_effects, function(x) x$effect_size$lower_ci)
upper_ci <- sapply(study_effects, function(x) x$effect_size$upper_ci)
weights <- sapply(study_effects, function(x) x$effect_size$weight)

# Prepare forest plot data
forest_data <- data.frame(
  study = study_ids,
  estimate = estimates,
  lower = lower_ci,
  upper = upper_ci,
  weight = weights
)

# Create forest plot
png("${output_path}", width = 3000, height = 2000, res = 300)

par(mar = c(5, 10, 4, 2))

# Plot using metafor
forest(
  x = forest_data$estimate,
  ci.lb = forest_data$lower,
  ci.ub = forest_data$upper,
  slab = forest_data$study,
  xlab = paste(effect_measure, "(${confidence_level * 100}% CI)"),
  main = "Forest Plot",
  refline = ifelse(effect_measure %in% c("OR", "RR", "HR"), 1, 0),
  pch = 19,
  psize = sqrt(forest_data$weight),
  cex = 0.8
)

# Add pooled effect
addpoly(
  x = pooled_effect$estimate,
  ci.lb = pooled_effect$lower_ci,
  ci.ub = pooled_effect$upper_ci,
  row = -1,
  mlab = paste(model_type, "effects model"),
  cex = 0.9
)

dev.off()

cat(toJSON(list(success = TRUE, output_path = "${output_path}"), auto_unbox = TRUE))
    `;

    // Execute R code
    const result = await rExecutor.execute(rCode);

    return {
      content: [
        {
          type: "text",
          text: JSON.stringify(
            {
              success: true,
              message: `Forest plot generated successfully`,
              output_path,
              format: "PNG (300 DPI)",
            },
            null,
            2
          ),
        },
      ],
    };
  } catch (error) {
    logger.error("Forest plot generation error:", error);
    throw error;
  }
}
