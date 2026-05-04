# R package installs for EEB 187 Lab 5
# Runs inside .binder/Dockerfile during repo2docker build.
#
# rocker/binder:4.4 already includes: tidyverse, knitr, rmarkdown, devtools.
# We list everything we touch in walkthrough.R / verify_pipeline.R so a base
# image upgrade can never silently strip a dependency.
#
# Posit Package Manager serves PRE-COMPILED R-package binaries that are
# linked against a *specific* Ubuntu release's system libraries. If we pull
# Jammy (22.04) binaries onto a Noble (24.04) base, the magick R package
# loads but its underlying magick.so cannot find libMagick++-6.Q16.so.8 —
# Noble only ships .so.9. So we sniff /etc/os-release at install time and
# pick the matching Posit URL. If the codename doesn't resolve we fall back
# to standard CRAN (slower because it builds from source, but correct).

posit_repo_for_this_distro <- function() {
  if (!file.exists("/etc/os-release")) return("https://cloud.r-project.org")
  osrel <- readLines("/etc/os-release")
  cn_line <- grep("^VERSION_CODENAME=", osrel, value = TRUE)
  if (!length(cn_line)) return("https://cloud.r-project.org")
  codename <- sub("^VERSION_CODENAME=", "", cn_line[1])
  codename <- gsub('"', "", codename)
  if (!nzchar(codename)) return("https://cloud.r-project.org")
  message("Detected distro codename: ", codename)
  paste0("https://packagemanager.posit.co/cran/__linux__/", codename, "/latest")
}

req <- c(
  "pavo",       # color pattern analysis — the lab's headline package
  "magick",     # image I/O backend that pavo uses
  "jpeg",       # used by render_classify_real.R for the slide figure
  "png",        # ditto
  "tidyverse",  # data wrangling + ggplot
  "knitr",      # for rendering the worksheet .qmd if students want HTML
  "rmarkdown"
)

installed <- rownames(installed.packages())
need <- setdiff(req, installed)

if (length(need)) {
  repo <- posit_repo_for_this_distro()
  message("Installing from ", repo, ": ", paste(need, collapse = ", "))
  install.packages(need, repos = repo)
} else {
  message("All R packages already present.")
}

# Hard-fail if pavo can't load — surfaces at build time, not lab time.
suppressPackageStartupMessages({
  library(pavo)
  library(magick)
  library(tidyverse)
})
cat("pavo version:", as.character(packageVersion("pavo")), "\n")
cat("magick version:", as.character(packageVersion("magick")), "\n")
cat("R version:", as.character(getRversion()), "\n")
