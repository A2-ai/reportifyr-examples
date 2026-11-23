# ------------------------------------------------------------------------------
# Helpers for the XYZ-101 example analysis
# ------------------------------------------------------------------------------

# One-compartment model with first-order absorption, single oral dose.
# dose in mg, cl_f in L/h, v_f in L, ka in 1/h -> concentration in ng/mL.
conc_1cmt_oral <- function(time, dose, cl_f, v_f, ka) {
  ke <- cl_f / v_f
  dose * 1000 * ka / (v_f * (ka - ke)) * (exp(-ke * time) - exp(-ka * time))
}

# AUC by the linear-up / log-down trapezoidal rule.
auc_linear_up_log_down <- function(time, conc) {
  keep <- !is.na(conc)
  time <- time[keep]
  conc <- conc[keep]
  auc <- 0
  for (i in seq_len(length(time) - 1)) {
    dt <- time[i + 1] - time[i]
    c1 <- conc[i]
    c2 <- conc[i + 1]
    if (c2 < c1 && c1 > 0 && c2 > 0) {
      auc <- auc + dt * (c1 - c2) / log(c1 / c2)
    } else {
      auc <- auc + dt * (c1 + c2) / 2
    }
  }
  auc
}

# Noncompartmental parameters for one subject. `time` is the actual time and
# `ntime` the nominal time. BLQ samples are NA in `conc` and are left out (the
# BLQ pre-dose sample counts as zero for the AUC); the terminal slope uses the
# last three measurable post-peak samples.
nca_subject <- function(time, ntime, conc, dose) {
  obs <- !is.na(conc) | ntime == 0
  t_obs <- time[obs]
  nt_obs <- ntime[obs]
  c_obs <- ifelse(is.na(conc[obs]), 0, conc[obs])

  i_max <- which.max(c_obs)
  cmax <- c_obs[i_max]
  tmax <- t_obs[i_max]

  auc_0_24 <- auc_linear_up_log_down(t_obs[nt_obs <= 24], c_obs[nt_obs <= 24])
  auc_last <- auc_linear_up_log_down(t_obs, c_obs)

  terminal <- utils::tail(which(t_obs > tmax), 3)
  fit <- stats::lm(log(c_obs[terminal]) ~ t_obs[terminal])
  lambda_z <- -unname(stats::coef(fit)[2])
  r2_adj <- summary(fit)$adj.r.squared

  clast <- utils::tail(c_obs, 1)
  auc_inf <- auc_last + clast / lambda_z

  data.frame(
    Cmax = cmax,
    Tmax = tmax,
    AUC_0_24 = auc_0_24,
    AUC_0_inf = auc_inf,
    Pct_extrap = 100 * (auc_inf - auc_last) / auc_inf,
    Half_life = log(2) / lambda_z,
    CL_F = dose * 1000 / auc_inf,
    R2_adj = r2_adj
  )
}

# Power model ln(P) = a + b * ln(dose), with the Smith et al. (2000) bounds
# for dose proportionality over the studied dose ratio.
power_model <- function(param, dose, label, ratio = max(dose) / min(dose)) {
  fit <- stats::lm(log(param) ~ log(dose))
  ci <- stats::confint(fit)[2, ]
  bounds <- 1 + log(c(0.8, 1.25)) / log(ratio)
  slope <- unname(stats::coef(fit)[2])

  conclusion <- if (ci[1] >= bounds[1] && ci[2] <= bounds[2]) {
    "Proportional"
  } else if (ci[2] < bounds[1] || ci[1] > bounds[2]) {
    "Not proportional"
  } else {
    "Inconclusive"
  }

  data.frame(
    Parameter = label,
    N = length(param),
    `Slope (b)` = sprintf("%.3f", slope),
    `95% CI` = sprintf("%.3f, %.3f", ci[1], ci[2]),
    `Acceptance range` = sprintf("%.3f, %.3f", bounds[1], bounds[2]),
    `R-squared` = sprintf("%.3f", summary(fit)$r.squared),
    Conclusion = conclusion,
    check.names = FALSE
  )
}

# Summary text helpers for the demographics table
fmt_mean_sd <- function(x, digits = 1) {
  sprintf(paste0("%.", digits, "f (%.", digits, "f)"), mean(x), stats::sd(x))
}

fmt_median_range <- function(x, digits = 1) {
  sprintf(
    paste0("%.", digits, "f [%.", digits, "f, %.", digits, "f]"),
    stats::median(x), min(x), max(x)
  )
}

fmt_n_pct <- function(hit, n) {
  sprintf("%d (%.0f%%)", hit, 100 * hit / n)
}

# Geometric mean and geometric CV%
geo_mean <- function(x) exp(mean(log(x)))
geo_cv <- function(x) 100 * sqrt(exp(stats::var(log(x))) - 1)
