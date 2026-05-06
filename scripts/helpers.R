# =============================================================================
# Lab 5 — Helper functions
# EEB 187 — Ecology & Evolution of Color — Week 6
# =============================================================================
# Source this file once at session start and every helper used in
# walkthrough.R + lab-05-pavo-intro.qmd is available:
#
#   source("scripts/helpers.R")
#
# IMPORTANT: source()ing helpers.R is NOT a substitute for library(pavo).
# Helpers like segment_fish() are defined here, but pavo functions like
# getimg() / classify() / adjacent() are part of the pavo package and
# require library(pavo) separately. After every R session restart, Step 0
# of walkthrough.R must be run in full:
#
#   library(pavo)
#   library(magick)
#   library(tidyverse)
#   source("scripts/helpers.R")
#
# All FOUR are needed. Skipping any of them produces "could not find
# function" errors mid-pipeline. See teaching/ta-guide.qmd Step 0
# troubleshooting for which line maps to which error.
#
# Six functions are defined below:
#
#   segment_fish()        — wrap rembg + ImageMagick into one R call so a
#                           raw photo becomes a white-background JPG ready
#                           for getimg() + classify().
#
#   composite_to_white()  — same end product as segment_fish(), but the input
#                           is a transparent PNG you produced with a web tool
#                           (remove.bg, photoroom.com, clipdrop). Useful when
#                           rembg isn't installed locally.
#
#   flip_to_left_lateral()— horizontal mirror so the fish faces LEFT (head
#                           on the left, tail on the right, ichthyology
#                           convention). Idempotent enough — call it once
#                           on images that need flipping.
#
#   simple_coldists()     — pairwise RGB distances between every pair of
#                           color classes. Required input to adjacent() if
#                           you want non-NA m_dS / m_dL boundary metrics.
#
#   pick_white_bg()       — return the class index whose RGB centroid is
#                           closest to white (R+G+B max). Pass to adjacent()
#                           as bkgID = pick_white_bg(class), with
#                           exclude = "background", to drop white-bg pixels
#                           from the transition matrix.
#
#   pick_col()            — robust column extraction: pavo's adjacent()
#                           output column names vary slightly between
#                           pavo releases (A vs Asp, m vs m_r). pick_col()
#                           accepts a vector of candidate names and returns
#                           the first match.
# =============================================================================


# -----------------------------------------------------------------------------
# segment_fish() — segment + standardize a raw fish photo
# -----------------------------------------------------------------------------
# Shells out to:
#   rembg  (Python ML model that removes natural-image backgrounds)
#   magick (ImageMagick, for trim + white-bg compositing + canvas standardize)
#
# Setup options (covered in pre-lab-installation.qmd Step 6):
#   uv (recommended): segment_fish() invokes rembg via `uvx --from rembg[cpu,cli]`
#   pip / pipx fallback: install rembg directly to PATH
#   ImageMagick: brew install imagemagick (mac) / apt install imagemagick (linux)
#
# Usage:
#   seg_path <- segment_fish("path/to/raw_fish.jpg")
#   my_fish  <- getimg(seg_path)
#
# Returns the path to the segmented JPG (saved alongside the raw image,
# named <original-name>-segmented.jpg).
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

  # Step 3: standardize to a fixed canvas with the fish's longer axis at
  # target_body px. After this, every fish that goes through segment_fish()
  # lands on the same canvas dimensions with the fish at the same body length
  # — so adjacent(xpts = N) samples at the same density across species and
  # A / m / Jc are directly comparable. White padding is masked out by
  # bkgID = pick_white_bg() downstream.
  info <- system2("magick", c("identify", "-format", "%wx%h", out_jpg),
                   stdout = TRUE, stderr = silent)
  dims <- as.integer(strsplit(trimws(info[1]), "x")[[1]])
  w0 <- dims[1]; h0 <- dims[2]

  resize_status <- system2(
    "magick",
    c(shQuote(out_jpg),
      "-resize", paste0(target_body, "x", target_body),
      shQuote(out_jpg)),
    stdout = silent, stderr = silent)
  if (resize_status != 0) stop("magick -resize failed in canvas standardization step")

  extent_status <- system2(
    "magick",
    c(shQuote(out_jpg),
      "-gravity", "center",
      "-background", "white",
      "-extent", paste0(canvas_w, "x", canvas_h),
      shQuote(out_jpg)),
    stdout = silent, stderr = silent)
  if (extent_status != 0) stop("magick -extent failed in canvas standardization step")

  info2 <- system2("magick", c("identify", "-format", "%wx%h", out_jpg),
                    stdout = TRUE, stderr = silent)
  dims2 <- as.integer(strsplit(trimws(info2[1]), "x")[[1]])
  message(sprintf(
    "Standardized: trimmed %dx%d -> body %dpx -> canvas %dx%d",
    w0, h0, target_body, dims2[1], dims2[2]))
  message("Segmented: ", out_jpg)
  invisible(out_jpg)
}


# -----------------------------------------------------------------------------
# composite_to_white() — for fish you segmented OUTSIDE R using a web tool
# -----------------------------------------------------------------------------
# If you used remove.bg, photoroom.com, or ClipDrop to remove the background
# before lab, you have a transparent PNG. pavo's classify-with-bkg approach
# wants a JPG with a SOLID white background. This helper composites your
# transparent PNG onto white and saves it as a JPG — same end product as
# segment_fish(), without needing rembg installed locally.
#
# Usage:
#   white_jpg <- composite_to_white("images/student-fish/.../my-fish.png")
#   my_fish   <- getimg(white_jpg)
#
# Requires only the R `magick` package (already installed for pavo).
composite_to_white <- function(transparent_png, out_path = NULL,
                               canvas_w = 1500, canvas_h = 800,
                               target_body = 1200) {
  if (!requireNamespace("magick", quietly = TRUE)) {
    stop("Install the 'magick' R package first: install.packages('magick')")
  }
  if (!file.exists(transparent_png)) {
    stop("Image not found: ", transparent_png)
  }
  if (is.null(out_path)) {
    base    <- tools::file_path_sans_ext(basename(transparent_png))
    out_path <- file.path(dirname(transparent_png),
                          paste0(base, "-segmented.jpg"))
  }

  img <- magick::image_read(transparent_png)
  img <- magick::image_trim(img)
  img <- magick::image_background(img, "white", flatten = TRUE)
  img <- magick::image_resize(img,
                              paste0(target_body, "x", target_body))
  img <- magick::image_extent(img,
                              paste0(canvas_w, "x", canvas_h),
                              color = "white", gravity = "center")
  magick::image_write(img, out_path, format = "jpeg")
  message("Composited to white: ", out_path)
  invisible(out_path)
}


# -----------------------------------------------------------------------------
# flip_to_left_lateral() — register an image to canonical left-lateral view
# -----------------------------------------------------------------------------
# Standard ichthyology convention is "left-lateral view" — head on the LEFT,
# tail on the RIGHT. Look at your image first, then call this helper only on
# images that are facing the wrong way.
#
# Note: horizontal mirroring does NOT change the A / m / Jc adjacency metrics
# — they're invariant to left/right reflection. Registration is for visual
# consistency and comparative validity, not metric correctness.
flip_to_left_lateral <- function(path) {
  if (!requireNamespace("magick", quietly = TRUE)) {
    stop("Install the 'magick' package first.")
  }
  img <- magick::image_read(path)
  img <- magick::image_flop(img)            # mirror about vertical axis
  magick::image_write(img, path, format = "jpeg")
  invisible(path)
}


# -----------------------------------------------------------------------------
# simple_coldists() — pairwise RGB distances between color classes
# -----------------------------------------------------------------------------
# Required input to adjacent() if you want m_dS / m_dL boundary-strength
# metrics. Computes Euclidean chromatic distance (dS) and luminance distance
# (dL) for every pair of color classes.
#
# Usage:
#   cd <- simple_coldists(my_classified_image)
#   adj <- adjacent(my_classified_image, coldists = cd, ...)
#
# Note: this is a *photographic* coldists in RGB space. *Perceptual* coldists
# (JNDs as a fish would see them) come from vismodel() %>% coldist() — covered
# in Lab 6, not this one.
simple_coldists <- function(classimg) {
  if (is.null(attr(classimg, "classRGB"))) {
    cols <- attr(classimg[[1]], "classRGB")
  } else {
    cols <- attr(classimg, "classRGB")
  }
  n <- nrow(cols)
  pairs <- data.frame()
  for (i in 1:(n - 1)) {
    for (j in (i + 1):n) {
      ds <- sqrt(sum((cols[i, ] - cols[j, ])^2))
      dl <- abs(mean(unlist(cols[i, ])) - mean(unlist(cols[j, ])))
      pairs <- rbind(pairs, data.frame(
        c1 = i, c2 = j,        # pavo expects 'c1'/'c2', not 'patch1'/'patch2'
        dS = ds,
        dL = dl
      ))
    }
  }
  pairs
}


# -----------------------------------------------------------------------------
# pick_white_bg() — find the white-background class in a classified image
# -----------------------------------------------------------------------------
# segment_fish() and composite_to_white() both produce images on a SOLID white
# background. After classify(img, kcols = N + 1), one of the N+1 classes is
# white (R≈G≈B≈1). pick_white_bg() returns its index — pass to adjacent() as
# bkgID = pick_white_bg(class), with exclude = "background", to drop white-bg
# pixels from the transition matrix.
pick_white_bg <- function(classimg) {
  rgb_table <- attr(classimg, "classRGB")
  which.max(rowSums(rgb_table))   # whitest = highest R+G+B
}


# -----------------------------------------------------------------------------
# pick_col() — robust column extraction across pavo versions
# -----------------------------------------------------------------------------
# pavo's adjacent() output column names vary slightly between releases —
# e.g., A vs Asp, m vs m_r. pick_col() takes a vector of candidate names
# and returns the first match. Falls back to NA if none of the candidates
# are present (rather than erroring), so a missing metric doesn't kill the
# whole metrics tibble construction.
pick_col <- function(df, candidates) {
  hit <- intersect(candidates, colnames(df))
  if (length(hit) == 0) return(rep(NA_real_, nrow(df)))
  df[[hit[1]]]
}


# =============================================================================
# End of helpers.R — load via source("scripts/helpers.R")
# =============================================================================
