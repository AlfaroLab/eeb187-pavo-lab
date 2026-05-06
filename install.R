# R package installs for EEB 187 Lab 5 — entry point for Posit Cloud
#
# Posit Cloud auto-runs an install.R at the repo root when a project is
# created from this git repo. Drop this file here so students who open the
# Posit Cloud project get pavo + helpers installed without any manual setup.
#
# (Binder uses .binder/install.R via its own Dockerfile copy step; the two
# files are intentionally identical so they don't drift.)

# Posit Package Manager serves PRE-COMPILED R-package binaries linked
# against a specific Ubuntu release. Sniff /etc/os-release at install time
# and pick the right repo so we get binaries (fast) rather than compile from
# source (slow, can fail). Fall back to standard CRAN if we can't detect.
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
  "jpeg",
  "png",
  "tidyverse",  # data wrangling + ggplot
  "knitr",
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

# Hard-fail if pavo can't load — surfaces at first project open, not lab time
suppressPackageStartupMessages({
  library(pavo)
  library(magick)
  library(tidyverse)
})
cat("pavo version:", as.character(packageVersion("pavo")), "\n")
cat("magick version:", as.character(packageVersion("magick")), "\n")
cat("R version:", as.character(getRversion()), "\n")
cat("\nNext step: in the Console, run\n  source(\"scripts/helpers.R\")\nto load the lab's helper functions, then open scripts/walkthrough.R.\n")
