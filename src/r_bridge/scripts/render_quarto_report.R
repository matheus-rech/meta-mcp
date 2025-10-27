#!/usr/bin/env Rscript

#' Render Quarto Meta-Analysis Report
#'
#' @param analysis_results List containing meta-analysis results
#' @param output_path Path to save HTML/PDF report
#' @param format Output format ("html" or "pdf")
#' @param include_code Whether to include R code in report

render_meta_analysis_report <- function(analysis_results,
                                       output_path = "meta_analysis_report.html",
                                       format = "html",
                                       include_code = FALSE) {

  # Check if quarto is available
  if(!requireNamespace("quarto", quietly = TRUE)) {
    stop("Quarto package not installed. Install with: install.packages('quarto')")
  }

  library(quarto)

  # Prepare parameters for report
  params <- list(
    n_studies = analysis_results$n_studies,
    n_participants = analysis_results$n_participants,
    intervention = analysis_results$intervention %||% "Intervention",
    comparison = analysis_results$comparison %||% "Control",
    outcome = analysis_results$outcome %||% "Primary outcome",
    pooled_or = exp(analysis_results$pooled_effect$estimate),
    ci_lower = exp(analysis_results$pooled_effect$lower_ci),
    ci_upper = exp(analysis_results$pooled_effect$upper_ci),
    p_value = analysis_results$pooled_effect$p_value,
    I2 = analysis_results$heterogeneity$I2,
    Q = analysis_results$heterogeneity$Q,
    Q_p = analysis_results$heterogeneity$p_value,
    tau2 = analysis_results$heterogeneity$tau2,
    forest_plot_path = analysis_results$forest_plot_path %||% "",
    funnel_plot_path = analysis_results$funnel_plot_path %||% "",
    studies = prepare_study_table(analysis_results),
    interpretation = generate_interpretation(analysis_results),
    include_code = include_code
  )

  # Get template path
  template_path <- system.file("scripts/generate_report.qmd",
                              package = "cochrane-meta-mcp")

  # If package path doesn't work, use relative path
  if(template_path == "" || !file.exists(template_path)) {
    template_path <- file.path(dirname(sys.frame(1)$ofile), "generate_report.qmd")
  }

  # Still not found? Use current directory
  if(!file.exists(template_path)) {
    template_path <- "generate_report.qmd"
  }

  if(!file.exists(template_path)) {
    stop("Cannot find Quarto template: generate_report.qmd")
  }

  # Determine output format
  output_format <- if(format == "pdf") "pdf" else "html"

  # Render report
  tryCatch({
    quarto_render(
      input = template_path,
      output_file = basename(output_path),
      output_format = output_format,
      execute_params = params
    )

    # Move to desired location if needed
    rendered_file <- file.path(dirname(template_path), basename(output_path))
    if(rendered_file != output_path && file.exists(rendered_file)) {
      file.rename(rendered_file, output_path)
    }

    cat(sprintf("✓ Report generated successfully: %s\n", output_path))
    return(list(success = TRUE, output_path = output_path))

  }, error = function(e) {
    cat(sprintf("❌ Error generating report: %s\n", e$message))
    return(list(success = FALSE, error = e$message))
  })
}

#' Prepare study table for report
prepare_study_table <- function(results) {
  if(is.null(results$study_effects)) return(NULL)

  studies_df <- data.frame(
    Study = sapply(results$study_effects, function(x) x$study_id),
    OR = sapply(results$study_effects, function(x) exp(x$effect_size$estimate)),
    Lower_CI = sapply(results$study_effects, function(x) exp(x$effect_size$lower_ci)),
    Upper_CI = sapply(results$study_effects, function(x) exp(x$effect_size$upper_ci)),
    Weight = sapply(results$study_effects, function(x) x$effect_size$weight %||% NA)
  )

  return(studies_df)
}

#' Generate clinical interpretation text
generate_interpretation <- function(results) {
  or <- exp(results$pooled_effect$estimate)
  p_val <- results$pooled_effect$p_value
  i2 <- results$heterogeneity$I2

  interpretation <- ""

  # Effect interpretation
  if(p_val < 0.05) {
    if(or < 1) {
      reduction <- (1 - or) * 100
      interpretation <- sprintf(
        "The treatment demonstrates a statistically significant protective effect (OR=%.3f, p<%.3f), reducing the odds of the outcome by approximately %.1f%%.",
        or, if(p_val < 0.001) 0.001 else p_val, reduction
      )
    } else {
      increase <- (or - 1) * 100
      interpretation <- sprintf(
        "The treatment demonstrates a statistically significant harmful effect (OR=%.3f, p<%.3f), increasing the odds of the outcome by approximately %.1f%%.",
        or, if(p_val < 0.001) 0.001 else p_val, increase
      )
    }
  } else {
    interpretation <- sprintf(
      "No statistically significant effect was detected (OR=%.3f, p=%.3f).",
      or, p_val
    )
  }

  # Heterogeneity interpretation
  if(i2 > 75) {
    interpretation <- paste(interpretation,
      "\n\nConsiderable heterogeneity was observed (I²=%.1f%%), suggesting substantial variability in treatment effects across studies. Pooled estimates should be interpreted with caution.",
      sprintf("%.1f", i2))
  } else if(i2 > 60) {
    interpretation <- paste(interpretation,
      sprintf("\n\nSubstantial heterogeneity was observed (I²=%.1f%%). Investigation of sources of heterogeneity is recommended.", i2))
  } else if(i2 > 40) {
    interpretation <- paste(interpretation,
      sprintf("\n\nModerate heterogeneity was observed (I²=%.1f%%), suggesting some variability in effects across studies.", i2))
  } else {
    interpretation <- paste(interpretation,
      sprintf("\n\nLow heterogeneity was observed (I²=%.1f%%), suggesting relatively consistent effects across studies.", i2))
  }

  return(interpretation)
}

# Helper for null coalescing
`%||%` <- function(x, y) if(is.null(x)) y else x
