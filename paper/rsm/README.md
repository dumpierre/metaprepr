# Reproduction scripts for the Research Synthesis Methods manuscript

These are the scripts referenced by the data availability statement of the
DataPrepR software paper submitted to *Research Synthesis Methods*. They
regenerate every number and the figure that appear in that manuscript.

Nothing here is needed to run the application itself. See the top-level
`README.md` for that.

## `worked_example.R`

Reproduces every value reported in the manuscript's worked example: the two
conversion routes for the Church control arm, the baseline-to-final
correlations recovered from Church, the change-score standard deviations
imputed for Sigal, the shared-control allocations, and the combined-arm
summary.

It calls the application's own calculator functions in `R/` rather than
reimplementing them, so the printed values are what the software actually
produces. Inputs are transcribed from `data-raw/META_Hardwork_2020.xlsx`,
with the source sheet and rows given in comments.

```
Rscript paper/rsm/worked_example.R
```

Requires `metaBLUE`.

## `figure1_decision_flow.py`

Draws Figure 1, the decision flow for choosing a transformation. Writes a
vector PDF, a 400 dpi PNG, and a 1000 dpi RGB TIFF at the journal's stated
resolution for line drawings, into `paper/rsm/figures/` (not tracked; run the
script to regenerate).

```
python paper/rsm/figure1_decision_flow.py
```

Requires `matplotlib` and `pillow`.

## Keeping these in step with the manuscript

Both files are maintained as byte-identical copies of the scripts in the
manuscript's own working folder. Each resolves its paths by searching rather
than by a fixed relative path, so the same file runs from either location. If
you edit one copy, copy it across rather than letting the two diverge, and
confirm with:

```
sha256sum paper/rsm/worked_example.R
sha256sum paper/rsm/figure1_decision_flow.py
```
