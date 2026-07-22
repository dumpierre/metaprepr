# Reproduces every number reported in the worked example of the manuscript
# (paper.md, section "Worked example"), using DataPrepR's own calculator
# functions rather than a separate reimplementation.
#
# Inputs are transcribed from META_Hardwork_2020.xlsx, the extraction
# workbook used for the HbA1c review. Sheet and cell references are given
# in comments so each input can be traced back to the source.
#
# This file is kept byte-identical in two places: the manuscript working
# folder, and paper/rsm/ in the DataPrepR repository, which is the copy the
# paper's data availability statement points at. It locates the app's R/
# directory by search rather than by a fixed relative path so that both
# copies stay identical and can be run from either tree.
#
# Run it from the DataPrepR repository root:
#   Rscript paper/rsm/worked_example.R

find_app_dir <- function() {
  candidates <- c(
    file.path("R"),                        # DataPrepR repository root
    file.path("..", "..", "R"),            # from paper/rsm/
    file.path("dataprepr", "R"),           # from the manuscript's parent folder
    file.path("..", "dataprepr", "R")      # from the manuscript folder
  )
  for (p in candidates) {
    if (file.exists(file.path(p, "split_control.R"))) return(p)
  }
  stop("Could not locate DataPrepR's R/ directory. Run from the repository root.")
}

app_dir <- find_app_dir()
for (f in c("utils_validation.R", "translations.R", "calc_se_to_sd.R",
            "calc_ci_to_sd.R", "calc_iqr_to_sd.R", "calc_median_to_mean_sd.R",
            "calc_sd_change.R", "combine_groups.R", "split_control.R")) {
  source(file.path(app_dir, f))
}

rule <- function(title) cat("\n", title, "\n", strrep("-", nchar(title)), "\n", sep = "")
show <- function(label, value, digits = 4) {
  cat(sprintf("  %-46s %s\n", paste0(label, ":"),
              if (is.numeric(value)) paste(sprintf(paste0("%.", digits, "f"), value), collapse = ", ")
              else paste(value, collapse = ", ")))
}

cat("Worked example: HbA1c, supervised exercise training in type 2 diabetes\n")
cat("Source workbook: META_Hardwork_2020.xlsx\n")

# ---------------------------------------------------------------------------
# 1. Church 2010 control arm: two reported statistics, two SDs
#    Sheet "IC 95 para SD" (CI) and sheet "SE para SD" (SE), both labelled
#    "Exemplo, Church - Grupo Controle", both with n = 41.
# ---------------------------------------------------------------------------
rule("1. Church 2010 control arm, HbA1c: CI route vs SE route (n = 41)")

ci_z <- calc_ci_to_sd(lower = -0.13, upper = 0.36, n = 41, crit_method = "z")
ci_t <- calc_ci_to_sd(lower = -0.13, upper = 0.36, n = 41, crit_method = "t")
se   <- calc_se_to_sd(se = 0.10, n = 41)

show("SD from 95% CI (-0.13, 0.36), z = 1.96", ci_z$sd)
show("SD from 95% CI (-0.13, 0.36), t critical value", ci_t$sd)
show("  t critical value used (df = 40)", ci_t$t_or_z)
show("SD from SE = 0.10", se$sd)
show("Ratio of the two SDs (CI z-route / SE route)", ci_z$sd / se$sd)
show("Workbook value carried into the analysis sheet", 0.80)

# ---------------------------------------------------------------------------
# 2. Correlation between baseline and final HbA1c, derived from Church
#    Sheet "Imputacao SD Delta", rows 7-14. Church reports baseline, final
#    AND change SDs, so r can be recovered rather than assumed.
#    r = (SD_base^2 + SD_final^2 - SD_change^2) / (2 * SD_base * SD_final)
#    Cochrane Handbook 6.5.2.8.
#
#    NOTE: DataPrepR has no tool for this step. It is computed here to show
#    what the app does not cover; see the manuscript's Limitations section.
# ---------------------------------------------------------------------------
rule("2. Correlation r recovered from Church 2010 (not a DataPrepR tool)")

recover_r <- function(sd_base, sd_final, sd_change) {
  (sd_base^2 + sd_final^2 - sd_change^2) / (2 * sd_base * sd_final)
}
r_exp     <- recover_r(0.61, 0.70, 0.80)   # combined-exercise arm
r_control <- recover_r(0.64, 0.64, 0.80)   # control arm

show("r, experimental arm (SDs 0.61 / 0.70 / 0.80)", r_exp)
show("r, control arm (SDs 0.64 / 0.64 / 0.80)", r_control)
show("Cochrane's default assumption when r is unknown", 0.5, digits = 1)

# ---------------------------------------------------------------------------
# 3. Change-score SDs imputed for Sigal 2007, using Church's r
#    Sheet "Imputacao SD Delta", columns F-Q. Sigal reports baseline and
#    final SDs but no change SD.
# ---------------------------------------------------------------------------
rule("3. Sigal 2007 change-score SDs, imputed with Church's r")

sigal <- list(
  list(arm = "Combined, experimental",  sd_base = 1.48, sd_final = 1.55, r = r_exp),
  list(arm = "Combined, control",       sd_base = 1.38, sd_final = 1.47, r = r_control),
  list(arm = "Aerobic, experimental",   sd_base = 1.50, sd_final = 1.50, r = r_exp),
  list(arm = "Resistance, experimental",sd_base = 1.47, sd_final = 1.52, r = r_exp)
)

for (a in sigal) {
  res <- calc_sd_change(sd_base = a$sd_base, sd_final = a$sd_final, r = a$r)
  show(a$arm, res$sd_change)
}

cat("\n  Sensitivity of one arm (Combined, experimental) to the choice of r:\n")
sens <- calc_sd_change(sd_base = 1.48, sd_final = 1.55, r = r_exp)$sensitivity
show("  r = 0.3", sens[["r_0.3"]])
show("  r = 0.5 (Cochrane default)", sens[["r_0.5"]])
show("  r = 0.7", sens[["r_0.7"]])
show("  r = 0.260 (recovered from Church)", calc_sd_change(1.48, 1.55, r_exp)$sd_change)
show("  Range across r = 0.3 to 0.7, as % of the r = 0.3 value",
     100 * (sens[["r_0.3"]] - sens[["r_0.7"]]) / sens[["r_0.3"]], digits = 1)

# ---------------------------------------------------------------------------
# 4. Church's shared control arm split across three comparisons
#    Sheet "Distribuicao de comparador": n control = 41; arms aerobic 72,
#    resistance 73, combined 76. Cochrane Handbook 23.3.4.
# ---------------------------------------------------------------------------
rule("4. Church 2010 shared control arm (n = 41) across k = 3 comparisons")

even <- split_control(n_control = 41, k = 3)
prop <- split_control(n_control = 41, k = 3, weighting = "proportional",
                       arm_n = c(72, 73, 76))   # aerobic, resistance, combined

show("Equal split (Cochrane default)", even$n_adjusted, digits = 0)
show("  total allocated", sum(even$n_adjusted), digits = 0)
show("Proportional split (aerobic 72, resistance 73, combined 76)", prop$n_adjusted, digits = 0)
show("  total allocated", sum(prop$n_adjusted), digits = 0)
show("Exact proportional shares before rounding", 41 * c(72, 73, 76) / 221)
show("Workbook's allocation (analysis sheet, rows 9-11)", c(13, 14, 14), digits = 0)
show("Independent rounding, round(41/3) three times",
     rep(round(41 / 3), 3), digits = 0)
show("  total allocated by independent rounding", 3 * round(41 / 3), digits = 0)

# ---------------------------------------------------------------------------
# 5. Combining the three Church intervention arms into one group
#    An alternative to splitting the control (Cochrane Handbook 6.5.2.10 /
#    Table 6.5.a). Arm means and SDs from the analysis sheet, rows 9-11.
# ---------------------------------------------------------------------------
rule("5. Alternative to splitting: combine Church's three exercise arms")

comb <- combine_groups(
  n    = c(73, 72, 76),          # resistance, aerobic, combined
  mean = c(-0.04, -0.12, -0.23),
  sd   = c(0.81, 0.82, 0.80)
)
show("Combined N", comb$n, digits = 0)
show("Combined mean", comb$mean)
show("Combined SD", comb$sd)
cat("\n  Control arm is then used once, at its full size of 41.\n")

cat("\nDone.\n")
