#!/usr/bin/env Rscript

# TEST STEP 2: Comprehensive Data Validation
# Simulates the validate_cochrane_data MCP tool

cat("╔═══════════════════════════════════════════════════════════════════════╗\n")
cat("║  TEST STEP 2: COMPREHENSIVE DATA VALIDATION                          ║\n")
cat("╚═══════════════════════════════════════════════════════════════════════╝\n\n")

cat("Tool: validate_cochrane_data\n")
cat("Input: {data: parsed_dataset, validation_level: 'comprehensive'}\n\n")

# Load parsed dataset
dataset <- readRDS("parsed_dataset.rds")

validation_result <- list(
  valid = TRUE,
  errors = character(),
  warnings = character(),
  suggestions = character()
)

cat("🔍 RUNNING VALIDATION CHECKS...\n\n")

# 1. Basic Requirements
cat("1. BASIC REQUIREMENTS\n")

# Check minimum studies
if(nrow(dataset$studies) < 2) {
  validation_result$errors <- c(validation_result$errors,
    sprintf("Meta-analysis requires at least 2 studies. Current: %d", nrow(dataset$studies)))
  cat("  ❌ Insufficient studies\n")
} else {
  cat(sprintf("  ✓ Sufficient studies: %d\n", nrow(dataset$studies)))
}

# Check study IDs match
study_ids_studies <- dataset$studies$id
study_ids_outcomes <- dataset$outcomes$study_id
missing_outcomes <- setdiff(study_ids_studies, study_ids_outcomes)
if(length(missing_outcomes) > 0) {
  validation_result$errors <- c(validation_result$errors,
    sprintf("Studies missing outcome data: %s", paste(missing_outcomes, collapse=", ")))
  cat("  ❌ Missing outcome data for some studies\n")
} else {
  cat("  ✓ All studies have outcome data\n")
}

# Check for duplicates
dup_ids <- study_ids_studies[duplicated(study_ids_studies)]
if(length(dup_ids) > 0) {
  validation_result$errors <- c(validation_result$errors,
    sprintf("Duplicate study IDs found: %s", paste(dup_ids, collapse=", ")))
  cat("  ❌ Duplicate study IDs detected\n")
} else {
  cat("  ✓ No duplicate studies\n")
}
cat("\n")

# 2. Study Quality
cat("2. STUDY QUALITY CHECKS\n")

for(i in 1:nrow(dataset$outcomes)) {
  outcome <- dataset$outcomes[i,]
  study <- dataset$studies[dataset$studies$id == outcome$study_id,]

  study_label <- sprintf("%s (%d)", study$authors, study$year)

  # Small sample sizes
  if(outcome$n_treatment < 10) {
    validation_result$warnings <- c(validation_result$warnings,
      sprintf("%s: Small treatment group (n=%d)", study_label, outcome$n_treatment))
  }

  if(outcome$n_control < 10) {
    validation_result$warnings <- c(validation_result$warnings,
      sprintf("%s: Small control group (n=%d)", study_label, outcome$n_control))
  }

  # Sample size warnings for n<100
  if(outcome$n_treatment < 100 || outcome$n_control < 100) {
    validation_result$warnings <- c(validation_result$warnings,
      sprintf("%s: Sample size <100, consider sensitivity analysis", study_label))
  }

  # Zero events
  if(outcome$events_treatment == 0 || outcome$events_control == 0) {
    validation_result$warnings <- c(validation_result$warnings,
      sprintf("%s: Zero events detected, continuity correction will be applied", study_label))
  }

  # Double-zero studies
  if(outcome$events_treatment == 0 && outcome$events_control == 0) {
    validation_result$suggestions <- c(validation_result$suggestions,
      sprintf("%s: Double-zero study, consider excluding per Cochrane Handbook 10.4.4", study_label))
  }
}

cat(sprintf("  ✓ Checked %d studies for quality issues\n", nrow(dataset$outcomes)))
cat("\n")

# 3. Statistical Requirements
cat("3. STATISTICAL REQUIREMENTS\n")

total_participants <- sum(dataset$outcomes$n_treatment) + sum(dataset$outcomes$n_control)
cat(sprintf("  Total participants: %d\n", total_participants))

if(total_participants < 100) {
  validation_result$warnings <- c(validation_result$warnings,
    "Small total sample size (n<100). Meta-analysis may be underpowered.")
}

# Check year distribution
years <- dataset$studies$year
median_year <- median(years)
old_studies <- dataset$studies[dataset$studies$year < median_year - 10,]

if(nrow(old_studies) > 0) {
  validation_result$suggestions <- c(validation_result$suggestions,
    sprintf("%d studies are >10 years older than median. Consider subgroup analysis by year.", nrow(old_studies)))
}

cat(sprintf("  Year range: %d - %d\n", min(years), max(years)))
cat("\n")

# 4. Cochrane Standards
cat("4. COCHRANE STANDARDS\n")

# Check for DOIs
studies_without_doi <- dataset$studies[dataset$studies$doi == "",]
if(nrow(studies_without_doi) > 0) {
  validation_result$suggestions <- c(validation_result$suggestions,
    sprintf("%d studies missing DOI. Add DOIs for better traceability.", nrow(studies_without_doi)))
  cat(sprintf("  ⚠️  %d studies missing DOI\n", nrow(studies_without_doi)))
}

# Standard recommendations
validation_result$suggestions <- c(validation_result$suggestions,
  "Perform risk of bias assessment using Cochrane RoB 2 tool for RCTs or ROBINS-I for non-randomized studies")

validation_result$suggestions <- c(validation_result$suggestions,
  "Consider GRADE assessment to evaluate certainty of evidence")

cat("  ✓ Cochrane standards checked\n")
cat("\n")

# Final validity
validation_result$valid <- length(validation_result$errors) == 0

# Print results
cat("═══════════════════════════════════════════════════════════════════════\n")
cat("VALIDATION RESULTS:\n")
cat("═══════════════════════════════════════════════════════════════════════\n\n")

if(length(validation_result$errors) > 0) {
  cat(sprintf("❌ ERRORS (%d):\n", length(validation_result$errors)))
  for(err in validation_result$errors) {
    cat(sprintf("  • %s\n", err))
  }
  cat("\n")
}

if(length(validation_result$warnings) > 0) {
  cat(sprintf("⚠️  WARNINGS (%d):\n", length(validation_result$warnings)))
  for(warn in validation_result$warnings) {
    cat(sprintf("  • %s\n", warn))
  }
  cat("\n")
}

if(length(validation_result$suggestions) > 0) {
  cat(sprintf("💡 SUGGESTIONS (%d):\n", length(validation_result$suggestions)))
  for(sug in validation_result$suggestions) {
    cat(sprintf("  • %s\n", sug))
  }
  cat("\n")
}

cat("📊 SUMMARY:\n")
cat(sprintf("  Valid: %s\n", ifelse(validation_result$valid, "✅ YES", "❌ NO")))
cat(sprintf("  Errors: %d\n", length(validation_result$errors)))
cat(sprintf("  Warnings: %d\n", length(validation_result$warnings)))
cat(sprintf("  Suggestions: %d\n", length(validation_result$suggestions)))
cat("\n")

# Save validation result
saveRDS(validation_result, "validation_result.rds")
cat("✓ Validation result saved to validation_result.rds\n\n")

if(validation_result$valid) {
  cat("═══════════════════════════════════════════════════════════════════════\n")
  cat("TEST STEP 2: ✅ PASSED\n")
  cat("═══════════════════════════════════════════════════════════════════════\n\n")
  quit(status = 0)
} else {
  cat("═══════════════════════════════════════════════════════════════════════\n")
  cat("TEST STEP 2: ❌ FAILED (Validation errors detected)\n")
  cat("═══════════════════════════════════════════════════════════════════════\n\n")
  quit(status = 1)
}
