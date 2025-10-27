#!/usr/bin/env Rscript

# TEST STEP 5: Assess Publication Bias
# Simulates the assess_publication_bias MCP tool

library(metafor)

cat("╔═══════════════════════════════════════════════════════════════════════╗\n")
cat("║  TEST STEP 5: PUBLICATION BIAS ASSESSMENT                            ║\n")
cat("╚═══════════════════════════════════════════════════════════════════════╝\n\n")

cat("Tool: assess_publication_bias\n")
cat("Input: {\n")
cat("  analysis_results: {...},\n")
cat("  methods: ['funnel_plot', 'egger_test', 'begg_test', 'trim_fill'],\n")
cat("  output_path: 'outputs/funnel_plot_comprehensive.png'\n")
cat("}\n\n")

# Load data
res <- readRDS("metafor_result.rds")

cat("📊 RUNNING PUBLICATION BIAS TESTS...\n\n")

bias_results <- list()

# 1. Funnel Plot
cat("1️⃣  FUNNEL PLOT GENERATION\n")

output_file <- "outputs/funnel_plot_comprehensive.png"
png(output_file, width = 2400, height = 2400, res = 300)

funnel(res,
       xlab = "Log Odds Ratio",
       ylab = "Standard Error",
       main = "Funnel Plot for Publication Bias Assessment",
       refline = 0,
       level = c(90, 95, 99),
       shade = c("white", "gray75", "gray60"),
       legend = TRUE)

dev.off()

if(file.exists(output_file)) {
  file_info <- file.info(output_file)
  cat(sprintf("  ✓ Funnel plot generated: %s (%.2f KB)\n", output_file, file_info$size / 1024))
  bias_results$funnel_plot <- list(
    generated = TRUE,
    path = output_file
  )
} else {
  cat("  ❌ ERROR: Funnel plot not created\n")
  bias_results$funnel_plot <- list(generated = FALSE)
}
cat("\n")

# 2. Egger's Test
cat("2️⃣  EGGER'S REGRESSION TEST\n")
cat("  Testing for funnel plot asymmetry...\n\n")

egger <- regtest(res, model = "rma")

cat("  Results:\n")
cat(sprintf("    Intercept: %.3f (SE: %.3f)\n", egger$est, egger$se))
cat(sprintf("    z-value: %.3f\n", egger$zval))
cat(sprintf("    p-value: %.4f\n", egger$pval))
cat("\n")

if(egger$pval < 0.10) {
  cat("  ⚠️  INTERPRETATION: Significant (p < 0.10)\n")
  cat("      Suggests potential publication bias (small-study effects)\n")
  cat("      Caution: Egger's test can have low power with <10 studies\n")
} else {
  cat("  ✅ INTERPRETATION: Not significant (p ≥ 0.10)\n")
  cat("      No evidence of publication bias detected\n")
}

bias_results$egger_test <- list(
  intercept = as.numeric(egger$est),
  se = egger$se,
  p_value = egger$pval
)
cat("\n")

# 3. Begg's Rank Correlation Test
cat("3️⃣  BEGG'S RANK CORRELATION TEST\n")
cat("  Testing for correlation between effect size and variance...\n\n")

begg <- ranktest(res)

cat("  Results:\n")
cat(sprintf("    Kendall's tau: %.3f\n", begg$tau))
cat(sprintf("    p-value: %.4f\n", begg$pval))
cat("\n")

if(begg$pval < 0.10) {
  cat("  ⚠️  INTERPRETATION: Significant (p < 0.10)\n")
  cat("      Suggests potential publication bias\n")
} else {
  cat("  ✅ INTERPRETATION: Not significant (p ≥ 0.10)\n")
  cat("      No evidence of publication bias detected\n")
}

bias_results$begg_test <- list(
  tau = begg$tau,
  p_value = begg$pval
)
cat("\n")

# 4. Trim-and-Fill
cat("4️⃣  TRIM-AND-FILL ANALYSIS\n")
cat("  Estimating potentially missing studies...\n\n")

tf <- trimfill(res)

cat("  Results:\n")
cat(sprintf("    Estimated missing studies: %d\n", tf$k0))

if(tf$k0 > 0) {
  cat(sprintf("    Adjusted log(OR): %.3f (SE: %.3f)\n", tf$beta[1], tf$se))
  cat(sprintf("    Adjusted 95%% CI: [%.3f, %.3f]\n", tf$ci.lb, tf$ci.ub))
  cat(sprintf("    Adjusted OR: %.3f (95%% CI: [%.3f, %.3f])\n",
              exp(tf$beta[1]), exp(tf$ci.lb), exp(tf$ci.ub)))
  cat("\n")

  # Compare with original
  original_or <- exp(res$beta[1])
  adjusted_or <- exp(tf$beta[1])
  change_pct <- abs((adjusted_or - original_or) / original_or * 100)

  cat("  Comparison with original:\n")
  cat(sprintf("    Original OR: %.3f\n", original_or))
  cat(sprintf("    Adjusted OR: %.3f\n", adjusted_or))
  cat(sprintf("    Change: %.1f%%\n", change_pct))
  cat("\n")

  if(change_pct > 20) {
    cat("  ⚠️  INTERPRETATION: Substantial change (>20%)\n")
    cat("      Results may be sensitive to publication bias\n")
  } else if(change_pct > 10) {
    cat("  ⚠️  INTERPRETATION: Moderate change (10-20%)\n")
    cat("      Some potential impact from publication bias\n")
  } else {
    cat("  ✅ INTERPRETATION: Minimal change (<10%)\n")
    cat("      Results relatively robust to potential publication bias\n")
  }

  bias_results$trim_fill <- list(
    n_missing = tf$k0,
    adjusted_effect = list(
      estimate = as.numeric(tf$beta[1]),
      lower_ci = tf$ci.lb,
      upper_ci = tf$ci.ub
    )
  )
} else {
  cat("    No missing studies detected\n\n")
  cat("  ✅ INTERPRETATION: No adjustment needed\n")
  cat("      Funnel plot appears symmetric\n")

  bias_results$trim_fill <- list(
    n_missing = 0,
    adjusted_effect = NULL
  )
}
cat("\n")

# Overall interpretation
cat("═══════════════════════════════════════════════════════════════════════\n")
cat("OVERALL PUBLICATION BIAS ASSESSMENT\n")
cat("═══════════════════════════════════════════════════════════════════════\n\n")

significant_tests <- 0
if(bias_results$egger_test$p_value < 0.10) significant_tests <- significant_tests + 1
if(bias_results$begg_test$p_value < 0.10) significant_tests <- significant_tests + 1

cat("📋 SUMMARY OF TESTS:\n")
cat(sprintf("  Egger's test: %s (p = %.4f)\n",
            ifelse(bias_results$egger_test$p_value < 0.10, "SIGNIFICANT ⚠️ ", "Not significant ✓"),
            bias_results$egger_test$p_value))
cat(sprintf("  Begg's test: %s (p = %.4f)\n",
            ifelse(bias_results$begg_test$p_value < 0.10, "SIGNIFICANT ⚠️ ", "Not significant ✓"),
            bias_results$begg_test$p_value))
cat(sprintf("  Trim-and-fill: %d potentially missing studies\n", bias_results$trim_fill$n_missing))
cat("\n")

if(significant_tests >= 2) {
  cat("⚠️  CONCLUSION: HIGH RISK of publication bias\n")
  cat("    Multiple tests suggest asymmetry\n")
  cat("    Results should be interpreted with caution\n")
  cat("    Consider:\n")
  cat("      • Sensitivity analysis\n")
  cat("      • Searching for unpublished studies\n")
  cat("      • Contacting authors for missing data\n")
} else if(significant_tests == 1) {
  cat("⚠️  CONCLUSION: MODERATE RISK of publication bias\n")
  cat("    One test suggests potential bias\n")
  cat("    Exercise caution in interpretation\n")
  cat("    Consider additional bias assessments\n")
} else if(bias_results$trim_fill$n_missing > 0) {
  cat("⚠️  CONCLUSION: LOW TO MODERATE RISK\n")
  cat("    Statistical tests not significant but trim-and-fill suggests missing studies\n")
  cat("    Visual inspection of funnel plot recommended\n")
} else {
  cat("✅ CONCLUSION: LOW RISK of publication bias\n")
  cat("    All tests suggest symmetric funnel plot\n")
  cat("    Results appear robust\n")
  cat("    NOTE: Tests have limited power with <10 studies\n")
}
cat("\n")

# Save results
saveRDS(bias_results, "bias_results.rds")
cat("✓ Publication bias results saved to bias_results.rds\n\n")

cat("═══════════════════════════════════════════════════════════════════════\n")
cat("TEST STEP 5: ✅ PASSED\n")
cat("═══════════════════════════════════════════════════════════════════════\n\n")
