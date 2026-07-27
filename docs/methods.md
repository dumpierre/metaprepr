# Methods

Each section states the formula, the assumptions it relies on, and its
literature source. Implementations live in `R/calc_*.R`, `R/combine_groups.R`,
and `R/split_control.R`; each has unit tests in
`tests/testthat/test-calculations.R`.

## 1. Standard error -> standard deviation

**Formula:** SD = SE * sqrt(n)

**Assumptions:** SE is the standard error of a *group mean* for a sample of
size n; n >= 1 and SE >= 0. If the reported SE belongs to a *difference*
between two means, this is the wrong formula: see Handbook 6.5.2.3, which
covers that case separately and is not implemented here.

**Source:** Cochrane Handbook for Systematic Reviews of Interventions (version
6.5, 2024), section 6.5.2.2, "Obtaining standard deviations from standard
errors and confidence intervals for group means".

## 2. 95% confidence interval (of a mean) -> standard deviation

**Formula:** df = n-1; crit = qt(0.975, df) (or 1.96 in z-mode); SE =
(upper-lower)/(2*crit); SD = SE*sqrt(n)

**Assumptions:** The CI is a symmetric 95% CI for a *group mean* (not for a
difference between means, nor for a proportion, ratio, or other quantity).
n >= 2.

**Direction of the error.** SD is recovered by *dividing* the interval by the
critical value, so the estimate moves inversely to the value assumed. Since
qt(0.975, n-1) > 1.96 for every finite n, the two cases are:

| You assume | Study actually used | Effect on SD |
|---|---|---|
| z (1.96) | t | **overstates** SD |
| t | z (1.96) | understates SD |

Assuming z when the interval came from a t distribution is the common case, and
it inflates SD. The size of the error is the ratio of the two critical values:
at n=5, t=2.776 against z=1.96, so the SD comes out about 42% too large. The
gap closes as n grows (15% at n=10, 4% at n=30, 1% at n=120) because
qt(0.975, n-1) converges on 1.96.

The Handbook advises that intervals for groups of fewer than about 60
participants should have been computed from a t distribution, so prefer t
unless you know the source study used a fixed z-based CI.

The Handbook's z-mode divisor is 3.92 for a 95% CI (2 x 1.96), 3.29 for a 90%
CI and 5.15 for a 99% CI. Only the 95% case is implemented.

**Source:** Cochrane Handbook, section 6.5.2.2. Section 6.5.2.3 covers the
same recovery from statistics describing a *difference* in means, including
from t statistics and P values, and is not implemented here.

## 3. Interquartile range -> standard deviation

**Formula:** the estimator depends on whether the sample size is known.

- **n supplied (default):** Wan et al. (2014), eq. (16), scenario S2:
  SD = (Q3 - Q1) / (2 * qnorm((0.75n - 0.125) / (n + 0.25)))
- **n not supplied:** SD = (Q3 - Q1) / 1.35

**Why n is the default path.** The 1.35 rule assumes the sampled interquartile
range equals the population one. It does not: the expected spread of the sample
quartiles depends on n, and the rule ignores that entirely, so it is biased
downwards, severely in small samples. Wan et al. (2014) make exactly this
criticism and supply the n-dependent denominator. With Q1=10 and Q3=20, the
1.35 rule returns 7.407 against Wan's:

| n | Wan SD | 1.35 rule | Error of the 1.35 rule |
|---|---|---|---|
| 3 | 12.635 | 7.407 | -41% |
| 10 | 8.600 | 7.407 | -14% |
| 25 | 7.861 | 7.407 | -6% |
| 100 | 7.522 | 7.407 | -2% |
| 5000 | 7.415 | 7.407 | -0.1% |

**The two are one estimator, not two.** As n grows, Wan's denominator converges
on 2 * qnorm(0.75) = 1.34898 — the 1.35 rule is Wan evaluated at n = infinity.
That is why the fallback is defensible when n genuinely is not reported: it is
the large-sample case of the better formula rather than a rival to it. It is
also why the app labels which one produced each row, since the difference is
material at the sample sizes trials actually report.

**Assumptions:** Both branches assume approximate normality (1.35 is the IQR of
a standard normal, qnorm(0.75)-qnorm(0.25) ~= 1.349) and both are unreliable
for markedly skewed outcomes. Wan corrects for sample size, not for skew.

**Implementation note:** the Wan branch is written in closed form rather than
routed through `metaBLUE::Wan.std()`, which requires a median it does not use
for the S2 SD. `tests/testthat/test-calculations.R` pins the closed form to
`metaBLUE` across n = 3 to 5000 (agreement to 1e-12) and separately confirms
that the S2 SD is invariant to the median, which is what makes Q1/Q3/n
sufficient here.

**Minimum n:** 3. The estimator is undefined at n = 1 (the denominator is
qnorm(0.5) = 0) and quartiles are not meaningful at n = 2. An n below 3 is
reported as an error rather than silently falling back to the 1.35 rule, which
would otherwise change the formula without telling the user.

**Source:** Cochrane Handbook, section 6.5.2.5 ("Interquartile ranges") for the
1.35 rule, which states that when sample sizes are large and the distribution
is close to normal, the interquartile range is approximately 1.35 SDs, and
cautions that the approximation is unreliable for skewed distributions. Wan X,
Wang W, Liu J, Tong T. *BMC Med Res Methodol.* 2014;14:135, for the
sample-size-corrected estimator.

## 4. Median/range/IQR -> mean & standard deviation

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

## 5. Standard deviation of change from baseline

**Formula:** SD_change = sqrt(SD_base^2 + SD_final^2 - 2*r*SD_base*SD_final)

**Assumptions:** r is the (usually unmeasured) correlation between baseline
and final scores; -1 <= r <= 1. When the term under the square root is
negative (can happen if r is set implausibly high relative to the two SDs),
the app reports this explicitly rather than returning `NaN`. A sensitivity
readout at r in {0.3, 0.5, 0.7} is shown alongside the point estimate.

**Source:** Cochrane Handbook, section 6.5.2.8. Cochrane's recommended default
imputation is r = 0.5 when the true correlation is unknown.

## 6. Combine groups (k >= 2)

**Formula:**
- Combined N = sum(N_i)
- Combined Mean = sum(N_i * Mean_i) / N
- Two-group SD: sqrt( ((N1-1)*SD1^2 + (N2-1)*SD2^2 + (N1*N2/(N1+N2))*(Mean1-Mean2)^2) / (N1+N2-1) )

**Assumptions:** For k > 2 groups, combination proceeds by iterative pairwise
folding (combine groups 1+2, then fold in group 3, etc.). This is tested for
order-invariance: combining in a different order produces the same N, Mean,
and SD (to floating-point tolerance).

**Source:** Cochrane Handbook, section 6.5.2.10 ("Combining groups") and
Table 6.5.a ("Formulae for combining summary statistics across two groups").

## 7. Split a shared control group

**Formula:** the control group's N is divided into k whole parts, one per
pairwise comparison sharing it; mean and SD are unchanged. Two weightings
are offered:

- `"even"` (default, Cochrane): k approximately equal parts.
- `"proportional"`: parts proportional to the sizes of the k intervention
  arms, so a comparison against a larger arm draws a larger share.

Both allocate integers by the largest-remainder (Hamilton) method: floor
each exact share, then hand the leftover units to the shares with the
largest discarded fraction.

**Why not round each share independently:** independent rounding does not
preserve the total. For n_control = 41 and k = 3, `round(41/3)` is 14, and
14 x 3 allocates 42 participants from a control arm of 41 - inventing a
participant and inflating the pooled precision. Largest-remainder gives
14, 14, 13. An earlier version of this app used independent rounding; the
test suite now guards the invariant `sum(n_adjusted) == n_control`
explicitly.

**Assumptions:** This is the simple Cochrane approximation used to avoid
double-counting a shared control group's contribution when it appears in
multiple pairwise comparisons within the same meta-analysis. It does not
model the correlation induced by reusing the same control data across
comparisons. The rigorous alternative is a network meta-analysis or another
multivariate method that explicitly accounts for the shared-control
correlation structure.

Note the Handbook's own position: splitting the shared group "only partially
overcomes the unit-of-analysis error (because the resulting comparisons remain
correlated) so is not generally recommended". Its preferred approach is to
combine all relevant experimental groups into one group and all relevant
comparator groups into one group, i.e. section 6 above. Prefer that route
unless the review question requires the arms to stay separate.

**Source:** Cochrane Handbook, section 23.3.4 ("How to include multiple groups
from one study").
