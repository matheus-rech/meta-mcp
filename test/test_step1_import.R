#!/usr/bin/env Rscript

# TEST STEP 1: Import and Parse Data
# Simulates the import_revman_data MCP tool

cat("╔═══════════════════════════════════════════════════════════════════════╗\n")
cat("║  TEST STEP 1: IMPORT AND PARSE DATA                                  ║\n")
cat("╚═══════════════════════════════════════════════════════════════════════╝\n\n")

cat("Tool: import_revman_data\n")
cat("Input: {file_path: 'comprehensive_test_data.csv', format: 'csv'}\n\n")

# Read CSV
data <- tryCatch({
  read.csv("comprehensive_test_data.csv", stringsAsFactors = FALSE)
}, error = function(e) {
  cat("❌ ERROR: Failed to read CSV file\n")
  cat("  ", e$message, "\n")
  quit(status = 1)
})

cat("✓ CSV file read successfully\n\n")

# Parse and validate structure
expected_columns <- c("study_id", "authors", "year", "title", "journal", "doi",
                      "intervention", "comparison", "outcome",
                      "events_treatment", "n_treatment", "events_control", "n_control")

missing_cols <- setdiff(expected_columns, names(data))
if(length(missing_cols) > 0) {
  cat("❌ ERROR: Missing required columns:", paste(missing_cols, collapse=", "), "\n")
  quit(status = 1)
}

cat("✓ All required columns present\n\n")

# Extract studies
studies <- data.frame(
  id = data$study_id,
  authors = data$authors,
  year = data$year,
  title = data$title,
  journal = data$journal,
  doi = data$doi,
  stringsAsFactors = FALSE
)

cat("📊 PARSED STUDIES:\n")
for(i in 1:nrow(studies)) {
  cat(sprintf("  %d. %s (%d) - %s\n", i, studies$authors[i], studies$year[i], studies$id[i]))
}
cat("\n")

# Extract outcomes
outcomes <- data.frame(
  study_id = data$study_id,
  events_treatment = as.integer(data$events_treatment),
  n_treatment = as.integer(data$n_treatment),
  events_control = as.integer(data$events_control),
  n_control = as.integer(data$n_control),
  stringsAsFactors = FALSE
)

# Detect outcome type
outcome_type <- "binary"  # We know this from the presence of events columns

cat("📊 PARSED OUTCOMES:\n")
cat(sprintf("  Type: %s\n", outcome_type))
cat(sprintf("  Number of outcomes: %d\n", nrow(outcomes)))
cat("\n")

# Check for data consistency
if(nrow(studies) != nrow(outcomes)) {
  cat("⚠️  WARNING: Number of studies doesn't match number of outcomes\n\n")
}

# Validate numeric values
if(any(is.na(outcomes$events_treatment)) ||
   any(is.na(outcomes$n_treatment)) ||
   any(is.na(outcomes$events_control)) ||
   any(is.na(outcomes$n_control))) {
  cat("❌ ERROR: Missing or invalid numeric values in outcomes\n")
  quit(status = 1)
}

cat("✓ All numeric values are valid\n\n")

# Create dataset object
dataset <- list(
  studies = studies,
  outcomes = outcomes,
  outcome_type = outcome_type,
  outcome_name = "All-cause mortality",
  intervention = data$intervention[1],
  comparison = data$comparison[1]
)

# Summary
cat("📋 IMPORT SUMMARY:\n")
cat(sprintf("  ✓ Studies imported: %d\n", nrow(studies)))
cat(sprintf("  ✓ Outcomes parsed: %d\n", nrow(outcomes)))
cat(sprintf("  ✓ Outcome type: %s\n", outcome_type))
cat(sprintf("  ✓ Intervention: %s\n", dataset$intervention))
cat(sprintf("  ✓ Comparison: %s\n", dataset$comparison))
cat("\n")

# Save parsed dataset for next step
saveRDS(dataset, "parsed_dataset.rds")
cat("✓ Dataset saved to parsed_dataset.rds\n\n")

cat("═══════════════════════════════════════════════════════════════════════\n")
cat("TEST STEP 1: ✅ PASSED\n")
cat("═══════════════════════════════════════════════════════════════════════\n\n")
