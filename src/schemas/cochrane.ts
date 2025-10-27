import { z } from "zod";

/**
 * Cochrane data validation schemas
 * Based on Cochrane Handbook and RevMan 5 data structures
 */

// Study identification
export const StudySchema = z.object({
  id: z.string(),
  authors: z.string(),
  year: z.number().int().min(1900).max(2100),
  title: z.string(),
  journal: z.string().optional(),
  doi: z.string().optional(),
});

// Outcome data for binary outcomes
export const BinaryOutcomeSchema = z.object({
  study_id: z.string(),
  events_treatment: z.number().int().min(0),
  n_treatment: z.number().int().min(1),
  events_control: z.number().int().min(0),
  n_control: z.number().int().min(1),
});

// Outcome data for continuous outcomes
export const ContinuousOutcomeSchema = z.object({
  study_id: z.string(),
  mean_treatment: z.number(),
  sd_treatment: z.number().positive(),
  n_treatment: z.number().int().min(1),
  mean_control: z.number(),
  sd_control: z.number().positive(),
  n_control: z.number().int().min(1),
});

// Effect size with confidence interval
export const EffectSizeSchema = z.object({
  estimate: z.number(),
  lower_ci: z.number(),
  upper_ci: z.number(),
  p_value: z.number().min(0).max(1).optional(),
  weight: z.number().min(0).max(100).optional(),
});

// Study-level effect size
export const StudyEffectSchema = z.object({
  study_id: z.string(),
  effect_size: EffectSizeSchema,
});

// Heterogeneity statistics
export const HeterogeneitySchema = z.object({
  I2: z.number().min(0).max(100),
  Q: z.number().min(0),
  df: z.number().int().min(0),
  p_value: z.number().min(0).max(1),
  tau2: z.number().min(0),
});

// Meta-analysis results
export const MetaAnalysisResultSchema = z.object({
  effect_measure: z.enum(["OR", "RR", "MD", "SMD", "HR"]),
  model: z.enum(["fixed", "random"]),
  pooled_effect: EffectSizeSchema,
  heterogeneity: HeterogeneitySchema,
  study_effects: z.array(StudyEffectSchema),
  n_studies: z.number().int().min(1),
  n_participants: z.number().int().min(1),
});

// Publication bias assessment
export const PublicationBiasSchema = z.object({
  egger_test: z
    .object({
      intercept: z.number(),
      p_value: z.number().min(0).max(1),
    })
    .optional(),
  begg_test: z
    .object({
      tau: z.number(),
      p_value: z.number().min(0).max(1),
    })
    .optional(),
  trim_fill: z
    .object({
      n_missing: z.number().int().min(0),
      adjusted_effect: EffectSizeSchema,
    })
    .optional(),
});

// Complete dataset
export const CochraneDatasetSchema = z.object({
  studies: z.array(StudySchema),
  outcomes: z.union([
    z.array(BinaryOutcomeSchema),
    z.array(ContinuousOutcomeSchema),
  ]),
  outcome_type: z.enum(["binary", "continuous"]),
  outcome_name: z.string(),
  intervention: z.string(),
  comparison: z.string(),
});

// Validation result
export const ValidationResultSchema = z.object({
  valid: z.boolean(),
  warnings: z.array(z.string()),
  errors: z.array(z.string()),
  suggestions: z.array(z.string()),
});

// Export types
export type Study = z.infer<typeof StudySchema>;
export type BinaryOutcome = z.infer<typeof BinaryOutcomeSchema>;
export type ContinuousOutcome = z.infer<typeof ContinuousOutcomeSchema>;
export type EffectSize = z.infer<typeof EffectSizeSchema>;
export type Heterogeneity = z.infer<typeof HeterogeneitySchema>;
export type MetaAnalysisResult = z.infer<typeof MetaAnalysisResultSchema>;
export type PublicationBias = z.infer<typeof PublicationBiasSchema>;
export type CochraneDataset = z.infer<typeof CochraneDatasetSchema>;
export type ValidationResult = z.infer<typeof ValidationResultSchema>;
