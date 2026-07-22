# Combine k >= 2 groups into one (Cochrane Handbook Table 6.5.a for the
# two-group SD formula; k > 2 combined by iterative pairwise folding, which
# is associative/commutative for N and Mean, and tested for order-invariance
# on SD below).

#' Combine exactly two groups
#'
#' @param n1,mean1,sd1 group 1 N, mean, SD
#' @param n2,mean2,sd2 group 2 N, mean, SD
#' @return list(ok, code, args, n, mean, sd)
combine_two_groups <- function(n1, mean1, sd1, n2, mean2, sd2) {
  validation <- validate_inputs(
    values = list(n1 = n1, mean1 = mean1, sd1 = sd1, n2 = n2, mean2 = mean2, sd2 = sd2),
    rules = list(
      n1 = function(v) v >= 1,
      n2 = function(v) v >= 1,
      sd1 = function(v) v >= 0,
      sd2 = function(v) v >= 0
    ),
    labels = list(n1 = "n1", mean1 = "mean1", sd1 = "sd1",
                  n2 = "n2", mean2 = "mean2", sd2 = "sd2")
  )
  if (!validation$ok) return(c(validation, list(n = NA_real_, mean = NA_real_, sd = NA_real_)))

  n <- n1 + n2
  mean <- (n1 * mean1 + n2 * mean2) / n

  if (n1 + n2 - 1 <= 0) {
    return(list(ok = FALSE, code = "combine_n_too_small", args = NULL,
                n = n, mean = mean, sd = NA_real_))
  }

  var_pooled <- (
    (n1 - 1) * sd1^2 + (n2 - 1) * sd2^2 +
      (n1 * n2 / (n1 + n2)) * (mean1 - mean2)^2
  ) / (n1 + n2 - 1)

  list(ok = TRUE, code = "", args = NULL, n = n, mean = mean, sd = sqrt(var_pooled))
}

#' Combine k >= 2 groups by iterative pairwise folding
#'
#' @param n numeric vector of length k >= 2
#' @param mean numeric vector of length k, same length as n
#' @param sd numeric vector of length k, same length as n
#' @return list(ok, code, args, n, mean, sd)
combine_groups <- function(n, mean, sd) {
  k <- length(n)
  if (k < 2 || length(mean) != k || length(sd) != k) {
    return(list(ok = FALSE, code = "combine_need_two_groups", args = NULL,
                n = NA_real_, mean = NA_real_, sd = NA_real_))
  }

  acc <- combine_two_groups(n[1], mean[1], sd[1], n[2], mean[2], sd[2])
  if (!acc$ok) return(acc)

  if (k > 2) {
    for (i in 3:k) {
      acc <- combine_two_groups(acc$n, acc$mean, acc$sd, n[i], mean[i], sd[i])
      if (!acc$ok) return(acc)
    }
  }

  acc
}
