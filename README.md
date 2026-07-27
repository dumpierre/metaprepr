# MetaPrepR

**Meta-Analysis Preparation in R** - a small R/Shiny toolkit for preparing
continuous-outcome data for meta-analysis, following the Cochrane Handbook and
the primary literature on estimating means and standard deviations from summary
statistics (Hozo 2005; Wan 2014; Luo 2018).

Studies often report medians, ranges, interquartile ranges, standard errors, or
confidence intervals instead of mean and SD. MetaPrepR converts these into the
mean/SD format most meta-analysis software expects, tracks provenance (which
tool and method was used, for which study/group), and exports a clean workspace
table ready for `metafor`, `meta`, RevMan, or similar tools.

Results update as you type; the only guarded action is "Send to workspace",
which stays disabled until the inputs for that tool are valid.

## Install

```r
install.packages(c("shiny", "bslib", "rhandsontable", "writexl"))
```

R >= 4.0 is recommended. If `install.packages()` fails to reach CRAN with a
"cannot open URL" error despite having internet access, try:

```r
options(download.file.method = "wininet")  # Windows-specific fix
install.packages(c("shiny", "bslib", "rhandsontable", "writexl"))
```

There are no other runtime dependencies: language switching and the guarded
buttons are handled in-app rather than via `shiny.i18n` or `shinyjs`.

## Run

```r
shiny::runApp("path/to/metaprepr")
```

or open `app.R` in RStudio and click "Run App".

The app opens in English. Use the language switch in the sidebar (or append
`?lang=pt` to the URL) for Portuguese; switching language reloads the page.

## Screenshot

*(placeholder - add a screenshot of the Workspace tab here before publishing)*

## Methods implemented

| Tool | Slug | Formula | Source |
|---|---|---|---|
| SE -> SD | `se-to-sd` | SD = SE * sqrt(n) | Cochrane Handbook 6.5.2.2 |
| 95% CI -> SD | `95ci-to-sd` | SE = (upper-lower)/(2*t or z); SD = SE*sqrt(n) | Cochrane Handbook 6.5.2.2 |
| IQR -> SD | `iqr-to-sd` | With n: Wan (2014) S2, SD = (Q3-Q1)/(2*qnorm((0.75n-0.125)/(n+0.25))). Without n: SD = (Q3-Q1)/1.35 | Wan et al. (2014) 14:135; Cochrane Handbook 6.5.2.5 for the fallback |
| Median/range/IQR -> Mean & SD (Hozo) | `median-to-mean` | Piecewise by n; see `docs/methods.md` | Hozo, Djulbegovic & Hozo (2005), *BMC Med Res Methodol* 5:13 |
| Median/range/IQR -> Mean & SD (Wan) | `median-to-mean` | SD via Wan et al.'s S1/S2/S3 estimators | Wan, Wang, Liu & Tong (2014), *BMC Med Res Methodol* 14:135 |
| Median/range/IQR -> Mean & SD (Luo) | `median-to-mean` | n-weighted optimal mean estimator, paired with Wan SD | Luo, Wan, Liu & Tong (2016/2018), *Stat Methods Med Res* |
| SD of change from baseline | `sd-change-imput` | SD = sqrt(SDb^2 + SDf^2 - 2*r*SDb*SDf) | Cochrane Handbook 6.5.2.8, r=0.5 default imputation |
| Combine groups | `combine-group` | Weighted mean; pooled SD via Table 6.5.a. SD is optional: without it you still get the combined N and mean | Cochrane Handbook 6.5.2.10, Table 6.5.a |
| Split shared control | `split-group` | n_control divided into k whole parts summing to n_control (equal or proportional to arm size) | Cochrane Handbook 23.3.4 (approximation; Handbook prefers combining) |

The slug is written to the `Tool` column of every workspace row and every CSV
or XLSX export. It is deliberately language-independent and fixed by a unit
test, so exported datasets stay filterable and comparable across versions and
across the English and Portuguese interfaces. The neighbouring `Method` column
carries the fuller, translated description (including which median method and
which S1/S2/S3 scenario was used).

Full assumptions and derivations: `docs/methods.md`. Task-based walkthrough:
`docs/user-guide.md`. What the app is, how to cite it, and where the code lives
are also summarised in the app's own **Notes** tab.

## Validation

The Wan/Luo estimators use `metaBLUE::Wan.std()` and `metaBLUE::Luo.mean()` -
the same functions the `estmeansd` package depends on internally for these
exact formulas - rather than a hand-rolled reimplementation. All calculators
are unit-tested in `tests/testthat/test-calculations.R` (36 test blocks, 552
assertions), including cross-validation against `estmeansd::qe.mean.sd()` on
simulated data. Run:

```r
testthat::test_dir("tests/testthat")
```

## Repository layout

```
metaprepr/
  app.R                 thin launcher
  R/                    calculators, validation helpers, UI, server
  tests/testthat/       unit tests
  docs/                 methods, user guide, static landing page
  paper/                JOSS-style software paper draft
  data-raw/             source Excel and validation data
  DEPLOY.md             shinyapps.io hosting and GA4 analytics setup
```

## License

MIT - see `LICENSE`.

## Citing

Umpierre D. MetaPrepR: Meta-Analysis Preparation in R [software]. 2026.
Available from: https://github.com/dumpierre/metaprepr

Cite the primary method you relied on as well, not only this software - the
sources are listed in the table above and in `docs/methods.md`. See also
`paper/paper.md` and `paper/references.bib`.
