# User Guide

A task-based walkthrough of MetaPrepR. For the formulas themselves, see
`methods.md`.

## Starting the app

```r
shiny::runApp("path/to/metaprepr")
```

The app opens on the **Home** tab, which lists every tool grouped the same way
the navbar menus are. Use the navbar to reach a calculator, the **Workspace**
tab to review and export what you have collected, or the **Notes** tab for a
short description of the app, its citation, and the source repository.

The sidebar on the left holds the language switch (English / Português) and a
live preview of the workspace: how many rows you have and the last few sent.
Collapse it with the toggle at the bottom of its edge.

Every calculator works the same way: type your values and the result appears
immediately below them. There is no Calculate button. If something is missing
or inconsistent, the banner explains what is wrong instead of showing a number,
and the **Send to workspace** button stays disabled until the inputs are valid.

## Task: "My study reports mean and SE, I need SD"

1. Go to **Variance conversions -> SE -> SD**.
2. Enter the SE and the sample size n.
3. The result banner shows the estimated SD as you type.
4. Optionally fill in the mean, Study ID, and Group label for traceability,
   then click **Send to workspace**.

## Task: "My study reports mean and a 95% CI"

1. Go to **Variance conversions -> 95% CI -> SD**.
2. Enter the lower and upper bounds and n.
3. Leave **Critical value** on "t distribution" unless you have a specific
   reason to match a z-based CI from the source study (see `methods.md` for
   why this matters at small n). The banner reports which critical value was
   used alongside the SD.
4. Send to workspace as above.

## Task: "My study reports Q1/Q3 (IQR) but not n"

1. Go to **Variance conversions -> IQR -> SD**.
2. Enter Q1 and Q3.
3. This gives a normal-approximation SD that ignores sample size. If the
   study also reports n, prefer **Median -> mean & SD** with the Wan or Luo
   method instead - it will use n and typically be more accurate.

## Task: "My study reports median, min/max, and/or Q1/Q3 (no mean/SD at all)"

1. Go to **Estimation & imputation -> Median -> mean & SD**.
2. Pick a method:
   - **Wan (2014)** (default) - good general-purpose choice.
   - **Hozo (2005)** - only if you have exactly min/median/max/n (no
     quartiles) and want the classic, simpler formula.
   - **Luo (2018) mean + Wan (2014) SD** - prefer this if you suspect the
     outcome is skewed (e.g., cost data, hospital length of stay, pain scores
     bounded at zero). It stays markedly more accurate than Wan's simple
     mean under skew (see `methods.md`, section 4).
3. Fill in whichever of {min, Q1, median, Q3, max} your source reports, plus
   n. Fields irrelevant to the Hozo method are hidden automatically.
4. The banner also shows which scenario (S1/S2/S3) was detected from your
   inputs, and that scenario is recorded in the workspace's Method column.

## Task: "I need the SD of a change-from-baseline score, but only baseline and final SDs are reported"

1. Go to **Estimation & imputation -> SD of change**.
2. Enter SD at baseline and SD at final measurement.
3. Adjust the correlation slider if you have a study-specific estimate of r;
   otherwise leave it at Cochrane's default of 0.5.
4. The banner shows both the point estimate and a sensitivity readout at
   r = 0.3, 0.5, 0.7, so you can see how much the choice of r matters for your
   data before committing to it.
5. If the result says the term under the square root went negative, it means
   your chosen r is implausibly high relative to the two SDs - try a lower r.
   The sensitivity line stays visible in that case, so you can see which
   values of r would work instead.

## Task: "I have two or more subgroups I need to combine into one group"

1. Go to **Group manipulation -> Combine groups**.
2. Edit the table directly: enter N, Mean, SD for each group. Right-click the
   table to add rows if you have more than 2 groups.
3. The combined N, Mean, and SD appear below the table once at least two rows
   are complete.
4. Send to workspace as one combined row.

## Task: "Two comparisons in my meta-analysis share the same control group"

1. Go to **Group manipulation -> Split shared control**.
2. Enter the control group's N and how many comparisons (k) share it.
   Optionally enter its mean/SD (passed through unchanged).
3. Choose how to divide the control N. **Equally** is Cochrane's default.
   **In proportion to intervention arm sizes** gives a larger share to the
   comparison against a larger arm; it needs the k arm sizes, typed
   comma-separated (e.g. `72, 73, 76`).
4. The result shows the N for each comparison and the total, which always
   adds back up to the control N you entered.
5. Click **Send all k rows to workspace** - this creates k rows, each with
   its own adjusted N and a numbered group label (`control_1`, `control_2`,
   ...), ready to pair with each comparison's intervention arm.
6. Remember this is Cochrane's simple approximation, not a full network
   meta-analysis correction - see `methods.md`, section 7, if your review
   needs the more rigorous approach. Combining the intervention arms into
   one group instead (the task above) avoids the problem altogether and is
   often the better choice.

## Exporting your workspace

On the **Workspace** tab:

- Edit any cell directly in the table if you need to make a manual
  correction. Edits are read straight from the table when you export.
- **Download CSV** or **Download XLSX** to save everything you've collected,
  ready to import into `metafor`, `meta`, RevMan, or a spreadsheet.
- **Clear table** empties the workspace. It asks for confirmation first, and
  there is no undo afterwards.

Two columns record where each row came from:

- `Tool` is a short, fixed identifier for the calculator that produced the row
  (`se-to-sd`, `95ci-to-sd`, `iqr-to-sd`, `median-to-mean`, `sd-change-imput`,
  `combine-group`, `split-group`). It is never translated, so it is safe to
  filter, group, or count on in a script, and it stays the same whether the row
  was created in the English or the Portuguese interface.
- `Method` is the readable description: the specific median method and detected
  scenario, the critical value used for a CI, or the correlation assumed for a
  change score.

Keep both in your final dataset for auditability when your review is checked or
replicated.
