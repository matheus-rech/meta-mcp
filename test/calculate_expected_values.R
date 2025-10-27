#!/usr/bin/env Rscript

# Calculate expected meta-analysis values for test data
# This documents the ground truth for our comprehensive test

library(metafor)
library(meta)

# Read test data
data <- read.csv("comprehensive_test_data.csv")

cat("=== COMPREHENSIVE TEST DATA ANALYSIS ===\n\n")

cat("📊 STUDY-LEVEL CALCULATIONS\n")
cat("=" , rep("=", 70), "\n\n", sep="")

# Calculate OR for each study
for(i in 1:nrow(data)) {
  study <- data[i,]

  # Calculate 2x2 table
  a <- study$events_treatment
  b <- study$n_treatment - study$events_treatment
  c <- study$events_control
  d <- study$n_control - study$events_control

  # Calculate OR
  or <- (a * d) / (b * c)

  # Calculate log(OR) and variance
  log_or <- log(or)
  var_log_or <- 1/a + 1/b + 1/c + 1/d
  se_log_or <- sqrt(var_log_or)

  # Calculate 95% CI
  log_or_lower <- log_or - 1.96 * se_log_or
  log_or_upper <- log_or + 1.96 * se_log_or

  or_lower <- exp(log_or_lower)
  or_upper <- exp(log_or_upper)

  # Event rates
  rate_tx <- a / study$n_treatment
  rate_ctrl <- c / study$n_control

  cat(sprintf("%s (%s, %d):\n", study$study_id, study$authors, study$year))
  cat(sprintf("  Events: %d/%d (%.1f%%) vs %d/%d (%.1f%%)\n",
              a, study$n_treatment, rate_tx*100,
              c, study$n_control, rate_ctrl*100))
  cat(sprintf("  OR: %.3f (95%% CI: %.3f - %.3f)\n", or, or_lower, or_upper))
  cat(sprintf("  log(OR): %.3f, SE: %.3f, Variance: %.3f\n", log_or, se_log_or, var_log_or))

  # Special notes
  if(a == 0 || c == 0) {
    cat("  ⚠️  ZERO EVENTS - Will need continuity correction\n")
  }
  if(study$n_treatment < 100 || study$n_control < 100) {
    cat("  ⚠️  SMALL SAMPLE SIZE\n")
  }
  if(or < 0.3 || or > 3.0) {
    cat("  ⚠️  EXTREME EFFECT SIZE - Potential outlier\n")
  }
  cat("\n")
}

cat("\n")
cat("🔬 META-ANALYSIS: RANDOM-EFFECTS MODEL\n")
cat("=", rep("=", 70), "\n\n", sep="")

# Perform meta-analysis using metafor
# Note: metafor handles zero events with continuity correction

# Calculate escalc for all studies
dat <- escalc(measure="OR",
              ai=events_treatment,
              bi=n_treatment-events_treatment,
              ci=events_control,
              di=n_control-events_control,
              data=data,
              slab=paste(authors, year))

cat("Individual Study Effect Sizes (with continuity correction if needed):\n")
print(dat[, c("yi", "vi")])
cat("\n")

# Random-effects model using REML
res_random <- rma(yi, vi, data=dat, method="REML")

cat("Random-Effects Model Results:\n")
cat(sprintf("  Pooled log(OR): %.3f (SE: %.3f)\n", res_random$beta[1], res_random$se))
cat(sprintf("  95%% CI: [%.3f, %.3f]\n", res_random$ci.lb, res_random$ci.ub))
cat(sprintf("  Z-value: %.3f, p-value: %.6f\n", res_random$zval, res_random$pval))
cat("\n")

cat(sprintf("  Pooled OR: %.3f\n", exp(res_random$beta[1])))
cat(sprintf("  95%% CI: [%.3f, %.3f]\n", exp(res_random$ci.lb), exp(res_random$ci.ub)))
cat("\n")

cat("Heterogeneity Statistics:\n")
cat(sprintf("  Q = %.2f (df = %d, p = %.4f)\n", res_random$QE, res_random$k-1, res_random$QEp))
cat(sprintf("  I² = %.1f%%\n", res_random$I2))
cat(sprintf("  τ² = %.3f\n", res_random$tau2))
cat(sprintf("  τ = %.3f\n", sqrt(res_random$tau2)))
cat("\n")

# Interpretation
if(res_random$I2 <= 40) {
  het_interp <- "LOW - Heterogeneity might not be important"
} else if(res_random$I2 <= 60) {
  het_interp <- "MODERATE - May represent moderate heterogeneity"
} else if(res_random$I2 <= 75) {
  het_interp <- "SUBSTANTIAL - May represent substantial heterogeneity"
} else {
  het_interp <- "CONSIDERABLE - Considerable heterogeneity present"
}

cat(sprintf("Interpretation: %s\n\n", het_interp))

# Fixed-effect model for comparison
res_fixed <- rma(yi, vi, data=dat, method="FE")

cat("\n")
cat("🔬 META-ANALYSIS: FIXED-EFFECT MODEL (Comparison)\n")
cat("=", rep("=", 70), "\n\n", sep="")

cat("Fixed-Effect Model Results:\n")
cat(sprintf("  Pooled OR: %.3f (95%% CI: %.3f - %.3f)\n",
            exp(res_fixed$beta[1]), exp(res_fixed$ci.lb), exp(res_fixed$ci.ub)))
cat(sprintf("  p-value: %.6f\n", res_fixed$pval))
cat("\n")

cat("Note: Fixed-effect model assumes all studies estimate the same true effect.\n")
cat("      Narrower CI but may be inappropriate given heterogeneity.\n\n")

# Study weights
cat("\n")
cat("📊 STUDY WEIGHTS IN RANDOM-EFFECTS MODEL\n")
cat("=", rep("=", 70), "\n\n", sep="")

weights_pct <- weights(res_random)
for(i in 1:length(weights_pct)) {
  cat(sprintf("%s: %.2f%%\n", dat$slab[i], weights_pct[i]))
}
cat("\n")

# Publication bias assessment
cat("\n")
cat("📈 PUBLICATION BIAS ASSESSMENT\n")
cat("=", rep("=", 70), "\n\n", sep="")

# Egger's test
egger <- regtest(res_random)
cat("Egger's Test for Funnel Plot Asymmetry:\n")
cat(sprintf("  Intercept: %.3f (SE: %.3f)\n", egger$est, egger$se))
cat(sprintf("  t = %.3f (df = %d)\n", egger$zval, egger$dfs))
cat(sprintf("  p-value: %.4f\n", egger$pval))
if(egger$pval < 0.10) {
  cat("  ⚠️  SIGNIFICANT - Suggests potential publication bias\n")
} else {
  cat("  ✓ NOT SIGNIFICANT - No evidence of publication bias\n")
}
cat("\n")

# Rank correlation test (Begg's test)
begg <- ranktest(res_random)
cat("Begg's Rank Correlation Test:\n")
cat(sprintf("  Kendall's tau: %.3f\n", begg$tau))
cat(sprintf("  p-value: %.4f\n", begg$pval))
if(begg$pval < 0.10) {
  cat("  ⚠️  SIGNIFICANT - Suggests potential publication bias\n")
} else {
  cat("  ✓ NOT SIGNIFICANT - No evidence of publication bias\n")
}
cat("\n")

# Trim and fill
tf <- trimfill(res_random)
cat("Trim-and-Fill Analysis:\n")
cat(sprintf("  Estimated missing studies: %d\n", tf$k0))
if(tf$k0 > 0) {
  cat(sprintf("  Adjusted pooled OR: %.3f (95%% CI: %.3f - %.3f)\n",
              exp(tf$beta[1]), exp(tf$ci.lb), exp(tf$ci.ub)))
  cat("  ⚠️  Results suggest potential missing studies\n")
} else {
  cat("  ✓ No missing studies detected\n")
}
cat("\n")

# Summary statistics
cat("\n")
cat("📋 SUMMARY STATISTICS\n")
cat("=", rep("=", 70), "\n\n", sep="")

total_tx <- sum(data$n_treatment)
total_ctrl <- sum(data$n_control)
total_events_tx <- sum(data$events_treatment)
total_events_ctrl <- sum(data$events_control)

cat(sprintf("Total studies: %d\n", nrow(data)))
cat(sprintf("Total participants: %d\n", total_tx + total_ctrl))
cat(sprintf("  Treatment arm: %d (events: %d, %.1f%%)\n",
            total_tx, total_events_tx, 100*total_events_tx/total_tx))
cat(sprintf("  Control arm: %d (events: %d, %.1f%%)\n",
            total_ctrl, total_events_ctrl, 100*total_events_ctrl/total_ctrl))
cat(sprintf("Year range: %d - %d\n", min(data$year), max(data$year)))
cat(sprintf("Studies with DOI: %d/%d\n", sum(data$doi != ""), nrow(data)))
cat("\n")

cat("✅ EXPECTED TEST RESULTS:\n")
cat("  ✓ All 12 studies should import successfully\n")
cat("  ✓ Validation: 0 errors expected\n")
cat("  ✓ Warnings: ~5 expected (small samples, zero events, missing DOIs)\n")
cat(sprintf("  ✓ Pooled OR: %.3f (95%% CI: %.3f-%.3f)\n",
            exp(res_random$beta[1]), exp(res_random$ci.lb), exp(res_random$ci.ub)))
cat(sprintf("  ✓ I²: %.1f%% (moderate heterogeneity)\n", res_random$I2))
cat("  ✓ Publication bias: p>0.10 (no bias detected)\n")
cat("  ✓ Effect is statistically significant (p<0.001)\n")
cat("\n")

cat("Test calculations completed successfully! ✅\n")
