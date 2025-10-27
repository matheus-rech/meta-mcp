# Cochrane Meta-Analysis MCP Server

An MCP (Model Context Protocol) server that provides AI-assisted meta-analysis workflows following Cochrane methodological standards.

## Features

- **RevMan Import**: Parse RevMan 5 (.rm5 XML) and Cochrane CSV exports
- **Data Validation**: Comprehensive validation against Cochrane standards
- **Meta-Analysis**: R-based statistical analysis using metafor/meta packages
- **Forest Plots**: Publication-ready visualizations
- **Publication Bias**: Funnel plots, Egger's test, trim-and-fill
- **Reporting**: Automated Cochrane-style HTML/PDF reports

## Installation

```bash
npm install
npm run build
```

### Prerequisites

1. **Node.js** 18+
2. **R** 4.0+ with packages:
   - metafor
   - meta
   - ggplot2
   - jsonlite

Install R packages:
```r
install.packages(c("metafor", "meta", "ggplot2", "jsonlite"))
```

## Configuration

Add to Claude Desktop config (`~/.config/claude/claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "cochrane-meta": {
      "command": "node",
      "args": ["/Users/YOUR_USERNAME/Documents/cochrane-meta-mcp/dist/index.js"]
    }
  }
}
```

## Available Tools

### 1. import_revman_data
Import and parse RevMan 5 files or Cochrane CSV exports.

```json
{
  "file_path": "/path/to/review.rm5",
  "format": "rm5"
}
```

### 2. validate_cochrane_data
Validate study data against Cochrane standards.

```json
{
  "data": { ... },
  "validation_level": "comprehensive"
}
```

### 3. perform_meta_analysis
Execute meta-analysis following Cochrane Handbook Chapter 10.

```json
{
  "data": { ... },
  "effect_measure": "OR",
  "model": "random",
  "heterogeneity_test": true
}
```

### 4. generate_forest_plot
Create publication-ready forest plot.

```json
{
  "analysis_results": { ... },
  "plot_style": "classic",
  "output_path": "/path/to/forest_plot.png"
}
```

### 5. assess_publication_bias
Perform publication bias assessment.

```json
{
  "analysis_results": { ... },
  "methods": ["funnel_plot", "egger_test", "trim_fill"],
  "output_path": "/path/to/funnel_plot.png"
}
```

### 6. generate_cochrane_report
Generate comprehensive Cochrane-style report.

```json
{
  "analysis_results": { ... },
  "format": "html",
  "output_path": "/path/to/report.html"
}
```

## Example Usage with Claude

```
User: I have a Cochrane CSV file with 10 RCTs comparing intervention A vs control.
      Can you help me run a meta-analysis?

Claude: I'll help you analyze this. First, let me import the data using the import_revman_data tool...

[Uses import_revman_data]

Claude: Great! I've imported 10 studies. Let me validate the data...

[Uses validate_cochrane_data]

Claude: Validation passed with 2 warnings about small sample sizes.
        Now I'll perform the meta-analysis using a random-effects model
        with odds ratios as the effect measure...

[Uses perform_meta_analysis]

Claude: The pooled OR is 0.75 (95% CI: 0.62-0.91), p=0.003, with moderate
        heterogeneity (I²=45%). Let me generate a forest plot...

[Uses generate_forest_plot]

Claude: Forest plot created. Now checking for publication bias...

[Uses assess_publication_bias]

Claude: Egger's test p=0.42, no evidence of publication bias.
        Generating final report...

[Uses generate_cochrane_report]

Claude: Complete! Your meta-analysis report is ready at report.html
```

## CSV Format

For CSV imports, use this format:

```csv
study_id,authors,year,title,intervention,comparison,outcome,events_treatment,n_treatment,events_control,n_control
Study1,Smith 2020,2020,RCT of intervention,Drug A,Placebo,Mortality,10,100,20,100
Study2,Jones 2021,2021,Another RCT,Drug A,Placebo,Mortality,15,150,30,150
```

For continuous outcomes:
```csv
study_id,authors,year,title,intervention,comparison,outcome,mean_treatment,sd_treatment,n_treatment,mean_control,sd_control,n_control
```

## Development

```bash
# Watch mode
npm run dev

# Build
npm run build

# Test (coming soon)
npm test
```

## Architecture

- **TypeScript MCP Server**: Handles tool requests from Claude
- **R Bridge**: Executes statistical analyses via Rscript
- **Validation Layer**: Zod schemas for data validation
- **Tools**: Modular tool implementations for each MCP capability

## Integration with Existing Tools

This MCP server integrates with your existing meta-analysis infrastructure:

- Uses your R meta-analysis scripts (`~/meta_analysis_workflow.R`)
- Compatible with medical research multi-agent system
- Can leverage AI citation processors for literature extraction

## Cochrane Compliance

Follows:
- Cochrane Handbook for Systematic Reviews (Chapter 10)
- PRISMA reporting guidelines
- Cochrane risk of bias (RoB 2) recommendations
- GRADE framework for evidence certainty

## License

MIT

## Version

0.1.0

## Author

Matheus Rech
