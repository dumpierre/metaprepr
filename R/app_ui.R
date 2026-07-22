# DataPrepR UI: bslib::page_navbar with grouped nav.
# Each calculator: inputs on the left, a Result card, and a "Send to
# workspace" button. See app_server.R for the corresponding logic and
# R/translations.R for the language strings used throughout.
#
# The UI is a function of `request` so that language can be chosen via a
# `?lang=pt` query parameter (default "en") without any added dependency or
# reactive UI-rebuild - switching language is a full page reload.

app_theme <- bslib::bs_theme(
  version = 5,
  bg = "#f7f5ef",
  fg = "#1b2a4a",
  primary = "#b8712a",
  secondary = "#2f6f62",
  success = "#2f6f62",
  base_font = "ui-sans-serif, -apple-system, \"Segoe UI\", Helvetica, Arial, sans-serif",
  heading_font = "\"Iowan Old Style\", Georgia, \"Times New Roman\", serif",
  code_font = "ui-monospace, \"Cascadia Code\", \"SF Mono\", Consolas, monospace"
)
app_theme <- bslib::bs_add_rules(app_theme, "
  .alert-info {
    background-color: #e4ede9;
    border-color: #2f6f62;
    color: #204840;
  }
  .app-result-card > .card-header {
    background-color: #fffdf8;
    color: #1b2a4a;
    border-bottom: 2px solid #cfc7ae;
    font-weight: 600;
  }
  input[type='radio'] {
    accent-color: #b8712a;
  }
  .navbar {
    border-bottom: 1px solid #cfc7ae;
  }
  .lang-toggle {
    font-size: 0.85rem;
    align-self: center;
  }
")

result_card <- function(output_id, lang) {
  bslib::card(
    class = "app-result-card",
    bslib::card_header(tr("card_result", lang)),
    bslib::card_body(shiny::verbatimTextOutput(output_id))
  )
}

study_group_inputs <- function(prefix, lang) {
  shiny::tagList(
    shiny::hr(),
    shiny::textInput(paste0(prefix, "_study"), tr("lbl_study_id", lang), value = ""),
    shiny::textInput(paste0(prefix, "_group"), tr("lbl_group_label", lang), value = "")
  )
}

send_button <- function(prefix, lang) {
  shiny::actionButton(paste0(prefix, "_send"), tr("btn_send", lang), class = "btn-success")
}

calc_button <- function(prefix, lang) {
  shiny::actionButton(paste0(prefix, "_calc"), tr("btn_calculate", lang), class = "btn-primary me-2")
}

build_panels <- function(lang) {
  t <- function(key) tr(key, lang)

  # -- Basic transforms -------------------------------------------------------

  se_to_sd_panel <- bslib::nav_panel(
    title = t("nav_se"),
    bslib::layout_columns(
      bslib::card(
        bslib::card_header(t("card_se")),
        bslib::card_body(
          shiny::p(class = "text-muted", t("help_se")),
          shiny::numericInput("se_se", t("lbl_se"), value = NA, min = 0, step = 0.01),
          shiny::numericInput("se_n", t("lbl_n"), value = NA, min = 1, step = 1),
          study_group_inputs("se", lang),
          shiny::hr(),
          calc_button("se", lang), send_button("se", lang)
        )
      ),
      result_card("se_result", lang),
      col_widths = c(6, 6)
    )
  )

  ci_to_sd_panel <- bslib::nav_panel(
    title = t("nav_ci"),
    bslib::layout_columns(
      bslib::card(
        bslib::card_header(t("card_ci")),
        bslib::card_body(
          shiny::p(class = "text-muted", t("help_ci")),
          shiny::numericInput("ci_lower", t("lbl_lower"), value = NA, step = 0.01),
          shiny::numericInput("ci_upper", t("lbl_upper"), value = NA, step = 0.01),
          shiny::numericInput("ci_n", t("lbl_n"), value = NA, min = 2, step = 1),
          shiny::radioButtons("ci_mode", t("lbl_crit_method"),
                               choices = stats::setNames(c("t", "z"), c(t("choice_t"), t("choice_z"))),
                               selected = "t"),
          shiny::div(class = "alert alert-info", t("alert_ci")),
          study_group_inputs("ci", lang),
          shiny::hr(),
          calc_button("ci", lang), send_button("ci", lang)
        )
      ),
      result_card("ci_result", lang),
      col_widths = c(6, 6)
    )
  )

  iqr_to_sd_panel <- bslib::nav_panel(
    title = t("nav_iqr"),
    bslib::layout_columns(
      bslib::card(
        bslib::card_header(t("card_iqr")),
        bslib::card_body(
          shiny::p(class = "text-muted", t("help_iqr")),
          shiny::numericInput("iqr_q1", t("lbl_q1"), value = NA, step = 0.01),
          shiny::numericInput("iqr_q3", t("lbl_q3"), value = NA, step = 0.01),
          shiny::div(class = "alert alert-info", t("alert_iqr")),
          study_group_inputs("iqr", lang),
          shiny::hr(),
          calc_button("iqr", lang), send_button("iqr", lang)
        )
      ),
      result_card("iqr_result", lang),
      col_widths = c(6, 6)
    )
  )

  # -- Median-based estimation -------------------------------------------------

  median_panel <- bslib::nav_panel(
    title = t("nav_median"),
    bslib::layout_columns(
      bslib::card(
        bslib::card_header(t("card_median")),
        bslib::card_body(
          shiny::radioButtons(
            "med_method", t("lbl_method"),
            choices = stats::setNames(c("wan", "hozo", "luo"),
                                       c(t("choice_wan"), t("choice_hozo"), t("choice_luo"))),
            selected = "wan"
          ),
          shiny::numericInput("med_n", t("lbl_n"), value = NA, min = 1, step = 1),
          shiny::numericInput("med_min", t("lbl_min"), value = NA, step = 0.01),
          shiny::conditionalPanel(
            condition = "input.med_method != 'hozo'",
            shiny::numericInput("med_q1", t("lbl_q1"), value = NA, step = 0.01)
          ),
          shiny::numericInput("med_median", t("lbl_median"), value = NA, step = 0.01),
          shiny::conditionalPanel(
            condition = "input.med_method != 'hozo'",
            shiny::numericInput("med_q3", t("lbl_q3"), value = NA, step = 0.01)
          ),
          shiny::numericInput("med_max", t("lbl_max"), value = NA, step = 0.01),
          shiny::div(
            class = "alert alert-info",
            shiny::conditionalPanel(
              condition = "input.med_method == 'hozo'",
              shiny::p(t("help_hozo_fields"))
            ),
            shiny::conditionalPanel(
              condition = "input.med_method != 'hozo'",
              shiny::p(t("help_wanluo_fields"))
            )
          ),
          study_group_inputs("med", lang),
          shiny::hr(),
          calc_button("med", lang), send_button("med", lang)
        )
      ),
      result_card("med_result", lang),
      col_widths = c(6, 6)
    )
  )

  # -- Meta-analysis adjustments ------------------------------------------------

  sd_change_panel <- bslib::nav_panel(
    title = t("nav_sdchange"),
    bslib::layout_columns(
      bslib::card(
        bslib::card_header(t("card_sdchange")),
        bslib::card_body(
          shiny::p(class = "text-muted", t("help_sdchange")),
          shiny::numericInput("sdc_base", t("lbl_sd_base"), value = NA, min = 0, step = 0.01),
          shiny::numericInput("sdc_final", t("lbl_sd_final"), value = NA, min = 0, step = 0.01),
          shiny::sliderInput("sdc_r", t("lbl_r"), min = -1, max = 1, value = 0.5, step = 0.05),
          shiny::div(class = "alert alert-info", t("alert_sdchange")),
          study_group_inputs("sdc", lang),
          shiny::hr(),
          calc_button("sdc", lang), send_button("sdc", lang)
        )
      ),
      result_card("sdc_result", lang),
      col_widths = c(6, 6)
    )
  )

  combine_groups_panel <- bslib::nav_panel(
    title = t("nav_combine"),
    bslib::layout_columns(
      bslib::card(
        bslib::card_header(t("card_combine")),
        bslib::card_body(
          shiny::p(class = "text-muted", t("help_combine")),
          rhandsontable::rHandsontableOutput("combine_table"),
          shiny::hr(),
          study_group_inputs("comb", lang),
          shiny::hr(),
          calc_button("comb", lang), send_button("comb", lang)
        )
      ),
      result_card("comb_result", lang),
      col_widths = c(6, 6)
    )
  )

  split_control_panel <- bslib::nav_panel(
    title = t("nav_split"),
    bslib::layout_columns(
      bslib::card(
        bslib::card_header(t("card_split")),
        bslib::card_body(
          shiny::p(class = "text-muted", t("help_split")),
          shiny::numericInput("split_n", t("lbl_split_n"), value = NA, min = 1, step = 1),
          shiny::numericInput("split_k", t("lbl_split_k"), value = 2, min = 2, step = 1),
          shiny::numericInput("split_mean", t("lbl_split_mean"), value = NA, step = 0.01),
          shiny::numericInput("split_sd", t("lbl_split_sd"), value = NA, min = 0, step = 0.01),
          shiny::div(class = "alert alert-info", t("alert_split")),
          shiny::textInput("split_study", t("lbl_study_id"), value = ""),
          shiny::textInput("split_group", t("lbl_group_prefix"), value = "control"),
          shiny::hr(),
          calc_button("split", lang),
          shiny::actionButton("split_send", t("btn_send_split"), class = "btn-success")
        )
      ),
      result_card("split_result", lang),
      col_widths = c(6, 6)
    )
  )

  # -- Workspace ---------------------------------------------------------------

  workspace_panel <- bslib::nav_panel(
    title = t("nav_workspace"),
    bslib::card(
      bslib::card_header(t("card_workspace")),
      bslib::card_body(
        shiny::p(class = "text-muted", t("help_workspace")),
        rhandsontable::rHandsontableOutput("workspace_table"),
        shiny::hr(),
        shiny::downloadButton("download_csv", t("btn_download_csv"), class = "btn-outline-primary me-2"),
        shiny::downloadButton("download_xlsx", t("btn_download_xlsx"), class = "btn-outline-primary")
      )
    )
  )

  list(
    se_to_sd_panel = se_to_sd_panel, ci_to_sd_panel = ci_to_sd_panel, iqr_to_sd_panel = iqr_to_sd_panel,
    median_panel = median_panel,
    sd_change_panel = sd_change_panel, combine_groups_panel = combine_groups_panel,
    split_control_panel = split_control_panel,
    workspace_panel = workspace_panel
  )
}

app_ui <- function(request) {
  lang <- get_lang(request)
  t <- function(key) tr(key, lang)
  p <- build_panels(lang)

  other_lang_link <- if (lang == "pt") {
    shiny::tags$a(class = "lang-toggle nav-link", href = "?lang=en", tr("lang_toggle_to_en", lang))
  } else {
    shiny::tags$a(class = "lang-toggle nav-link", href = "?lang=pt", tr("lang_toggle_to_pt", lang))
  }

  bslib::page_navbar(
    title = t("app_title"),
    theme = app_theme,
    navbar_options = bslib::navbar_options(bg = "#fffdf8", theme = "light"),
    bslib::nav_menu(title = t("nav_basic_transforms"),
                     p$se_to_sd_panel, p$ci_to_sd_panel, p$iqr_to_sd_panel),
    bslib::nav_menu(title = t("nav_median_estimation"), p$median_panel),
    bslib::nav_menu(title = t("nav_meta_adjustments"),
                     p$sd_change_panel, p$combine_groups_panel, p$split_control_panel),
    p$workspace_panel,
    bslib::nav_spacer(),
    bslib::nav_item(other_lang_link)
  )
}
