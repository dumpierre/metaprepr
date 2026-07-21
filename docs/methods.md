# Methods

Each section states the formula, the assumptions it relies on, and its
literature source. Implementations live in `R/calc_*.R`, `R/combine_groups.R`,
and `R/split_control.R`; each has unit tests in
`tests/testthat/test-calculations.R`.

## 1. Standard Error -> Standard Deviation

**Formula:** SD = SE * sqrt(n)

**Assumptions:** SE is the standard error of the mean for a sample of size n;
n >= 1 and SE >= 0.

**Source:** Cochrane Handbook for Systematic Reviews of Interventions, section
6.5.2.3.

## 2. 95% Confidence Interval (of a mean) -> Standard Deviation

**Formula:** df = n-1; crit = qt(0.975, df) (or 1.96 in z-mode); SE =
(upper-lower)/(2*crit); SD = SE*sqrt(n)

**Assumptions:** The CI is a symmetric 95% CI for a mean (not a CI for a
proportion, ratio, or other quantity). n >= 2. The t-distribution critical
value is exact for this purpose; the z=1.96 approximation understates the true
critical value for small n (e.g., t=2.78 vs z=1.96 at n=5), which will
overstate the estimated SD if used incorrectly, or understate it if the
original study actually used t but you assume z. Prefer t unless you know the
source study used a fixed z-based CI.

**Source:** Cochrane Handbook, section 6.5.2.3.

## 3. Interquartile Range -> Standard Deviation

**Formula:** SD = (Q3 - Q1) / 1.35

**Assumptions:** The outcome is approximately normally distributed (1.35 is
the IQR of a standard normal distribution, i.e. qnorm(0.75)-qnorm(0.25) ~=
1.349). This is a rule-of-thumb normal approximation that ignores sample size
entirely. When n is known, the Wan (2014) method (below) is preferable because
it accounts for n.

**Source:** Common normal-approximation heuristic; see Cochrane Handbook
6.5.2.5 for discussion of range/IQR-based approximations.

## 4. Median/Range/IQR -> Mean & Standard Deviation

Three selectable methods, applied to one of three input scenarios:

- **S1**: minimum, median, maximum, n
- **S2**: Q1, median, Q3, n
- **S3**: minimum, Q1, median, Q3, maximum, n

### 4a. Hozo et al. (2005) - S1 only

**Mean:** (min + 2*median + max) / 4 if n <= 25, else median alone.

**SD:**
- n <= 15: (1/sqrt(12)) * sqrt( ((min - 2*median + max)^2)/4 + (max-min)^2 )
- 15 < n <= 70: (max - min) / 4
- n > 70: (max - min) / 6

**Assumptions:** Approximate normality; accuracy degrades for skewed outcomes
or extreme n. This is the *corrected* formula - an earlier internal draft used
the wrong constant (1/(12*(n-1))) with swapped n-thresholds, which the test
suite explicitly guards against (see `test-calculations.R`, "rejects the
earlier-draft's wrong SD constant").

**Source:** Hozo, Djulbegovic & Hozo (2005). Estimating the mean and variance
from the median, range, and the size of a sample. *BMC Medical Research
Methodology*, 5:13.

### 4b. Wan et al. (2014) - default method, S1/S2/S3

**SD:** Computed via `metaBLUE::Wan.std()`, which implements Wan et al.'s
closed-form S1/S2/S3 estimators (order-statistic-based, using
`qnorm()`-derived expected spacings). This is the same function `estmeansd`
depends on internally.

**Mean:** The "simple"/Bland estimator conventionally paired with Wan's SD
(Wan et al. 2014 proposed SD estimators only, not new mean estimators):
- S1: (min + 2*median + max) / 4
- S2: (Q1 + 2*median + Q3) / 4
- S3: 0.25*(min+max)/2 + 0.5*(Q1+Q3)/2 + 0.25*median (Bland's weighting)

**Assumptions:** Approximate normality. Under strong right-skew, this simple
mean estimator can be noticeably biased (see the "skew-sensitivity" test in
`test-calculations.R`, which documents ~41% relative error on a strongly
skewed lognormal simulation) - use the Luo method below when skew is a
concern.

**Source:** Wan, Wang, Liu & Tong (2014). Estimating the sample mean and
standard deviation from the sample size, median, range and/or interquartile
range. *BMC Medical Research Methodology*, 14:135.

### 4c. Luo et al. (2016/2018) mean + Wan (2014) SD - S1/S2/S3

**Mean:** Computed via `metaBLUE::Luo.mean()`, an n-weighted combination of
the mid-range ((min+max)/2), the mid-quartile-range ((Q1+Q3)/2), and the
median, with weights that shift toward the median as n grows (asymptotically
optimal under normality).

**SD:** Same as the Wan method (`metaBLUE::Wan.std()`), as specified.

**Assumptions:** Approximate normality; markedly more robust to skew than the
simple mean estimator (see the skew-sensitivity test: ~7% error vs ~41% for
the same simulated dataset).

**Source:** Luo, Wan, Liu & Tong (2016/2018 in print). Optimally estimating
the sample mean from the sample size, median, mid-range, and/or mid-quartile
range. *Statistical Methods in Medical Research*, 27(6):1785-1805.

**Cross-validation:** All three methods are cross-checked in
`test-calculations.R` against `estmeansd::qe.mean.sd()` (McGrath et al. 2020's
quantile-estimation method) on simulated normal and log-normal datasets.
Agreement is loose by design (different methodology), typically within 15-25%
on moderately skewed data; any larger gap is printed during the test run for
manual inspection.

## 5. Standard Deviation of Change from Baseline

**Formula:** SD_change = sqrt(SD_base^2 + SD_final^2 - 2*r*SD_base*SD_final)

**Assumptions:** r is the (usually unmeasured) correlation between baseline
and final scores; -1 <= r <= 1. When the term under the square root is
negative (can happen if r is set implausibly high relative to the two SDs),
the app reports this explicitly rather than returning `NaN`. A sensitivity
readout at r in {0.3, 0.5, 0.7} is shown alongside the point estimate.

**Source:** Cochrane Handbook, section 6.5.2.8. Cochrane's recommended default
imputation is r = 0.5 when the true correlation is unknown.

## 6. Combine Groups (k >= 2)

**Formula:**
- Combined N = sum(N_i)
- Combined Mean = sum(N_i * Mean_i) / N
- Two-group SD: sqrt( ((N1-1)*SD1^2 + (N2-1)*SD2^2 + (N1*N2/(N1+N2))*(Mean1-Mean2)^2) / (N1+N2-1) )

**Assumptions:** For k > 2 groups, combination proceeds by iterative pairwise
folding (combine groups 1+2, then fold in group 3, etc.). This is tested for
order-invariance: combining in a different order produces the same N, Mean,
and SD (to floating-point tolerance).

**Source:** Cochrane Handbook, Table 6.5.a.

## 7. Split a Shared Control Group

**Formula:** n_adjusted = round(n_control / k) for each of the k pairwise
comparisons sharing the control group; mean and SD are unchanged.

**Assumptions:** This is the simple Cochrane approximation used to avoid
double-counting a shared control group's contribution when it appears in
multiple pairwise comparisons within the same meta-analysis. It does not
model the correlation induced by reusing the same control data across
comparisons. The rigorous alternative is a network meta-analysis or another
multivariate method that explicitly accounts for the shared-control
correlation structure.

**Source:** Cochrane Handbook, section 23.3.4.
