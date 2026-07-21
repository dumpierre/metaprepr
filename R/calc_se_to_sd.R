# SE -> SD
#
# Cochrane Handbook 6.5.2.3: SD = SE * sqrt(n)
# Guards: n >= 1, SE >= 0.

#' Convert standard error to standard deviation
#'
#' @param se standard error (>= 0)
#' @param n sample size (>= 1)
#' @return list(ok, message, sd)
calc_se_to_sd <- function(se, n) {
  validation <- validate_inputs(
    values = list(se = se, n = n),
    rules = list(
      se = function(v) v >= 0,
      n = function(v) v >= 1
    ),
    labels = list(se = "SE", n = "n")
  )
  if (!validation$ok) {
    return(c(validation, list(sd = NA_real_)))
  }

  sd <- se * sqrt(n)
  list(ok = TRUE, message = "", sd = sd)
}
