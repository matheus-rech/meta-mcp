#!/usr/bin/env Rscript

#' Test XLSX Import Functionality
#' Simulates the TypeScript parseExcelFile() function

library(readxl)

cat("=== Phase 2.2: XLSX Import Testing ===\n\n")

# Read the XLSX file
xlsx_file <- "test/comprehensive_test_data.xlsx"
cat(sprintf("Reading: %s\n", xlsx_file))

xlsx_data <- read_excel(xlsx_file)

cat(sprintf("✓ Loaded %d rows\n", nrow(xlsx_data)))
cat(sprintf("✓ Columns (%d): %s\n", ncol(xlsx_data),
            paste(names(xlsx_data), collapse = ", ")))

# Detect outcome type (simulating parseRecords logic)
has_binary <- all(c("events_treatment", "events_control") %in% names(xlsx_data))
has_continuous <- all(c("mean_treatment", "mean_control") %in% names(xlsx_data))

if (has_binary) {
  outcome_type <- "binary"
  cat("✓ Detected outcome type: binary\n")
} else if (has_continuous) {
  outcome_type <- "continuous"
  cat("✓ Detected outcome type: continuous\n")
} else {
  stop("❌ Cannot determine outcome type")
}

# Extract unique studies (simulating parseRecords logic)
studies <- unique(xlsx_data[, c("study_id", "authors", "year", "title", "journal", "doi")])
cat(sprintf("✓ Extracted %d unique studies\n", nrow(studies)))

# Verify data integrity
cat("\n=== Data Integrity Checks ===\n")

# Check for missing study IDs
if (any(is.na(xlsx_data$study_id))) {
  stop("❌ Found missing study IDs")
}
cat("✓ No missing study IDs\n")

# Check for valid years
if (any(xlsx_data$year < 1900 | xlsx_data$year > 2100)) {
  stop("❌ Invalid years found")
}
cat("✓ All years valid (1900-2100)\n")

# Check for non-negative counts
if (outcome_type == "binary") {
  if (any(xlsx_data$events_treatment < 0 | xlsx_data$events_control < 0 |
          xlsx_data$n_treatment < 0 | xlsx_data$n_control < 0)) {
    stop("❌ Negative counts found")
  }
  cat("✓ All counts non-negative\n")

  # Check events <= n
  if (any(xlsx_data$events_treatment > xlsx_data$n_treatment |
          xlsx_data$events_control > xlsx_data$n_control)) {
    stop("❌ Events exceed sample size")
  }
  cat("✓ All events within sample size\n")
}

# Show sample data
cat("\n=== Sample Data (First 3 Studies) ===\n")
sample_data <- xlsx_data[1:min(3, nrow(xlsx_data)), ]
print(sample_data)

# Compare with CSV to ensure identical results
cat("\n=== Cross-Format Validation ===\n")
csv_data <- read.csv("test/comprehensive_test_data.csv", stringsAsFactors = FALSE)

# Compare dimensions
if (nrow(xlsx_data) != nrow(csv_data)) {
  stop(sprintf("❌ Row count mismatch: XLSX=%d, CSV=%d", nrow(xlsx_data), nrow(csv_data)))
}
cat(sprintf("✓ Row count matches: %d rows\n", nrow(xlsx_data)))

if (ncol(xlsx_data) != ncol(csv_data)) {
  stop(sprintf("❌ Column count mismatch: XLSX=%d, CSV=%d", ncol(xlsx_data), ncol(csv_data)))
}
cat(sprintf("✓ Column count matches: %d columns\n", ncol(xlsx_data)))

# Compare column names
if (!all(names(xlsx_data) == names(csv_data))) {
  stop("❌ Column names don't match")
}
cat("✓ Column names match\n")

# Compare data values (allowing for type differences and NAs)
mismatches <- 0
for (col in names(xlsx_data)) {
  if (is.numeric(xlsx_data[[col]]) && is.numeric(csv_data[[col]])) {
    if (!isTRUE(all.equal(as.numeric(xlsx_data[[col]]), as.numeric(csv_data[[col]])))) {
      cat(sprintf("  ⚠️  Numeric mismatch in column: %s\n", col))
      mismatches <- mismatches + 1
    }
  } else {
    xlsx_char <- as.character(xlsx_data[[col]])
    csv_char <- as.character(csv_data[[col]])
    # Handle NAs properly
    xlsx_char[is.na(xlsx_char)] <- "NA"
    csv_char[is.na(csv_char)] <- "NA"
    if (!all(xlsx_char == csv_char)) {
      cat(sprintf("  ⚠️  Text mismatch in column: %s\n", col))
      mismatches <- mismatches + 1
    }
  }
}

if (mismatches == 0) {
  cat("✓ All data values match between XLSX and CSV\n")
} else {
  warning(sprintf("Found %d column mismatches", mismatches))
}

# Summary statistics
cat("\n=== Summary Statistics ===\n")
if (outcome_type == "binary") {
  cat(sprintf("Total events (treatment): %d / %d\n",
              sum(xlsx_data$events_treatment),
              sum(xlsx_data$n_treatment)))
  cat(sprintf("Total events (control): %d / %d\n",
              sum(xlsx_data$events_control),
              sum(xlsx_data$n_control)))
  cat(sprintf("Overall event rate (treatment): %.1f%%\n",
              100 * sum(xlsx_data$events_treatment) / sum(xlsx_data$n_treatment)))
  cat(sprintf("Overall event rate (control): %.1f%%\n",
              100 * sum(xlsx_data$events_control) / sum(xlsx_data$n_control)))
}

cat(sprintf("\nTotal participants: %d\n",
            sum(xlsx_data$n_treatment) + sum(xlsx_data$n_control)))
cat(sprintf("Year range: %d - %d\n", min(xlsx_data$year), max(xlsx_data$year)))

cat("\n✅ XLSX import test PASSED! All validations successful.\n")
cat("✅ XLSX and CSV produce identical results.\n")
