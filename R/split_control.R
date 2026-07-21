# Split a shared control group across k pairwise comparisons.
#
# n_adjusted = round(n_control / k) for each comparison; mean/SD unchanged.
# This is the simple Cochrane approximation to avoid double-counting a
# shared control in a meta-analysis; the rigorous alternative is a
# network/multivariate meta-analysis method.

#' Split a shared control group's N across k comparisons
#'
#' @param n_control control group sample size
#' @param k number of comparisons sharing this control (>= 2)
#' @param mean_control,sd_control control group mean/SD (unchanged, passed through)
#' @return list(ok, message, n_adjusted, mean, sd)
split_control <- function(n_control, k, mean_control = NA_real_, sd_control = NA_real_) {
  validation <- validate_inputs(
    values = list(n_control = n_control, k = k),
    rules = list(
      n_control = function(v) v >= 1,
      k = function(v) v >= 2 && v == round(v)
    ),
    labels = list(n_control = "control N", k = "number of comparisons (k)")
  )
  if (!validation$ok) return(c(validation, list(n_adjusted = NA_real_, mean = NA_real_, sd = NA_real_)))

  list(ok = TRUE, message = "", n_adjusted = round(n_control / k),
       mean = mean_control, sd = sd_control)
}
