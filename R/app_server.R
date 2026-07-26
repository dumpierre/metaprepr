# MetaPrepR server logic. Each calculator follows the same pattern:
#   1. a reactive state: "empty" (nothing typed yet), "error" (validation
#      message from the calc_*() function), or "ok" (plus its numbers)
#   2. output$X_banner renders that state as an alert, live as the user types
#   3. an observer enables/disables the X_send button to match the state
#   4. observeEvent(input$X_send) appends a row to the shared workspace
#
# There is no Calculate button: results update on every keystroke, and the
# Send button is the only guarded action. The send handlers re-check ok
# server-side, so a disabled button that is defeated in the browser still
# cannot write a bad row.
#
# Language comes from the `?lang=` query string and does not change
# reactively within a session (switching language is a full page reload).
# current_lang() re-derives it from session$clientData$url_search on every
# call rather than caching a single read at server startup, since clientData
# is only populated after the client's first round-trip - reading it eagerly
# at the top of this function would see it before it exists.

# The workspace carries two provenance columns: Tool is the stable slug from
# R/translations.R (never translated, safe to filter on in exported data) and
# Method is the human-readable, translated description of what was applied.
empty_workspace <- function() {
  data.frame(
    Study_ID = character(0), Group_Label = character(0),
    Tool = character(0), Method = character(0),
    Mean = numeric(0), SD = numeric(0), N = numeric(0),
    stringsAsFactors = FALSE
  )
}

# TRUE when every supplied value is absent - used to tell "nothing typed yet"
# apart from "typed something invalid", so an untouched form shows a neutral
# prompt rather than a validation error.
all_blank <- function(...) {
  vals <- list(...)
  all(vapply(vals, function(v) is.null(v) || length(v) == 0 || all(is.na(v)), logical(1)))
}

# Format a number for display; an em-free dash when missing
fmt_num <- function(x, d = 4) {
  if (is.null(x) || length(x) == 0 || is.na(x)) return("-")
  formatC(x, format = "f", digits = d)
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

  ga_event <- function(name, params = list()) {
    session$sendCustomMessage("ga_event", list(name = name, params = params))
  }

  # ---------------------------------------------------------------------------
  # Banner helpers
  # ---------------------------------------------------------------------------

  # Turn a state into an alert: neutral prompt, validation warning, or the
  # tool's own success node.
  render_banner <- function(state, ok_node) {
    if (identical(state$status, "empty")) {
      return(shiny::div(class = "alert alert-secondary mb-0", t("result_awaiting")))
    }
    if (identical(state$status, "error")) {
      return(shiny::div(class = "alert alert-warning mb-0",
                        paste(t("result_error_prefix"),
                              render_message(state$code, state$args, current_lang()))))
    }
    ok_node
  }

  # A success alert made of label/value rows
  ok_rows <- function(...) {
    rows <- list(...)
    shiny::div(
      class = "alert alert-success mb-0",
      lapply(rows, function(r) {
        shiny::div(class = "d-flex justify-content-between align-items-center",
                   shiny::tags$span(shiny::strong(r$label)),
                   shiny::tags$span(class = "fw-semibold", r$value))
      })
    )
  }
  row_of <- function(label, value) list(label = label, value = value)

  # Wrap a calc_*() result as a state, given whether the form is untouched
  state_from <- function(res, blank) {
    if (blank) return(list(status = "empty"))
    if (!isTRUE(res$ok)) return(list(status = "error", code = res$code, args = res$args))
    c(list(status = "ok"), res)
  }

  # Keep a Send button's enabled state in step with its tool's validity
  guard_send <- function(id, state_fn) {
    shiny::observe({
      session$sendCustomMessage(
        "toggle_enabled",
        list(id = id, enabled = identical(state_fn()$status, "ok"))
      )
    })
  }

  # ---------------------------------------------------------------------------
  # Workspace store
  # ---------------------------------------------------------------------------

  workspace_data <- shiny::reactiveVal(empty_workspace())

  append_workspace_row <- function(study_id, group_label, tool, method, mean, sd, n) {
    new_row <- data.frame(
      Study_ID = if (is.null(study_id) || !nzchar(study_id)) NA_character_ else study_id,
      Group_Label = if (is.null(group_label) || !nzchar(group_label)) NA_character_ else group_label,
      Tool = tool,
      Method = method,
      Mean = if (is.null(mean) || length(mean) == 0) NA_real_ else as.numeric(mean),
      SD = if (is.null(sd) || length(sd) == 0) NA_real_ else as.numeric(sd),
      N = if (is.null(n) || length(n) == 0) NA_real_ else as.numeric(n),
      stringsAsFactors = FALSE
    )
    workspace_data(rbind(workspace_data(), new_row))
  }

  # Append + notify + log, the tail end of every send handler
  send_row <- function(prefix, study_id, group_label, method, mean, sd, n) {
    slug <- tool_slug(prefix)
    append_workspace_row(study_id, group_label, slug, method, mean, sd, n)
    shiny::showNotification(t("msg_sent"), type = "message")
    ga_event("calc_send", list(tool = slug))
  }

  workspace_col_headers <- function() {
    c(t("col_study_id"), t("col_group_label"), t("col_tool"), t("col_method"),
      t("col_mean"), t("col_sd"), t("col_n"))
  }

  # ---------------------------------------------------------------------------
  # SE -> SD
  # ---------------------------------------------------------------------------
  se_state <- shiny::reactive({
    state_from(calc_se_to_sd(se = input$se_se, n = input$se_n),
               all_blank(input$se_se, input$se_n))
  })
  output$se_banner <- shiny::renderUI({
    st <- se_state()
    render_banner(st, ok_rows(row_of(t("result_label_sd"), fmt_num(st$sd))))
  })
  guard_send("se_send", se_state)
  shiny::observeEvent(input$se_send, {
    st <- se_state()
    shiny::req(identical(st$status, "ok"))
    send_row("se", input$se_study, input$se_group, t("method_se"),
             input$se_mean, st$sd, input$se_n)
  })

  # ---------------------------------------------------------------------------
  # 95% CI -> SD
  # ---------------------------------------------------------------------------
  ci_state <- shiny::reactive({
    state_from(
      calc_ci_to_sd(lower = input$ci_lower, upper = input$ci_upper, n = input$ci_n,
                    crit_method = input$ci_mode),
      all_blank(input$ci_lower, input$ci_upper, input$ci_n)
    )
  })
  output$ci_banner <- shiny::renderUI({
    st <- ci_state()
    render_banner(st, ok_rows(
      row_of(t("result_label_sd"), fmt_num(st$sd)),
      row_of(sprintf("%s (%s)", t("result_crit_label"), input$ci_mode), fmt_num(st$t_or_z))
    ))
  })
  guard_send("ci_send", ci_state)
  shiny::observeEvent(input$ci_send, {
    st <- ci_state()
    shiny::req(identical(st$status, "ok"))
    send_row("ci", input$ci_study, input$ci_group,
             sprintf("%s (%s)", t("nav_ci"), input$ci_mode),
             input$ci_mean, st$sd, input$ci_n)
  })

  # ---------------------------------------------------------------------------
  # IQR -> SD
  # ---------------------------------------------------------------------------
  iqr_state <- shiny::reactive({
    state_from(calc_iqr_to_sd(q1 = input$iqr_q1, q3 = input$iqr_q3),
               all_blank(input$iqr_q1, input$iqr_q3))
  })
  output$iqr_banner <- shiny::renderUI({
    st <- iqr_state()
    render_banner(st, ok_rows(row_of(t("result_label_sd"), fmt_num(st$sd))))
  })
  guard_send("iqr_send", iqr_state)
  shiny::observeEvent(input$iqr_send, {
    st <- iqr_state()
    shiny::req(identical(st$status, "ok"))
    send_row("iqr", input$iqr_study, input$iqr_group, t("method_iqr"),
             input$iqr_mean, st$sd, input$iqr_n)
  })

  # ---------------------------------------------------------------------------
  # Median/range/IQR -> mean & SD
  # ---------------------------------------------------------------------------
  med_state <- shiny::reactive({
    state_from(
      calc_median_to_mean_sd(
        min_val = input$med_min, q1_val = input$med_q1, med_val = input$med_median,
        q3_val = input$med_q3, max_val = input$med_max, n = input$med_n,
        method = input$med_method
      ),
      all_blank(input$med_min, input$med_q1, input$med_median,
                input$med_q3, input$med_max, input$med_n)
    )
  })
  med_method_label <- function() {
    switch(input$med_method,
           hozo = t("method_hozo"),
           wan = t("method_wan"),
           luo = t("method_luo"))
  }
  output$med_banner <- shiny::renderUI({
    st <- med_state()
    render_banner(st, ok_rows(
      row_of(t("result_scenario_label"),
             sprintf("%s (%s)", st$scenario, scenario_label(st$scenario, current_lang()))),
      row_of(t("result_label_mean"), fmt_num(st$mean)),
      row_of(t("result_label_sd"), fmt_num(st$sd))
    ))
  })
  guard_send("med_send", med_state)
  shiny::observeEvent(input$med_send, {
    st <- med_state()
    shiny::req(identical(st$status, "ok"))
    send_row("med", input$med_study, input$med_group,
             paste0(med_method_label(), " [", st$scenario, "]"),
             st$mean, st$sd, input$med_n)
  })

  # ---------------------------------------------------------------------------
  # SD of change from baseline
  # ---------------------------------------------------------------------------
  sdc_state <- shiny::reactive({
    state_from(
      calc_sd_change(sd_base = input$sdc_base, sd_final = input$sdc_final, r = input$sdc_r),
      all_blank(input$sdc_base, input$sdc_final)
    )
  })
  output$sdc_banner <- shiny::renderUI({
    st <- sdc_state()
    # The sensitivity readout is worth showing even when the chosen r drives the
    # variance negative, since it points at which r values would work instead.
    sens_node <- function(sens) {
      if (is.null(sens)) return(NULL)
      shiny::div(
        class = "mt-2 small",
        shiny::strong(t("result_sensitivity_header")), " ",
        paste(vapply(c("r_0.3", "r_0.5", "r_0.7"), function(k) {
          v <- sens[[k]]
          sprintf("%s = %s", sub("r_", "r=", k),
                  if (is.na(v)) t("result_sd_change_undefined") else fmt_num(v))
        }, character(1)), collapse = "; ")
      )
    }
    if (identical(sdc_state()$status, "error")) {
      return(shiny::div(
        class = "alert alert-warning mb-0",
        paste(t("result_error_prefix"), render_message(st$code, st$args, current_lang())),
        sens_node(st$sensitivity)
      ))
    }
    render_banner(st, shiny::div(
      class = "alert alert-success mb-0",
      shiny::div(class = "d-flex justify-content-between align-items-center",
                 shiny::tags$span(shiny::strong(sprintf("%s (r=%.2f)", t("result_label_sd"),
                                                        input$sdc_r))),
                 shiny::tags$span(class = "fw-semibold", fmt_num(st$sd_change))),
      sens_node(st$sensitivity)
    ))
  })
  guard_send("sdc_send", sdc_state)
  shiny::observeEvent(input$sdc_send, {
    st <- sdc_state()
    shiny::req(identical(st$status, "ok"))
    send_row("sdc", input$sdc_study, input$sdc_group,
             sprintf("%s (r=%.2f)", t("nav_sdchange"), input$sdc_r),
             input$sdc_mean, st$sd_change, input$sdc_n)
  })

  # ---------------------------------------------------------------------------
  # Combine groups
  # ---------------------------------------------------------------------------
  output$combine_table <- rhandsontable::renderRHandsontable({
    default_df <- data.frame(N = c(NA_real_, NA_real_), Mean = c(NA_real_, NA_real_),
                             SD = c(NA_real_, NA_real_))
    rhandsontable::rhandsontable(default_df, rowHeaders = TRUE,
                                 colHeaders = c(t("col_n"), t("col_mean"), t("col_sd"))) |>
      rhandsontable::hot_context_menu(allowRowEdit = TRUE, allowColEdit = FALSE)
  })

  comb_state <- shiny::reactive({
    if (is.null(input$combine_table)) return(list(status = "empty"))
    tbl <- rhandsontable::hot_to_r(input$combine_table)
    complete <- tbl[stats::complete.cases(tbl), , drop = FALSE]
    if (nrow(complete) == 0) return(list(status = "empty"))
    if (nrow(complete) < 2) {
      return(list(status = "error", code = "__combine_row_error__", args = NULL))
    }
    state_from(combine_groups(n = complete$N, mean = complete$Mean, sd = complete$SD), FALSE)
  })
  output$comb_banner <- shiny::renderUI({
    st <- comb_state()
    if (identical(st$code, "__combine_row_error__")) {
      return(shiny::div(class = "alert alert-warning mb-0",
                        paste(t("result_error_prefix"), t("combine_row_error"))))
    }
    render_banner(st, ok_rows(
      row_of(t("result_label_n"), fmt_num(st$n, 0)),
      row_of(t("result_label_mean"), fmt_num(st$mean)),
      row_of(t("result_label_sd"), fmt_num(st$sd))
    ))
  })
  guard_send("comb_send", comb_state)
  shiny::observeEvent(input$comb_send, {
    st <- comb_state()
    shiny::req(identical(st$status, "ok"))
    send_row("comb", input$comb_study, input$comb_group, t("method_combine"),
             st$mean, st$sd, st$n)
  })

  # ---------------------------------------------------------------------------
  # Split shared control group
  # ---------------------------------------------------------------------------
  # Arm sizes arrive as free text ("72, 73, 76") so the user can type them
  # without a variable number of numericInputs. Anything unparseable becomes
  # NA and is rejected by split_control()'s own validation.
  parse_arm_n <- function(txt) {
    if (is.null(txt) || !nzchar(trimws(txt))) return(numeric(0))
    parts <- trimws(strsplit(txt, "[,;[:space:]]+")[[1]])
    as.list(suppressWarnings(as.numeric(parts[nzchar(parts)])))
  }
  split_state <- shiny::reactive({
    state_from(
      split_control(n_control = input$split_n, k = input$split_k,
                    mean_control = input$split_mean, sd_control = input$split_sd,
                    weighting = input$split_weighting,
                    arm_n = parse_arm_n(input$split_arm_n)),
      all_blank(input$split_n)
    )
  })
  output$split_banner <- shiny::renderUI({
    st <- split_state()
    render_banner(st, ok_rows(
      row_of(t("result_label_n_per_comparison"), paste(st$n_adjusted, collapse = ", ")),
      row_of(t("result_label_n_total"), sum(st$n_adjusted)),
      row_of(t("result_label_mean_sd_slash"),
             sprintf("%s / %s",
                     if (is.na(st$mean)) t("result_not_provided") else fmt_num(st$mean),
                     if (is.na(st$sd)) t("result_not_provided") else fmt_num(st$sd)))
    ))
  })
  guard_send("split_send", split_state)
  shiny::observeEvent(input$split_send, {
    st <- split_state()
    shiny::req(identical(st$status, "ok"))
    slug <- tool_slug("split")
    prefix <- if (is.null(input$split_group) || !nzchar(input$split_group)) "control" else input$split_group
    for (i in seq_along(st$n_adjusted)) {
      append_workspace_row(input$split_study, paste0(prefix, "_", i), slug,
                           t("method_split"), st$mean, st$sd, st$n_adjusted[i])
    }
    shiny::showNotification(sprintf(t("msg_sent_split"), length(st$n_adjusted)), type = "message")
    ga_event("calc_send", list(tool = slug))
  })

  # ---------------------------------------------------------------------------
  # Workspace: sidebar preview, table, guarded clear, downloads
  # ---------------------------------------------------------------------------
  output$ws_summary <- shiny::renderUI({
    n <- nrow(workspace_data())
    if (n == 0) {
      shiny::div(class = "text-muted small", t("sidebar_ws_empty"))
    } else {
      shiny::tags$p(class = "small", shiny::strong(t("sidebar_ws_rows")), " ", n)
    }
  })

  output$ws_preview <- shiny::renderTable({
    df <- workspace_data()
    if (nrow(df) == 0) return(NULL)
    utils::tail(df[, c("Tool", "Mean", "SD", "N")], 5)
  }, na = "", digits = 3, width = "100%", striped = TRUE, spacing = "xs")

  output$workspace_table <- rhandsontable::renderRHandsontable({
    rhandsontable::rhandsontable(workspace_data(), rowHeaders = TRUE,
                                 colHeaders = workspace_col_headers()) |>
      rhandsontable::hot_context_menu(allowRowEdit = TRUE, allowColEdit = FALSE)
  })

  # Manual edits live in the table widget until they are exported; reading them
  # back into workspace_data() here would re-render the table under the user's
  # cursor, so the export path reads the widget directly instead.
  current_workspace <- function() {
    if (!is.null(input$workspace_table)) {
      rhandsontable::hot_to_r(input$workspace_table)
    } else {
      workspace_data()
    }
  }

  shiny::observeEvent(input$clear_table, {
    n <- nrow(workspace_data())
    shiny::showModal(shiny::modalDialog(
      title = t("modal_clear_title"),
      sprintf(t("modal_clear_body"), n),
      footer = shiny::tagList(
        shiny::modalButton(t("btn_cancel")),
        shiny::actionButton("clear_confirm", t("btn_delete"), class = "btn-danger")
      ),
      easyClose = TRUE
    ))
  })
  shiny::observeEvent(input$clear_confirm, {
    workspace_data(empty_workspace())
    shiny::removeModal()
    shiny::showNotification(t("msg_cleared"), type = "message")
    ga_event("clear_table")
  })

  output$download_csv <- shiny::downloadHandler(
    filename = function() paste0("metaprepr_workspace_", Sys.Date(), ".csv"),
    content = function(file) {
      utils::write.csv(current_workspace(), file, row.names = FALSE, na = "")
      ga_event("export_csv")
    }
  )
  output$download_xlsx <- shiny::downloadHandler(
    filename = function() paste0("metaprepr_workspace_", Sys.Date(), ".xlsx"),
    content = function(file) {
      writexl::write_xlsx(current_workspace(), file)
      ga_event("export_xlsx")
    }
  )
}
