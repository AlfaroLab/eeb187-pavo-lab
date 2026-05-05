# EEB 187 — pavo lab environment
# Base: rocker/rstudio (R + RStudio Server, port 8787)
FROM rocker/rstudio:4.4

# System libraries: ImageMagick CLI + dev headers (for the R `magick` package),
# plus libs that pavo's image stack pulls in.
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
        ca-certificates \
        curl \
    && rm -rf /var/lib/apt/lists/*

# uv (Astral) — used by segment_fish() to invoke rembg via uvx without pip
RUN curl -LsSf https://astral.sh/uv/install.sh | sh \
    && mv /root/.local/bin/uv /usr/local/bin/uv \
    && mv /root/.local/bin/uvx /usr/local/bin/uvx

# R packages — pinned to CRAN snapshot baked into rocker:4.4
RUN R -e "install.packages(c('pavo','tidyverse','magick','jpeg','png','knitr'), \
                           repos='https://packagemanager.posit.co/cran/__linux__/jammy/latest')"

# Pre-warm rembg so the first segment_fish() call doesn't pause to download
# (~150 MB ONNX model). Best-effort — skip if offline at build time.
RUN uvx --quiet --from "rembg[cpu,cli]" rembg --help >/dev/null 2>&1 || true

# RStudio user defaults (rocker convention)
ENV USER=rstudio
EXPOSE 8787
