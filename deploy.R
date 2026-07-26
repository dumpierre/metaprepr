# Deploy MetaPrepR to shinyapps.io.
#
# Run this from the repository root. It is not part of the app and is excluded
# from the bundle by .rscignore. See DEPLOY.md for the full explanation of the
# analytics setup and the free-tier limits.
#
# STEP 1 (once per machine): authorise rsconnect.
#   Get the token and secret from https://www.shinyapps.io -> Account -> Tokens
#   -> Show -> Copy to clipboard, then run that setAccountInfo() call yourself in
#   the console. Do not paste the secret into this file - it is version
#   controlled.
#
#   rsconnect::setAccountInfo(name = "<account>", token = "<token>", secret = "<secret>")
#
# STEP 2 (optional): set the GA4 Measurement ID in the shinyapps.io dashboard
#   under Applications -> metaprepr -> Settings -> Variables, as
#   GA_MEASUREMENT_ID. Without it the app runs normally and loads no analytics.
#
# STEP 3: run this script.

library(rsconnect)

app_dir <- normalizePath(".", winslash = "/")

stopifnot(
  "run this from the repository root (app.R not found)" = file.exists(file.path(app_dir, "app.R")),
  "R/ directory not found" = dir.exists(file.path(app_dir, "R"))
)

accts <- rsconnect::accounts()
if (is.null(accts) || nrow(accts) == 0) {
  stop(
    "No rsconnect account configured. Run setAccountInfo() first - see STEP 1 ",
    "at the top of this file.",
    call. = FALSE
  )
}

message("Deploying as: ", paste(accts$name, collapse = ", "))

# Preflight: the app must at least parse and build its UI before we ship it.
local({
  env <- new.env()
  for (f in list.files(file.path(app_dir, "R"), pattern = "[.]R$", full.names = TRUE)) {
    sys.source(f, envir = env)
  }
  ui <- env$app_ui(list(QUERY_STRING = ""))
  stopifnot("UI failed to build" = nchar(as.character(ui)) > 1000)
  message("Preflight OK: UI builds (", nchar(as.character(ui)), " chars)")
})

rsconnect::deployApp(
  appDir      = app_dir,
  appName     = "metaprepr",
  appTitle    = "MetaPrepR",
  account     = accts$name[1],
  forceUpdate = TRUE,
  launch.browser = TRUE
)
