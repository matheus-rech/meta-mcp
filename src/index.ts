#!/usr/bin/env node

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  Tool,
} from "@modelcontextprotocol/sdk/types.js";
import { logger } from "./utils/logger.js";
import { importRevManTool } from "./tools/import_revman.js";
import { validateDataTool } from "./tools/validation.js";
import { performMetaAnalysisTool } from "./tools/meta_analysis.js";
import { generateForestPlotTool } from "./tools/forest_plot.js";
import { assessPublicationBiasTool } from "./tools/publication_bias.js";
import { generateReportTool } from "./tools/reporting.js";

/**
 * Cochrane Meta-Analysis MCP Server
 *
 * Provides AI-assisted meta-analysis workflows following Cochrane methodological standards.
 * Integrates with R statistical environment and existing meta-analysis infrastructure.
 */

const server = new Server(
  {
    name: "cochrane-meta-mcp",
    version: "0.1.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Define available tools
const tools: Tool[] = [
  {
    name: "import_revman_data",
    description: "Import and parse meta-analysis data from CSV, Excel (XLSX), or JSON formats. Supports both structured Cochrane datasets and flat record arrays. Extracts study metadata, outcomes, and analysis parameters following Cochrane standards.",
    inputSchema: {
      type: "object",
      properties: {
        file_path: {
          type: "string",
          description: "Path to data file (.csv, .xlsx, or .json)",
        },
        format: {
          type: "string",
          enum: ["csv", "xlsx", "json"],
          description: "Input file format: 'csv' for comma-separated values, 'xlsx' for Excel workbooks, 'json' for structured or array format JSON",
        },
      },
      required: ["file_path", "format"],
    },
  },
  {
    name: "validate_cochrane_data",
    description: "Validate study data against Cochrane standards. Checks PICO criteria, sample sizes, effect sizes, and data quality.",
    inputSchema: {
      type: "object",
      properties: {
        data: {
          type: "object",
          description: "Study data to validate",
        },
        validation_level: {
          type: "string",
          enum: ["basic", "comprehensive"],
          description: "Level of validation checks",
          default: "comprehensive",
        },
      },
      required: ["data"],
    },
  },
  {
    name: "perform_meta_analysis",
    description: "Execute meta-analysis using R metafor/meta packages. Follows Cochrane Handbook Chapter 10 guidelines.",
    inputSchema: {
      type: "object",
      properties: {
        data: {
          type: "object",
          description: "Validated study data",
        },
        effect_measure: {
          type: "string",
          enum: ["OR", "RR", "MD", "SMD", "HR"],
          description: "Effect measure type",
        },
        model: {
          type: "string",
          enum: ["fixed", "random"],
          description: "Meta-analysis model",
          default: "random",
        },
        heterogeneity_test: {
          type: "boolean",
          description: "Perform heterogeneity assessment (I², Q-test, τ²)",
          default: true,
        },
      },
      required: ["data", "effect_measure"],
    },
  },
  {
    name: "generate_forest_plot",
    description: "Create publication-ready forest plot following Cochrane standards.",
    inputSchema: {
      type: "object",
      properties: {
        analysis_results: {
          type: "object",
          description: "Meta-analysis results",
        },
        plot_style: {
          type: "string",
          enum: ["classic", "modern"],
          description: "Visual style of forest plot",
          default: "classic",
        },
        confidence_level: {
          type: "number",
          description: "Confidence interval level (0-1)",
          default: 0.95,
        },
        output_path: {
          type: "string",
          description: "Path to save plot (PNG format, 300 DPI)",
        },
      },
      required: ["analysis_results", "output_path"],
    },
  },
  {
    name: "assess_publication_bias",
    description: "Perform publication bias assessment using funnel plots, Egger's test, and trim-and-fill method.",
    inputSchema: {
      type: "object",
      properties: {
        analysis_results: {
          type: "object",
          description: "Meta-analysis results",
        },
        methods: {
          type: "array",
          items: {
            type: "string",
            enum: ["funnel_plot", "egger_test", "begg_test", "trim_fill"],
          },
          description: "Publication bias assessment methods",
          default: ["funnel_plot", "egger_test"],
        },
        output_path: {
          type: "string",
          description: "Path to save funnel plot",
        },
      },
      required: ["analysis_results"],
    },
  },
  {
    name: "generate_cochrane_report",
    description: "Generate comprehensive meta-analysis report in Cochrane format (HTML/PDF).",
    inputSchema: {
      type: "object",
      properties: {
        analysis_results: {
          type: "object",
          description: "Complete meta-analysis results",
        },
        format: {
          type: "string",
          enum: ["html", "pdf"],
          description: "Report format",
          default: "html",
        },
        include_code: {
          type: "boolean",
          description: "Include R code in report",
          default: false,
        },
        output_path: {
          type: "string",
          description: "Path to save report",
        },
      },
      required: ["analysis_results", "output_path"],
    },
  },
];

// List tools handler
server.setRequestHandler(ListToolsRequestSchema, async () => {
  logger.info("Listing available tools");
  return { tools };
});

// Call tool handler
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  logger.info(`Calling tool: ${name}`, { args });

  try {
    switch (name) {
      case "import_revman_data":
        return await importRevManTool(args);

      case "validate_cochrane_data":
        return await validateDataTool(args);

      case "perform_meta_analysis":
        return await performMetaAnalysisTool(args);

      case "generate_forest_plot":
        return await generateForestPlotTool(args);

      case "assess_publication_bias":
        return await assessPublicationBiasTool(args);

      case "generate_cochrane_report":
        return await generateReportTool(args);

      default:
        throw new Error(`Unknown tool: ${name}`);
    }
  } catch (error) {
    logger.error(`Error executing tool ${name}:`, error);
    return {
      content: [
        {
          type: "text",
          text: `Error: ${error instanceof Error ? error.message : String(error)}`,
        },
      ],
      isError: true,
    };
  }
});

// Start server
async function main() {
  const transport = new StdioServerTransport();

  logger.info("Starting Cochrane Meta-Analysis MCP Server");

  await server.connect(transport);

  logger.info("Server running on stdio");
}

main().catch((error) => {
  logger.error("Fatal error:", error);
  process.exit(1);
});
