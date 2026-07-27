# MetaPrepR UI: bslib::page_navbar with a persistent sidebar and grouped nav.
#
# Each calculator is one centred column: inputs, then a live result banner
# that updates as you type, then a "Send to workspace" button that stays
# disabled until the inputs are valid. There is no Calculate button - see
# app_server.R for the reactive state behind each banner, and
# R/translations.R for every string used here.
#
# The UI is a function of `request` so that language can be chosen via a
# `?lang=pt` query parameter (default "en") without any added dependency or
# reactive UI-rebuild - switching language is a full page reload.

# -----------------------------------------------------------------------------
# Theme and styling
# -----------------------------------------------------------------------------

# font_google() downloads and self-hosts the font files, which keeps the page
# from calling out to Google on every visitor's browser. That download happens
# on a cold container start, so a hosted deployment with no outbound network
# (or a Google Fonts hiccup) would otherwise fail to build the theme at all.
# Fall back to a system font stack instead of taking the app down with it.
font_or_stack <- function(family, stack) {
  tryCatch(bslib::font_google(family), error = function(e) stack)
}

app_theme <- bslib::bs_theme(
  version = 5,
  bootswatch = "flatly",
  primary = "#2f4b94",
  base_font = font_or_stack(
    "Inter", 'system-ui, -apple-system, "Segoe UI", Helvetica, Arial, sans-serif'),
  heading_font = font_or_stack(
    "Space Grotesk", 'system-ui, -apple-system, "Segoe UI", Helvetica, Arial, sans-serif'),
  code_font = font_or_stack(
    "IBM Plex Mono", 'ui-monospace, Consolas, "SF Mono", Menlo, monospace')
)

app_css <- shiny::tags$style(shiny::HTML("
  /* ---- Navbar: light, with a thin gradient accent on top ---------------- */
  .navbar { background-color:#ffffff !important; background-image:none !important;
            border-bottom:1px solid #e6e9ee; position:relative; box-shadow:none; }
  .navbar::before { content:''; position:absolute; top:0; left:0; right:0; height:3px;
            background:linear-gradient(90deg,#2f4b94,#12b3a6); }
  .navbar .navbar-brand { color:#1b2430 !important; font-family:'Space Grotesk',sans-serif;
            font-weight:600; letter-spacing:-.02em; font-size:1.12rem; }
  .navbar .nav-link { color:#3f4854 !important; font-weight:400;
            font-size:.75rem; padding-left:.55rem; padding-right:.55rem; }
  .navbar .nav-link:hover { color:#1b2430 !important; }
  .navbar .nav-link.active, .navbar .show > .nav-link { color:#26408a !important; font-weight:500; }
  /* The dropdown entries keep their normal size - only the bar itself shrinks. */
  .navbar .dropdown-menu { border:1px solid #e6e9ee; font-size:.9rem; }

  /* ---- Navbar toggle: make the hamburger visible -------------------------
     bslib fills the toggler icon with a white SVG, which is invisible against
     the white bar above. Repaint it in the nav-link ink and give the button an
     outline so it reads as a control. Covers both the Bootstrap 3 markup Shiny
     emits (.navbar-toggle > .icon-bar) and the Bootstrap 5 name. */
  .navbar .navbar-toggle > .icon-bar:last-child,
  .navbar .navbar-toggler-icon {
    --bs-navbar-toggler-icon-bg: url(\"data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 30 30'%3e%3cpath stroke='%233f4854' stroke-linecap='round' stroke-miterlimit='10' stroke-width='2.2' d='M4 7h22M4 15h22M4 23h22'/%3e%3c/svg%3e\");
  }
  .navbar .navbar-toggle, .navbar .navbar-toggler {
    border:1px solid #d7dce4 !important; border-radius:4px;
    padding:.3rem .45rem; background-color:transparent;
  }
  .navbar .navbar-toggle:hover, .navbar .navbar-toggler:hover { border-color:#2f4b94 !important; }

  /* ---- Where the navbar collapses ---------------------------------------
     Bootstrap collapses at 992px regardless of whether the labels still fit,
     so shrinking the type alone would not buy any extra width - the bar would
     hide itself at the same point, just in smaller letters. At .75rem the six
     menus need roughly 750px in English and 830px in Portuguese, so the
     expanded layout is re-asserted down to 900px and the hamburger only takes
     over below that. Mirrors Bootstrap's own min-width:992px block. */
  @media (min-width: 900px) {
    .navbar { flex-wrap:nowrap; justify-content:flex-start; }
    .navbar .navbar-collapse { display:flex !important; flex-basis:auto; }
    .navbar .navbar-nav { flex-direction:row; }
    .navbar .navbar-nav .dropdown-menu { position:absolute; }
    .navbar .navbar-toggle, .navbar .navbar-toggler { display:none !important; }
  }

  /* ---- Sidebar: collapse toggle pinned to the bottom edge ---------------
     bslib places the toggle at the top by default, where it collides with an
     open navbar dropdown. Moving it to the bottom keeps it clear of the menus. */
  .bslib-sidebar-layout > .collapse-toggle {
    top: auto !important;
    bottom: 0.75rem !important;
  }

  /* ---- Cards: quieter headers in the display face ----------------------- */
  .card-header { font-family:'Space Grotesk',sans-serif; font-weight:600; font-size:1rem;
            background:#f4f6f9; color:#1b2430; border-bottom:1px solid #e6e9ee; }
  .card { border-color:#e6e9ee; }

  /* ---- Home page -------------------------------------------------------- */
  .mp-home { max-width:820px; }
  .mp-kicker { display:flex; align-items:center; gap:.7rem; margin:.4rem 0 1.3rem; }
  .mp-mark { font-family:'Space Grotesk',sans-serif; font-weight:600; letter-spacing:-.02em;
            color:#1b2430; }
  .mp-rule { height:1px; flex:1; background:linear-gradient(90deg,#2f4b94,transparent); }
  .mp-tagline { font-family:'IBM Plex Mono',monospace; font-size:.78rem; color:#79828d; }
  .mp-title { font-family:'Space Grotesk',sans-serif; font-weight:600; font-size:1.6rem;
            line-height:1.18; letter-spacing:-.02em; color:#1b2430; margin:.1rem 0 .7rem;
            max-width:24ch; }
  .mp-lede { color:#3f4854; font-size:.95rem; max-width:62ch; margin:0 0 1.6rem; }
  .mp-section { font-family:'Space Grotesk',sans-serif; font-weight:600; font-size:1rem;
            color:#1b2430; margin:0 0 .3rem; }

  /* One column of tools, with a heading per navbar menu so the page and the
     navigation read the same way. */
  .mp-group-label { font-family:'Space Grotesk',sans-serif; font-weight:600; font-size:.82rem;
            text-transform:uppercase; letter-spacing:.06em; color:#79828d;
            margin:1.15rem 0 .1rem; }
  .mp-group-label:first-of-type { margin-top:.5rem; }
  .mp-tool { display:grid; grid-template-columns:190px 1fr; gap:.85rem; align-items:baseline;
            padding:.55rem 0; border-bottom:1px solid #e6e9ee; }
  @media (max-width:640px){ .mp-tool { grid-template-columns:1fr; gap:.25rem; } }
  .mp-tok { font-family:'IBM Plex Mono',monospace; font-size:.76rem; font-weight:600;
            white-space:nowrap; color:#26408a; background:#eef1fb; border:1px solid #d3daf3;
            border-radius:3px; padding:.2rem .5rem; justify-self:start; }
  .mp-tool p { margin:0; font-size:.86rem; color:#3f4854; }
  /* Reference list, now shown on the Notes page rather than Home */
  .mp-refs { padding-left:1rem; border-left:2px solid #d3daf3; }
  .mp-refs p { margin:.35rem 0; font-size:.78rem; color:#79828d;
            font-family:'IBM Plex Mono',monospace; line-height:1.5; }

  /* ---- Notes page -------------------------------------------------------- */
  .mp-notes { max-width:820px; }
  .mp-note-label { font-family:'Space Grotesk',sans-serif; font-weight:600; font-size:.82rem;
            text-transform:uppercase; letter-spacing:.06em; color:#79828d;
            margin:1.4rem 0 .35rem; }
  .mp-note-label:first-of-type { margin-top:0; }
  .mp-notes p { font-size:.9rem; color:#3f4854; max-width:66ch; }
  .mp-cite { font-family:'IBM Plex Mono',monospace; font-size:.78rem; color:#3f4854;
            background:#f4f6f9; border:1px solid #e6e9ee; border-radius:3px;
            padding:.6rem .7rem; line-height:1.6; word-break:break-word; }

  /* ---- Combine groups: one labelled block per group --------------------- */
  .mp-comb-group { border-left:2px solid #d3daf3; padding:.1rem 0 0 .7rem;
            margin-bottom:.35rem; }
  .mp-comb-title { font-family:'IBM Plex Mono',monospace; font-size:.76rem;
            font-weight:600; color:#26408a; margin-bottom:.15rem; }
  .mp-comb-group .form-group { margin-bottom:.5rem; }

  /* ---- Sidebar language switch ------------------------------------------ */
  .mp-lang a { font-size:.85rem; text-decoration:none; color:#3f4854; }
  .mp-lang a.active { color:#26408a; font-weight:600; }
  .mp-lang span { color:#c3c9d2; margin:0 .35rem; }
"))

# -----------------------------------------------------------------------------
# Google Analytics 4 (fail-open: with no Measurement ID nothing loads and the
# app runs normally). The ID comes from an environment variable, never source.
# -----------------------------------------------------------------------------

ga_measurement_id <- function() Sys.getenv("GA_MEASUREMENT_ID", "")

ga_head <- function(id) {
  if (!nzchar(id)) return(NULL)
  shiny::tagList(
    shiny::tags$script(async = NA,
      src = sprintf("https://www.googletagmanager.com/gtag/js?id=%s", id)),
    shiny::tags$script(shiny::HTML(sprintf(
      "window.dataLayer = window.dataLayer || [];
       function gtag(){dataLayer.push(arguments);}
       gtag('consent', 'default', {'analytics_storage':'denied'});
       gtag('js', new Date());
       gtag('config', '%s', {'anonymize_ip': true});", id
    )))
  )
}

# Two small bridges, both safe to include when GA is not configured:
#   ga_event        - server -> gtag custom events
#   toggle_enabled  - server -> enable/disable a button, so the Send buttons can
#                     be guarded without taking on a shinyjs dependency
app_scripts <- function() {
  shiny::tags$script(shiny::HTML(
    "Shiny.addCustomMessageHandler('ga_event', function(m){
       if (typeof gtag === 'function') { gtag('event', m.name, m.params || {}); }
     });
     Shiny.addCustomMessageHandler('toggle_enabled', function(m){
       var el = document.getElementById(m.id);
       if (!el) return;
       if (m.enabled) { el.removeAttribute('disabled'); el.classList.remove('disabled'); }
       else { el.setAttribute('disabled', 'disabled'); el.classList.add('disabled'); }
     });
     function mpConsent(choice){
       if (choice === 'granted' && typeof gtag === 'function') {
         gtag('consent','update',{'analytics_storage':'granted'});
       }
       localStorage.setItem('ga_consent', choice);
       var b = document.getElementById('ga_consent');
       if (b) b.style.display = 'none';
     }
     document.addEventListener('DOMContentLoaded', function(){
       var c = localStorage.getItem('ga_consent');
       var banner = document.getElementById('ga_consent');
       if (c === 'granted') {
         if (typeof gtag === 'function') { gtag('consent','update',{'analytics_storage':'granted'}); }
         if (banner) banner.style.display = 'none';
       } else if (c === 'denied') {
         if (banner) banner.style.display = 'none';
       }
     });"
  ))
}

# Consent notice, shown only when GA is actually configured. The buttons are
# plain HTML: the choice is a browser-local preference, so it needs no round trip.
consent_banner <- function(id, lang) {
  if (!nzchar(id)) return(NULL)
  shiny::div(
    id = "ga_consent",
    style = paste(
      "position:fixed;bottom:0;left:0;right:0;z-index:1080;",
      "background:#1b2430;color:#fff;padding:.6rem 1rem;",
      "display:flex;flex-wrap:wrap;align-items:center;gap:.5rem;",
      "justify-content:center;font-size:.9rem;"
    ),
    shiny::tags$span(tr("consent_text", lang)),
    shiny::tags$button(type = "button", class = "btn btn-sm btn-success",
                       onclick = "mpConsent('granted')", tr("btn_accept", lang)),
    shiny::tags$button(type = "button", class = "btn btn-sm btn-outline-light",
                       onclick = "mpConsent('denied')", tr("btn_decline", lang))
  )
}

# -----------------------------------------------------------------------------
# Small building blocks
# -----------------------------------------------------------------------------

# Wrap a calculator in a centred, readable-width column
tool_page <- function(...) {
  shiny::div(class = "mx-auto", style = "max-width: 760px;", bslib::card(...))
}

# The optional Study ID / Group label pair shared by every calculator
study_group_inputs <- function(prefix, lang, group_key = "lbl_group_label", group_default = "") {
  shiny::tagList(
    shiny::hr(),
    shiny::textInput(paste0(prefix, "_study"), tr("lbl_study_id", lang), value = ""),
    shiny::textInput(paste0(prefix, "_group"), tr(group_key, lang), value = group_default)
  )
}

# The live result banner plus the guarded Send button, in that order. The
# button starts disabled; app_server.R enables it once the tool's inputs are valid.
result_and_send <- function(prefix, lang, send_key = "btn_send") {
  shiny::tagList(
    shiny::hr(),
    shiny::uiOutput(paste0(prefix, "_banner")),
    shiny::hr(),
    shiny::actionButton(paste0(prefix, "_send"), tr(send_key, lang),
                        class = "btn-success w-100", disabled = TRUE,
                        icon = shiny::icon("plus"))
  )
}

# One line of the home page tool list: a monospaced token + a plain-language line
tool_row <- function(token, desc_key, lang) {
  shiny::div(class = "mp-tool",
             shiny::span(class = "mp-tok", token),
             shiny::p(tr(desc_key, lang)))
}

# -----------------------------------------------------------------------------
# Home
# -----------------------------------------------------------------------------

home_ui <- function(lang) {
  t <- function(key) tr(key, lang)
  shiny::div(
    class = "mp-home mx-auto",
    shiny::div(class = "mp-kicker",
               shiny::span(class = "mp-mark", t("app_title")),
               shiny::span(class = "mp-rule"),
               shiny::span(class = "mp-tagline", t("app_subtitle"))),
    shiny::h1(class = "mp-title", t("home_title")),
    shiny::p(class = "mp-lede", t("home_lede")),

    shiny::div(class = "mp-section", t("home_tools_label")),

    # One column, grouped under the same headings as the navbar menus.
    shiny::div(class = "mp-group-label", t("nav_variance")),
    tool_row(t("nav_se"), "home_desc_se", lang),
    tool_row(t("nav_ci"), "home_desc_ci", lang),
    tool_row(t("nav_iqr"), "home_desc_iqr", lang),

    shiny::div(class = "mp-group-label", t("nav_estimation")),
    tool_row(t("nav_median"), "home_desc_median", lang),
    tool_row(t("nav_sdchange"), "home_desc_sdchange", lang),

    shiny::div(class = "mp-group-label", t("nav_groups")),
    tool_row(t("nav_combine"), "home_desc_combine", lang),
    tool_row(t("nav_split"), "home_desc_split", lang),

    shiny::div(class = "mp-group-label", t("nav_workspace")),
    tool_row(t("nav_workspace"), "home_desc_workspace", lang),

    shiny::div(class = "mp-group-label", t("nav_notes")),
    tool_row(t("nav_notes"), "home_desc_notes", lang)
  )
}

# -----------------------------------------------------------------------------
# Notes
# -----------------------------------------------------------------------------

notes_ui <- function(lang) {
  t <- function(key) tr(key, lang)
  repo_url <- "https://github.com/dumpierre/metaprepr"
  shiny::div(
    class = "mx-auto", style = "max-width: 860px;",
    bslib::card(
      bslib::card_header(t("card_notes")),
      bslib::card_body(
        shiny::div(
          class = "mp-notes",
          shiny::div(class = "mp-note-label", t("notes_technical_label")),
          shiny::p(t("notes_technical")),

          shiny::div(class = "mp-note-label", t("notes_plain_label")),
          shiny::p(t("notes_plain")),

          shiny::div(class = "mp-note-label", t("notes_repo_label")),
          shiny::p(t("notes_repo_text")),
          shiny::p(shiny::tags$a(href = repo_url, target = "_blank",
                                 rel = "noopener noreferrer", repo_url)),

          shiny::div(class = "mp-note-label", t("notes_licence_label")),
          shiny::p(t("notes_licence_text")),

          shiny::div(class = "mp-note-label", t("notes_citation_label")),
          shiny::div(class = "mp-cite", t("notes_citation_software")),
          shiny::p(class = "mt-2", t("notes_citation_note")),

          shiny::div(class = "mp-note-label", t("notes_preprint_label")),
          shiny::p(t("notes_preprint_text")),

          shiny::div(class = "mp-note-label", t("notes_refs_label")),
          shiny::p(t("notes_refs_intro")),
          shiny::div(
            class = "mp-refs",
            shiny::p(t("ref_cochrane")),
            shiny::p(t("ref_hozo")),
            shiny::p(t("ref_wan")),
            shiny::p(t("ref_luo"))
          )
        )
      )
    )
  )
}

# -----------------------------------------------------------------------------
# Calculator panels
# -----------------------------------------------------------------------------

build_panels <- function(lang) {
  t <- function(key) tr(key, lang)

  # -- Variance conversions ---------------------------------------------------

  se_to_sd_panel <- bslib::nav_panel(
    title = t("nav_se"),
    tool_page(
      bslib::card_header(t("card_se")),
      bslib::card_body(
        shiny::p(class = "text-muted", t("help_se")),
        shiny::numericInput("se_se", t("lbl_se"), value = NA, min = 0, step = 0.01),
        shiny::numericInput("se_n", t("lbl_n"), value = NA, min = 1, step = 1),
        shiny::numericInput("se_mean", t("lbl_mean_optional"), value = NA, step = 0.01),
        study_group_inputs("se", lang),
        result_and_send("se", lang)
      )
    )
  )

  ci_to_sd_panel <- bslib::nav_panel(
    title = t("nav_ci"),
    tool_page(
      bslib::card_header(t("card_ci")),
      bslib::card_body(
        shiny::p(class = "text-muted", t("help_ci")),
        shiny::numericInput("ci_lower", t("lbl_lower"), value = NA, step = 0.01),
        shiny::numericInput("ci_upper", t("lbl_upper"), value = NA, step = 0.01),
        shiny::numericInput("ci_n", t("lbl_n"), value = NA, min = 2, step = 1),
        shiny::numericInput("ci_mean", t("lbl_mean_optional"), value = NA, step = 0.01),
        shiny::radioButtons("ci_mode", t("lbl_crit_method"),
                            choices = stats::setNames(c("t", "z"), c(t("choice_t"), t("choice_z"))),
                            selected = "t"),
        shiny::div(class = "alert alert-info", t("alert_ci")),
        study_group_inputs("ci", lang),
        result_and_send("ci", lang)
      )
    )
  )

  iqr_to_sd_panel <- bslib::nav_panel(
    title = t("nav_iqr"),
    tool_page(
      bslib::card_header(t("card_iqr")),
      bslib::card_body(
        shiny::p(class = "text-muted", t("help_iqr")),
        shiny::numericInput("iqr_q1", t("lbl_q1"), value = NA, step = 0.01),
        shiny::numericInput("iqr_q3", t("lbl_q3"), value = NA, step = 0.01),
        shiny::numericInput("iqr_n", t("lbl_n_optional"), value = NA, min = 1, step = 1),
        shiny::numericInput("iqr_mean", t("lbl_mean_optional"), value = NA, step = 0.01),
        shiny::div(class = "alert alert-info", t("alert_iqr")),
        study_group_inputs("iqr", lang),
        result_and_send("iqr", lang)
      )
    )
  )

  # -- Estimation & imputation --------------------------------------------------

  median_panel <- bslib::nav_panel(
    title = t("nav_median"),
    tool_page(
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
        result_and_send("med", lang)
      )
    )
  )

  sd_change_panel <- bslib::nav_panel(
    title = t("nav_sdchange"),
    tool_page(
      bslib::card_header(t("card_sdchange")),
      bslib::card_body(
        shiny::p(class = "text-muted", t("help_sdchange")),
        shiny::numericInput("sdc_base", t("lbl_sd_base"), value = NA, min = 0, step = 0.01),
        shiny::numericInput("sdc_final", t("lbl_sd_final"), value = NA, min = 0, step = 0.01),
        shiny::sliderInput("sdc_r", t("lbl_r"), min = -1, max = 1, value = 0.5, step = 0.05),
        shiny::div(class = "alert alert-info", t("alert_sdchange")),
        shiny::numericInput("sdc_n", t("lbl_n_optional"), value = NA, min = 1, step = 1),
        shiny::numericInput("sdc_mean", t("lbl_mean_optional"), value = NA, step = 0.01),
        study_group_inputs("sdc", lang),
        result_and_send("sdc", lang)
      )
    )
  )

  # -- Group manipulation --------------------------------------------------------

  # Plain numbered inputs rather than an editable grid: the grid needed a
  # right-click to add a row, which is undiscoverable and did not work at all
  # for some users. Here the number of groups is just a number you set.
  combine_groups_panel <- bslib::nav_panel(
    title = t("nav_combine"),
    tool_page(
      bslib::card_header(t("card_combine")),
      bslib::card_body(
        shiny::p(class = "text-muted", t("help_combine")),
        shiny::numericInput("comb_k", t("lbl_comb_k"), value = 2,
                            min = 2, max = 10, step = 1),
        shiny::uiOutput("comb_inputs"),
        shiny::div(class = "alert alert-info", t("alert_combine_sd")),
        study_group_inputs("comb", lang, group_default = "combined"),
        result_and_send("comb", lang)
      )
    )
  )

  split_control_panel <- bslib::nav_panel(
    title = t("nav_split"),
    tool_page(
      bslib::card_header(t("card_split")),
      bslib::card_body(
        shiny::p(class = "text-muted", t("help_split")),
        shiny::numericInput("split_n", t("lbl_split_n"), value = NA, min = 1, step = 1),
        shiny::numericInput("split_k", t("lbl_split_k"), value = 2, min = 2, step = 1),
        shiny::radioButtons(
          "split_weighting", t("lbl_split_weighting"),
          choices = stats::setNames(c("even", "proportional"),
                                    c(t("choice_split_even"), t("choice_split_proportional"))),
          selected = "even"
        ),
        shiny::conditionalPanel(
          condition = "input.split_weighting == 'proportional'",
          shiny::textInput("split_arm_n", t("lbl_split_arm_n"), value = "")
        ),
        shiny::numericInput("split_mean", t("lbl_split_mean"), value = NA, step = 0.01),
        shiny::numericInput("split_sd", t("lbl_split_sd"), value = NA, min = 0, step = 0.01),
        shiny::div(class = "alert alert-info", t("alert_split")),
        study_group_inputs("split", lang, group_key = "lbl_group_prefix",
                           group_default = "control"),
        result_and_send("split", lang, send_key = "btn_send_split")
      )
    )
  )

  # -- Workspace ------------------------------------------------------------------

  workspace_panel <- bslib::nav_panel(
    title = t("nav_workspace"),
    shiny::div(
      class = "mx-auto", style = "max-width: 1040px;",
      bslib::card(
        bslib::card_header(t("card_workspace")),
        bslib::card_body(
          shiny::p(class = "text-muted", t("help_workspace")),
          rhandsontable::rHandsontableOutput("workspace_table"),
          shiny::hr(),
          bslib::layout_columns(
            shiny::actionButton("clear_table", t("btn_clear"), class = "btn-warning"),
            shiny::downloadButton("download_csv", t("btn_download_csv"), class = "btn-primary"),
            shiny::downloadButton("download_xlsx", t("btn_download_xlsx"), class = "btn-primary"),
            col_widths = c(4, 4, 4)
          )
        )
      )
    )
  )

  list(
    se_to_sd_panel = se_to_sd_panel, ci_to_sd_panel = ci_to_sd_panel,
    iqr_to_sd_panel = iqr_to_sd_panel, median_panel = median_panel,
    sd_change_panel = sd_change_panel, combine_groups_panel = combine_groups_panel,
    split_control_panel = split_control_panel, workspace_panel = workspace_panel
  )
}

# -----------------------------------------------------------------------------
# Sidebar
# -----------------------------------------------------------------------------

# Language is a page-level choice (?lang=), so the switch is a pair of links
# rather than a reactive input.
app_sidebar <- function(lang) {
  t <- function(key) tr(key, lang)
  bslib::sidebar(
    width = 260,
    shiny::div(
      shiny::tags$strong(class = "d-block mb-1", style = "font-size:.85rem;", t("sidebar_language")),
      shiny::div(
        class = "mp-lang",
        shiny::tags$a(href = "?lang=en", class = if (lang == "en") "active" else NULL,
                      t("lang_toggle_to_en")),
        shiny::tags$span("/"),
        shiny::tags$a(href = "?lang=pt", class = if (lang == "pt") "active" else NULL,
                      t("lang_toggle_to_pt"))
      )
    ),
    shiny::hr(),
    shiny::h6(t("sidebar_ws_preview")),
    shiny::uiOutput("ws_summary"),
    shiny::tableOutput("ws_preview")
  )
}

# -----------------------------------------------------------------------------
# Page
# -----------------------------------------------------------------------------

app_ui <- function(request) {
  lang <- get_lang(request)
  t <- function(key) tr(key, lang)
  p <- build_panels(lang)
  ga_id <- ga_measurement_id()

  bslib::page_navbar(
    title = t("app_title"),
    id = "main_nav",
    theme = app_theme,
    header = shiny::tagList(app_css, ga_head(ga_id), app_scripts()),
    sidebar = app_sidebar(lang),

    bslib::nav_panel(t("nav_home"), home_ui(lang)),
    bslib::nav_menu(title = t("nav_variance"),
                    p$se_to_sd_panel, p$ci_to_sd_panel, p$iqr_to_sd_panel),
    bslib::nav_menu(title = t("nav_estimation"),
                    p$median_panel, p$sd_change_panel),
    bslib::nav_menu(title = t("nav_groups"),
                    p$combine_groups_panel, p$split_control_panel),
    p$workspace_panel,
    bslib::nav_panel(t("nav_notes"), notes_ui(lang)),

    footer = consent_banner(ga_id, lang)
  )
}
