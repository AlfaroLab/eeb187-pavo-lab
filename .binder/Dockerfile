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
