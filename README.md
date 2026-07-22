# DataPrepR

A small R/Shiny toolkit for preparing continuous-outcome data for meta-analysis,
following the Cochrane Handbook and the primary literature on estimating means
and standard deviations from summary statistics (Hozo 2005; Wan 2014; Luo 2018).

Studies often report medians, ranges, interquartile ranges, standard errors, or
confidence intervals instead of mean and SD. DataPrepR converts these into the
mean/SD format most meta-analysis software expects, tracks provenance (which
method was used, for which study/group), and exports a clean workspace table
ready for `metafor`, `meta`, RevMan, or similar tools.

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

## Run

```r
shiny::runApp("path/to/dataprepr")
```

or open `app.R` in RStudio and click "Run App".

## Screenshot

*(placeholder - add a screenshot of the Workspace tab here before publishing)*

## Methods implemented

| Tool | Formula | Source |
|---|---|---|
| SE -> SD | SD = SE * sqrt(n) | Cochrane Handbook 6.5.2.3 |
| 95% CI -> SD | SE = (upper-lower)/(2*t or z); SD = SE*sqrt(n) | Cochrane Handbook 6.5.2.3 |
| IQR -> SD | SD = (Q3-Q1)/1.35 | Normal-approximation rule of thumb |
| Median/range/IQR -> Mean & SD (Hozo) | Piecewise by n; see `docs/methods.md` | Hozo, Djulbegovic & Hozo (2005), *BMC Med Res Methodol* 5:13 |
| Median/range/IQR -> Mean & SD (Wan) | SD via Wan et al.'s S1/S2/S3 estimators | Wan, Wang, Liu & Tong (2014), *BMC Med Res Methodol* 14:135 |
| Median/range/IQR -> Mean & SD (Luo) | n-weighted optimal mean estimator, paired with Wan SD | Luo, Wan, Liu & Tong (2016/2018), *Stat Methods Med Res* |
| SD of change from baseline | SD = sqrt(SDb^2 + SDf^2 - 2*r*SDb*SDf) | Cochrane Handbook 6.5.2.8, r=0.5 default imputation |
| Combine groups | Weighted mean; pooled SD via Table 6.5.a | Cochrane Handbook Table 6.5.a |
| Split shared control | n_adjusted = round(n_control/k) | Cochrane Handbook 23.3.4 (simple approximation) |

Full assumptions and derivations: `docs/methods.md`. Task-based walkthrough:
`docs/user-guide.md`.

## Validation

The Wan/Luo estimators use `metaBLUE::Wan.std()` and `metaBLUE::Luo.mean()` -
the same functions the `estmeansd` package depends on internally for these
exact formulas - rather than a hand-rolled reimplementation. All calculators
are unit-tested in `tests/testthat/test-calculations.R` (86 tests), including
cross-validation against `estmeansd::qe.mean.sd()` on simulated data. Run:

```r
testthat::test_dir("tests/testthat")
```

## Repository layout

```
dataprepr/
  app.R                 thin launcher
  R/                    calculators, validation helpers, UI, server
  tests/testthat/       unit tests
  docs/                 methods, user guide, static landing page
  paper/                JOSS-style software paper draft
  data-raw/             source Excel and validation data
```

## License

MIT - see `LICENSE`.

## Citing

See `paper/paper.md` and `paper/references.bib` 
