# EEB 187 Lab 5 — pavo Introduction
# Binder-compatible image for one-click cloud RStudio.
#
# Base image: rocker/binder bundles R 4.4 + RStudio Server + many CRAN binaries
# pre-built (tidyverse already included), drastically reducing build time.
# https://rocker-project.org/images/versioned/binder.html

FROM rocker/binder:4.4

# ---- root: system libraries for pavo / magick / rembg --------------------
USER root

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
        imagemagick \
        libmagick++-dev \
        libpng-dev \
        libjpeg-dev \
        libtiff5-dev \
        python3 \
        python3-pip \
        python3-venv \
        curl \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Loosen ImageMagick policy so the magick R package + the magick CLI can read
# JPGs without "not authorized" errors that ship by default on Debian.
RUN if [ -f /etc/ImageMagick-6/policy.xml ]; then \
      sed -i 's/rights="none" pattern="PDF"/rights="read|write" pattern="PDF"/' /etc/ImageMagick-6/policy.xml || true ; \
      sed -i 's/rights="none" pattern="JPEG"/rights="read|write" pattern="JPEG"/' /etc/ImageMagick-6/policy.xml || true ; \
      sed -i 's/rights="none" pattern="PNG"/rights="read|write" pattern="PNG"/' /etc/ImageMagick-6/policy.xml || true ; \
    fi

# Ubuntu's `imagemagick` apt package ships ImageMagick 6 (legacy `convert` /
# `identify` as separate binaries). pavo's segment_fish() helper calls IM 7's
# unified `magick` entrypoint. Provide a thin shim so the helper works.
RUN printf '#!/bin/bash\nif [ "$1" = "identify" ]; then shift; exec identify "$@"; fi\nif [ "$1" = "convert" ];  then shift; exec convert  "$@"; fi\nexec convert "$@"\n' \
        > /usr/local/bin/magick \
    && chmod +x /usr/local/bin/magick

# Make /home/rstudio/.local/bin (where uv/uvx/rembg get installed) visible
# to R sessions, not just bash. R reads Renviron.site at startup; setting
# PATH there is the most reliable way to make Sys.which() see uv tools.
# (Per-user ~/.Renviron is overridden in some rocker configurations; the
# system-wide file always wins.)
RUN echo 'PATH=/home/rstudio/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' \
        >> /usr/local/lib/R/etc/Renviron.site

# ---- back to NB_USER: install R + Python deps as the binder user ---------
USER ${NB_USER}

# Install uv (handles rembg's Python deps automatically — same path students
# use locally per pre-lab-installation.qmd).
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/home/${NB_USER}/.local/bin:${PATH}"

# Pre-warm rembg + its u2net model so the first segment_fish() call in lab
# is fast (no surprise download for students). The "echo 'rembg health'"
# round-trip pulls the onnx model into the uv cache.
RUN uv tool install --with "rembg[cpu,cli]" rembg && \
    rembg --help > /dev/null && \
    echo "rembg installed, model will fetch on first call"

# R packages — pavo is the headline addition. tidyverse / magick are already
# pre-installed in the rocker/binder base, but we list them defensively in
# install.R so a base-image change won't silently break the build.
COPY --chown=${NB_USER}:${NB_USER} .binder/install.R /tmp/install.R
RUN Rscript /tmp/install.R

# Copy the lab content into the binder home so RStudio opens to it.
COPY --chown=${NB_USER}:${NB_USER} . /home/${NB_USER}/

WORKDIR /home/${NB_USER}

# Build-time smoke test: prove pavo loads from R, the magick CLI shim
# resolves, Sys.which() finds both uvx + magick from the R PATH (which
# is what segment_fish()'s tool detection actually does), and a real
# segment_fish() roundtrip succeeds end-to-end. Catches the silent
# regressions we hit during the Docker image work this morning.
RUN R -e "suppressPackageStartupMessages({library(pavo); library(magick); library(tidyverse)}); \
          source('scripts/helpers.R'); \
          stopifnot(nzchar(Sys.which('uvx'))); \
          stopifnot(nzchar(Sys.which('magick'))); \
          seg <- segment_fish('images/demo/raw/sergeant-major.jpg'); \
          stopifnot(file.exists(seg)); \
          img <- getimg(seg); \
          stopifnot(inherits(img, 'rimg')); \
          cat('Binder smoke OK — pavo:', as.character(packageVersion('pavo')), \
              ', uvx + magick + segment_fish roundtrip OK\n'); \
          unlink(seg)" \
    && magick -version | head -1 \
    && echo "Binder image build verified."
