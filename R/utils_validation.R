# Shared input validation helpers for DataPrepR calculators.
#
# Every calc_*() function returns a list with at least:
#   ok      - logical, TRUE if inputs passed validation
#   message - character, empty string if ok, else a user-facing explanation
# plus whatever numeric results the calculator produces (NA when !ok).

#' Check that a value is a single finite (non-NA, non-NaN, non-Inf) number
#'
#' @param x value to check
#' @return TRUE/FALSE
is_finite_scalar <- function(x) {
  is.numeric(x) && length(x) == 1 && !is.na(x) && is.finite(x)
}

#' Validate a set of named numeric inputs against required conditions
#'
#' @param values named list of values, e.g. list(n = 25, se = 2)
#' @param rules named list of predicate functions keyed by the same names,
#'   e.g. list(n = function(v) v >= 1, se = function(v) v >= 0)
#' @param labels optional named list of human-readable labels for messages
#' @return list(ok = logical, message = character)
validate_inputs <- function(values, rules, labels = list()) {
  missing_names <- names(values)[!vapply(values, is_finite_scalar, logical(1))]
  if (length(missing_names) > 0) {
    lbl <- vapply(missing_names, function(n) {
      if (!is.null(labels[[n]])) labels[[n]] else n
    }, character(1))
    return(list(
      ok = FALSE,
      message = paste0("Missing or invalid input: ", paste(lbl, collapse = ", "), ".")
    ))
  }

  for (nm in names(rules)) {
    if (!rules[[nm]](values[[nm]])) {
      lbl <- if (!is.null(labels[[nm]])) labels[[nm]] else nm
      return(list(
        ok = FALSE,
        message = paste0("Invalid value for ", lbl, ".")
      ))
    }
  }

  list(ok = TRUE, message = "")
}

#' Build a standard "not yet calculated / invalid" result list
#'
#' @param extra_fields character vector of additional NA numeric fields to include
#' @param message character, validation message (empty if just awaiting input)
#' @return named list
empty_result <- function(extra_fields = character(0), message = "") {
  out <- list(ok = FALSE, message = message)
  for (f in extra_fields) out[[f]] <- NA_real_
  out
}
