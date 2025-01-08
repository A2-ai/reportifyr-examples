calc_auc_linear_log <- function(time, conc) {
  auc <- 0

  cmax_index <- which.max(conc)

  for (i in 1:(length(time) - 1)) {
    delta_t <- time[i + 1] - time[i]

    if (i < cmax_index) {

      auc <- auc + delta_t * (conc[i + 1] + conc[i]) / 2
    } else if (i >= cmax_index && conc[i + 1] > 0 && conc[i] > 0) {

      auc <- auc + delta_t * (conc[i] - conc[i + 1]) / log(conc[i] / conc[i + 1])
    } else {

      auc <- auc + delta_t * (conc[i + 1] + conc[i]) / 2
    }
  }

  return(auc)
}
