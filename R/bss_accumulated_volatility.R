#' Estimate accumulated volatility processes
#'
#' \code{estimateAccumulatedVolatility} estimates the pth power accumulated volatility process for a Brownian
#' semistationary process, using either parametric methods of model fitting first, or using a non-parametric
#' estimator for the scale factor.
#'
#'
#' @param Y a vector of observations of a BSS process.
#' @param n positive integer indicating the number of observations per unit of time.
#' @param p the power to evaluate the accumulated power volatility process for. Defaults to 2, in order to
#' estimate the accumulated squared volatility process.
#' @param method text string representing the method used to estimate the accumulated volatility. Options are \code{'acf'}, \code{'cof'}
#' or \code{nonparametric}. If \code{'acf'} is selected, model parameters are fit to the data \code{Y} using
#' least squares on the autocorrelation function and these parameters are used to estimate the scale factor.
#' If \code{'cof'} is selected, only the smoothness parameter \code{alpha} is estimated using the change of frequency
#' method, and then put into an asymptotic expression for the scale factor in the calculation. If \code{'nonparametric'}
#' is selected then the non-parametric estimator for the scale factor will be used in the calculation. Defaults to \code{'nonparametric'}.
#' @param kernel text string representing the choice of kernel when fitting the model to estimate
#' the scale factor parametrically. Options are \code{'gamma'} and \code{'power'}. Defaults to \code{'gamma'}.
#'
#' @return The function returns a vector of the same length as \code{Y} which is the estimate for the
#' accumulated volatility process, observed from time 0 to T, at intervals of T/n. Note that the values have been
#' divided by m_p in the output, so that the estimation is of the integral alone. If the non-parametric
#' estimator for tau_n is used then the values will be scaled by the expectation of the squared volatility, as
#' per the theory.
#'
#' @examples
#'
#' N <- 10000
#' n <- 100
#' T <- 1.0
#' theta <- 0.5
#' beta <- 0.125
#'
#' kappa <- 3
#' alpha <- -0.2
#' lambda <- 1.0
#'
#'
#' vol <- exponentiatedOrnsteinUhlenbeck(N, n, T, theta, beta)
#' bss_simulation <- gammaKernelBSS(N, n, T, kappa, alpha, lambda, sigma = vol)
#' y <- bss_simulation$bss
#' estimateAccumulatedVolatility(y, n, p = 2, method = 'nonparametric', kernel = 'gamma')
#'
#' #'
#'
#' @export
#'
estimateAccumulatedVolatility <- function(Y, n, p = 2, method = 'nonparametric', kernel = 'gamma') {

  m_p <- 2^(p/2) * gamma((p + 1)/2) / sqrt(pi)

  if (method == 'cof'){

    alpha <- bssAlphaFit(Y)

    if (kernel == 'gamma') {

      return(cumsum(abs(diff(Y))^p) / n / gammaKernelTauAsymptotic(n, alpha)^p / m_p)

    }

  } else if (method == 'acf') {

    if (kernel == 'gamma') {

      theta <- gammaKernelBSSFit(Y, n)

      alpha <- theta[[1]]

      lambda <- theta[[2]]

      return(cumsum(abs(diff(Y))^p) / n / gammaKernelTau(n, alpha, lambda)^p / m_p)

    } else if (kernel == 'power') {

      theta <- powerKernelBSSFit(Y, n)

      alpha <- theta[[1]]

      beta <- theta[[2]]

      return(cumsum(abs(diff(Y))^p) / n / powerKernelTau(n, alpha, beta)^p / m_p)
    }

  } else {

    return(cumsum(abs(diff(Y))^p) / n / tauNonParametricEstimate(Y)^p / m_p)

  }

}


#' Estimate confidence interval for the accumulated volatility processes
#'
#' \code{estimateAccumulatedVolatility} estimates a confidence interval for the pth power accumulated volatility process for a Brownian
#' semistationary process, using either parametric methods of model fitting first, or using a non-parametric
#' estimator for the scale factor.
#'
#'
#' @param Y a vector of observations of a BSS process.
#' @param n positive integer indicating the number of observations per unit of time.
#' @param p the power to evaluate the accumulated power volatility process for. Defaults to 2, in order to
#' estimate the accumulated squared volatility process.
#' @param method text string representing the method used to estimate the accumulated volatility. Options are \code{'acf'}, \code{'cof'}
#' or \code{nonparametric}. If \code{'acf'} is selected, model parameters are fit to the data \code{Y} using
#' least squares on the autocorrelation function and these parameters are used to estimate the scale factor.
#' If \code{'cof'} is selected, only the smoothness parameter \code{alpha} is estimated using the change of frequency
#' method, and then put into an asymptotic expression for the scale factor in the calculation. If \code{'nonparametric'}
#' is selected then the non-parametric estimator for the scale factor will be used in the calculation. Defaults to \code{'nonparametric'}.
#' @param kernel text string representing the choice of kernel when fitting the model to estimate
#' the scale factor parametrically. Options are \code{'gamma'} and \code{'power'}. Defaults to \code{'gamma'}.
#' @param confidence_level the required level for the confidence interval, as a probability between 0 and 1.
#' @return The function returns a list of two vectors of the same length as \code{Y} which are the estimates for the
#' lower and upper values for the confidence interval. Note that the values have been
#' divided by m_p in the output, so that the estimation is of the integral alone. If the non-parametric
#' estimator for tau_n is used then the values will be scaled by the expectation of the squared volatility, as
#' per the theory.
#'
#' @examples
#'
#' N <- 10000
#' n <- 100
#' T <- 1.0
#' theta <- 0.5
#' beta <- 0.125
#'
#' kappa <- 3
#' alpha <- -0.2
#' lambda <- 1.0
#'
#'
#' vol <- exponentiatedOrnsteinUhlenbeck(N, n, T, theta, beta)
#' bss_simulation <- gammaKernelBSS(N, n, T, kappa, alpha, lambda, sigma = vol)
#' y <- bss_simulation$bss
#' estimateAccumulatedVolatility(y, n, p = 2, method = 'nonparametric', kernel = 'gamma')
#'
#' #'
#'
#' @export
#'
estimateAccumulatedVolatilityCI <- function(Y, n, p, method = "nonparametric", kernel = "gamma", confidence_level) {

  p_val = 0.5 + 0.5 * confidence_level

  z_a = qnorm(p_val)

  K_p <- estimateK(Y, p)

  mean <- estimateAccumulatedVolatility(Y, n, p, method = "nonparametric", kernel = "gamma")

  var_term <- estimateAccumulatedVolatility(Y, n, 2*p, method = "nonparametric", kernel = "gamma")

  var <- z_a * K_p * sqrt(var_term)

  list(lower = (mean - var), upper = (mean + var))

}






