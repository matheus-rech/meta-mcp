#!/usr/bin/env Rscript

#' Perform meta-analysis using metafor package
#'
#' This script performs Cochrane-compliant meta-analysis
#' Following Cochrane Handbook Chapter 10 guidelines

library(metafor)
library(meta)
library(jsonlite)

# Parse command line arguments or read from stdin
args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  stop("No input provided. Expected JSON data.")
}

# Read JSON input
input_data <- fromJSON(args[1])

# Extract parameters
effect_measure <- input_data$effect_measure
model_type <- input_data$model
outcome_type <- input_data$outcome_type
outcomes <- input_data$outcomes
studies <- input_data$studies

# Prepare data frame
n_studies <- length(outcomes)

#' Perform meta-analysis for binary outcomes
perform_binary_meta <- function(outcomes, model_type, effect_measure) {

  # Extract data
  events_treatment <- sapply(outcomes, function(x) x$events_treatment)
  n_treatment <- sapply(outcomes, function(x) x$n_treatment)
  events_control <- sapply(outcomes, function(x) x$events_control)
  n_control <- sapply(outcomes, function(x) x$n_control)
  study_ids <- sapply(outcomes, function(x) x$study_id)

  # Choose measure
  measure <- switch(effect_measure,
    "OR" = "OR",
    "RR" = "RR",
    "RD" = "RD",
    "OR"  # default
  )

  # Perform meta-analysis using metafor
  res <- rma(
    ai = events_treatment,
    bi = n_treatment - events_treatment,
    ci = events_control,
    di = n_control - events_control,
    data = data.frame(study_ids),
    measure = measure,
    method = ifelse(model_type == "random", "REML", "FE"),
    slab = study_ids
  )

  # Calculate heterogeneity statistics
  heterogeneity <- list(
    I2 = res$I2,
    Q = res$QE,
    df = res$k - 1,
    p_value = res$QEp,
    tau2 = res$tau2
  )

  # Extract study-level effects
  study_effects <- lapply(1:res$k, function(i) {
    list(
      study_id = study_ids[i],
      effect_size = list(
        estimate = res$yi[i],
        lower_ci = res$yi[i] - 1.96 * sqrt(res$vi[i]),
        upper_ci = res$yi[i] + 1.96 * sqrt(res$vi[i]),
        weight = res$weights[i]
      )
    )
  })

  # Pooled effect
  pooled_effect <- list(
    estimate = res$beta[1],
    lower_ci = res$ci.lb[1],
    upper_ci = res$ci.ub[1],
    p_value = res$pval[1]
  )

  # Return results
  list(
    effect_measure = effect_measure,
    model = model_type,
    pooled_effect = pooled_effect,
    heterogeneity = heterogeneity,
    study_effects = study_effects,
    n_studies = res$k,
    n_participants = sum(n_treatment) + sum(n_control)
  )
}

#' Perform meta-analysis for continuous outcomes
perform_continuous_meta <- function(outcomes, model_type, effect_measure) {

  # Extract data
  mean_treatment <- sapply(outcomes, function(x) x$mean_treatment)
  sd_treatment <- sapply(outcomes, function(x) x$sd_treatment)
  n_treatment <- sapply(outcomes, function(x) x$n_treatment)
  mean_control <- sapply(outcomes, function(x) x$mean_control)
  sd_control <- sapply(outcomes, function(x) x$sd_control)
  n_control <- sapply(outcomes, function(x) x$n_control)
  study_ids <- sapply(outcomes, function(x) x$study_id)

  # Choose measure
  measure <- switch(effect_measure,
    "MD" = "MD",
    "SMD" = "SMD",
    "ROM" = "ROM",
    "MD"  # default
  )

  # Perform meta-analysis using metafor
  res <- rma(
    m1i = mean_treatment,
    sd1i = sd_treatment,
    n1i = n_treatment,
    m2i = mean_control,
    sd2i = sd_control,
    n2i = n_control,
    data = data.frame(study_ids),
    measure = measure,
    method = ifelse(model_type == "random", "REML", "FE"),
    slab = study_ids
  )

  # Calculate heterogeneity statistics
  heterogeneity <- list(
    I2 = res$I2,
    Q = res$QE,
    df = res$k - 1,
    p_value = res$QEp,
    tau2 = res$tau2
  )

  # Extract study-level effects
  study_effects <- lapply(1:res$k, function(i) {
    list(
      study_id = study_ids[i],
      effect_size = list(
        estimate = res$yi[i],
        lower_ci = res$yi[i] - 1.96 * sqrt(res$vi[i]),
        upper_ci = res$yi[i] + 1.96 * sqrt(res$vi[i]),
        weight = res$weights[i]
      )
    )
  })

  # Pooled effect
  pooled_effect <- list(
    estimate = res$beta[1],
    lower_ci = res$ci.lb[1],
    upper_ci = res$ci.ub[1],
    p_value = res$pval[1]
  )

  # Return results
  list(
    effect_measure = effect_measure,
    model = model_type,
    pooled_effect = pooled_effect,
    heterogeneity = heterogeneity,
    study_effects = study_effects,
    n_studies = res$k,
    n_participants = sum(n_treatment) + sum(n_control)
  )
}

# Perform analysis based on outcome type
result <- if (outcome_type == "binary") {
  perform_binary_meta(outcomes, model_type, effect_measure)
} else {
  perform_continuous_meta(outcomes, model_type, effect_measure)
}

# Output JSON result
cat(toJSON(result, auto_unbox = TRUE, pretty = TRUE))
