# DataPrepR: A Toolkit for Systematic Review Data Preparation
# Thin launcher - see R/app_ui.R and R/app_server.R for UI/server logic,
# and R/calc_*.R / R/*_groups.R / R/*_control.R for the calculators.

library(shiny)
library(bslib)
library(rhandsontable)
library(writexl)

r_files <- list.files("R", pattern = "\\.R$", full.names = TRUE)
for (f in r_files) source(f)

shinyApp(ui = app_ui, server = app_server)
