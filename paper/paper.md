---
title: 'DataPrepR: An R/Shiny Toolkit for Preparing Continuous Outcome Data for Meta-Analysis'
tags:
  - R
  - Shiny
  - meta-analysis
  - systematic review
  - biostatistics
authors:
  # TODO: fill in author names, ORCID iDs, and affiliation indices before submission.
  - name: TODO
    affiliation: 1
affiliations:
  # TODO: fill in institutional affiliation(s).
  - name: TODO
    index: 1
date: TODO
bibliography: references.bib
---

## Summary

Systematic reviewers combining continuous outcomes across trials frequently
encounter studies that do not report a mean and standard deviation (SD)
directly - the format required by standard meta-analysis methods and software
(e.g., inverse-variance pooling). Instead, trials report medians and ranges,
interquartile ranges (IQR), standard errors (SE), or confidence intervals
(CI). `DataPrepR` is a small, open-source R/Shiny application that converts
these commonly reported summary statistics into mean/SD, using methods
documented in the Cochrane Handbook for Systematic Reviews of Interventions
[@cochrane2023] and the methodological literature on estimating means and SDs
from order statistics [@hozo2005; @wan2014; @luo2018]. It also implements
three further Cochrane-recommended data-preparation steps relevant to
continuous outcomes: imputing the SD of a change-from-baseline score,
combining multiple subgroups into one group, and splitting a shared control
group's sample size across multiple pairwise comparisons.

## Statement of Need

Estimating a mean and SD from reported quantiles is a well-studied statistical
problem, and validated R packages already exist for parts of it: notably
`estmeansd` [@estmeansd] and `metamedian` [@metamedian], which implement
McGrath et al.'s quantile-estimation and Box-Cox methods [@mcgrath2020], and
`metaBLUE` [@metabblue], which implements the closed-form Wan (2014) SD
estimator and Luo (2016/2018) mean estimator that `estmeansd` itself depends
on internally. These packages are correct and well-maintained, but they are R
functions for users already comfortable scripting in R, and each covers only
one methodological family. None of them address the other Cochrane-recommended
data-preparation steps a reviewer needs alongside mean/SD estimation:
change-score SD imputation, subgroup combination, and shared-control
splitting.

`DataPrepR` packages the Hozo, Wan, and Luo estimators, using `metaBLUE`'s
verified formulas rather than a reimplementation, together with these adjacent
Cochrane steps in a single Shiny interface aimed at reviewers who do not write
R code. Every conversion records which method was used, for which study and
group, which supports the audit trail that systematic review reporting
guidelines such as PRISMA expect. The authors built this tool for exactly this
use case in evidence synthesis training.

## Implementation and Methods

`DataPrepR` is implemented in R using `shiny` [@shiny] for reactivity and
`bslib` [@bslib] for the Bootstrap-based interface. Each calculation is a
pure, independently testable R function (`R/calc_*.R`, `R/combine_groups.R`,
`R/split_control.R`) that returns a structured result: success/failure plus a
message code and its data, decoupled from both the UI layer and from any one
language, so the underlying calculations can be reused or tested outside the
app. The interface is available in English (default) or Portuguese, chosen
via a URL parameter and translated at display time from the same message
codes (`R/translations.R`).

Seven tools are implemented:

1. **SE -> SD**: SD = SE x sqrt(n) [@cochrane2023].
2. **95% CI -> SD**: SE derived from the CI width using a t- or
   z-distribution critical value, then converted to SD [@cochrane2023].
3. **IQR -> SD**: the normal-approximation SD = (Q3-Q1)/1.35.
4. **Median/range/IQR -> mean and SD**: three selectable methods -
   Hozo et al.'s original range-based estimator [@hozo2005], corrected from
   an earlier internal draft that had used the wrong SD constant and swapped
   sample-size thresholds; Wan et al.'s SD estimator [@wan2014] paired with
   a simple mean estimator; and Luo et al.'s sample-size-weighted optimal
   mean estimator [@luo2018] paired with the same Wan SD. The Wan and Luo
   estimators are computed via `metaBLUE::Wan.std()` and
   `metaBLUE::Luo.mean()` [@metabblue] rather than hand-derived, since these
   are the exact functions `estmeansd`'s Box-Cox method depends on internally
   for this step.
5. **SD of change from baseline**: the Cochrane change-score SD formula, with
   a correlation slider and a sensitivity readout at r in {0.3, 0.5, 0.7}.
6. **Combine groups**: pooled mean and SD for k >= 2 groups via the Cochrane
   Handbook's Table 6.5.a formula, applied pairwise for k > 2.
7. **Split shared control group**: the simple sample-size-splitting
   approximation for avoiding double-counting a shared control arm.

Results from any tool can be sent to a shared, editable workspace
(`rhandsontable` [@rhandsontable]) and exported as CSV or XLSX
(`writexl` [@writexl]) for use in downstream meta-analysis software such as
`meta` [@meta] or `metafor`.

## Validation

All seven tools are unit-tested with `testthat` [@testthat]
(`tests/testthat/test-calculations.R`; 107 assertions at time of writing),
including:

- exact hand-computed values for the SE, IQR, and group-combination formulas.
- a regression test confirming the Hozo SD estimator no longer reproduces the
  incorrect constant and threshold combination from an earlier internal draft.
- order-invariance of pairwise group combination for k > 2 groups.
- cross-validation of the Wan and Luo mean/SD estimates against
  `estmeansd::qe.mean.sd()` [@estmeansd; @mcgrath2020] on simulated normal and
  log-normal data. Agreement is loose, not exact, since the underlying
  estimation approach differs. A separate test documents a known limitation:
  under strong right-skew, the simple mean estimator paired with Wan's SD is
  measurably biased against ground truth, while Luo's estimator stays close,
  which is why the tool defaults to Luo's method when skew is a concern.

TODO: no empirical validation against real, published systematic-review
extraction data has yet been performed; this section should be expanded with
such a comparison, and any resulting discrepancies reported, before a formal
release claim of production-readiness.

## Availability

`DataPrepR` is available at <https://github.com/dumpierre/dataprepr> under the
MIT license (repository currently private; TODO: confirm visibility before
submission). It requires R >= 4.0 and the packages `shiny`, `bslib`,
`rhandsontable`, `writexl`, and, for the test suite, `testthat`, `estmeansd`,
`metamedian`, and `meta`.

## References
