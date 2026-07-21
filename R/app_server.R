# DataPrepR server logic. Each calculator follows the same pattern:
#   1. observeEvent(input$X_calc) computes and stores a result list
#   2. output$X_result renders it (friendly message if !ok, never a crash)
#   3. observeEvent(input$X_send) appends a row to the shared workspace

workspace_columns <- c("Study_ID", "Group_Label", "Method", "Mean", "SD", "N")

empty_workspace <- function() {
  df <- data.frame(
    Study_ID = character(0), Group_Label = character(0), Method = character(0),
    Mean = numeric(0), SD = numeric(0), N = numeric(0),
    stringsAsFactors = FALSE
  )
  df
}

format_result_text <- function(res, lines) {
  if (is.null(res)) return("Awaiting calculation...")
  if (!res$ok) return(paste("Cannot calculate:", res$message))
  paste(lines(res), collapse = "\n")
}

app_server <- function(input, output, session) {

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

  # -- SE -> SD --------------------------------------------------------------
  se_res <- shiny::reactiveVal(NULL)
  shiny::observeEvent(input$se_calc, {
    se_res(calc_se_to_sd(se = input$se_se, n = input$se_n))
  })
  output$se_result <- shiny::renderText({
    format_result_text(se_res(), function(r) sprintf("Estimated SD: %.4f", r$sd))
  })
  shiny::observeEvent(input$se_send, {
    r <- se_res()
    shiny::req(r, r$ok)
    append_workspace_row(input$se_study, input$se_group, "SE->SD", NA_real_, r$sd, input$se_n)
  })

  # -- 95% CI -> SD ------------------------------------------------------------
  ci_res <- shiny::reactiveVal(NULL)
  shiny::observeEvent(input$ci_calc, {
    ci_res(calc_ci_to_sd(lower = input$ci_lower, upper = input$ci_upper, n = input$ci_n,
                          crit_method = input$ci_mode))
  })
  output$ci_result <- shiny::renderText({
    format_result_text(ci_res(), function(r) sprintf(
      "Estimated SD: %.4f\nCritical value used (%s): %.4f",
      r$sd, if (input$ci_mode == "t") "t" else "z", r$t_or_z
    ))
  })
  shiny::observeEvent(input$ci_send, {
    r <- ci_res()
    shiny::req(r, r$ok)
    append_workspace_row(input$ci_study, input$ci_group,
                          paste0("CI->SD (", input$ci_mode, ")"), NA_real_, r$sd, input$ci_n)
  })

  # -- IQR -> SD --------------------------------------------------------------
  iqr_res <- shiny::reactiveVal(NULL)
  shiny::observeEvent(input$iqr_calc, {
    iqr_res(calc_iqr_to_sd(q1 = input$iqr_q1, q3 = input$iqr_q3))
  })
  output$iqr_result <- shiny::renderText({
    format_result_text(iqr_res(), function(r) sprintf("Estimated SD: %.4f", r$sd))
  })
  shiny::observeEvent(input$iqr_send, {
    r <- iqr_res()
    shiny::req(r, r$ok)
    append_workspace_row(input$iqr_study, input$iqr_group, "IQR->SD", NA_real_, r$sd, NA_real_)
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
      "Scenario: %s\nEstimated Mean: %.4f\nEstimated SD: %.4f", r$scenario, r$mean, r$sd
    ))
  })
  shiny::observeEvent(input$med_send, {
    r <- med_res()
    shiny::req(r, r$ok)
    method_label <- switch(input$med_method,
                           hozo = "Hozo (2005)",
                           wan = "Wan (2014)",
                           luo = "Luo (2018)+Wan (2014)")
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
    if (is.null(r)) return("Awaiting calculation...")
    if (!r$ok) return(paste("Cannot calculate:", r$message))
    sens <- r$sensitivity
    sprintf(
      "SD of change (r=%.2f): %.4f\n\nSensitivity:\n  r=0.3: %s\n  r=0.5: %s\n  r=0.7: %s",
      input$sdc_r, r$sd_change,
      ifelse(is.na(sens[["r_0.3"]]), "undefined (negative under sqrt)", sprintf("%.4f", sens[["r_0.3"]])),
      ifelse(is.na(sens[["r_0.5"]]), "undefined (negative under sqrt)", sprintf("%.4f", sens[["r_0.5"]])),
      ifelse(is.na(sens[["r_0.7"]]), "undefined (negative under sqrt)", sprintf("%.4f", sens[["r_0.7"]]))
    )
  })
  shiny::observeEvent(input$sdc_send, {
    r <- sdc_res()
    shiny::req(r, r$ok)
    append_workspace_row(input$sdc_study, input$sdc_group,
                          sprintf("SD change (r=%.2f)", input$sdc_r), NA_real_, r$sd_change, NA_real_)
  })

  # -- Combine groups -----------------------------------------------------------
  output$combine_table <- rhandsontable::renderRHandsontable({
    default_df <- data.frame(N = c(NA_real_, NA_real_), Mean = c(NA_real_, NA_real_),
                              SD = c(NA_real_, NA_real_))
    rhandsontable::rhandsontable(default_df, rowHeaders = TRUE) |>
      rhandsontable::hot_context_menu(allowRowEdit = TRUE, allowColEdit = FALSE)
  })
  comb_res <- shiny::reactiveVal(NULL)
  shiny::observeEvent(input$comb_calc, {
    shiny::req(input$combine_table)
    tbl <- rhandsontable::hot_to_r(input$combine_table)
    tbl <- tbl[stats::complete.cases(tbl), , drop = FALSE]
    if (nrow(tbl) < 2) {
      comb_res(list(ok = FALSE, message = "Provide at least 2 complete rows (N, Mean, SD)."))
    } else {
      comb_res(combine_groups(n = tbl$N, mean = tbl$Mean, sd = tbl$SD))
    }
  })
  output$comb_result <- shiny::renderText({
    format_result_text(comb_res(), function(r) sprintf(
      "Combined N: %.0f\nCombined Mean: %.4f\nCombined SD: %.4f", r$n, r$mean, r$sd
    ))
  })
  shiny::observeEvent(input$comb_send, {
    r <- comb_res()
    shiny::req(r, r$ok)
    append_workspace_row(input$comb_study, input$comb_group, "Combined groups", r$mean, r$sd, r$n)
  })

  # -- Split shared control group -----------------------------------------------
  split_res <- shiny::reactiveVal(NULL)
  shiny::observeEvent(input$split_calc, {
    split_res(split_control(n_control = input$split_n, k = input$split_k,
                             mean_control = input$split_mean, sd_control = input$split_sd))
  })
  output$split_result <- shiny::renderText({
    format_result_text(split_res(), function(r) sprintf(
      "Adjusted N per comparison: %.0f (x%d comparisons)\nMean/SD unchanged: %s / %s",
      r$n_adjusted, input$split_k,
      ifelse(is.na(r$mean), "(not provided)", sprintf("%.4f", r$mean)),
      ifelse(is.na(r$sd), "(not provided)", sprintf("%.4f", r$sd))
    ))
  })
  shiny::observeEvent(input$split_send, {
    r <- split_res()
    shiny::req(r, r$ok)
    for (i in seq_len(input$split_k)) {
      label <- paste0(ifelse(input$split_group == "", "control", input$split_group), "_", i)
      append_workspace_row(input$split_study, label, "Split control", r$mean, r$sd, r$n_adjusted)
    }
  })

  # -- Workspace -----------------------------------------------------------------
  output$workspace_table <- rhandsontable::renderRHandsontable({
    rhandsontable::rhandsontable(workspace_data(), rowHeaders = TRUE) |>
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
