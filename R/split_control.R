# Split a shared control group across k pairwise comparisons.
#
# Returns a vector of k adjusted control Ns whose sum is exactly n_control;
# mean and SD are unchanged. This is the simple Cochrane approximation
# (Handbook section 23.3.4) for avoiding double-counting a shared control
# arm; the rigorous alternative is a network or multivariate method that
# models the induced correlation.
#
# Two weightings are offered:
#   "even"         - Cochrane's default: divide the control arm into k
#                    approximately equal parts.
#   "proportional" - divide it in proportion to the sizes of the k
#                    intervention arms it is compared against, so that
#                    larger comparisons draw a larger share of the control.
#                    Requires arm_n.
#
# Both allocate integers by the largest-remainder (Hamilton) method rather
# than rounding each share independently. Independent rounding does not
# preserve the total: round(41/3) = 14 repeated three times allocates 42
# participants from a control arm of 41, inventing a participant and
# inflating the pooled precision. Largest-remainder gives 14, 14, 13.

#' Allocate n units across weights so the parts are integers summing to n
#'
#' Floors each exact share, then hands the leftover units out one at a time
#' to the shares with the largest discarded fractional part (ties broken by
#' original order, so the result is deterministic).
#'
#' @param n total to allocate (non-negative integer)
#' @param weights positive numeric vector, one per part
#' @return integer vector, same length as weights, summing to n
largest_remainder_allocate <- function(n, weights) {
  exact <- n * weights / sum(weights)
  base <- floor(exact)
  leftover <- n - sum(base)
  if (leftover > 0) {
    # order() is stable, so equal remainders keep their input order.
    recipients <- order(exact - base, decreasing = TRUE)[seq_len(leftover)]
    base[recipients] <- base[recipients] + 1
  }
  as.integer(base)
}

#' Split a shared control group's N across k comparisons
#'
#' @param n_control control group sample size
#' @param k number of comparisons sharing this control (>= 2)
#' @param mean_control,sd_control control group mean/SD (unchanged, passed through)
#' @param weighting "even" (default, Cochrane) or "proportional"
#' @param arm_n intervention arm sizes, length k; required when
#'   weighting = "proportional", ignored otherwise
#' @return list(ok, code, args, n_adjusted, mean, sd) where n_adjusted is an
#'   integer vector of length k summing to n_control
split_control <- function(n_control, k, mean_control = NA_real_, sd_control = NA_real_,
                           weighting = c("even", "proportional"), arm_n = NULL) {
  weighting <- match.arg(weighting)

  fail <- function(code, args = NULL) {
    list(ok = FALSE, code = code, args = args,
         n_adjusted = NA_integer_, mean = NA_real_, sd = NA_real_)
  }

  validation <- validate_inputs(
    values = list(n_control = n_control, k = k),
    rules = list(
      n_control = function(v) v >= 1,
      k = function(v) v >= 2 && v == round(v)
    ),
    labels = list(n_control = "n_control", k = "k")
  )
  if (!validation$ok) return(fail(validation$code, validation$args))

  # Every comparison must receive at least one participant, otherwise the
  # split has silently dropped a comparison from the analysis.
  if (n_control < k) {
    return(fail("split_n_lt_k", list(n_control = n_control, k = k)))
  }

  if (weighting == "proportional") {
    if (length(arm_n) != k || !all(vapply(arm_n, is_finite_scalar, logical(1)))) {
      return(fail("split_arm_n_length", list(k = k)))
    }
    arm_n <- as.numeric(arm_n)
    if (any(arm_n <= 0)) return(fail("split_arm_n_positive"))
    weights <- arm_n
  } else {
    weights <- rep(1, k)
  }

  list(ok = TRUE, code = "", args = NULL,
       n_adjusted = largest_remainder_allocate(n_control, weights),
       mean = mean_control, sd = sd_control)
}
