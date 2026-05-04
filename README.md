# EEB 187 — Lab 5: pavo Introduction (cloud-launchable)

[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/AlfaroLab/eeb187-pavo-lab/HEAD?urlpath=rstudio)

One-click cloud RStudio session for **Lab 5: Quantifying Reef Fish Color Patterns**, EEB 187 Ecology & Evolution of Color (UCLA, Spring 2026).

Click the badge above to launch a fully-configured RStudio session in your browser — no install, no GitHub account, no setup. Everything you need (R 4.4, RStudio, pavo, tidyverse, magick, ImageMagick, rembg) is pre-built into the cloud image.

---

## Who this is for

Students in EEB 187 who don't have R/RStudio working locally for the Wednesday Week 6 lab. If you completed `pre-lab-installation.qmd` and your local install works, **use that instead** — it's faster and you keep your work between sessions. This launcher is the fallback.

---

## How to launch

1. Click the **Launch Binder** badge at the top of this page.
2. Wait. First launch builds the image (5–10 min the first time anyone clicks after a code change; ~30 seconds after that, since Binder caches built images). You'll see a build log scrolling — leave the tab open.
3. RStudio Server opens in your browser tab. You're in.

When RStudio loads, the lab files are already in your home directory:

```
/home/rstudio/
├── lab-05-pavo-intro.qmd     ← the worksheet (open this)
├── pre-lab-installation.qmd  ← reference only — install steps are pre-done here
├── scripts/
│   ├── walkthrough.R         ← the live-coded demo (open this and follow along)
│   └── verify_pipeline.R     ← run this once to sanity-check your environment
└── images/
    ├── demo/
    │   ├── raw/              ← uncropped originals (3 fish)
    │   └── segmented/        ← rembg output, used in Part A demo
    └── student-fish/
        ├── acanthuridae/     ← surgeonfish (5 species)
        ├── balistidae/       ← triggerfish
        ├── chaetodontidae/   ← butterflyfish
        └── pomacanthidae/    ← angelfish
```

In RStudio: open `scripts/walkthrough.R` (File → Open File) and run it line by line with Cmd/Ctrl+Enter, alongside the slide deck.

---

## Important caveats — read before launching

- **Sessions time out after ~10 minutes idle.** If you walk away mid-lab, you may lose the session. Save your worksheet locally (File → Export) before stepping away.
- **Cap of ~2 GB memory, ~1 CPU.** Plenty for this lab, but don't try to load 50 fish at once.
- **No persistence.** When the session ends, anything you wrote to disk is gone. Download your worksheet and any output plots before closing the tab.
- **First launch is slow** (5–10 min build). Subsequent launches are fast as long as the repo hasn't changed.
- **`segment_fish()` works.** rembg is pre-installed via uv, and the u2net model has been pre-warmed during build. The first call still downloads the ML model (~170 MB) the first time the cached image runs in a fresh container; budget ~30 seconds.

---

## Doing the lab

The worksheet (`lab-05-pavo-intro.qmd`) is the source of truth for what to submit. The walkthrough script (`scripts/walkthrough.R`) is the live-coded demo that pairs with Rosamari's slide deck.

**Submission**: render the `.qmd` to HTML/PDF, or write your answers in a 1-page Word/Google doc. Submit on BruinLearn by end of day Wednesday.

---

## Contact

- Instructor: Michael Alfaro · michael.edward.alfaro@gmail.com
- TA: Rosamari (see BruinLearn)
- Bug reports for this launcher: open an issue on this repo

---

## For Michael / future maintainers

See [`DEPLOY.md`](DEPLOY.md) for repo-creation, push, and Binder-validation steps.
