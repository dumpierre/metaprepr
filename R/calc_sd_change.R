# SD of change from baseline
#
# SD_change = sqrt(SD_base^2 + SD_final^2 - 2*r*SD_base*SD_final)
# r is the baseline-final correlation; Cochrane's default imputation is 0.5.
# Guard against a negative value under the square root (occurs when r is too
# low relative to the two SDs) - report clearly rather than returning NaN.

#' Estimate SD of a change-from-baseline score
#'
#' @param sd_base SD at baseline (>= 0)
#' @param sd_final SD at final measurement (>= 0)
#' @param r assumed correlation between baseline and final (-1 to 1, default 0.5)
#' @return list(ok, code, args, sd_change, sensitivity) where sensitivity is a
#'   named numeric vector of SD_change at r in {0.3, 0.5, 0.7}
calc_sd_change <- function(sd_base, sd_final, r = 0.5) {
  validation <- validate_inputs(
    values = list(sd_base = sd_base, sd_final = sd_final, r = r),
    rules = list(
      sd_base = function(v) v >= 0,
      sd_final = function(v) v >= 0,
      r = function(v) v >= -1 && v <= 1
    ),
    labels = list(sd_base = "sd_base", sd_final = "sd_final", r = "r")
  )
  if (!validation$ok) return(c(validation, list(sd_change = NA_real_, sensitivity = NULL)))

  compute <- function(rr) sd_base^2 + sd_final^2 - 2 * rr * sd_base * sd_final

  under_root <- compute(r)
  sensitivity_r <- c(0.3, 0.5, 0.7)
  sensitivity <- setNames(
    vapply(sensitivity_r, function(rr) {
      v <- compute(rr)
      if (v < 0) NA_real_ else sqrt(v)
    }, numeric(1)),
    paste0("r_", sensitivity_r)
  )

  if (under_root < 0) {
    return(list(
      ok = FALSE,
      code = "sd_change_negative",
      args = list(value = round(under_root, 4), r = r),
      sd_change = NA_real_,
      sensitivity = sensitivity
    ))
  }

  list(ok = TRUE, code = "", args = NULL, sd_change = sqrt(under_root), sensitivity = sensitivity)
}
