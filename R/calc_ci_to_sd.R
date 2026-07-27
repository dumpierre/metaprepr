# 95% CI (of a mean) -> SD
#
# df = n - 1; t = qt(0.975, df); SE = (upper - lower) / (2 * t); SD = SE * sqrt(n)
# Assumes a symmetric CI for a mean. Guard n >= 2.
# Optional "z" mode uses the fixed normal critical value 1.96 instead of the
# t-distribution; matters for small n, where t > z. SD is recovered by dividing
# by the critical value, so assuming the smaller z OVERSTATES SD - by about 42%
# at n=5. See docs/methods.md section 2 for both directions.

#' Convert a 95% CI for a mean to SD
#'
#' @param lower lower bound of the 95% CI
#' @param upper upper bound of the 95% CI (must be >= lower)
#' @param n sample size (>= 2)
#' @param crit_method "t" (default, exact) or "z" (approximate, uses 1.96)
#' @return list(ok, code, args, sd, t_or_z)
calc_ci_to_sd <- function(lower, upper, n, crit_method = c("t", "z")) {
  crit_method <- match.arg(crit_method)

  validation <- validate_inputs(
    values = list(lower = lower, upper = upper, n = n),
    rules = list(n = function(v) v >= 2),
    labels = list(lower = "lower_bound", upper = "upper_bound", n = "n")
  )
  if (!validation$ok) return(c(validation, list(sd = NA_real_, t_or_z = NA_real_)))

  if (upper < lower) {
    return(list(ok = FALSE, code = "ci_upper_lt_lower", args = NULL,
                sd = NA_real_, t_or_z = NA_real_))
  }

  crit <- if (crit_method == "t") stats::qt(0.975, df = n - 1) else 1.96
  se <- (upper - lower) / (2 * crit)
  sd <- se * sqrt(n)

  list(ok = TRUE, code = "", args = NULL, sd = sd, t_or_z = crit)
}
