# Deploy guide — push this directory to AlfaroLab and validate Binder

Audience: Michael Alfaro. The launchable lab repo lives in `/Users/alfarolab/Dropbox/git/EEB187-ecology-evolution-color-2026/eeb187-pavo-lab/` and is meant to be pushed as a **separate public repo** at `https://github.com/AlfaroLab/eeb187-pavo-lab`.

## 1. Create the GitHub repo

On github.com:

1. Sign in as the AlfaroLab org (or as yourself with org-create perms).
2. https://github.com/organizations/AlfaroLab/repositories/new
3. Name: `eeb187-pavo-lab`
4. Visibility: **Public** (Binder cannot build private repos on the free tier)
5. **Do not** initialize with README / .gitignore / license — we already have a README and the rest will be pushed clean.
6. Create.

Copy the SSH or HTTPS URL it gives you.

## 2. Push this directory

From a terminal:

```bash
cd /Users/alfarolab/Dropbox/git/EEB187-ecology-evolution-color-2026/eeb187-pavo-lab
git init
git add .
git commit -m "Initial commit: cloud-launchable EEB 187 Lab 5 (pavo intro)"
git branch -M main
git remote add origin git@github.com:AlfaroLab/eeb187-pavo-lab.git   # or HTTPS
git push -u origin main
```

If the repo also needs to live as a subtree of the main course repo, **don't add it as a submodule there** — keep it standalone. The main course repo's `labs/demo-pavo-week6/` continues to be the canonical, instructor-facing source. This launcher repo is a frozen snapshot for student use.

## 3. Trigger and validate the Binder build

Binder builds lazily — the first click on the launch URL kicks off the build. To pre-warm it (so students never see the cold-build wait):

1. Open https://mybinder.org/v2/gh/AlfaroLab/eeb187-pavo-lab/HEAD?urlpath=rstudio in a private window.
2. Watch the build log. It will run `repo2docker` on the GitHub repo, detect `.binder/Dockerfile`, and build.
3. Expected build time on Binder's free tier: **8–15 minutes** the first time, due to:
   - Downloading rocker/binder:4.4 base (~2 GB)
   - apt-get installing ImageMagick + libmagick++-dev (~30 s)
   - Installing pavo from source binary (Posit binary repo, fast: ~30 s)
   - `uv tool install rembg` (~1–2 min, includes onnxruntime + opencv wheels)
4. Image size estimated: **~3.5–4 GB** uncompressed (rocker/binder base alone is ~2 GB, pavo + rembg add ~1.5 GB).
5. When build completes, RStudio loads. Confirm:
   - `library(pavo); packageVersion("pavo")` shows ≥ 2.9.0
   - `system("which uvx && uvx --help")` works
   - `system("magick -version")` shows ImageMagick 6.x
   - Try one full pipeline call: `source("scripts/walkthrough.R")` (run interactively, not all at once)

**If the build fails** on Binder, the most likely causes (in order of frequency):
- Memory limit hit during R package compilation. Mitigation: we use Posit's pre-built binary repo, which avoids compilation. If this still fails, switch the install repo line in `install.R` back to default CRAN and accept slower compile.
- `uv tool install rembg` fails because the binder build VM has stale Python wheels. Mitigation: pin a known-good rembg version, e.g. `rembg[cpu,cli]==2.0.50`.
- ImageMagick policy.xml doesn't have the path we sed for. Mitigation: harmless — the `|| true` keeps the build going.

## 4. Add a launch badge to the AlfaroLab org page

Two paths:

- **Pin this repo** on the AlfaroLab org page (Customize your pins) so it shows on the org's landing page. Each pinned repo shows its README's first line + the Binder badge as a tile.
- **Add a link** to the AlfaroLab `.github` repo's profile README (creates an org-level landing page).

The badge URL is already in this repo's README; nothing else needs to be done unless you want a top-level org-page badge that links to the same Binder URL.

## 5. Update the launcher when the lab changes

This repo is a **frozen** copy of the lab. If you edit `walkthrough.R` or the worksheet in the main course repo, those changes don't propagate automatically. To re-sync:

```bash
cd /Users/alfarolab/Dropbox/git/EEB187-ecology-evolution-color-2026

# Manually copy the changed files
cp labs/lab-05-pavo-intro.qmd                          eeb187-pavo-lab/
cp labs/demo-pavo-week6/pre-lab-installation.qmd       eeb187-pavo-lab/
cp labs/demo-pavo-week6/scripts/walkthrough.R          eeb187-pavo-lab/scripts/
cp labs/demo-pavo-week6/scripts/verify_pipeline.R      eeb187-pavo-lab/scripts/

cd eeb187-pavo-lab
git add . && git commit -m "Sync lab content from main course repo" && git push
```

After push, the next Binder launch builds a fresh image (5–10 min). For an instant rebuild, hit the launch URL once yourself to absorb the build wait before students arrive.

## 6. Codespaces — wired up

`.devcontainer/devcontainer.json` is now committed and reuses the same `.binder/Dockerfile`, so any student can click **Code → Codespaces → Create codespace on main** and get the lab running with persistent state. No extra config needed on the maintainer side. To validate after a Dockerfile change, open a codespace yourself and confirm port 8787 forwards RStudio.

## 7. Local Docker fallback (zero-cloud option)

For students with Docker installed who don't trust Binder:

```bash
git clone https://github.com/AlfaroLab/eeb187-pavo-lab.git
cd eeb187-pavo-lab
docker build -f .binder/Dockerfile -t eeb187-pavo-lab .
docker run --rm -p 8787:8787 eeb187-pavo-lab
```

Then open http://localhost:8787 (Binder's RStudio runs without a password since it boots into the rocker/binder runtime). Estimated local build time: 5–8 min on a recent Mac/Linux.
