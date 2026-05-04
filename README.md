# EEB 187 — Lab 5: pavo Introduction

A computer lab for **EEB 187 Ecology & Evolution of Color** (UCLA, Spring 2026), pre-packaged so any student can get it running — in the cloud or on their own machine — without an hour of dependency wrangling.

There are **four ways to launch this lab**. They all run the same code from the same Dockerfile, so the lab is identical no matter which path you pick. Pick the one that matches what you have available right now.

| | Path | Install needed on your machine | Session persists when you close the tab? | First-time start |
|--|--|--|--|--|
| 1 | **[Binder](#1-binder--zero-install-cloud-rstudio)** (cloud RStudio) | Nothing | No | 5–10 min build, then ~30 s |
| 2 | **[GitHub Codespaces](#2-github-codespaces--persistent-cloud-rstudio)** (cloud RStudio) | A free GitHub account | Yes | 5–10 min build, then ~30 s |
| 3 | **[Docker](#3-docker--local-rstudio-no-r-needed)** (local RStudio) | Docker Desktop (~600 MB) | Yes | 5–8 min build, then instant |
| 4 | **[Native R + RStudio](#4-native--full-local-install)** (no Docker) | R, RStudio, uv (a few hundred MB total) | Yes — fastest, full integration | 30–60 min one-time |

**Recommendation by week:**

- **Lab day (Week 6)**: Option 1 (Binder) is fine. No install, just click and go. Sessions only last 90 min, but the lab fits in that.
- **From Week 7 on**: graduate to Option 4 (Native). You'll be doing your own analyses, you'll want your work to persist, and a native install is what you'll use for everything beyond this course.
- **In between**: Options 2 and 3 are good middle steps if your laptop can't run R natively yet.

---

## 1. Binder — zero-install cloud RStudio

[![Launch Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/AlfaroLab/eeb187-pavo-lab/HEAD?urlpath=rstudio)

Click the badge. Wait for the build (5–10 min the first time anyone clicks after a code change; ~30 s after that, since Binder caches built images). RStudio Server opens in your browser. You're in.

**Caveats:**
- **Sessions time out after ~10 min idle**, hard cap of **90 min**. Save your worksheet locally before stepping away.
- **No persistence.** Anything you write to disk is gone when the session ends. Download your worksheet and any output plots before closing the tab.
- **First launch is slow.** Subsequent launches are fast as long as the repo hasn't changed.
- **~2 GB memory, ~1 CPU.** Plenty for this lab; don't try to load 50 fish at once.

This option is the lowest-friction way to do the Wednesday Week 6 lab. Use it for that, then move on.

---

## 2. GitHub Codespaces — persistent cloud RStudio

If you have a free GitHub account and want your work to persist between sessions:

1. Click the green **&lt;&gt; Code** button at the top of the [GitHub repo page](https://github.com/AlfaroLab/eeb187-pavo-lab).
2. Tab over to **Codespaces** → **Create codespace on main**.
3. The codespace boots into VS Code in your browser. Wait for the post-create build (5–10 min the first time).
4. Once it's ready, an in-browser RStudio Server is forwarded on port **8787**. Click the popup notification, or open the **Ports** panel and click the globe icon next to 8787.

**Why pick this over Binder:**
- Sessions persist (your edits, your output plots, your installed packages).
- Free tier: 60 hours/month of 2-core compute (more than enough for this course).
- Works the same on any laptop or Chromebook.

**Caveats:**
- Requires GitHub account (free).
- After 30 min of inactivity Codespaces auto-stops the VM; restart resumes in <10 s.
- Eats your free tier, so don't leave it running overnight.

---

## 3. Docker — local RStudio, no R needed

If you have [Docker Desktop](https://docs.docker.com/desktop/) (free for academic use) installed, you can run the entire lab on your own laptop without installing R, RStudio, or any R packages:

```bash
git clone https://github.com/AlfaroLab/eeb187-pavo-lab.git
cd eeb187-pavo-lab
docker build -f .binder/Dockerfile -t eeb187-pavo-lab .
docker run --rm -p 8787:8787 -v "$PWD:/home/rstudio/work" eeb187-pavo-lab
```

Then open `http://localhost:8787` — log in as `rstudio` / `rstudio` (or no password, depending on the base image). The `-v "$PWD:/home/rstudio/work"` flag mounts your local repo folder inside RStudio so anything you save in `~/work/` lives on your laptop, not just in the container.

**Why pick this over Codespaces:**
- Completely offline-capable after the first build.
- Faster than the cloud options.
- Doesn't count against any cloud quota.

**Caveats:**
- Docker Desktop is ~600 MB to install.
- First-time build: 5–8 min. Image is ~3.5 GB on disk.
- You're still inside a container, not native — startup is fast but not instant.

---

## 4. Native — full local install

The "do it like a real scientist" path. Once you've done this once, you'll launch RStudio in 2 seconds and never wait on a build again.

Open [`pre-lab-installation.qmd`](pre-lab-installation.qmd) and follow the platform-specific steps for macOS, Windows, or Linux. The short version:

1. Install **R** (≥ 4.4) and **RStudio Desktop**.
2. Install **uv** (one-line installer; manages the Python tooling for `rembg`).
3. Install **ImageMagick** (`brew install imagemagick` on Mac, the installer on Windows, `apt install imagemagick` on Linux).
4. Inside R: `install.packages(c("pavo", "tidyverse", "magick", "units"))`.
5. Clone this repo: `git clone https://github.com/AlfaroLab/eeb187-pavo-lab.git`.
6. Open `eeb187-pavo-lab.Rproj` in RStudio (or just open `scripts/walkthrough.R`).
7. Run `Rscript scripts/verify_pipeline.R` to confirm everything works.

The pre-lab guide also covers the common gotchas (missing `udunits` on macOS, ImageMagick policy on Linux, Windows path quirks).

**Why this is the long-term answer:**
- Sub-second startup. No build, no container, no cloud round-trip.
- Full integration: your editor, your file system, your other R projects.
- It's what you'll use to analyze your own thesis data, publish papers, run permutation tests, and so on. Build the muscle memory now.
- Quarto rendering, ggplot output, and PDF export "just work."

If you hit a wall during native install, the cloud options above are always there as a fallback. There's no shame in launching Binder for one lab while you sort out a Windows path issue at home.

---

## What's in this repo

```
eeb187-pavo-lab/
├── lab-05-pavo-intro.qmd        ← the worksheet (this is what you submit)
├── pre-lab-installation.qmd     ← native-install guide for Option 4
├── scripts/
│   ├── walkthrough.R            ← the live-coded demo (open this in lab)
│   └── verify_pipeline.R        ← run once to sanity-check your environment
├── images/
│   ├── demo/
│   │   ├── raw/                 ← uncropped originals (3 fish)
│   │   └── segmented/           ← rembg output (1500×800 standardized)
│   └── student-fish/            ← fallback fish across 4 reef-fish families
├── .binder/Dockerfile           ← used by all 4 launch paths
├── .devcontainer/               ← Codespaces config (reuses Binder Dockerfile)
└── DEPLOY.md                    ← maintainer notes (push/sync workflow)
```

When RStudio loads, open `scripts/walkthrough.R` and run it line by line with **Cmd/Ctrl+Enter**, alongside the slide deck.

---

## Submission

Render the `.qmd` to HTML/PDF, or write your answers in a 1-page Word/Google doc. Submit on BruinLearn by end of day Wednesday Week 6.

---

## Contact

- Instructor: **Michael Alfaro** · michael.edward.alfaro@gmail.com
- TA: **Rosamari** (see BruinLearn)
- Bug reports for this launcher: open an issue on this repo

---

## For maintainers

See [`DEPLOY.md`](DEPLOY.md) for repo-creation, sync, and Binder pre-warm steps.
