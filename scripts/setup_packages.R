# Package check fxn
install_if_missing <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message(sprintf("Installing %s from CRAN...", pkg))
    install.packages(pkg)
  } else {
    message(sprintf("%s already installed.", pkg))
  }
}

# Ensure pak is installed first
install_if_missing("pak")

# Install CRAN packages
cran_pkgs <- c("here", "ggplot2", "dplyr")
for (p in cran_pkgs) {
  install_if_missing(p)
}

# Install reportifyr from GitHub if missing
if (!requireNamespace("reportifyr", quietly = TRUE)) {
  message("Installing reportifyr from GitHub (a2-ai/reportifyr)...")
  pak::pkg_install("a2-ai/reportifyr")
} else {
  message("reportifyr already installed.")
}
