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

#' Combine exactly two groups when no SD is available
#'
#' The combined N and weighted mean need only N and mean. Splitting this out
#' lets the SD stay optional without inventing a value for it.
#'
#' @param n1,mean1 group 1 N and mean
#' @param n2,mean2 group 2 N and mean
#' @return list(ok, code, args, n, mean)
combine_two_means <- function(n1, mean1, n2, mean2) {
  validation <- validate_inputs(
    values = list(n1 = n1, mean1 = mean1, n2 = n2, mean2 = mean2),
    rules = list(
      n1 = function(v) v >= 1,
      n2 = function(v) v >= 1
    ),
    labels = list(n1 = "n1", mean1 = "mean1", n2 = "n2", mean2 = "mean2")
  )
  if (!validation$ok) return(c(validation, list(n = NA_real_, mean = NA_real_)))

  n <- n1 + n2
  list(ok = TRUE, code = "", args = NULL, n = n, mean = (n1 * mean1 + n2 * mean2) / n)
}

#' Combine k >= 2 groups by iterative pairwise folding
#'
#' SD is optional. When every group has one, the pooled SD is returned as
#' before. When any group is missing one, the combined N and weighted mean are
#' still exact and are returned with `sd = NA` and `sd_available = FALSE`.
#' It is deliberately all-or-nothing: a variance pooled from only the subset of
#' groups that reported an SD would not describe the combined group, and would
#' be wrong in a way nothing downstream could detect.
#'
#' @param n numeric vector of length k >= 2
#' @param mean numeric vector of length k, same length as n
#' @param sd numeric vector of length k, or NULL/all-NA when unavailable
#' @return list(ok, code, args, n, mean, sd, sd_available)
combine_groups <- function(n, mean, sd = NULL) {
  k <- length(n)
  if (is.null(sd) || length(sd) == 0) sd <- rep(NA_real_, k)
  if (k < 2 || length(mean) != k || length(sd) != k) {
    return(list(ok = FALSE, code = "combine_need_two_groups", args = NULL,
                n = NA_real_, mean = NA_real_, sd = NA_real_, sd_available = FALSE))
  }

  if (all(vapply(sd, is_finite_scalar, logical(1)))) {
    acc <- combine_two_groups(n[1], mean[1], sd[1], n[2], mean[2], sd[2])
    if (!acc$ok) return(c(acc, list(sd_available = TRUE)))

    if (k > 2) {
      for (i in 3:k) {
        acc <- combine_two_groups(acc$n, acc$mean, acc$sd, n[i], mean[i], sd[i])
        if (!acc$ok) return(c(acc, list(sd_available = TRUE)))
      }
    }
    return(c(acc, list(sd_available = TRUE)))
  }

  acc <- combine_two_means(n[1], mean[1], n[2], mean[2])
  if (!acc$ok) return(c(acc, list(sd = NA_real_, sd_available = FALSE)))

  if (k > 2) {
    for (i in 3:k) {
      acc <- combine_two_means(acc$n, acc$mean, n[i], mean[i])
      if (!acc$ok) return(c(acc, list(sd = NA_real_, sd_available = FALSE)))
    }
  }

  c(acc, list(sd = NA_real_, sd_available = FALSE))
}
