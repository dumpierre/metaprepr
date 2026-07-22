# DataPrepR server logic. Each calculator follows the same pattern:
#   1. observeEvent(input$X_calc) computes and stores a result list
#   2. output$X_result renders it (friendly message if !ok, never a crash)
#   3. observeEvent(input$X_send) appends a row to the shared workspace
#
# Language comes from the `?lang=` query string and does not change
# reactively within a session (switching language is a full page reload).
# current_lang() re-derives it from session$clientData$url_search on every
# call rather than caching a single read at server startup, since clientData
# is only populated after the client's first round-trip - reading it eagerly
# at the top of this function would see it before it exists.

empty_workspace <- function() {
  data.frame(
    Study_ID = character(0), Group_Label = character(0), Method = character(0),
    Mean = numeric(0), SD = numeric(0), N = numeric(0),
    stringsAsFactors = FALSE
  )
}

app_server <- function(input, output, session) {

  # Unlike app_ui()'s `request` (available synchronously from the HTTP
  # request), session$clientData$url_search is only populated after the
  # client's first round-trip - so it must be read lazily, inside a reactive
  # context (render/observe), never eagerly at server startup. isolate() is
  # safe to call from anywhere (reactive or not) and does not itself delay
  # anything; it only skips dependency tracking.
  current_lang <- function() shiny::isolate(get_lang_from_search(session$clientData$url_search))
  t <- function(key) tr(key, current_lang())

  format_result_text <- function(res, lines) {
    if (is.null(res)) return(t("result_awaiting"))
    if (!res$ok) return(paste(t("result_error_prefix"), render_message(res$code, res$args, current_lang())))
    paste(lines(res), collapse = "\n")
  }

  workspace_data <- shiny::reactiveVal(empty_workspace())

  append_workspace_row <- function(study_id, group_label, method, mean, sd, n) {
    new_row <- data.frame(
      Study_ID = ifelse(is.null(study_id) || study_id == "", NA_character_, study_id),
      Group_Label = ifelse(is.null(group_label) || group_label == "", NA_character_, group_label),
      Method = method,
      Mean = mean,
      SD = sd,
      N = n,
      stringsAsFactors = FALSE
    )
    workspace_data(rbind(workspace_data(), new_row))
  }

  workspace_col_headers <- function() {
    c(t("col_study_id"), t("col_group_label"), t("col_method"), t("col_mean"), t("col_sd"), t("col_n"))
  }

  # -- SE -> SD --------------------------------------------------------------
  se_res <- shiny::reactiveVal(NULL)
  shiny::observeEvent(input$se_calc, {
    se_res(calc_se_to_sd(se = input$se_se, n = input$se_n))
  })
  output$se_result <- shiny::renderText({
    format_result_text(se_res(), function(r) sprintf("%s: %.4f", t("result_label_sd"), r$sd))
  })
  shiny::observeEvent(input$se_send, {
    r <- se_res()
    shiny::req(r, r$ok)
    append_workspace_row(input$se_study, input$se_group, t("method_se"), NA_real_, r$sd, input$se_n)
  })

  # -- 95% CI -> SD ------------------------------------------------------------
  ci_res <- shiny::reactiveVal(NULL)
  shiny::observeEvent(input$ci_calc, {
    ci_res(calc_ci_to_sd(lower = input$ci_lower, upper = input$ci_upper, n = input$ci_n,
                          crit_method = input$ci_mode))
  })
  output$ci_result <- shiny::renderText({
    format_result_text(ci_res(), function(r) sprintf(
      "%s: %.4f\n%s (%s): %.4f",
      t("result_label_sd"), r$sd, t("result_crit_label"), input$ci_mode, r$t_or_z
    ))
  })
  shiny::observeEvent(input$ci_send, {
    r <- ci_res()
    shiny::req(r, r$ok)
    method_label <- sprintf("%s (%s)", t("nav_ci"), input$ci_mode)
    append_workspace_row(input$ci_study, input$ci_group, method_label, NA_real_, r$sd, input$ci_n)
  })

  # -- IQR -> SD --------------------------------------------------------------
  iqr_res <- shiny::reactiveVal(NULL)
  shiny::observeEvent(input$iqr_calc, {
    iqr_res(calc_iqr_to_sd(q1 = input$iqr_q1, q3 = input$iqr_q3))
  })
  output$iqr_result <- shiny::renderText({
    format_result_text(iqr_res(), function(r) sprintf("%s: %.4f", t("result_label_sd"), r$sd))
  })
  shiny::observeEvent(input$iqr_send, {
    r <- iqr_res()
    shiny::req(r, r$ok)
    append_workspace_row(input$iqr_study, input$iqr_group, t("method_iqr"), NA_real_, r$sd, NA_real_)
  })

  # -- Median/Range/IQR -> Mean & SD -------------------------------------------
  med_res <- shiny::reactiveVal(NULL)
  shiny::observeEvent(input$med_calc, {
    med_res(calc_median_to_mean_sd(
      min_val = input$med_min, q1_val = input$med_q1, med_val = input$med_median,
      q3_val = input$med_q3, max_val = input$med_max, n = input$med_n,
      method = input$med_method
    ))
  })
  output$med_result <- shiny::renderText({
    format_result_text(med_res(), function(r) sprintf(
      "%s: %s (%s)\n%s: %.4f\n%s: %.4f",
      t("result_scenario_label"), r$scenario, scenario_label(r$scenario, current_lang()),
      t("result_label_mean"), r$mean, t("result_label_sd"), r$sd
    ))
  })
  shiny::observeEvent(input$med_send, {
    r <- med_res()
    shiny::req(r, r$ok)
    method_label <- switch(input$med_method,
                           hozo = t("method_hozo"),
                           wan = t("method_wan"),
                           luo = t("method_luo"))
    append_workspace_row(input$med_study, input$med_group,
                          paste0(method_label, " [", r$scenario, "]"), r$mean, r$sd, input$med_n)
  })

  # -- SD of change from baseline ----------------------------------------------
  sdc_res <- shiny::reactiveVal(NULL)
  shiny::observeEvent(input$sdc_calc, {
    sdc_res(calc_sd_change(sd_base = input$sdc_base, sd_final = input$sdc_final, r = input$sdc_r))
  })
  output$sdc_result <- shiny::renderText({
    r <- sdc_res()
    if (is.null(r)) return(t("result_awaiting"))
    if (!r$ok) return(paste(t("result_error_prefix"), render_message(r$code, r$args, current_lang())))
    sens <- r$sensitivity
    fmt <- function(v) if (is.na(v)) t("result_sd_change_undefined") else sprintf("%.4f", v)
    sprintf(
      "%s (r=%.2f): %.4f\n\n%s\n  r=0.3: %s\n  r=0.5: %s\n  r=0.7: %s",
      t("result_label_sd"), input$sdc_r, r$sd_change, t("result_sensitivity_header"),
      fmt(sens[["r_0.3"]]), fmt(sens[["r_0.5"]]), fmt(sens[["r_0.7"]])
    )
  })
  shiny::observeEvent(input$sdc_send, {
    r <- sdc_res()
    shiny::req(r, r$ok)
    append_workspace_row(input$sdc_study, input$sdc_group,
                          sprintf("%s (r=%.2f)", t("nav_sdchange"), input$sdc_r), NA_real_, r$sd_change, NA_real_)
  })

  # -- Combine groups -----------------------------------------------------------
  output$combine_table <- rhandsontable::renderRHandsontable({
    default_df <- data.frame(N = c(NA_real_, NA_real_), Mean = c(NA_real_, NA_real_),
                              SD = c(NA_real_, NA_real_))
    rhandsontable::rhandsontable(default_df, rowHeaders = TRUE,
                                  colHeaders = c(t("col_n"), t("col_mean"), t("col_sd"))) |>
      rhandsontable::hot_context_menu(allowRowEdit = TRUE, allowColEdit = FALSE)
  })
  comb_res <- shiny::reactiveVal(NULL)
  shiny::observeEvent(input$comb_calc, {
    shiny::req(input$combine_table)
    tbl <- rhandsontable::hot_to_r(input$combine_table)
    tbl <- tbl[stats::complete.cases(tbl), , drop = FALSE]
    if (nrow(tbl) < 2) {
      comb_res(list(ok = FALSE, code = "__combine_row_error__", args = NULL))
    } else {
      comb_res(combine_groups(n = tbl$N, mean = tbl$Mean, sd = tbl$SD))
    }
  })
  output$comb_result <- shiny::renderText({
    r <- comb_res()
    if (is.null(r)) return(t("result_awaiting"))
    if (!r$ok) {
      msg <- if (identical(r$code, "__combine_row_error__")) t("combine_row_error") else render_message(r$code, r$args, current_lang())
      return(paste(t("result_error_prefix"), msg))
    }
    sprintf("%s: %.0f\n%s: %.4f\n%s: %.4f",
            t("result_label_n"), r$n, t("result_label_mean"), r$mean, t("result_label_sd"), r$sd)
  })
  shiny::observeEvent(input$comb_send, {
    r <- comb_res()
    shiny::req(r, r$ok)
    append_workspace_row(input$comb_study, input$comb_group, t("method_combine"), r$mean, r$sd, r$n)
  })

  # -- Split shared control group -----------------------------------------------
  split_res <- shiny::reactiveVal(NULL)
  # Arm sizes arrive as free text ("72, 73, 76") so the user can type them
  # without a variable number of numericInputs. Anything unparseable becomes
  # NA and is rejected by split_control()'s own validation.
  parse_arm_n <- function(txt) {
    if (is.null(txt) || !nzchar(trimws(txt))) return(numeric(0))
    parts <- trimws(strsplit(txt, "[,;[:space:]]+")[[1]])
    as.list(suppressWarnings(as.numeric(parts[nzchar(parts)])))
  }
  shiny::observeEvent(input$split_calc, {
    split_res(split_control(n_control = input$split_n, k = input$split_k,
                             mean_control = input$split_mean, sd_control = input$split_sd,
                             weighting = input$split_weighting,
                             arm_n = parse_arm_n(input$split_arm_n)))
  })
  output$split_result <- shiny::renderText({
    format_result_text(split_res(), function(r) sprintf(
      "%s: %s\n%s: %d\n%s: %s / %s",
      t("result_label_n_per_comparison"), paste(r$n_adjusted, collapse = ", "),
      t("result_label_n_total"), sum(r$n_adjusted),
      t("result_label_mean_sd_slash"),
      ifelse(is.na(r$mean), t("result_not_provided"), sprintf("%.4f", r$mean)),
      ifelse(is.na(r$sd), t("result_not_provided"), sprintf("%.4f", r$sd))
    ))
  })
  shiny::observeEvent(input$split_send, {
    r <- split_res()
    shiny::req(r, r$ok)
    for (i in seq_along(r$n_adjusted)) {
      label <- paste0(ifelse(input$split_group == "", "control", input$split_group), "_", i)
      append_workspace_row(input$split_study, label, t("method_split"), r$mean, r$sd, r$n_adjusted[i])
    }
  })

  # -- Workspace -----------------------------------------------------------------
  output$workspace_table <- rhandsontable::renderRHandsontable({
    rhandsontable::rhandsontable(workspace_data(), rowHeaders = TRUE,
                                  colHeaders = workspace_col_headers()) |>
      rhandsontable::hot_context_menu(allowRowEdit = TRUE, allowColEdit = FALSE)
  })

  current_workspace <- function() {
    if (!is.null(input$workspace_table)) {
      rhandsontable::hot_to_r(input$workspace_table)
    } else {
      workspace_data()
    }
  }

  output$download_csv <- shiny::downloadHandler(
    filename = function() paste0("dataprepr_workspace_", Sys.Date(), ".csv"),
    content = function(file) utils::write.csv(current_workspace(), file, row.names = FALSE)
  )
  output$download_xlsx <- shiny::downloadHandler(
    filename = function() paste0("dataprepr_workspace_", Sys.Date(), ".xlsx"),
    content = function(file) writexl::write_xlsx(current_workspace(), file)
  )
}
