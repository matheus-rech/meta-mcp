import { spawn } from "child_process";
import { writeFileSync, readFileSync, unlinkSync } from "fs";
import { join } from "path";
import { tmpdir } from "os";
import { logger } from "../utils/logger.js";

/**
 * Execute R scripts and return results
 */
export class RExecutor {
  private rScriptPath: string;

  constructor() {
    // Use Rscript from PATH
    this.rScriptPath = "Rscript";
  }

  /**
   * Execute R code and return JSON result
   */
  async execute(rCode: string): Promise<any> {
    const tempScriptPath = join(tmpdir(), `cochrane_meta_${Date.now()}.R`);
    const tempOutputPath = join(tmpdir(), `cochrane_meta_output_${Date.now()}.json`);

    try {
      // Write R script to temp file
      writeFileSync(tempScriptPath, rCode);

      logger.info(`Executing R script: ${tempScriptPath}`);

      // Execute R script
      const output = await this.runRScript(tempScriptPath);

      logger.info("R script completed successfully");

      // Try to read JSON output if it exists
      try {
        const result = readFileSync(tempOutputPath, "utf-8");
        unlinkSync(tempOutputPath);
        return JSON.parse(result);
      } catch (err) {
        // If no JSON output file, return stdout
        return { output, success: true };
      }
    } catch (error) {
      logger.error("R execution error:", error);
      throw error;
    } finally {
      // Cleanup temp files
      try {
        unlinkSync(tempScriptPath);
      } catch (err) {
        // Ignore cleanup errors
      }
    }
  }

  /**
   * Run Rscript command
   */
  private runRScript(scriptPath: string): Promise<string> {
    return new Promise((resolve, reject) => {
      const process = spawn(this.rScriptPath, [scriptPath]);
      let stdout = "";
      let stderr = "";

      process.stdout.on("data", (data) => {
        stdout += data.toString();
      });

      process.stderr.on("data", (data) => {
        stderr += data.toString();
      });

      process.on("close", (code) => {
        if (code !== 0) {
          reject(new Error(`R script failed with code ${code}:\n${stderr}`));
        } else {
          resolve(stdout);
        }
      });

      process.on("error", (err) => {
        reject(new Error(`Failed to start R process: ${err.message}`));
      });
    });
  }

  /**
   * Check if R is available
   */
  async checkR(): Promise<boolean> {
    try {
      const version = await this.runRScript(
        join(tmpdir(), `check_r_${Date.now()}.R`)
      );
      return true;
    } catch (error) {
      return false;
    }
  }

  /**
   * Check if required R packages are installed
   */
  async checkPackages(): Promise<{
    meta: boolean;
    metafor: boolean;
    ggplot2: boolean;
  }> {
    const checkScript = `
      cat(jsonlite::toJSON(list(
        meta = require("meta", quietly = TRUE),
        metafor = require("metafor", quietly = TRUE),
        ggplot2 = require("ggplot2", quietly = TRUE)
      )))
    `;

    try {
      const result = await this.execute(checkScript);
      return result;
    } catch (error) {
      return { meta: false, metafor: false, ggplot2: false };
    }
  }
}

export const rExecutor = new RExecutor();
