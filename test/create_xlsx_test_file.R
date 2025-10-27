#!/usr/bin/env Rscript

#' Create Real XLSX Test File
#' Converts existing CSV test data to Excel format

# Install writexl if not available
if (!requireNamespace("writexl", quietly = TRUE)) {
  cat("Installing writexl package...\n")
  install.packages("writexl", repos = "https://cloud.r-project.org")
}

library(writexl)

# Read the comprehensive CSV test data
csv_data <- read.csv("test/comprehensive_test_data.csv", stringsAsFactors = FALSE)

cat(sprintf("Read %d rows from CSV\n", nrow(csv_data)))
cat(sprintf("Columns: %s\n", paste(names(csv_data), collapse = ", ")))

# Write to Excel format
output_file <- "test/comprehensive_test_data.xlsx"
write_xlsx(csv_data, output_file)

cat(sprintf("✓ Created XLSX file: %s\n", output_file))

# Verify the file was created
if (file.exists(output_file)) {
  file_size <- file.info(output_file)$size
  cat(sprintf("✓ File size: %d bytes\n", file_size))

  # Verify we can read it back
  library(readxl)
  readback <- read_excel(output_file)

  cat(sprintf("✓ Verified: Read back %d rows\n", nrow(readback)))
  cat(sprintf("✓ Columns match: %s\n",
              ifelse(all(names(csv_data) == names(readback)), "YES", "NO")))

  # Show sample data
  cat("\n=== First 2 rows ===\n")
  print(head(readback, 2))

  cat("\n✅ XLSX test file created successfully!\n")
} else {
  stop("❌ Failed to create XLSX file")
}
