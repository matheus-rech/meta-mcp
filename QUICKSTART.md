# Cochrane Meta-Analysis MCP Server - Quick Start

## 🚀 5-Minute Setup

### Step 1: Build (2 minutes)
```bash
cd ~/Documents/cochrane-meta-mcp
./build.sh
```

### Step 2: Install R Packages (2 minutes)
```bash
R
```
```r
install.packages(c("metafor", "meta", "ggplot2", "jsonlite"))
q()
```

### Step 3: Configure Claude Desktop (1 minute)

Edit `~/.config/claude/claude_desktop_config.json`:

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

**Replace `YOUR_USERNAME` with your actual username!**

### Step 4: Restart Claude Desktop

Quit and relaunch Claude Desktop.

### Step 5: Test It!

In Claude Code, try:
```
Import the CSV file at ~/Documents/cochrane-meta-mcp/examples/sample_data.csv
and run a random-effects meta-analysis using odds ratios
```

## ✅ Verification

Claude should:
1. ✅ Use `import_revman_data` tool
2. ✅ Parse 5 studies from the CSV
3. ✅ Use `validate_cochrane_data` tool
4. ✅ Use `perform_meta_analysis` tool
5. ✅ Report pooled OR with confidence interval
6. ✅ Report heterogeneity statistics

## 🎯 First Real Analysis

### Prepare Your Data

Create a CSV file with your study data:

```csv
study_id,authors,year,title,intervention,comparison,outcome,events_treatment,n_treatment,events_control,n_control
study1,Smith 2020,2020,My RCT,Drug A,Placebo,Mortality,20,100,30,100
study2,Jones 2021,2021,Another RCT,Drug A,Placebo,Mortality,15,80,25,80
```

### Run the Analysis

Ask Claude:
```
I have a CSV file at [path/to/your/file.csv] with RCT data.
Please:
1. Import and validate the data
2. Run a random-effects meta-analysis using odds ratios
3. Generate a forest plot
4. Assess publication bias
5. Create a comprehensive HTML report

Save all outputs to ~/Documents/meta_results/
```

Claude will:
- Import your data
- Validate against Cochrane standards
- Perform the meta-analysis
- Calculate heterogeneity (I², Q-test, τ²)
- Generate forest plot (PNG, 300 DPI)
- Create funnel plot
- Run Egger's test and trim-and-fill
- Generate a complete Cochrane-style report

## 📊 Available Tools

1. **import_revman_data** - Import RevMan/CSV files
2. **validate_cochrane_data** - Validate study data
3. **perform_meta_analysis** - Run statistical analysis
4. **generate_forest_plot** - Create forest plots
5. **assess_publication_bias** - Test for publication bias
6. **generate_cochrane_report** - Generate reports

## 💡 Pro Tips

### Tip 1: Use Existing Data
```
Use the sample data at examples/sample_data.csv to test
```

### Tip 2: Specify Your Preferences
```
Use a fixed-effect model instead of random-effects
```

### Tip 3: Get Recommendations
```
What effect measure should I use for binary outcomes in a case-control study?
```

### Tip 4: Interpret Results
```
My I² is 68%. What does this mean and what should I do?
```

### Tip 5: Troubleshoot
```
I'm getting a warning about zero events. How should I handle this?
```

## 🔧 Common Commands

### Import Data
```
Import the RevMan file at /path/to/review.rm5
```

### Validate Data
```
Validate this data comprehensively
```

### Run Analysis
```
Perform a random-effects meta-analysis using odds ratios
```

### Generate Plots
```
Create a forest plot and save it to ~/Desktop/forest.png
```

### Check Publication Bias
```
Assess publication bias using all available methods
```

### Generate Report
```
Generate an HTML report with R code included
```

## 🐛 Troubleshooting

### "MCP server not found"
- Check Claude Desktop config path
- Verify JSON syntax (no trailing commas!)
- Restart Claude Desktop

### "R package not found"
```r
install.packages(c("metafor", "meta", "ggplot2", "jsonlite"))
```

### "Build failed"
```bash
npm install
npm run build
```

### "Cannot find module"
- Check that dist/index.js exists
- Rebuild: `./build.sh`

## 📚 Learn More

- **Full Documentation**: README.md
- **Detailed Examples**: examples/example_usage.md
- **Configuration Help**: CLAUDE_DESKTOP_CONFIG.md
- **Project Status**: PROJECT_STATUS.md
- **Cochrane Handbook**: Chapter 10

## 🎓 Example Questions for Claude

"Walk me through a complete meta-analysis workflow"

"What's the difference between fixed and random-effects models?"

"How do I interpret an I² of 75%?"

"Should I use OR or RR for my cohort study?"

"How many studies do I need for a reliable meta-analysis?"

"What publication bias tests should I use?"

"How do I handle studies with zero events?"

"Generate a sample CSV format for continuous outcomes"

## 🎉 You're Ready!

You now have a fully functional Cochrane-compliant meta-analysis system integrated with Claude Code. The AI will guide you through each step of your analysis, following best practices from the Cochrane Handbook.

Happy analyzing! 🔬📊
