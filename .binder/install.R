# R package installs for EEB 187 Lab 5
# Runs inside .binder/Dockerfile during repo2docker build.
#
# rocker/binder:4.4 already includes: tidyverse, knitr, rmarkdown, devtools.
# We list everything we touch in walkthrough.R / verify_pipeline.R so a base
# image upgrade can never silently strip a dependency.

req <- c(
  "pavo",       # color pattern analysis — the lab's headline package
  "magick",     # image I/O backend that pavo uses
  "tidyverse",  # data wrangling + ggplot
  "knitr",      # for rendering the worksheet .qmd if students want HTML
  "rmarkdown"
)

installed <- rownames(installed.packages())
need <- setdiff(req, installed)

if (length(need)) {
  message("Installing: ", paste(need, collapse = ", "))
  install.packages(need, repos = "https://packagemanager.posit.co/cran/__linux__/jammy/latest")
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
