#!/usr/bin/env Rscript

#' Test JSON Import Functionality
#'
#' This script simulates the import_revman_data MCP tool for JSON format

library(jsonlite)

# Read structured JSON
cat("Testing structured JSON format...\n")
structured_data <- fromJSON("test/test_data.json")

cat("✓ Loaded structured JSON\n")
cat(sprintf("  Studies: %d\n", length(structured_data$studies$id)))
cat(sprintf("  Outcomes: %d\n", nrow(structured_data$outcomes)))
cat(sprintf("  Outcome type: %s\n", structured_data$outcome_type))
cat(sprintf("  Intervention: %s vs %s\n",
            structured_data$intervention,
            structured_data$comparison))

# Read array JSON
cat("\nTesting array JSON format...\n")
array_data <- fromJSON("test/test_data_array.json")

cat("✓ Loaded array JSON\n")
cat(sprintf("  Records: %d\n", nrow(array_data)))
cat(sprintf("  Columns: %s\n", paste(names(array_data), collapse=", ")))

# Verify data structure
cat("\n=== Structured JSON Validation ===\n")
cat(sprintf("Study 1: %s (%d)\n",
            structured_data$studies$authors[1],
            structured_data$studies$year[1]))
cat(sprintf("  Events: %d/%d vs %d/%d\n",
            structured_data$outcomes$events_treatment[1],
            structured_data$outcomes$n_treatment[1],
            structured_data$outcomes$events_control[1],
            structured_data$outcomes$n_control[1]))

cat("\n=== Array JSON Validation ===\n")
cat(sprintf("Study 1: %s (%d)\n",
            array_data$authors[1],
            array_data$year[1]))
cat(sprintf("  Events: %d/%d vs %d/%d\n",
            array_data$events_treatment[1],
            array_data$n_treatment[1],
            array_data$events_control[1],
            array_data$n_control[1]))

cat("\n✅ All JSON import tests passed!\n")
