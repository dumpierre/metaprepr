# MetaPrepR - Deployment & Analytics Guide

This repository is a self-contained Shiny app ready for **shinyapps.io** (Posit).

```
metaprepr/
├── app.R                # thin launcher; sources everything in R/
├── R/                   # calculators, validation, UI, server, translations
├── tests/testthat/      # unit tests
├── docs/                # methods, user guide, static landing page
└── DEPLOY.md            # this file
```

## 1. Local requirements

Install the packages once, locally, so `rsconnect` can build the dependency
manifest:

```r
install.packages(c("shiny", "bslib", "rhandsontable", "writexl", "rsconnect"))
```

Run locally to test:

```r
shiny::runApp("path/to/metaprepr")
```

The app opens in **English**. The EN/PT switch is in the sidebar and works by
reloading the page with `?lang=pt`, so a language can also be linked to
directly. There is no `shiny.i18n` or `shinyjs` dependency: strings live in
`R/translations.R` and the guarded buttons are toggled through a small custom
message handler in `R/app_ui.R`.

## 2. Google Analytics (GA4)

Analytics are **fail-open**: with no Measurement ID the app runs normally and
simply does not load GA. The ID is read from an environment variable, never
hardcoded.

1. Create a GA4 property at <https://analytics.google.com> and copy its
   **Measurement ID** (`G-XXXXXXXXXX`).
2. Provide it to the app via the `GA_MEASUREMENT_ID` environment variable.
   - **Local:** add to `~/.Renviron` → `GA_MEASUREMENT_ID=G-XXXXXXXXXX`
   - **shinyapps.io:** set it in the dashboard under
     *Applications → (your app) → Settings → Variables*, or with
     `rsconnect::configureApp(appName, envVars = c("GA_MEASUREMENT_ID"))`.

### What GA4 captures for annual reports
- Unique visitors and total sessions
- Geography (country / region / city)
- New vs. returning users
- Usage over time / seasonality
- Average engagement time
- Devices, browsers, referral source

### Tool-level custom events (beyond standard GA4)
The app fires these events so reports can show *which* tools are used, not just
visits:

- `calc_send`, with a `tool` parameter carrying the same stable slug that goes
  into the workspace: `se-to-sd`, `95ci-to-sd`, `iqr-to-sd`, `median-to-mean`,
  `sd-change-imput`, `combine-group`, `split-group`
- `export_csv`, `export_xlsx`
- `clear_table`

Language is not a custom event: switching language reloads the page with
`?lang=pt`, so GA4's own page-view report already separates the two.

Mark these as **key events** (conversions) in GA4 to chart them easily. In
*Explore* you can build a "tool usage" report by event name and an "exports per
year" trend.

### Privacy / LGPD
- IP anonymization is enabled and GA **Consent Mode** starts in the *denied*
  state.
- A dismissible consent notice is shown, and GA is only granted after the
  visitor accepts. The choice is stored in the browser's `localStorage`, so it
  is not asked again on the next visit.
- No personally identifying data is collected by the app itself.

## 3. Deploy to shinyapps.io

```r
library(rsconnect)

# One-time: paste token + secret from the shinyapps.io dashboard (Account → Tokens)
setAccountInfo(name = "<account>", token = "<token>", secret = "<secret>")

# Deploy the repository root (app.R must be at its root)
deployApp(
  appDir   = "path/to/metaprepr",
  appName  = "metaprepr",
  appTitle = "MetaPrepR"
)
```

Notes:
- **Free tier:** 5 applications and ~25 active hours/month. Fine for a research
  tool.
- **Ephemeral filesystem:** the container's disk resets on restart, so the app
  writes no local logs. All usage metrics live in GA4 (this is why GA4 was
  chosen over server-side logging). If server-side tool logs are ever needed,
  write them to an external store (a Google Sheet via `googlesheets4`, a `pins`
  board, or a database).
- `rsconnect` bundles the whole folder, so `R/` is picked up automatically by
  the launcher's `source()` loop. Excluding `tests/`, `docs/`, and `paper/`
  from the bundle keeps deployments smaller but is optional.

## 4. Updating translations

Every user-facing string lives in `R/translations.R`, under `ui_text$en` and
`ui_text$pt`. Add the key to both lists; a key present in English but missing in
Portuguese falls back to English, so the app never breaks on a missing string.
`tests/testthat/test-calculations.R` fails if a key is missing from `pt`, which
is what stops that silent fallback from going unnoticed.

The `tool_slugs` vector in the same file is **not** translatable: those strings
are published in exported datasets and in the analytics event stream, and a
test pins their values.
