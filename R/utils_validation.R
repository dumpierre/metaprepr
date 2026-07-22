# Shared input validation helpers for DataPrepR calculators.
#
# Every calc_*() function returns a list with at least:
#   ok      - logical, TRUE if inputs passed validation
#   code    - character, "" if ok, else a message code (see R/translations.R)
#   args    - list of data for the message code (e.g. which fields), or NULL
# plus whatever numeric results the calculator produces (NA when !ok).
#
# Calculators never build user-facing text themselves - they return a code
# and structured args, and the display layer (app_server.R's
# render_message()) translates that into English or Portuguese at render
# time. The "labels" argument below maps each input's internal name to a
# field_labels key (see R/translations.R), not to English text directly.

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
#' @param labels named list mapping each value's name to a field_labels key
#'   (e.g. list(se = "se", n = "n")); falls back to the raw name if absent
#' @return list(ok = logical, code = character, args = list or NULL)
validate_inputs <- function(values, rules, labels = list()) {
  missing_names <- names(values)[!vapply(values, is_finite_scalar, logical(1))]
  if (length(missing_names) > 0) {
    field_keys <- vapply(missing_names, function(n) {
      if (!is.null(labels[[n]])) labels[[n]] else n
    }, character(1))
    return(list(ok = FALSE, code = "missing_input", args = list(fields = field_keys)))
  }

  for (nm in names(rules)) {
    if (!rules[[nm]](values[[nm]])) {
      field_key <- if (!is.null(labels[[nm]])) labels[[nm]] else nm
      return(list(ok = FALSE, code = "invalid_value", args = list(field = field_key)))
    }
  }

  list(ok = TRUE, code = "", args = NULL)
}
