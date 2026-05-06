# EEB 187 — pavo lab environment
# Base: rocker/rstudio (R + RStudio Server, port 8787)
FROM rocker/rstudio:4.4

# System libraries: ImageMagick CLI + dev headers (for the R `magick` package),
# plus the GIS / udunits / Fortran stack that pavo pulls in via sf, units,
# plot3D, and misc3d. Without these, install.packages('pavo') silently
# fails the cascade and pavo isn't actually available in the image.
RUN apt-get update && apt-get install -y --no-install-recommends \
        imagemagick \
        libmagick++-dev \
        libjpeg-dev \
        libpng-dev \
        libtiff5-dev \
        libxml2-dev \
        libssl-dev \
        libcurl4-openssl-dev \
        libfontconfig1-dev \
        libfreetype6-dev \
        libharfbuzz-dev \
        libfribidi-dev \
        libudunits2-dev \
        libgdal-dev \
        libgeos-dev \
        libproj-dev \
        gfortran \
        tcl tk \
        ca-certificates \
        curl \
    && rm -rf /var/lib/apt/lists/*

# uv (Astral) — used by segment_fish() to invoke rembg via uvx without pip
RUN curl -LsSf https://astral.sh/uv/install.sh | sh \
    && mv /root/.local/bin/uv /usr/local/bin/uv \
    && mv /root/.local/bin/uvx /usr/local/bin/uvx

# Ubuntu 24.04 Noble's `imagemagick` package ships IM 6 (legacy `convert`,
# `identify`, etc.). pavo's segment_fish() helper calls the unified IM 7
# `magick` entrypoint. Provide a thin shim that delegates to the right IM 6
# binary so segment_fish() works without R-side changes.
RUN printf '#!/bin/bash\nif [ "$1" = "identify" ]; then shift; exec identify "$@"; fi\nif [ "$1" = "convert" ];  then shift; exec convert  "$@"; fi\nexec convert "$@"\n' \
        > /usr/local/bin/magick \
    && chmod +x /usr/local/bin/magick

# R packages — use rocker:4.4's bundled PPM defaults so we get binaries
# matched to this image's Ubuntu codename instead of overriding it manually.
RUN R -e "install.packages(c('pavo','tidyverse','magick','jpeg','png','knitr'))"

# Hard sanity check: fail the build if pavo (or any other lab-critical
# package) can't actually load, OR if the magick CLI shim doesn't resolve.
# Without this, a silent install.packages cascade failure or a missing
# binary would ship a broken image to students.
RUN R -e "suppressPackageStartupMessages({library(pavo); library(magick); library(tidyverse)}); cat('pavo:', as.character(packageVersion('pavo')), '\n', sep='')" \
    && magick -version | head -1 \
    && magick label:test /tmp/_smoke.png \
    && magick identify -format '%wx%h ' /tmp/_smoke.png \
    && magick /tmp/_smoke.png /tmp/_smoke.jpg \
    && echo "magick CLI shim OK" \
    && rm -f /tmp/_smoke.png /tmp/_smoke.jpg

# Pre-warm rembg so the first segment_fish() call doesn't pause to download
# (~150 MB ONNX model). Best-effort — skip if offline at build time.
RUN uvx --quiet --from "rembg[cpu,cli]" rembg --help >/dev/null 2>&1 || true

# RStudio user defaults (rocker convention)
ENV USER=rstudio
EXPOSE 8787
