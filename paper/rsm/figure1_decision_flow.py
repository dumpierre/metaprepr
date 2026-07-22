"""
Figure 1 for paper_RSM_v1.md, section 3: the decision flow a reviewer follows
when a trial does not report a mean, an SD and an n directly.

Produces a print-ready vector PDF plus a 400 dpi PNG. The figure is designed
to survive greyscale reproduction: the distinction between an in-scope tool,
a step needing no action, and a step outside the tool's scope is carried by
border style and fill lightness, not by hue alone.

Run from the repository root:
    python paper-synthesis-methods/scripts/figure1_decision_flow.py
"""

import textwrap
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch

# --- page geometry, in millimetres ------------------------------------------
W = 180.0            # full text width of a journal page
MARGIN = 3.0
GUTTER = 3.0
PAD = 1.8            # padding inside a box
LEAD = 1.22          # line spacing, as a multiple of the font size

MM_PER_PT = 0.352777

# --- palette ----------------------------------------------------------------
# Taken from the application's own theme so the figure and the tool read as
# one piece of work. All fills are light enough to print behind black text.
NAVY = "#1b2a4a"
COPPER = "#b8712a"
COPPER_FILL = "#f3e8da"
TEAL = "#2f6f62"
TEAL_FILL = "#e4ede9"
GREY = "#6f7480"
GREY_FILL = "#f2f1ec"
PAPER = "#faf8f3"

plt.rcParams.update({
    "font.family": "sans-serif",
    "font.sans-serif": ["Arial", "DejaVu Sans"],
    "pdf.fonttype": 42,      # embed as TrueType, not Type 3
    "ps.fonttype": 42,
})


def wrap(text, width_mm, fs, pad=PAD):
    """Wrap text to fit a box, respecting explicit newlines."""
    usable = width_mm - 2 * pad
    chars = max(8, int(usable / (0.50 * fs * MM_PER_PT)))
    out = []
    for para in text.split("\n"):
        out.extend(textwrap.wrap(para, chars) or [""])
    return out


def box_height(lines, fs, extra=0.0):
    return 2 * PAD + len(lines) * LEAD * fs * MM_PER_PT + extra


def measure(text, w, fs):
    return box_height(wrap(text, w, fs), fs)


class Sheet:
    def __init__(self, width, height):
        self.w, self.h = width, height
        self.fig = plt.figure(figsize=(width / 25.4, height / 25.4))
        self.ax = self.fig.add_axes([0, 0, 1, 1])
        self.ax.set_xlim(0, width)
        self.ax.set_ylim(height, 0)          # y grows downward
        self.ax.axis("off")
        self.ax.add_patch(plt.Rectangle((0, 0), width, height,
                                        facecolor=PAPER, edgecolor="none", zorder=0))

    def box(self, x, y, w, text, fs=7.0, kind="branch", bold_first=False, force_h=None):
        """Draw a box whose top-left corner is (x, y). Returns its height.

        force_h equalises heights across a row; the text stays vertically
        centred inside whatever height is imposed.
        """
        style = {
            "branch": dict(fc="#ffffff", ec=NAVY, lw=0.8, ls="solid", tc=NAVY),
            "tool":   dict(fc=COPPER_FILL, ec=COPPER, lw=1.2, ls="solid", tc="#5c380f"),
            "ready":  dict(fc=GREY_FILL, ec=GREY, lw=0.7, ls="solid", tc="#3b3f47"),
            "out":    dict(fc="#ffffff", ec=GREY, lw=0.7, ls=(0, (2.2, 1.6)), tc=GREY),
        }[kind]

        # A tool box carries a solid bar down its left edge. In greyscale the
        # copper and grey fills are almost the same value, so scope has to be
        # signalled by shape rather than by hue.
        bar = 1.5 if kind == "tool" else 0.0

        lines = wrap(text, w, fs, pad=PAD + bar)
        h = force_h if force_h is not None else box_height(lines, fs)
        self.ax.add_patch(FancyBboxPatch(
            (x + 0.5, y + 0.5), w - 1.0, h - 1.0,
            boxstyle="round,pad=0.5,rounding_size=1.1",
            facecolor=style["fc"], edgecolor=style["ec"],
            linewidth=style["lw"], linestyle=style["ls"], zorder=3))
        if bar:
            self.ax.add_patch(FancyBboxPatch(
                (x + 1.9, y + 1.9), bar, max(h - 3.8, 0.6),
                boxstyle="round,pad=0,rounding_size=0.35",
                facecolor=COPPER, edgecolor="none", zorder=4))

        lh = LEAD * fs * MM_PER_PT
        ly = y + (h - len(lines) * lh) / 2 + 0.55 * lh
        for i, line in enumerate(lines):
            self.ax.text(x + w / 2 + bar / 2, ly, line, ha="center", va="center",
                         fontsize=fs, color=style["tc"], zorder=5,
                         fontweight="bold" if (bold_first and i == 0) else "normal",
                         style="italic" if kind == "out" else "normal")
            ly += lh
        return h

    def header(self, x, y, w, number, text, fs=8.0):
        h = 2 * PAD + LEAD * fs * MM_PER_PT
        self.ax.add_patch(FancyBboxPatch(
            (x + 0.5, y + 0.5), w - 1.0, h - 1.0,
            boxstyle="round,pad=0.5,rounding_size=1.1",
            facecolor=NAVY, edgecolor=NAVY, linewidth=0.7, zorder=3))
        self.ax.text(x + 4.5, y + h / 2, str(number), ha="center", va="center",
                     fontsize=fs + 1.5, color=COPPER, fontweight="bold", zorder=4)
        self.ax.text(x + 9.0, y + h / 2, text, ha="left", va="center",
                     fontsize=fs, color="#ffffff", fontweight="bold", zorder=4)
        return h

    def note(self, x, y, w, text, fs=6.2):
        lines = wrap(text, w, fs, pad=0)
        lh = LEAD * fs * MM_PER_PT
        ly = y + 0.55 * lh
        for line in lines:
            self.ax.text(x, ly, line, ha="left", va="center",
                         fontsize=fs, color=GREY, style="italic", zorder=4)
            ly += lh
        return len(lines) * lh

    def arrow(self, x, y0, y1, color=NAVY, lw=0.7, ls="solid"):
        self.ax.add_patch(FancyArrowPatch(
            (x, y0), (x, y1), arrowstyle="-|>", mutation_scale=6,
            linewidth=lw, color=color, linestyle=ls, zorder=2,
            shrinkA=0, shrinkB=0))

    def elbow(self, x0, y0, x1, y1, color=NAVY, lw=0.7):
        """Vertical drop, horizontal run, then a short arrow down."""
        mid = y0 + (y1 - y0) * 0.45
        self.ax.plot([x0, x0], [y0, mid], color=color, lw=lw, zorder=2,
                     solid_capstyle="round")
        self.ax.plot([x0, x1], [mid, mid], color=color, lw=lw, zorder=2,
                     solid_capstyle="round")
        self.arrow(x1, mid, y1, color=color, lw=lw)


# --- content -----------------------------------------------------------------
# Each stage: header question, then one column per condition. A column holds a
# condition box and the outcome box(es) it leads to.

STAGES = [
    dict(
        q="What does the reported dispersion describe?",
        note=("An SD describes the spread of the sample; an SE or a CI describes the precision "
              "of an estimate and depends on n. Read the table footnote, not the number. Where "
              "a trial reports both, resolve the discrepancy and record how."),
        cols=[
            ("Mean, SD and n\nare reported directly",
             [("ready", "No conversion needed\nGo to stage 3", False)]),
            ("Standard error\nof the mean",
             [("tool", "SE to SD\nSD = SE x sqrt(n)", True)]),
            ("95% confidence\ninterval for a mean",
             [("tool", "CI to SD\nUse the t critical value unless the "
                       "trial states it used a normal one", True)]),
            ("Median, with quartiles\nor a range",
             [("ready", "Go to stage 2", False)]),
        ],
    ),
    dict(
        q="Does the distribution justify an estimator that assumes symmetry?",
        note=("If a trial reports a median, ask why. When the answer is skew, an estimator built "
              "on normality is biased and gives no sign of it. Where estimators disagree on the "
              "same inputs, carry the disagreement into a sensitivity analysis."),
        cols=[
            ("Approximately symmetric,\nand n is known",
             [("tool", "Median to mean and SD\nLuo's mean estimator is the more robust; "
                       "Hozo's is included only to reproduce older reviews", True)]),
            ("Approximately symmetric,\nbut n is not available",
             [("tool", "IQR to SD\nSD = (Q3 - Q1) / 1.35, a rule of thumb that ignores n; "
                       "prefer the estimator at left whenever n is known", True)]),
            ("Strongly skewed, or the\nmedian was chosen because\nof skew",
             [("out", "Outside this tool\nUse estmeansd, metamedian, or "
                      "metafor::conv.fivenum()", False)]),
        ],
    ),
    dict(
        q="Is the quantity you need a final value or a change from baseline?",
        note=("The mean change is the difference of the means. Its SD is not, because baseline "
              "and final values are measured on the same people. The correlation between them "
              "is almost never reported, so it is assumed, and the assumption belongs in the record."),
        cols=[
            ("What the review needs is\nwhat the trial reports",
             [("ready", "Nothing to impute\nGo to stage 4", False)]),
            ("Change is needed; another\ntrial reports baseline, final\nand change SDs",
             [("tool", "SD of change, r recovered\nsqrt(SDb^2 + SDf^2 - 2 r SDb SDf). "
                       "Recovering r is not implemented; do it separately", True)]),
            ("Change is needed and r\ncannot be recovered from\nany included trial",
             [("tool", "SD of change, with r assumed\nCochrane's default is 0.5. Report the "
                       "result at r = 0.3, 0.5 and 0.7", True)]),
        ],
    ),
    dict(
        q="Does every participant enter the analysis exactly once?",
        note=("Shared control arms, subgroup reporting and cluster designs all break this without "
              "leaving a trace in the extracted table. The check is arithmetic: the sample sizes a "
              "trial contributes must reconcile with the number it randomised."),
        cols=[
            ("One intervention arm\nand one control arm",
             [("ready", "Ready for synthesis", False)]),
            ("Several intervention arms\nshare one control arm",
             [("tool", "Combine, or split the control\nCombining is preferred; a split is an "
                       "approximation whose parts must sum to the control n", True)]),
            ("Results are reported by a\nsubgroup the review does\nnot ask about",
             [("tool", "Combine groups\nThe combined SD must absorb the gap "
                       "between the subgroup means", True)]),
            ("Cluster-randomised\nor crossover design",
             [("out", "Outside this tool\nCompute the effective sample size "
                      "before synthesis", False)]),
        ],
    ),
]

ENTRY = "A reported result for one group of one trial"
TERMINAL = ("Record the study, the group, the method applied and every assumed parameter value, "
            "and export them with the data")
TERMINAL_SUB = "PRISMA 2020, item 13b"


def build():
    inner = W - 2 * MARGIN
    # Two passes: measure, then draw onto a correctly sized sheet.
    for measuring in (True, False):
        height = 400.0 if measuring else total_h
        sh = Sheet(W, height)
        y = MARGIN + 1.0

        # entry node
        eh = sh.box(MARGIN + inner * 0.22, y, inner * 0.56, ENTRY, fs=8.0,
                    kind="branch", bold_first=True)
        y += eh
        sh.arrow(W / 2, y, y + 4.0)
        y += 4.0

        for si, st in enumerate(STAGES, start=1):
            hh = sh.header(MARGIN, y, inner, si, st["q"])
            y_head = y + hh
            y = y_head + 3.0

            n = len(st["cols"])
            cw = (inner - (n - 1) * GUTTER) / n

            # Equalise heights down each row so the stage reads as a band.
            cond_h = max(measure(c, cw, 7.0) for c, _ in st["cols"])
            depth = max(len(outs) for _, outs in st["cols"])
            out_h = [
                max((measure(o[1], cw, 6.6) for _, outs in st["cols"]
                     if len(outs) > i for o in [outs[i]]), default=0.0)
                for i in range(depth)
            ]

            for ci, (cond, outs) in enumerate(st["cols"]):
                cx = MARGIN + ci * (cw + GUTTER)
                centre = cx + cw / 2
                sh.arrow(centre, y_head, y - 0.4, lw=0.6)

                cy = y + sh.box(cx, y, cw, cond, fs=7.0, kind="branch", force_h=cond_h)
                for i, (kind, text, bold) in enumerate(outs):
                    sh.arrow(centre, cy, cy + 2.6, lw=0.6,
                             color=GREY if kind == "out" else NAVY,
                             ls=(0, (2, 1.5)) if kind == "out" else "solid")
                    cy += 2.6
                    cy += sh.box(cx, cy, cw, text, fs=6.6, kind=kind,
                                 bold_first=bold, force_h=out_h[i])

            y += cond_h + sum(2.6 + h for h in out_h) + 2.2
            y += sh.note(MARGIN + 1.0, y, inner - 2.0, st["note"])
            y += 2.4

            if si < len(STAGES):
                sh.arrow(W / 2, y - 2.0, y + 1.0)
                y += 1.8

        # terminal band
        sh.arrow(W / 2, y - 2.4, y + 0.8)
        y += 1.2
        lines = wrap(TERMINAL, inner, 8.0)
        lh8 = LEAD * 8.0 * MM_PER_PT
        th = box_height(lines, 8.0) + 3.6
        sh.ax.add_patch(FancyBboxPatch(
            (MARGIN + 0.5, y + 0.5), inner - 1.0, th - 1.0,
            boxstyle="round,pad=0.5,rounding_size=1.1",
            facecolor=TEAL, edgecolor=TEAL, linewidth=0.8, zorder=3))
        ly = y + PAD + 0.55 * lh8
        for line in lines:
            sh.ax.text(W / 2, ly, line, ha="center", va="center", fontsize=8.0,
                       color="#ffffff", fontweight="bold", zorder=4)
            ly += lh8
        sh.ax.text(W / 2, ly + 0.2, TERMINAL_SUB, ha="center", va="center",
                   fontsize=6.4, color=TEAL_FILL, zorder=4)
        y += th + 3.2

        # legend
        keys = [("tool", "a step DataPrepR performs"),
                ("ready", "no action needed"),
                ("out", "outside the tool's scope")]
        lx = MARGIN + 1.0
        for kind, label in keys:
            fc, ec, ls, lw = {"tool": (COPPER_FILL, COPPER, "solid", 1.2),
                              "ready": (GREY_FILL, GREY, "solid", 0.7),
                              "out": ("#ffffff", GREY, (0, (2.2, 1.6)), 0.7)}[kind]
            sh.ax.add_patch(FancyBboxPatch(
                (lx, y), 6.0, 3.2, boxstyle="round,pad=0.3,rounding_size=0.8",
                facecolor=fc, edgecolor=ec, linewidth=lw, linestyle=ls, zorder=3))
            if kind == "tool":
                sh.ax.add_patch(FancyBboxPatch(
                    (lx + 0.9, y + 0.7), 1.2, 1.8,
                    boxstyle="round,pad=0,rounding_size=0.3",
                    facecolor=COPPER, edgecolor="none", zorder=4))
            sh.ax.text(lx + 7.6, y + 1.6, label, ha="left", va="center",
                       fontsize=6.4, color="#3b3f47", zorder=4)
            lx += 7.6 + 0.55 * 6.4 * MM_PER_PT * len(label) + 7.0
        y += 3.2 + MARGIN

        if measuring:
            globals()["total_h"] = y
            plt.close(sh.fig)
        else:
            return sh


def output_dir():
    """Locate the figures directory, whichever checkout this script sits in.

    This file is kept byte-identical in two places: the manuscript working
    folder and paper/rsm/ in the DataPrepR repository, which is the copy the
    paper's data availability statement points at. Resolving the output
    directory by search rather than by a fixed relative path lets both copies
    stay identical.
    """
    here = Path(__file__).resolve().parent
    for candidate in (here / "figures", here.parent / "figures"):
        if candidate.is_dir():
            return candidate
    fallback = here / "figures"
    fallback.mkdir(parents=True, exist_ok=True)
    return fallback


if __name__ == "__main__":
    out = output_dir()
    sheet = build()

    # Vector master, plus a screen-resolution PNG for the review copy.
    sheet.fig.savefig(out / "figure1_decision_flow.pdf")
    sheet.fig.savefig(out / "figure1_decision_flow.png", dpi=400)

    # Submission raster. Research Synthesis Methods asks for line drawings at
    # 1000 dpi at final size; the file is named to the journal's convention,
    # which uses the first author's surname (edit AUTHOR below).
    AUTHOR = "Fig"
    tif = out / f"{AUTHOR}1.tif"
    sheet.fig.savefig(tif, dpi=1000, pil_kwargs={"compression": "tiff_lzw"})

    # matplotlib writes RGBA; flatten to RGB so the file has no alpha channel.
    from PIL import Image
    Image.MAX_IMAGE_PIXELS = None
    with Image.open(tif) as im:
        if im.mode != "RGB":
            flat = Image.new("RGB", im.size, "white")
            flat.paste(im, mask=im.split()[-1] if im.mode == "RGBA" else None)
            flat.save(tif, dpi=(1000, 1000), compression="tiff_lzw")

    print(f"wrote {out/'figure1_decision_flow.pdf'}  ({W:.0f} x {total_h:.1f} mm)")
    print(f"wrote {tif}  (1000 dpi, RGB, LZW)")
