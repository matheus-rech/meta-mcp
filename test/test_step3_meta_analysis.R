#!/usr/bin/env Rscript

# TEST STEP 3: Perform Meta-Analysis
# Simulates the perform_meta_analysis MCP tool

library(metafor)
library(meta)

cat("╔═══════════════════════════════════════════════════════════════════════╗\n")
cat("║  TEST STEP 3: PERFORM META-ANALYSIS                                  ║\n")
cat("╚═══════════════════════════════════════════════════════════════════════╝\n\n")

cat("Tool: perform_meta_analysis\n")
cat("Input: {\n")
cat("  data: parsed_dataset,\n")
cat("  effect_measure: 'OR',\n")
cat("  model: 'random',\n")
cat("  heterogeneity_test: true\n")
cat("}\n\n")

# Load data
dataset <- readRDS("parsed_dataset.rds")

cat("📊 CALCULATING EFFECT SIZES...\n\n")

# Calculate effect sizes with escalc
dat <- escalc(measure="OR",
              ai=dataset$outcomes$events_treatment,
              bi=dataset$outcomes$n_treatment - dataset$outcomes$events_treatment,
              ci=dataset$outcomes$events_control,
              di=dataset$outcomes$n_control - dataset$outcomes$events_control,
              data=dataset$outcomes)

# Add study labels
dat$slab <- paste(dataset$studies$authors, dataset$studies$year)

cat("Effect sizes calculated (with continuity correction for zero events):\n")
print(dat[, c("study_id", "yi", "vi")], row.names=FALSE)
cat("\n")

cat("🔬 RUNNING RANDOM-EFFECTS META-ANALYSIS...\n\n")

# Perform random-effects meta-analysis
res <- rma(yi, vi, data=dat, method="REML", slab=dat$slab)

# Extract results
pooled_effect <- list(
  estimate = as.numeric(res$beta[1]),
  lower_ci = res$ci.lb,
  upper_ci = res$ci.ub,
  p_value = res$pval
)

heterogeneity <- list(
  I2 = res$I2,
  Q = res$QE,
  df = res$k - 1,
  p_value = res$QEp,
  tau2 = res$tau2
)

# Study-level effects with weights
study_effects <- list()
weights_pct <- weights(res)
for(i in 1:res$k) {
  study_effects[[i]] <- list(
    study_id = dataset$outcomes$study_id[i],
    effect_size = list(
      estimate = dat$yi[i],
      lower_ci = dat$yi[i] - 1.96 * sqrt(dat$vi[i]),
      upper_ci = dat$yi[i] + 1.96 * sqrt(dat$vi[i]),
      weight = weights_pct[i]
    )
  )
}

analysis_result <- list(
  effect_measure = "OR",
  model = "random",
  pooled_effect = pooled_effect,
  heterogeneity = heterogeneity,
  study_effects = study_effects,
  n_studies = res$k,
  n_participants = sum(dataset$outcomes$n_treatment) + sum(dataset$outcomes$n_control)
)

cat("═══════════════════════════════════════════════════════════════════════\n")
cat("RANDOM-EFFECTS MODEL RESULTS:\n")
cat("═══════════════════════════════════════════════════════════════════════\n\n")

cat("📈 POOLED EFFECT (log scale):\n")
cat(sprintf("  Estimate: %.3f\n", pooled_effect$estimate))
cat(sprintf("  95%% CI: [%.3f, %.3f]\n", pooled_effect$lower_ci, pooled_effect$upper_ci))
cat(sprintf("  p-value: %.6f\n", pooled_effect$p_value))
cat("\n")

cat("📈 POOLED EFFECT (Odds Ratio):\n")
pooled_or <- exp(pooled_effect$estimate)
pooled_or_lower <- exp(pooled_effect$lower_ci)
pooled_or_upper <- exp(pooled_effect$upper_ci)
cat(sprintf("  OR: %.3f\n", pooled_or))
cat(sprintf("  95%% CI: [%.3f, %.3f]\n", pooled_or_lower, pooled_or_upper))
if(pooled_effect$p_value < 0.001) {
  cat("  Significance: p < 0.001 ***\n")
} else if(pooled_effect$p_value < 0.01) {
  cat("  Significance: p < 0.01 **\n")
} else if(pooled_effect$p_value < 0.05) {
  cat("  Significance: p < 0.05 *\n")
} else {
  cat("  Significance: p ≥ 0.05 (not significant)\n")
}
cat("\n")

cat("📊 HETEROGENEITY STATISTICS:\n")
cat(sprintf("  Q = %.2f (df = %d)\n", heterogeneity$Q, heterogeneity$df))
cat(sprintf("  p-value = %.4f\n", heterogeneity$p_value))
cat(sprintf("  I² = %.1f%%\n", heterogeneity$I2))
cat(sprintf("  τ² = %.3f\n", heterogeneity$tau2))
cat("\n")

# Interpret heterogeneity (Cochrane Handbook guidelines)
if(heterogeneity$I2 <= 40) {
  het_interp <- "LOW - Heterogeneity might not be important"
  het_color <- "✅"
} else if(heterogeneity$I2 <= 60) {
  het_interp <- "MODERATE - May represent moderate heterogeneity"
  het_color <- "⚠️ "
} else if(heterogeneity$I2 <= 75) {
  het_interp <- "SUBSTANTIAL - May represent substantial heterogeneity"
  het_color <- "⚠️ "
} else {
  het_interp <- "CONSIDERABLE - Considerable heterogeneity present"
  het_color <- "❌"
}

cat(sprintf("  Interpretation: %s %s\n", het_color, het_interp))
cat("\n")

cat("⚖️  STUDY WEIGHTS:\n")
for(i in 1:length(study_effects)) {
  cat(sprintf("  %s: %.2f%%\n",
              paste(dataset$studies$authors[i], dataset$studies$year[i]),
              study_effects[[i]]$effect_size$weight))
}
cat("\n")

cat("💡 RECOMMENDATIONS:\n")
if(heterogeneity$I2 > 75) {
  cat("  • HIGH heterogeneity detected\n")
  cat("  • Investigate sources through subgroup analysis\n")
  cat("  • Consider meta-regression for covariates\n")
  cat("  • Question whether pooling is appropriate\n")
} else if(heterogeneity$I2 > 60) {
  cat("  • SUBSTANTIAL heterogeneity detected\n")
  cat("  • Consider subgroup analysis\n")
  cat("  • Random-effects model appropriate\n")
}

if(heterogeneity$p_value < 0.10) {
  cat(sprintf("  • Significant heterogeneity (Q-test p=%.3f)\n", heterogeneity$p_value))
  cat("  • Random-effects model is recommended\n")
}

if(analysis_result$n_studies < 5) {
  cat("  • Small number of studies (n<5)\n")
  cat("  • Interpret results with caution\n")
  cat("  • Publication bias tests may not be reliable\n")
}

# Effect interpretation
if(pooled_or_lower < 1 && pooled_or_upper > 1) {
  cat("  • CI crosses 1.0 - No statistically significant effect\n")
} else if(pooled_or < 1) {
  reduction <- (1 - pooled_or) * 100
  cat(sprintf("  • Treatment REDUCES odds by %.1f%%\n", reduction))
  cat("  • Statistically significant protective effect\n")
} else {
  increase <- (pooled_or - 1) * 100
  cat(sprintf("  • Treatment INCREASES odds by %.1f%%\n", increase))
  cat("  • Statistically significant harmful effect\n")
}

cat("\n")

# Save results
saveRDS(analysis_result, "analysis_result.rds")
saveRDS(res, "metafor_result.rds")
cat("✓ Analysis results saved\n")
cat("  - analysis_result.rds (structured data)\n")
cat("  - metafor_result.rds (metafor object)\n\n")

cat("═══════════════════════════════════════════════════════════════════════\n")
cat("TEST STEP 3: ✅ PASSED\n")
cat("═══════════════════════════════════════════════════════════════════════\n\n")
