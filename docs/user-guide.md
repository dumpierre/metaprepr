# User Guide

A task-based walkthrough of DataPrepR. For the formulas themselves, see
`methods.md`.

## Starting the app

```r
shiny::runApp("path/to/dataprepr")
```

The app opens on the **SE -> SD** tab under **Basic transforms**. Use the
navbar dropdowns to reach the other calculators, or the **Workspace** tab on
the right to review and export everything you've sent so far.

## Task: "My study reports mean and SE, I need SD"

1. Go to **Basic transforms -> SE -> SD**.
2. Enter the SE and the sample size n.
3. Click **Calculate**. The Result card shows the estimated SD.
4. Optionally fill in Study ID / Group label for traceability, then click
   **Send to Workspace**.

## Task: "My study reports mean and a 95% CI"

1. Go to **Basic transforms -> 95% CI -> SD**.
2. Enter the lower and upper bounds and n.
3. Leave **Critical value** on "t distribution" unless you have a specific
   reason to match a z-based CI from the source study (see `methods.md` for
   why this matters at small n).
4. Calculate, then send to workspace as above.

## Task: "My study reports Q1/Q3 (IQR) but not n"

1. Go to **Basic transforms -> IQR -> SD**.
2. Enter Q1 and Q3.
3. This gives a normal-approximation SD that ignores sample size. If the
   study also reports n, prefer **Median -> Mean & SD** with the Wan or Luo
   method instead - it will use n and typically be more accurate.

## Task: "My study reports median, min/max, and/or Q1/Q3 (no mean/SD at all)"

1. Go to **Median-based estimation -> Median -> Mean & SD**.
2. Pick a method:
   - **Wan (2014)** (default) - good general-purpose choice.
   - **Hozo (2005)** - only if you have exactly min/median/max/n (no
     quartiles) and want the classic, simpler formula.
   - **Luo (2018) mean + Wan (2014) SD** - prefer this if you suspect the
     outcome is skewed (e.g., cost data, hospital length of stay, pain scores
     bounded at zero). It's markedly more robust to skew than Wan's simple
     mean (see `methods.md`, section 4).
3. Fill in whichever of {min, Q1, median, Q3, max} your source reports, plus
   n. Fields irrelevant to the Hozo method are hidden automatically.
4. Calculate. The Result card also shows which scenario (S1/S2/S3) was
   detected from your inputs.

## Task: "I need the SD of a change-from-baseline score, but only baseline and
final SDs are reported"

1. Go to **Meta-analysis adjustments -> SD of Change**.
2. Enter SD at baseline and SD at final measurement.
3. Adjust the correlation slider if you have a study-specific estimate of r;
   otherwise leave it at Cochrane's default of 0.5.
4. The Result card shows both the point estimate and a sensitivity readout at
   r = 0.3, 0.5, 0.7, so you can see how much the choice of r matters for your
   data before committing to it.
5. If the result says the term under the square root went negative, it means
   your chosen r is implausibly high relative to the two SDs - try a lower r.

## Task: "I have two or more subgroups I need to combine into one group"

1. Go to **Meta-analysis adjustments -> Combine Groups**.
2. Edit the table directly: enter N, Mean, SD for each group. Right-click the
   table to add rows if you have more than 2 groups.
3. Click **Calculate** to get the combined N, Mean, and SD.
4. Send to workspace as one combined row.

## Task: "Two comparisons in my meta-analysis share the same control group"

1. Go to **Meta-analysis adjustments -> Split Shared Control**.
2. Enter the control group's N and how many comparisons (k) share it.
   Optionally enter its mean/SD (passed through unchanged).
3. Click **Calculate**, then **Send all k rows to Workspace** - this creates
   k rows, each with the adjusted N and a numbered group label
   (`control_1`, `control_2`, ...), ready to pair with each comparison's
   intervention arm.
4. Remember this is Cochrane's simple approximation, not a full network
   meta-analysis correction - see `methods.md`, section 7, if your review
   needs the more rigorous approach.

## Exporting your workspace

On the **Workspace** tab:

- Edit any cell directly in the table if you need to make a manual
  correction.
- **Download CSV** or **Download XLSX** to save everything you've collected,
  ready to import into `metafor`, `meta`, RevMan, or a spreadsheet.

The `Method` column records which calculator and method produced each row -
keep it in your final dataset for auditability when your review is checked or
replicated.
