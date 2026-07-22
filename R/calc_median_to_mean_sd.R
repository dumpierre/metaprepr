# Median/range/IQR -> Mean & SD
#
# Three selectable methods, applied to scenario S1 {min, median, max, n},
# S2 {Q1, median, Q3, n}, or S3 {min, Q1, median, Q3, max, n}.
#
#   - "hozo": Hozo et al. (2005). S1 only. Hand-coded exactly per the
#     corrected spec (an earlier draft used the wrong SD constant and
#     swapped n-thresholds; this implementation fixes both).
#   - "wan":  Wan et al. (2014) SD estimator (implemented via
#     metaBLUE::Wan.std(), the package estmeansd itself depends on for
#     this exact formula) paired with the "simple"/Bland mean estimator
#     conventionally used alongside it. Default method.
#   - "luo":  Luo et al. (2016/2018) sample-size-weighted optimal mean
#     estimator (metaBLUE::Luo.mean()) paired with Wan (2014) SD
#     (metaBLUE::Wan.std()), as specified.
#
# Wan.std() and Luo.mean() formulas were verified against their published
# source (Wan et al. 2014, BMC Med Res Methodol 14:135; Luo et al. 2016,
# Stat Methods Med Res) and cross-checked against the metaBLUE source code
# shipped inside estmeansd's own bc.mean.sd() implementation.
#
# The internal scenario codes "S1"/"S2"/"S3" below are matched literally in
# switch() statements throughout this file and in app_server.R - they must
# not be renamed. Only their translated display label (see scenario_labels
# in R/translations.R) changes between languages.

#' Determine which of S1/S2/S3 a set of inputs corresponds to
#'
#' @return "S1", "S2", "S3", or NA if the inputs don't form a valid scenario
detect_scenario <- function(min_val, q1_val, med_val, q3_val, max_val) {
  has <- function(x) is_finite_scalar(x)
  if (has(min_val) && has(q1_val) && has(med_val) && has(q3_val) && has(max_val)) {
    return("S3")
  }
  if (has(q1_val) && has(med_val) && has(q3_val)) {
    return("S2")
  }
  if (has(min_val) && has(med_val) && has(max_val)) {
    return("S1")
  }
  NA_character_
}

#' Hozo et al. (2005) mean & SD estimator (S1: min, median, max, n)
calc_hozo <- function(min_val, med_val, max_val, n) {
  validation <- validate_inputs(
    values = list(min_val = min_val, med_val = med_val, max_val = max_val, n = n),
    rules = list(n = function(v) v >= 1),
    labels = list(min_val = "min_val", med_val = "med_val", max_val = "max_val", n = "n")
  )
  if (!validation$ok) return(c(validation, list(mean = NA_real_, sd = NA_real_)))

  if (max_val < min_val || med_val < min_val || med_val > max_val) {
    return(list(ok = FALSE, code = "hozo_order", args = NULL,
                mean = NA_real_, sd = NA_real_))
  }

  a <- min_val; m <- med_val; b <- max_val

  est_mean <- if (n <= 25) (a + 2 * m + b) / 4 else m

  est_sd <- if (n <= 15) {
    (1 / sqrt(12)) * sqrt(((a - 2 * m + b)^2) / 4 + (b - a)^2)
  } else if (n <= 70) {
    (b - a) / 4
  } else {
    (b - a) / 6
  }

  list(ok = TRUE, code = "", args = NULL, mean = est_mean, sd = est_sd)
}

#' Bland's "simple" mean estimator, conventionally paired with Wan (2014) SD
#'
#' S1: (a + 2m + b)/4 ; S2: (q1 + 2m + q3)/4 ; S3: (a+b)/8 + (q1+q3)/4 + m/4
simple_mean_estimate <- function(min_val, q1_val, med_val, q3_val, max_val, scenario) {
  m <- med_val
  if (scenario == "S1") {
    (min_val + 2 * m + max_val) / 4
  } else if (scenario == "S2") {
    (q1_val + 2 * m + q3_val) / 4
  } else {
    0.25 * ((min_val + max_val) / 2) + 0.5 * ((q1_val + q3_val) / 2) + 0.25 * m
  }
}

#' Wan (2014) / Luo (2018) mean & SD estimator (S1, S2, or S3)
#'
#' @param mean_method "wan" (simple/Bland mean + Wan SD) or "luo"
#'   (Luo optimal mean + Wan SD)
calc_wan_luo <- function(min_val, q1_val, med_val, q3_val, max_val, n,
                          mean_method = c("wan", "luo")) {
  mean_method <- match.arg(mean_method)

  scenario <- detect_scenario(min_val, q1_val, med_val, q3_val, max_val)
  if (is.na(scenario)) {
    return(list(
      ok = FALSE, code = "median_scenario_not_detected", args = NULL,
      mean = NA_real_, sd = NA_real_, scenario = NA_character_
    ))
  }

  validation <- validate_inputs(values = list(n = n), rules = list(n = function(v) v >= 3),
                                 labels = list(n = "n"))
  if (!validation$ok) {
    return(c(validation, list(mean = NA_real_, sd = NA_real_, scenario = scenario)))
  }

  quants <- switch(scenario,
    S1 = c(min_val, med_val, max_val),
    S2 = c(q1_val, med_val, q3_val),
    S3 = c(min_val, q1_val, med_val, q3_val, max_val)
  )
  if (is.unsorted(quants)) {
    return(list(ok = FALSE, code = "median_quantiles_unsorted", args = NULL,
                mean = NA_real_, sd = NA_real_, scenario = scenario))
  }

  est_sd <- metaBLUE::Wan.std(quants, n, scenario)$sigmahat
  est_mean <- if (mean_method == "luo") {
    metaBLUE::Luo.mean(quants, n, scenario)$muhat
  } else {
    simple_mean_estimate(min_val, q1_val, med_val, q3_val, max_val, scenario)
  }

  list(ok = TRUE, code = "", args = NULL, mean = as.numeric(est_mean), sd = as.numeric(est_sd),
       scenario = scenario)
}

#' Unified entry point: median/range/IQR -> Mean & SD, method selectable
#'
#' @param method one of "hozo", "wan" (default), "luo"
calc_median_to_mean_sd <- function(min_val = NA, q1_val = NA, med_val = NA,
                                    q3_val = NA, max_val = NA, n = NA,
                                    method = c("wan", "hozo", "luo")) {
  method <- match.arg(method)

  if (method == "hozo") {
    res <- calc_hozo(min_val, med_val, max_val, n)
    res$scenario <- "S1"
    return(res)
  }

  calc_wan_luo(min_val, q1_val, med_val, q3_val, max_val, n,
               mean_method = if (method == "luo") "luo" else "wan")
}
