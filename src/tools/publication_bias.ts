import { rExecutor } from "../r_bridge/executor.js";
import { logger } from "../utils/logger.js";

interface AssessPublicationBiasArgs {
  analysis_results: any;
  methods?: string[];
  output_path?: string;
}

/**
 * Assess publication bias using multiple methods
 */
export async function assessPublicationBiasTool(args: unknown) {
  const {
    analysis_results,
    methods = ["funnel_plot", "egger_test"],
    output_path,
  } = args as AssessPublicationBiasArgs;

  logger.info(
    `Assessing publication bias using: ${methods.join(", ")}`
  );

  try {
    // Prepare R script
    const rCode = `
library(metafor)
library(meta)
library(jsonlite)

# Parse input data
input_data <- fromJSON('${JSON.stringify(analysis_results).replace(/'/g, "\\'")}')

# Extract study-level data
study_effects <- input_data$study_effects
n_studies <- length(study_effects)
estimates <- sapply(study_effects, function(x) x$effect_size$estimate)
lower_ci <- sapply(study_effects, function(x) x$effect_size$lower_ci)
upper_ci <- sapply(study_effects, function(x) x$effect_size$upper_ci)

# Calculate standard errors
se <- (upper_ci - lower_ci) / (2 * 1.96)

# Initialize results
bias_results <- list()

# Funnel plot
${methods.includes("funnel_plot") && output_path ? `
png("${output_path}", width = 2400, height = 2400, res = 300)
funnel(estimates, se,
       xlab = "${analysis_results.effect_measure}",
       ylab = "Standard Error",
       main = "Funnel Plot for Publication Bias Assessment")
dev.off()
bias_results$funnel_plot <- list(generated = TRUE, path = "${output_path}")
` : ""}

# Egger's test
${methods.includes("egger_test") ? `
if (n_studies >= 3) {
  egger_result <- regtest(estimates, se, model = "rma")
  bias_results$egger_test <- list(
    intercept = egger_result$b[1],
    p_value = egger_result$pval
  )
} else {
  bias_results$egger_test <- list(
    error = "Insufficient studies for Egger's test (minimum 3 required)"
  )
}
` : ""}

# Begg's test
${methods.includes("begg_test") ? `
if (n_studies >= 3) {
  begg_result <- ranktest(estimates, se)
  bias_results$begg_test <- list(
    tau = begg_result$tau,
    p_value = begg_result$pval
  )
} else {
  bias_results$begg_test <- list(
    error = "Insufficient studies for Begg's test (minimum 3 required)"
  )
}
` : ""}

# Trim and fill
${methods.includes("trim_fill") ? `
if (n_studies >= 3) {
  # Create a metafor object
  res <- rma(yi = estimates, sei = se)
  tf_result <- trimfill(res)

  bias_results$trim_fill <- list(
    n_missing = tf_result$k0,
    adjusted_effect = list(
      estimate = tf_result$b[1],
      lower_ci = tf_result$ci.lb[1],
      upper_ci = tf_result$ci.ub[1]
    )
  )
} else {
  bias_results$trim_fill <- list(
    error = "Insufficient studies for trim-and-fill (minimum 3 required)"
  )
}
` : ""}

# Output results
cat(toJSON(bias_results, auto_unbox = TRUE, pretty = TRUE))
    `;

    // Execute R code
    const result = await rExecutor.execute(rCode);

    // Interpret results
    const interpretation = interpretPublicationBias(result, methods);

    return {
      content: [
        {
          type: "text",
          text: JSON.stringify(
            {
              success: true,
              bias_assessment: result,
              interpretation,
              warning:
                analysis_results.n_studies < 10
                  ? "Publication bias tests have limited power with fewer than 10 studies"
                  : null,
            },
            null,
            2
          ),
        },
      ],
    };
  } catch (error) {
    logger.error("Publication bias assessment error:", error);
    throw error;
  }
}

/**
 * Interpret publication bias test results
 */
function interpretPublicationBias(
  results: any,
  methods: string[]
): string[] {
  const interpretations: string[] = [];

  // Egger's test interpretation
  if (methods.includes("egger_test") && results.egger_test) {
    const egger = results.egger_test;
    if (egger.error) {
      interpretations.push(`Egger's test: ${egger.error}`);
    } else {
      if (egger.p_value < 0.10) {
        interpretations.push(
          `Egger's test suggests potential publication bias (p=${egger.p_value.toFixed(3)}, p<0.10)`
        );
      } else {
        interpretations.push(
          `Egger's test does not suggest publication bias (p=${egger.p_value.toFixed(3)})`
        );
      }
    }
  }

  // Begg's test interpretation
  if (methods.includes("begg_test") && results.begg_test) {
    const begg = results.begg_test;
    if (begg.error) {
      interpretations.push(`Begg's test: ${begg.error}`);
    } else {
      if (begg.p_value < 0.10) {
        interpretations.push(
          `Begg's test suggests potential publication bias (p=${begg.p_value.toFixed(3)}, p<0.10)`
        );
      } else {
        interpretations.push(
          `Begg's test does not suggest publication bias (p=${begg.p_value.toFixed(3)})`
        );
      }
    }
  }

  // Trim-and-fill interpretation
  if (methods.includes("trim_fill") && results.trim_fill) {
    const tf = results.trim_fill;
    if (tf.error) {
      interpretations.push(`Trim-and-fill: ${tf.error}`);
    } else {
      if (tf.n_missing > 0) {
        interpretations.push(
          `Trim-and-fill suggests ${tf.n_missing} potentially missing studies due to publication bias`
        );
        interpretations.push(
          `Adjusted pooled estimate: ${tf.adjusted_effect.estimate.toFixed(3)} (95% CI: ${tf.adjusted_effect.lower_ci.toFixed(3)} to ${tf.adjusted_effect.upper_ci.toFixed(3)})`
        );
      } else {
        interpretations.push(
          "Trim-and-fill does not suggest missing studies"
        );
      }
    }
  }

  // Funnel plot interpretation
  if (methods.includes("funnel_plot") && results.funnel_plot) {
    if (results.funnel_plot.generated) {
      interpretations.push(
        `Funnel plot generated at ${results.funnel_plot.path}. Visual inspection recommended.`
      );
    }
  }

  return interpretations;
}
