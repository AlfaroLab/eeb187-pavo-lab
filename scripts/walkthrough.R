# =============================================================================
# Lab 5 — pavo Walkthrough
# EEB 187 — Ecology & Evolution of Color — Week 6
# =============================================================================
# This is the live-coded R script that runs alongside Rosamari's slide deck.
# Three demo fish, three reef families, three pattern types.
#
# Read top to bottom. Each section corresponds to a slide block.
# =============================================================================


# -----------------------------------------------------------------------------
# Step 0 — Setup: load packages and confirm the environment
# -----------------------------------------------------------------------------

library(pavo)         # color analysis
library(magick)       # image I/O backend
library(tidyverse)    # data wrangling + ggplot

# Sanity check — should print 2.9.0 or higher
packageVersion("pavo")

# Set working directory to the lab bundle.
# Adjust this path if you put the lab folder somewhere else.
# In RStudio: Session → Set Working Directory → To Source File Location
# is usually the easiest move.
#
# setwd("~/Documents/EEB187-pavo-lab/labs/demo-pavo-week6/")


# -----------------------------------------------------------------------------
# Step 1 — Load the three demo fish images (SEGMENTED versions)
# -----------------------------------------------------------------------------
# pavo's getimg() reads JPG / PNG into an rimg object — internally a 3D array
# (height x width x {R, G, B}) plus metadata. Pass a folder and it loads every
# image; pass a filename and it loads one.
#
# Two things to know about getimg() on a folder:
#   1. It returns the list in ALPHABETICAL ORDER — not in the order you might
#      expect. Don't index by position; index by name.
#   2. The filename is stored as the 'imgname' ATTRIBUTE on each rimg object,
#      not as the list's names(). Use attr(x, "imgname") to read it.
#
# We sidestep both by loading each fish individually with a clear R name.
#
# THREE VERSIONS of each demo fish exist in this bundle:
#   images/demo/raw/        original Wikimedia photos with full background
#   images/demo/            cropped to bounding box around the fish
#   images/demo/segmented/  background actually removed (rembg ML model) and
#                           composited onto solid white. THIS is what we use.
#
# Walking through these three folders shows the segmentation progression
# visually: raw -> cropped -> segmented. Each step strips more background
# noise and makes the resulting pavo metrics cleaner and more dramatic.

sergeant_major <- getimg("images/demo/segmented/sergeant-major.jpg")
cleaner_wrasse <- getimg("images/demo/segmented/cleaner-wrasse.jpg")
mandarin_fish  <- getimg("images/demo/segmented/mandarin-fish.jpg")

# Inspect: each is an rimg object — a 3D array plus pavo metadata
class(sergeant_major)                          # "rimg" "array"
attr(sergeant_major, "imgname")                # "sergeant-major"
dim(sergeant_major)                            # height × width × 3 (RGB)

# Plot all three
par(mfrow = c(1, 3))
plot(sergeant_major); title("sergeant major")
plot(cleaner_wrasse); title("cleaner wrasse")
plot(mandarin_fish);  title("mandarin fish")
par(mfrow = c(1, 1))


# -----------------------------------------------------------------------------
# Step 1.5 — SEGMENTATION: crop tightly around the fish
# -----------------------------------------------------------------------------
# WHY THIS MATTERS: pavo's classify() runs k-means over the WHOLE input image.
# If your image has substantial background (water, reef, tank glass), k-means
# will assign one or more "color classes" to the BACKGROUND, not the fish.
# k=3 over an uncropped photo of a bluish reef + yellow fish often gives:
#   class 1 = blue water        (BACKGROUND, biologically meaningless)
#   class 2 = fish black bars
#   class 3 = fish yellow + white (collapsed)
# That's "color calling that doesn't make sense."
#
# Then adjacent() samples grid points across the WHOLE image, and the long
# stretches of uniform background dilute the directional signal in A.
#
# THE FIX: crop the image to a tight bounding box around the fish BEFORE
# loading. The 3 demo fish here are pre-cropped (see images/demo/raw/ for
# uncropped originals).
#
# For your own fish later, crop in any of:
#   - Preview.app (Tools -> Crop)
#   - macOS Photos app
#   - terminal:   magick raw.jpg -crop WxH+X+Y +repage cropped.jpg
#   - GIMP / Photoshop / other image editor
#
# Tighter is better, but don't cut into the fish's body or fins.
#
# Optional advanced: pavo::procimg(img, outline = TRUE) lets you click a
# polygon outline around the fish in RStudio's Plot pane. The outline is
# saved as an attribute and respected by adjacent(exclude = "background").
# This is more precise than rectangular cropping but requires interactive
# clicking. We use rectangular cropping below for simplicity.


# -----------------------------------------------------------------------------
# segment_fish() — for use on YOUR OWN fish images later
# -----------------------------------------------------------------------------
# The 3 demo fish above are already segmented. When you process YOUR three
# fish in Part B of the lab, you'll need to segment them yourself.
#
# This helper does it in one R call by shelling out to:
#   rembg  (Python ML model that removes natural-image backgrounds)
#   magick (ImageMagick, for trimming + white-bg compositing)
#
# Setup (do ONCE before lab):
#   pip install "rembg[cpu,cli]"        # in terminal
#   brew install imagemagick            # macOS only; Linux: apt install
#   (Windows: install both via their respective installers; or use WSL.)
#
# Usage:
#   seg_path <- segment_fish("path/to/raw_fish.jpg")
#   my_fish  <- getimg(seg_path)        # canonical fish-only image
#
# Returns the path to the segmented JPG (saved alongside the raw image).
# Output filename: <original-name>-segmented.jpg

segment_fish <- function(raw_path, out_dir = NULL,
                          target_body  = 1200,
                          canvas_w     = 1500,
                          canvas_h     = 800,
                          quiet        = TRUE) {
  if (!file.exists(raw_path)) {
    stop("Raw image not found: ", raw_path)
  }
  if (is.null(out_dir)) out_dir <- dirname(raw_path)
  base    <- tools::file_path_sans_ext(basename(raw_path))
  tmp_png <- file.path(out_dir, paste0(base, "-rembg-tmp.png"))
  out_jpg <- file.path(out_dir, paste0(base, "-segmented.jpg"))

  silent <- if (quiet) FALSE else ""

  # Step 1: rembg removes the background, output PNG with alpha mask.
  # Try uvx first (auto-manages Python + rembg), then a direct rembg binary,
  # so the helper works on whichever install path the student took.
  rembg_status <- 1L
  if (nzchar(Sys.which("uvx"))) {
    rembg_status <- system2(
      "uvx",
      args = c("--quiet", "--from", shQuote("rembg[cpu,cli]"),
               "rembg", "i", shQuote(raw_path), shQuote(tmp_png)),
      stdout = silent, stderr = silent
    )
  }
  if ((rembg_status != 0 || !file.exists(tmp_png)) &&
      nzchar(Sys.which("rembg"))) {
    rembg_status <- system2(
      "rembg",
      args = c("i", shQuote(raw_path), shQuote(tmp_png)),
      stdout = silent, stderr = silent
    )
  }
  if (rembg_status != 0 || !file.exists(tmp_png)) {
    stop("rembg failed (or not installed).\n",
         "  Install option A (recommended):  brew install uv  (then no further setup)\n",
         "  Install option B:                 pip install \"rembg[cpu,cli]\"\n",
         "  Install option C:                 pipx install \"rembg[cpu,cli]\"\n",
         "If installed but not found, R may not see your PATH. Run:\n",
         "  Sys.getenv(\"PATH\")\n",
         "and confirm the install location is listed.")
  }

  # Step 2: magick auto-trims transparent borders + composites onto white
  if (!nzchar(Sys.which("magick"))) {
    stop("ImageMagick (magick) not on PATH.\n",
         "  macOS:  brew install imagemagick\n",
         "  Linux:  sudo apt install imagemagick\n",
         "  Windows: download from https://imagemagick.org/script/download.php#windows")
  }
  magick_status <- system2(
    "magick",
    args = c(shQuote(tmp_png),
             "-trim", "+repage",
             "-background", "white",
             "-alpha", "remove", "-alpha", "off",
             shQuote(out_jpg)),
    stdout = silent, stderr = silent
  )
  if (magick_status != 0 || !file.exists(out_jpg)) {
    stop("magick failed during compositing. The intermediate PNG is at:\n  ",
         tmp_png)
  }

  file.remove(tmp_png)

  # Step 3: Standardize the canvas. After magick -trim the JPG is the tight
  # bounding box of the fish. We do TWO uniform operations:
  #   (a) aspect-preserving resize so the fish's longer axis = target_body px,
  #   (b) -extent to pad with white to a fixed canvas (canvas_w x canvas_h),
  #       fish centered.
  # The result: every fish that goes through segment_fish() lands on the
  # same canvas dimensions with the fish at the same physical body length.
  # This makes adjacent(xpts = N) sample the fish at the SAME density across
  # species, so A / m / Jc are directly comparable. The white padding gets
  # masked out by bkgID = "white" downstream.
  # Use 'x' as the separator (not a space) so system2 doesn't split it.
  info <- system2("magick", c("identify", "-format", "%wx%h", out_jpg),
                   stdout = TRUE, stderr = silent)
  dims <- as.integer(strsplit(trimws(info[1]), "x")[[1]])
  w0 <- dims[1]; h0 <- dims[2]

  # (a) Uniform rescale so longer body axis = target_body. Image::Magick's
  # `-resize WxH` preserves aspect by default (the bigger of W or H wins),
  # so giving target_body for both is equivalent to "fit-into-square".
  resize_status <- system2(
    "magick",
    c(shQuote(out_jpg),
      "-resize", paste0(target_body, "x", target_body),
      shQuote(out_jpg)),
    stdout = silent, stderr = silent)
  if (resize_status != 0) {
    stop("magick -resize failed in canvas standardization step")
  }

  # (b) Pad to uniform canvas, fish centered. -extent pads with the
  # -background color (white) without rescaling.
  extent_status <- system2(
    "magick",
    c(shQuote(out_jpg),
      "-gravity", "center",
      "-background", "white",
      "-extent", paste0(canvas_w, "x", canvas_h),
      shQuote(out_jpg)),
    stdout = silent, stderr = silent)
  if (extent_status != 0) {
    stop("magick -extent failed in canvas standardization step")
  }

  # Tell the student what happened — useful when reviewing weird inputs.
  info2 <- system2("magick", c("identify", "-format", "%wx%h", out_jpg),
                    stdout = TRUE, stderr = silent)
  dims2 <- as.integer(strsplit(trimws(info2[1]), "x")[[1]])
  message(sprintf(
    "Standardized: trimmed %dx%d -> body %dpx -> canvas %dx%d",
    w0, h0, target_body, dims2[1], dims2[2]))

  message("Segmented: ", out_jpg)
  invisible(out_jpg)
}

# Fallback (if rembg / magick aren't installed): manually crop your fish image
# in Preview.app (Tools -> Crop), then load directly with getimg(). The
# resulting metrics will be slightly weaker than rembg-segmented but the
# directional A claim still holds.


# -----------------------------------------------------------------------------
# Step 1.6 — REGISTRATION: confirm left-lateral view (head on left)
# -----------------------------------------------------------------------------
# Standard ichthyology convention is "left-lateral view" — the fish facing
# LEFT, with the head on the left side of the frame and the tail on the right.
# All three demo fish are pre-registered to this orientation.
#
# WHY: the A statistic itself is invariant to horizontal mirroring (flipping
# left/right doesn't change vertical-vs-horizontal transitions), but visual
# consistency matters for:
#   - Student predictions ("vertical bars" presumes a canonical view)
#   - Comparing metrics across students/groups in the next pavo session
#   - Standard reporting in fish coloration papers
#
# IF YOU LOAD AN IMAGE THAT'S RIGHT-LATERAL (head on right), flip it first.
# Easiest path is terminal-side, using ImageMagick:
#
#     magick my_fish.jpg -flop my_fish.jpg     # in-place horizontal mirror
#
# Or in R, using magick directly (then re-load with getimg):

flip_to_left_lateral <- function(path) {
  if (!requireNamespace("magick", quietly = TRUE)) {
    stop("Install the 'magick' package first.")
  }
  img <- magick::image_read(path)
  img <- magick::image_flop(img)            # mirror about vertical axis
  magick::image_write(img, path, format = "jpeg")
  invisible(path)
}

# --- Worked example of flip_to_left_lateral() -------------------------------
# Live demo: take the cleaner wrasse (already left-lateral), flip it the WRONG
# way to right-lateral so we can see what flip_to_left_lateral() does, and
# then flip it back. In real use you'd only call it once, on an image that
# you've inspected and decided is facing the wrong way.

# Make a temp copy so we don't mangle the canonical demo file
flip_demo_path <- file.path(tempdir(), "cleaner-wrasse-flip-demo.jpg")
file.copy("images/demo/segmented/cleaner-wrasse.jpg",
          flip_demo_path, overwrite = TRUE)

# 1. Original (left-lateral, head on left)
img_before <- getimg(flip_demo_path)

# 2. Flip — this mirrors the image horizontally (vertical-axis mirror)
flip_to_left_lateral(flip_demo_path)
img_flipped <- getimg(flip_demo_path)

# 3. Flip BACK to restore the canonical orientation
flip_to_left_lateral(flip_demo_path)
img_restored <- getimg(flip_demo_path)

par(mfrow = c(3, 1))
plot(img_before);   title("BEFORE — head on LEFT (canonical)")
plot(img_flipped);  title("AFTER one flip — head on RIGHT (would need fixing)")
plot(img_restored); title("AFTER second flip — head on LEFT again (correct)")
par(mfrow = c(1, 1))

# Cleanup
file.remove(flip_demo_path)

# Lesson: flip_to_left_lateral() is a horizontal mirror operation. It does NOT
# detect orientation — YOU decide whether to call it after inspecting your
# image. Demo fish here are pre-registered, so we never actually call it on
# them in the rest of this script. For YOUR fish, look at the image first and
# call this function only if the head is on the right.


# -----------------------------------------------------------------------------
# Step 2 — Classify each image into a small number of color classes
# -----------------------------------------------------------------------------
# k-means: every pixel gets snapped to one of k color centroids in RGB space.
# The classified image is the input to all the pattern statistics.
#
# Choosing k is a judgment call. The segmented images have a WHITE background
# in addition to fish colors, so we add +1 to capture white as its own class.
#   - sergeant major  -> k = 4  (yellow, black, belly-pale, WHITE bg)
#   - cleaner wrasse  -> k = 4  (dark stripe, mid, light, WHITE bg)
#   - mandarin fish   -> k = 6  (orange, deep-blue, mid-blue, dark, accent, WHITE bg)

sm_class <- classify(sergeant_major, kcols = 4)
cw_class <- classify(cleaner_wrasse, kcols = 4)
mf_class <- classify(mandarin_fish,  kcols = 6)

# Inspect each classified palette — one class will have R≈G≈B≈1 (the white
# background). We'll exclude it from the adjacency analysis in Step 3.
cat("\n=== Classified color palettes ===\n")
cat("Sergeant major:\n"); print(round(attr(sm_class, "classRGB"), 3))
cat("Cleaner wrasse:\n"); print(round(attr(cw_class, "classRGB"), 3))
cat("Mandarin fish:\n");  print(round(attr(mf_class, "classRGB"), 3))

# Plot before / after for sergeant major
par(mfrow = c(2, 1))
plot(sergeant_major); title("Sergeant major — original")
plot(sm_class);       title("Sergeant major — classified, k = 3")
par(mfrow = c(1, 1))


# -----------------------------------------------------------------------------
# Step 3 — Adjacency analysis: drop a grid, count transitions, build T
# -----------------------------------------------------------------------------
# adjacent() does ALL of the grid sampling + transition-matrix building +
# metric calculation in one call.
#
# Key arguments:
#   xpts   = number of grid points along the longest axis
#   xscale = real-world length corresponding to longest axis (e.g., 5 cm)
#            — only matters for distance metrics, can be left at default
#   coldists = optional data frame of perceptual distances between color classes
#              REQUIRED to populate the m_dS and m_dL boundary-strength metrics.
#              Without this, m_dS and m_dL come back as NA.
#
# Helper: build a simple coldists from the classified image's RGB centroids.
# This computes Euclidean chromatic distance (dS) and luminance distance (dL)
# pairwise between every pair of color classes.

simple_coldists <- function(classimg) {
  # classimg is one rimg object; multi-image lists need lapply
  if (is.null(attr(classimg, "classRGB"))) {
    # multi-image: take the first one's palette as a representative
    cols <- attr(classimg[[1]], "classRGB")
  } else {
    cols <- attr(classimg, "classRGB")
  }
  n <- nrow(cols)
  pairs <- data.frame()
  for (i in 1:(n - 1)) {
    for (j in (i + 1):n) {
      ds <- sqrt(sum((cols[i, ] - cols[j, ])^2))     # chromatic distance
      dl <- abs(mean(unlist(cols[i, ])) - mean(unlist(cols[j, ])))  # luminance
      pairs <- rbind(pairs, data.frame(
        c1 = i,    # pavo expects 'c1'/'c2', not 'patch1'/'patch2'
        c2 = j,
        dS = ds,
        dL = dl
      ))
    }
  }
  pairs
}

# Per-fish coldists (palettes differ between fish, so each gets its own)
sm_cd <- simple_coldists(sm_class)
cw_cd <- simple_coldists(cw_class)
mf_cd <- simple_coldists(mf_class)

# Identify the white-background color class (highest R+G+B sum) for each fish.
# This excludes background pixels from adjacency computation.
pick_white_bg <- function(classimg) {
  rgb_table <- attr(classimg, "classRGB")
  which.max(rowSums(rgb_table))   # whitest = highest R+G+B
}
sm_bkg <- pick_white_bg(sm_class)
cw_bkg <- pick_white_bg(cw_class)
mf_bkg <- pick_white_bg(mf_class)

cat(sprintf("\nBackground class IDs — sm: %d, cw: %d, mf: %d\n",
            sm_bkg, cw_bkg, mf_bkg))

# Run adjacency with bkgID + exclude="background" so the white background
# is dropped from the transition matrix. Without this, A is diluted by
# the long uniform stretches of white surrounding each fish.
sm_adj <- adjacent(sm_class, xpts = 200, xscale = 5, coldists = sm_cd,
                   bkgID = sm_bkg, exclude = "background")
cw_adj <- adjacent(cw_class, xpts = 200, xscale = 5, coldists = cw_cd,
                   bkgID = cw_bkg, exclude = "background")
mf_adj <- adjacent(mf_class, xpts = 200, xscale = 5, coldists = mf_cd,
                   bkgID = mf_bkg, exclude = "background")

# Stack into one data frame. Note: different k values produce different
# column counts in adjacent() output (more colors → more pairwise columns),
# so rbind() would fail. bind_rows() fills missing cells with NA.
fish_adj <- bind_rows(
  sergeant_major = sm_adj,
  cleaner_wrasse = cw_adj,
  mandarin_fish  = mf_adj,
  .id = "fish"
)

# The result is a data frame: one row per fish, many columns of metrics
class(fish_adj)
dim(fish_adj)
colnames(fish_adj)


# -----------------------------------------------------------------------------
# Step 4 — Extract the six metrics we care about
# -----------------------------------------------------------------------------
# pavo returns ~30 columns from adjacent(). We focus on the six headline
# pattern metrics from Endler (2012):
#
#   k     : number of color classes used
#   m     : transition density   (off-diagonal mass / total)
#   A     : aspect ratio         (vertical edges / horizontal edges)
#   Jc    : color heterogeneity  (Simpson diversity of color classes)
#   Jt    : transition heterogeneity
#   m_dS  : mean chromatic boundary strength  (saturation step at edges)
#   m_dL  : mean achromatic boundary strength (luminance step at edges)
#
# Note: pavo column names vary slightly between versions. The block below
# tries the standard names and falls back gracefully.

pick_col <- function(df, candidates) {
  hit <- intersect(candidates, colnames(df))
  if (length(hit) == 0) return(rep(NA_real_, nrow(df)))
  df[[hit[1]]]
}

metrics <- tibble(
  fish  = c("sergeant_major", "cleaner_wrasse", "mandarin_fish"),
  family = c("Pomacentridae", "Labridae", "Callionymidae"),
  k     = pick_col(fish_adj, c("k", "kcols")),
  m     = pick_col(fish_adj, c("m", "m_r")),
  A     = pick_col(fish_adj, c("A", "Asp")),
  Jc    = pick_col(fish_adj, c("Jc")),
  Jt    = pick_col(fish_adj, c("Jt")),
  m_dS  = pick_col(fish_adj, c("m_dS", "Cs_dS")),
  m_dL  = pick_col(fish_adj, c("m_dL", "Cs_dL")),
)

print(metrics)


# -----------------------------------------------------------------------------
# Step 5 — Predict, then verify
# -----------------------------------------------------------------------------
# Before computing — what did we predict?
#
#   sergeant major  (vertical bars)        ->  A > 1 (more vertical edges)
#   cleaner wrasse  (horizontal stripe)    ->  A < 1 (more horizontal edges)
#   mandarin fish   (reticulate)           ->  A ≈ 1 (isotropic)
#
# Mandarin should have the highest m (most edges per unit area) and
# the highest Jc (most colors used).

cat("\n\n== Predictions vs measurements (A statistic) ==\n")
metrics %>%
  mutate(
    prediction = c("A > 1", "A < 1", "A ≈ 1"),
    measured   = round(A, 2)
  ) %>%
  select(fish, family, prediction, measured) %>%
  print()

# Visualize the comparison
metrics %>%
  pivot_longer(c(m, A, Jc, m_dL), names_to = "metric", values_to = "value") %>%
  ggplot(aes(x = fish, y = value, fill = family)) +
    geom_col() +
    facet_wrap(~metric, scales = "free_y") +
    scale_fill_manual(values = c("Pomacentridae" = "#5BC0EB",
                                  "Labridae"      = "#3FB8AF",
                                  "Callionymidae" = "#FFC946")) +
    labs(title = "Pattern metrics across three reef families",
         x = NULL, y = "metric value") +
    theme_minimal(base_size = 14) +
    theme(legend.position = "bottom",
          axis.text.x = element_text(angle = 30, hjust = 1))


# -----------------------------------------------------------------------------
# Step 6 — Now you try
# -----------------------------------------------------------------------------
# Open the worksheet (lab-05-pavo-intro.qmd). Pick THREE fish from your
# assigned lineage that span three different pattern types.
#
# IMPORTANT: REGISTER each of your three fish to LEFT-LATERAL view BEFORE
# running classify(). If your image has the head pointing RIGHT, flip it with
# flip_to_left_lateral() (defined in Step 1.5 above) or terminal magick.
#
# Template:

# # Step A: SEGMENT (background removal). Pick ONE of two paths.
# #   Path 1 (recommended) — rembg via segment_fish() helper above:
# seg_path <- segment_fish("path/to/raw_fish.jpg")
# #   Path 2 (fallback) — pre-crop the fish manually in Preview.app, save
# #   the cropped JPG, then skip segment_fish() and load directly:
# # seg_path <- "path/to/cropped_fish.jpg"
#
# # Step B: REGISTER (left-lateral, head on left) — flip if needed
# # flip_to_left_lateral(seg_path)
#
# # Step C: load
# my_fish <- getimg(seg_path)
# plot(my_fish)
#
# # Step D: classify. Use kcols = (number_of_fish_colors + 1) when using rembg
# # (the +1 captures the white background). For manually-cropped images, use
# # number_of_fish_colors directly.
# my_k     <- 4                                # 3 fish colors + 1 white bg
# my_class <- classify(my_fish, kcols = my_k)
# plot(my_class)
#
# # Step E: adjacency, with white-bg exclusion (skip bkgID for cropped path)
# my_bkg   <- pick_white_bg(my_class)          # = which.max(rowSums(classRGB))
# my_cd    <- simple_coldists(my_class)
# my_adj   <- adjacent(my_class, xpts = 200, xscale = 5,
#                      coldists = my_cd,
#                      bkgID = my_bkg, exclude = "background")
#
# my_metrics <- tibble(
#   fish  = "chaetodon_auriga",
#   k     = pick_col(my_adj, c("k", "kcols")),
#   m     = pick_col(my_adj, c("m", "m_r")),
#   A     = pick_col(my_adj, c("A", "Asp")),
#   Jc    = pick_col(my_adj, c("Jc")),
#   Jt    = pick_col(my_adj, c("Jt")),
#   m_dS  = pick_col(my_adj, c("m_dS", "Cs_dS")),
#   m_dL  = pick_col(my_adj, c("m_dL", "Cs_dL")),
# )
#
# print(my_metrics)


# =============================================================================
# Done. Submit your worksheet by end of day.
# =============================================================================
