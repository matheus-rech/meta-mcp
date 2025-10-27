# Cochrane Meta-Analysis MCP Server - Usage Examples

## Quick Start Guide

### 1. Basic Meta-Analysis Workflow

#### Step 1: Import Data
```
User: Import the CSV file at examples/sample_data.csv

Claude uses: import_revman_data
{
  "file_path": "examples/sample_data.csv",
  "format": "csv"
}

Result: 5 studies imported successfully
```

#### Step 2: Validate Data
```
User: Validate this data

Claude uses: validate_cochrane_data
{
  "data": {...imported data...},
  "validation_level": "comprehensive"
}

Result: Data validated with 0 errors, 2 warnings
- Warning: study01 has small sample events
- Suggestion: Add DOIs for better traceability
```

#### Step 3: Perform Meta-Analysis
```
User: Run a random-effects meta-analysis using odds ratios

Claude uses: perform_meta_analysis
{
  "data": {...validated data...},
  "effect_measure": "OR",
  "model": "random"
}

Result:
- Pooled OR: 0.72 (95% CI: 0.59-0.88)
- I²: 42% (moderate heterogeneity)
- Q-test p=0.08
```

#### Step 4: Generate Forest Plot
```
User: Create a forest plot at outputs/forest.png

Claude uses: generate_forest_plot
{
  "analysis_results": {...results...},
  "output_path": "outputs/forest.png"
}

Result: Forest plot generated (PNG, 300 DPI)
```

#### Step 5: Assess Publication Bias
```
User: Check for publication bias

Claude uses: assess_publication_bias
{
  "analysis_results": {...results...},
  "methods": ["funnel_plot", "egger_test", "trim_fill"],
  "output_path": "outputs/funnel.png"
}

Result:
- Egger's test: p=0.35 (no bias)
- Trim-and-fill: 0 missing studies
- Funnel plot: outputs/funnel.png
```

#### Step 6: Generate Report
```
User: Generate a comprehensive HTML report

Claude uses: generate_cochrane_report
{
  "analysis_results": {...results...},
  "format": "html",
  "include_code": true,
  "output_path": "outputs/report.html"
}

Result: Report generated at outputs/report.html
```

## Advanced Scenarios

### Continuous Outcomes

CSV format for continuous data:
```csv
study_id,authors,year,title,intervention,comparison,outcome,mean_treatment,sd_treatment,n_treatment,mean_control,sd_control,n_control
study01,Smith 2020,2020,Pain study,Drug,Placebo,Pain score,45.2,12.3,100,52.1,11.8,100
study02,Jones 2021,2021,Pain trial,Drug,Placebo,Pain score,43.5,10.2,80,51.3,12.1,80
```

Use with Standardized Mean Difference (SMD):
```
User: Analyze this continuous outcome data using SMD

Claude uses: perform_meta_analysis
{
  "data": {...},
  "effect_measure": "SMD",
  "model": "random"
}
```

### Subgroup Analysis

```
User: I want to compare effects in studies from before 2020 vs after 2020

Claude: I'll need to split the data by publication year and run separate
meta-analyses for each subgroup, then compare the pooled effects.

[Runs two separate analyses]

Result:
- Pre-2020: OR 0.78 (95% CI: 0.62-0.98), I²=35%
- Post-2020: OR 0.68 (95% CI: 0.51-0.90), I²=48%
- No significant difference between subgroups (p=0.42)
```

### Sensitivity Analysis

```
User: Exclude studies with high risk of bias and re-run the analysis

Claude: I'll remove studies marked as high risk and perform the analysis
on the remaining studies to test robustness.

[Filters data and re-runs analysis]

Result:
- Original: OR 0.72 (95% CI: 0.59-0.88)
- Sensitivity: OR 0.69 (95% CI: 0.54-0.88)
- Conclusion: Results are robust to exclusion of high-risk studies
```

## Integration with Existing Tools

### Using with Medical Paper Extraction

```
User: Extract data from these 10 PDFs and run a meta-analysis

Claude:
1. [Uses medical research multi-agent system to extract data]
2. [Converts extracted data to Cochrane CSV format]
3. [Uses import_revman_data]
4. [Uses validate_cochrane_data]
5. [Uses perform_meta_analysis]
6. [Generates visualizations and report]

Result: Complete meta-analysis from raw PDFs to publication-ready outputs
```

### Using with R Meta-Analysis Tools

```
User: Use my existing R scripts at ~/meta_analysis_workflow.R

Claude: I'll integrate your custom R functions with the MCP tools.
The R bridge can execute your existing scripts while providing
the MCP interface for Claude Code integration.

[Modifies R bridge to source custom scripts]
[Executes analysis using existing workflows]
```

## Tips for Best Results

### 1. Data Preparation
- Ensure study IDs are unique
- Include DOIs when available
- Verify all numeric data is complete
- Use consistent outcome names

### 2. Effect Measure Selection
- **Binary outcomes**: OR (case-control), RR (cohorts/RCTs)
- **Continuous outcomes**: MD (same scale), SMD (different scales)
- **Time-to-event**: HR (hazard ratio)

### 3. Model Selection
- **Fixed-effect**: Use when I² < 25% and studies are very similar
- **Random-effects**: Default choice, accounts for between-study variation
- Run both if uncertain and compare results

### 4. Heterogeneity Investigation
- I² > 60%: Investigate through subgroup analysis
- Consider meta-regression for continuous covariates
- Check for outliers using influence diagnostics

### 5. Publication Bias Assessment
- Need at least 10 studies for reliable tests
- Visual inspection of funnel plot is important
- Egger's test p<0.10 suggests potential bias
- Trim-and-fill provides adjusted estimates

## Common Workflows

### Cochrane Review Update
```
1. Import existing RevMan file
2. Add new studies to dataset
3. Validate updated data
4. Re-run meta-analysis
5. Compare with previous results
6. Generate updated forest plot
7. Create change log in report
```

### Rapid Review
```
1. Import CSV with study data
2. Quick validation (basic level)
3. Run fixed-effect analysis
4. Generate forest plot only
5. Skip publication bias (if <10 studies)
6. Generate brief HTML report
```

### Full Systematic Review
```
1. Import comprehensive dataset
2. Comprehensive validation
3. Random-effects meta-analysis
4. Generate forest plot
5. Assess publication bias
6. Subgroup analyses
7. Sensitivity analyses
8. Meta-regression (if data available)
9. Generate full Cochrane-style report
10. GRADE assessment (manual)
```

## Troubleshooting

### "Insufficient studies for test"
- Publication bias tests require ≥3 studies
- Some tests work better with ≥10 studies
- Consider visual assessment only for small meta-analyses

### "Zero events in all arms"
- Double-zero studies excluded automatically
- Single-zero studies get continuity correction (0.5)
- Consider risk difference instead of OR/RR

### "High heterogeneity"
- I² > 75%: Consider not pooling
- Investigate sources through subgroup analysis
- Check for data entry errors
- Consider meta-regression

### "R package not found"
- Install required R packages:
  ```r
  install.packages(c("metafor", "meta", "ggplot2", "jsonlite"))
  ```

## Next Steps

After completing your meta-analysis:

1. **GRADE Assessment**: Evaluate certainty of evidence
2. **Risk of Bias**: Use Cochrane RoB 2 tool
3. **PRISMA**: Create flow diagram for study selection
4. **Registration**: Register protocol (PROSPERO)
5. **Publication**: Submit to Cochrane or peer-reviewed journal

## Support

For issues or questions:
- Check documentation in README.md
- Review Cochrane Handbook Chapter 10
- Consult with statistical expert for complex analyses
