# IQR -> SD
#
# Two estimators, selected by whether the sample size is known:
#
#   n given    Wan et al. (2014), eq. (16), scenario S2:
#              SD ~= (Q3 - Q1) / (2 * qnorm((0.75n - 0.125)/(n + 0.25)))
#              The denominator depends on n, which is exactly what the plain
#              1.35 rule leaves out. Wan's paper is explicit that ignoring it
#              biases SD downwards, badly at small n: with Q1=10, Q3=20 the
#              1.35 rule sits 16% below Wan at n=10 and 71% below at n=3.
#
#   n missing  the Cochrane Handbook 6.5.2.5 normal approximation,
#              SD ~= (Q3 - Q1) / 1.35
#
# These are the same estimator at two ends of a limit, not rivals: as n grows
# Wan's denominator converges on 2*qnorm(0.75) = 1.34898, so the 1.35 rule is
# Wan evaluated at n = infinity. That is also why the fallback is defensible
# when n genuinely is not reported - it is the large-sample case of the better
# formula rather than a different idea.
#
# The Wan branch is written in closed form rather than routed through
# metaBLUE::Wan.std(), which requires a median it does not actually use for the
# SD (verified: sigmahat is invariant to the median under S2). A test pins this
# implementation to metaBLUE across a range of n so the shortcut cannot drift.

#' Wan (2014) S2 standard deviation estimator from an interquartile range
#'
#' @param q1,q3 first and third quartiles
#' @param n sample size (>= 3)
#' @return numeric standard deviation estimate
wan_sd_from_iqr <- function(q1, q3, n) {
  (q3 - q1) / (2 * stats::qnorm((0.75 * n - 0.125) / (n + 0.25)))
}

#' Convert an interquartile range to SD
#'
#' Uses Wan et al. (2014) when the sample size is supplied, and the Cochrane
#' normal approximation when it is not.
#'
#' @param q1 first quartile
#' @param q3 third quartile (must be >= q1)
#' @param n sample size; optional. When supplied it must be at least 3 - the
#'   estimator is undefined at n = 1 and quartiles are not meaningful at n = 2.
#' @return list(ok, code, args, sd, method) where method is "wan" or "simple"
calc_iqr_to_sd <- function(q1, q3, n = NA) {
  validation <- validate_inputs(
    values = list(q1 = q1, q3 = q3),
    rules = list(),
    labels = list(q1 = "q1", q3 = "q3")
  )
  if (!validation$ok) return(c(validation, list(sd = NA_real_, method = NA_character_)))

  if (q3 < q1) {
    return(list(ok = FALSE, code = "iqr_q3_lt_q1", args = NULL,
                sd = NA_real_, method = NA_character_))
  }

  # An n that was offered but is unusable is an error, not a silent downgrade:
  # quietly swapping in the other estimator would change the number without the
  # user ever being told which formula produced it.
  if (is_finite_scalar(n)) {
    if (n < 3) {
      return(list(ok = FALSE, code = "invalid_value", args = list(field = "n"),
                  sd = NA_real_, method = NA_character_))
    }
    return(list(ok = TRUE, code = "", args = NULL,
                sd = wan_sd_from_iqr(q1, q3, n), method = "wan"))
  }

  list(ok = TRUE, code = "", args = NULL, sd = (q3 - q1) / 1.35, method = "simple")
}
