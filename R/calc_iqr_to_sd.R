# IQR -> SD (normal approximation)
#
# SD = (Q3 - Q1) / 1.35. Assumes approximate normality; Wan (2014) is
# preferable when n is known (see calc_median_to_mean_sd.R).

#' Convert an interquartile range to SD via the normal approximation
#'
#' @param q1 first quartile
#' @param q3 third quartile (must be >= q1)
#' @return list(ok, message, sd)
calc_iqr_to_sd <- function(q1, q3) {
  validation <- validate_inputs(
    values = list(q1 = q1, q3 = q3),
    rules = list(),
    labels = list(q1 = "Q1", q3 = "Q3")
  )
  if (!validation$ok) return(c(validation, list(sd = NA_real_)))

  if (q3 < q1) {
    return(list(ok = FALSE, message = "Q3 must be >= Q1.", sd = NA_real_))
  }

  sd <- (q3 - q1) / 1.35
  list(ok = TRUE, message = "", sd = sd)
}
