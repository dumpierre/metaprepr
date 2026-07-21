# DataPrepR UI: bslib::page_navbar with grouped nav.
# Each calculator: inputs on the left, a Result card, and a "Send to
# Workspace" button. See app_server.R for the corresponding logic.

result_card <- function(output_id, title = "Result") {
  bslib::card(
    bslib::card_header(title, class = "bg-success text-white"),
    bslib::card_body(shiny::verbatimTextOutput(output_id))
  )
}

study_group_inputs <- function(prefix) {
  shiny::tagList(
    shiny::hr(),
    shiny::textInput(paste0(prefix, "_study"), "Study ID (optional):", value = ""),
    shiny::textInput(paste0(prefix, "_group"), "Group label (optional):", value = "")
  )
}

send_button <- function(prefix) {
  shiny::actionButton(paste0(prefix, "_send"), "Send to Workspace", class = "btn-success")
}

calc_button <- function(prefix) {
  shiny::actionButton(paste0(prefix, "_calc"), "Calculate", class = "btn-primary me-2")
}

# ---------------------------------------------------------------------------
# Basic transforms
# ---------------------------------------------------------------------------

se_to_sd_panel <- bslib::nav_panel(
  title = "SE -> SD",
  bslib::layout_columns(
    bslib::card(
      bslib::card_header("Standard Error -> Standard Deviation"),
      bslib::card_body(
        shiny::p(class = "text-muted", "SD = SE * sqrt(n). Cochrane Handbook 6.5.2.3."),
        shiny::numericInput("se_se", "Standard Error (SE):", value = NA, min = 0, step = 0.01),
        shiny::numericInput("se_n", "Sample size (n):", value = NA, min = 1, step = 1),
        study_group_inputs("se"),
        shiny::hr(),
        calc_button("se"), send_button("se")
      )
    ),
    result_card("se_result"),
    col_widths = c(6, 6)
  )
)

ci_to_sd_panel <- bslib::nav_panel(
  title = "95% CI -> SD",
  bslib::layout_columns(
    bslib::card(
      bslib::card_header("95% Confidence Interval (of a mean) -> Standard Deviation"),
      bslib::card_body(
        shiny::p(class = "text-muted",
                 "Assumes a symmetric 95% CI for a mean. SE = (upper-lower)/(2*crit); SD = SE*sqrt(n)."),
        shiny::numericInput("ci_lower", "Lower bound:", value = NA, step = 0.01),
        shiny::numericInput("ci_upper", "Upper bound:", value = NA, step = 0.01),
        shiny::numericInput("ci_n", "Sample size (n):", value = NA, min = 2, step = 1),
        shiny::radioButtons("ci_mode", "Critical value:",
                             choices = c("t distribution (exact, recommended)" = "t",
                                         "Normal approximation (z = 1.96)" = "z"),
                             selected = "t"),
        shiny::div(class = "alert alert-info",
                   "The t and z critical values diverge for small n; using z when n is small "
                   , "understates SD. Prefer t unless you have a specific reason to use z."),
        study_group_inputs("ci"),
        shiny::hr(),
        calc_button("ci"), send_button("ci")
      )
    ),
    result_card("ci_result"),
    col_widths = c(6, 6)
  )
)

iqr_to_sd_panel <- bslib::nav_panel(
  title = "IQR -> SD",
  bslib::layout_columns(
    bslib::card(
      bslib::card_header("Interquartile Range -> Standard Deviation"),
      bslib::card_body(
        shiny::p(class = "text-muted", "SD = (Q3 - Q1) / 1.35 (normal approximation)."),
        shiny::numericInput("iqr_q1", "Q1 (first quartile):", value = NA, step = 0.01),
        shiny::numericInput("iqr_q3", "Q3 (third quartile):", value = NA, step = 0.01),
        shiny::div(class = "alert alert-info",
                   "This assumes approximate normality. When the sample size is known, the ",
                   "Wan (2014) method under \"Median-based estimation\" is preferable."),
        study_group_inputs("iqr"),
        shiny::hr(),
        calc_button("iqr"), send_button("iqr")
      )
    ),
    result_card("iqr_result"),
    col_widths = c(6, 6)
  )
)

# ---------------------------------------------------------------------------
# Median-based estimation
# ---------------------------------------------------------------------------

median_panel <- bslib::nav_panel(
  title = "Median -> Mean & SD",
  bslib::layout_columns(
    bslib::card(
      bslib::card_header("Median/Range/IQR -> Mean & Standard Deviation"),
      bslib::card_body(
        shiny::radioButtons("med_method", "Method:",
                             choices = c("Wan (2014) - default" = "wan",
                                         "Hozo (2005) - range only" = "hozo",
                                         "Luo (2018) mean + Wan (2014) SD" = "luo"),
                             selected = "wan"),
        shiny::numericInput("med_n", "Sample size (n):", value = NA, min = 1, step = 1),
        shiny::numericInput("med_min", "Minimum:", value = NA, step = 0.01),
        shiny::conditionalPanel(
          condition = "input.med_method != 'hozo'",
          shiny::numericInput("med_q1", "Q1 (first quartile):", value = NA, step = 0.01)
        ),
        shiny::numericInput("med_median", "Median:", value = NA, step = 0.01),
        shiny::conditionalPanel(
          condition = "input.med_method != 'hozo'",
          shiny::numericInput("med_q3", "Q3 (third quartile):", value = NA, step = 0.01)
        ),
        shiny::numericInput("med_max", "Maximum:", value = NA, step = 0.01),
        shiny::div(
          class = "alert alert-info",
          shiny::conditionalPanel(
            condition = "input.med_method == 'hozo'",
            shiny::p("Hozo needs min, median, max, n (S1 only). SD formula switches at n<=15, ",
                     "n<=70, n>70; mean uses the full range formula for n<=25, median alone above.")
          ),
          shiny::conditionalPanel(
            condition = "input.med_method != 'hozo'",
            shiny::p("Wan/Luo support three scenarios - fill in what your source reports: ",
                     "min+median+max (S1), Q1+median+Q3 (S2), or all five (S3). Leave the rest blank.")
          )
        ),
        study_group_inputs("med"),
        shiny::hr(),
        calc_button("med"), send_button("med")
      )
    ),
    result_card("med_result"),
    col_widths = c(6, 6)
  )
)

# ---------------------------------------------------------------------------
# Meta-analysis adjustments
# ---------------------------------------------------------------------------

sd_change_panel <- bslib::nav_panel(
  title = "SD of Change",
  bslib::layout_columns(
    bslib::card(
      bslib::card_header("Standard Deviation of Change from Baseline"),
      bslib::card_body(
        shiny::p(class = "text-muted",
                 "SD_change = sqrt(SD_base^2 + SD_final^2 - 2*r*SD_base*SD_final)"),
        shiny::numericInput("sdc_base", "SD at baseline:", value = NA, min = 0, step = 0.01),
        shiny::numericInput("sdc_final", "SD at final measurement:", value = NA, min = 0, step = 0.01),
        shiny::sliderInput("sdc_r", "Assumed correlation r:", min = -1, max = 1, value = 0.5, step = 0.05),
        shiny::div(class = "alert alert-info",
                   "Cochrane's default imputation is r = 0.5 when the true correlation is unknown."),
        study_group_inputs("sdc"),
        shiny::hr(),
        calc_button("sdc"), send_button("sdc")
      )
    ),
    result_card("sdc_result"),
    col_widths = c(6, 6)
  )
)

combine_groups_panel <- bslib::nav_panel(
  title = "Combine Groups",
  bslib::layout_columns(
    bslib::card(
      bslib::card_header("Combine k >= 2 Groups (Cochrane Handbook Table 6.5.a)"),
      bslib::card_body(
        shiny::p(class = "text-muted",
                 "Edit the table below (add rows for k > 2 groups), then combine."),
        rhandsontable::rHandsontableOutput("combine_table"),
        shiny::hr(),
        study_group_inputs("comb"),
        shiny::hr(),
        calc_button("comb"), send_button("comb")
      )
    ),
    result_card("comb_result"),
    col_widths = c(6, 6)
  )
)

split_control_panel <- bslib::nav_panel(
  title = "Split Shared Control",
  bslib::layout_columns(
    bslib::card(
      bslib::card_header("Split a Shared Control Group Across k Comparisons"),
      bslib::card_body(
        shiny::p(class = "text-muted", "n_adjusted = round(n_control / k); mean/SD unchanged."),
        shiny::numericInput("split_n", "Control group N:", value = NA, min = 1, step = 1),
        shiny::numericInput("split_k", "Number of comparisons (k):", value = 2, min = 2, step = 1),
        shiny::numericInput("split_mean", "Control group mean (optional):", value = NA, step = 0.01),
        shiny::numericInput("split_sd", "Control group SD (optional):", value = NA, min = 0, step = 0.01),
        shiny::div(class = "alert alert-info",
                   "This is the simple Cochrane approximation to avoid double-counting a shared ",
                   "control group. For a rigorous alternative, use network/multivariate meta-analysis."),
        shiny::textInput("split_study", "Study ID (optional):", value = ""),
        shiny::textInput("split_group", "Group label prefix (optional):", value = "control"),
        shiny::hr(),
        calc_button("split"),
        shiny::actionButton("split_send", "Send all k rows to Workspace", class = "btn-success")
      )
    ),
    result_card("split_result"),
    col_widths = c(6, 6)
  )
)

# ---------------------------------------------------------------------------
# Workspace
# ---------------------------------------------------------------------------

workspace_panel <- bslib::nav_panel(
  title = "Workspace",
  bslib::card(
    bslib::card_header("Workspace"),
    bslib::card_body(
      shiny::p(class = "text-muted",
               "Results sent from any calculator land here. Edit directly in the table if needed."),
      rhandsontable::rHandsontableOutput("workspace_table"),
      shiny::hr(),
      shiny::downloadButton("download_csv", "Download CSV", class = "btn-outline-primary me-2"),
      shiny::downloadButton("download_xlsx", "Download XLSX", class = "btn-outline-primary")
    )
  )
)

# ---------------------------------------------------------------------------
# Top-level UI
# ---------------------------------------------------------------------------

app_ui <- bslib::page_navbar(
  title = "DataPrepR",
  theme = bslib::bs_theme(version = 5, bootswatch = "flatly"),
  bslib::nav_menu(
    title = "Basic transforms",
    se_to_sd_panel, ci_to_sd_panel, iqr_to_sd_panel
  ),
  bslib::nav_menu(
    title = "Median-based estimation",
    median_panel
  ),
  bslib::nav_menu(
    title = "Meta-analysis adjustments",
    sd_change_panel, combine_groups_panel, split_control_panel
  ),
  workspace_panel
)
