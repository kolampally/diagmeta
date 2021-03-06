diagmeta <- function(TP, FP, TN, FN, cutoff, studlab, data = NULL,
                     ##
                     distr = "logistic", model = "DICS", equalvar = FALSE,
                     lambda = 0.5, log.cutoff = FALSE,
                     method.weights = "invvar",
                     ##
                     level = 0.95, incr = 0.5,
                     ##
                     n.iter.max = 1000, tol = 1e-08, silent = TRUE,
                     ...) {
  
  
  ##
  ##
  ## (1) Check arguments
  ##
  ##
  chklength <- meta:::chklength
  chklevel <- meta:::chklevel
  chklogical <- meta:::chklogical
  chknull <- meta:::chknull
  chknumeric <- meta:::chknumeric
  setchar <- meta:::setchar
  ##
  distr <- setchar(distr, c("logistic", "normal"))
  ##
  is.logistic <- distr == "logistic"
  is.normal <- distr == "normal"
  ##
  model <- setchar(model,
                   c("CI", "DI", "CS", "DS",
                     "CICS", "DICS", "CIDS", "DIDS"))
  ##
  chklogical(equalvar)
  chklevel(level)
  chklogical(log.cutoff)
  ##
  chknumeric(incr, min = 0, single = TRUE)
  ##
  method.weights <- setchar(method.weights,
                            c("equal", "size", "invvar"))
  ##
  chknumeric(lambda, min = 0, single = TRUE)
  chknumeric(n.iter.max, min = 0, single = TRUE)
  chknumeric(tol, min = 0, single = TRUE)
  ##
  chklogical(silent)
  ##
  ## Additional arguments / checks
  ##
  fun <- "diagmeta"
  
  
  ##
  ##
  ## (2) Read data
  ##
  ##
  nulldata <- is.null(data)
  ##
  if (nulldata)
    data <- sys.frame(sys.parent())
  ##
  mf <- match.call()
  ##
  ## Catch 'TP', 'FP', 'TN', 'FN', 'cutoff', and 'studlab'
  ##
  TP <- eval(mf[[match("TP", names(mf))]],
             data, enclos = sys.frame(sys.parent()))
  chknull(TP)
  k.All <- length(TP)
  ##
  FP <- eval(mf[[match("FP", names(mf))]],
             data, enclos = sys.frame(sys.parent()))
  chknull(FP)
  ##
  TN <- eval(mf[[match("TN", names(mf))]],
             data, enclos = sys.frame(sys.parent()))
  chknull(TN)
  ##
  FN <- eval(mf[[match("FN", names(mf))]],
             data, enclos = sys.frame(sys.parent()))
  chknull(FN)
  ##
  cutoff <- eval(mf[[match("cutoff", names(mf))]],
                 data, enclos = sys.frame(sys.parent()))
  chknull(cutoff)
  ##
  studlab <- eval(mf[[match("studlab", names(mf))]],
                  data, enclos = sys.frame(sys.parent()))
  chknull(studlab)
  
  
  ##
  ##
  ## (3) Check length of essential variables
  ##
  ##
  chklength(FP, k.All, fun, name = "TP")
  chklength(TN, k.All, fun, name = "TP")
  chklength(FN, k.All, fun, name = "TP")
  chklength(cutoff, k.All, fun, name = "TP")
  chklength(studlab, k.All, fun, name = "TP")


  ##
  ##
  ## (4) Auxiliary function
  ##     (to calculate weighted cut-off point of two logistic
  ##      distributions by an iterative fixpoint procedure)
  ##
  ##
  g <- function(x)
    mean1 - sd1 * acosh(lambda / (1 - lambda) * sd0 / sd1 *
                        (1 + cosh((x - mean0) / sd0)) - 1)
  ##
  ## Inverse function
  ##
  f <- function(x)
    mean0 + sd0 * acosh((1 - lambda) / lambda * sd1 / sd0 *
                        (1 + cosh((x - mean1) / sd1)) - 1)
  ##
  ## Error handling for iterate() - chooses f or g for iterations
  ##
  saveIterate <- function(x0, n.iter.max, tol, silent) {
    
    tryCatch({ # try iterating with function f
      x <- iterate(f, x0, n.iter.max, tol, !silent)
      if (!silent)
        cat("* Optimal cut-off iteration with f *\n")
      return(list(x = x, iter = "f"))
    },
    warning = function(w) {
      suppressWarnings(x <- iterate(f, x0, n.iter.max, tol, !silent))
      warning(w$message)
      return(list(x = x, iter = "f"))
    },
    ## if error occurs, iterate with function g
    error = function(e) {
      tryCatch({ # try iteration with function g
        x <- iterate(g, x0, n.iter.max, tol, !silent)
        if (!silent)
          cat("* Optimal cut-off iteration with g *\n")
        return(list(x = x, iter = "g"))
      },
      warning = function(wa) {
        suppressWarnings(x <- iterate(g, x0, n.iter.max, tol, !silent))
        warning(w$message)
        return(list(x = x, iter = "g"))
      },
      error = function(er) {
        stop("Optimal cutoff iteration didn't converge. Use argument distribution = \"normal\".")
        return(list(x = NULL, iter = NULL))
      })
    }
    )
  }
  
  
  ##
  ##
  ## (5) Assignments
  ##
  ##
  k <- length(unique(studlab))
  ##
  N0 <- FP + TN   # number of non-diseased patients
  N1 <- TP + FN   # number of diseased patients
  N  <- c(N0, N1) # number of all patients in one study IN ONE GROUP!!!(0 or 1)
  ##
  NN <- (c(TN, FN) + incr) / (N + 2 * incr)
  ##  
  ## Inverse variance weights for variance within studies
  ##
  if (is.logistic) {
    w0.iv <- (TN + incr) * (FP + incr) / (N0 + 2 * incr)
    w1.iv <- (TP + incr) * (FN + incr) / (N1 + 2 * incr)
  }
  ##
  else if (is.normal) {
    w0.iv <- (N0 + 2 * incr)^3 * dnorm(qnorm((TN + incr) /
                                             (N0 + 2 * incr)))^2 / ((TN + incr) *
                                                                    (FP + incr))
    w1.iv <- (N1 + 2 * incr)^3 * dnorm(qnorm((TP + incr) /
                                             (N1 + 2 * incr)))^2 / ((TP + incr) *
                                                                    (FN + incr))
  }
  ##  
  ## Variance component within studies for both models
  ##
  var.nondiseased <- k / sum(w0.iv)
  var.diseased <- k / sum(w1.iv)
  ##
  ## Weights
  ##
  if (method.weights == "equal")
    w <- rep(1, length(c(N0, N1)))
  else if (method.weights == "size")
    w <- (length(N) * N) / sum(N)
  else if (method.weights == "invvar") {
    w <- c(w0.iv, w1.iv)
    ## scaling 
    w <-  length(w) * w / sum(w)
  }
  
  
  iter <- ""
  
  
  ##
  ##
  ## (6) Model fitting
  ##
  ##
  ## Data frame consisting of rows with data for each cutoff of each
  ## study, first for all non-diseased individuals and then everything
  ## again for the diseased individuals (each cutoff of each study is
  ## named twice)
  ##
  Group <- c(rep(0, length(studlab)), rep(1, length(studlab)))
  ##
  if (log.cutoff)
    Cutoff <- log(c(cutoff, cutoff))
  else
    Cutoff <- c(cutoff, cutoff)
  ##
  Study <- c(studlab, studlab)
  ##
  if (equalvar) {
    if (model == "CI")
      lme1 <- lmer(rescale(NN, distr) ~ Group + Cutoff + (1 | Study),
                   weights = w, ...)
    else if (model == "DI")
      lme1 <- lmer(rescale(NN, distr) ~ Group + Cutoff + (1 + Group | Study),
                   weights = w, ...)
    else if (model == "CS")
      lme1 <- lmer(rescale(NN, distr) ~ Group + Cutoff + (0 + Cutoff | Study),
                   weights = w, ...)
    else if (model == "DS")
      lme1 <- lmer(rescale(NN, distr) ~ Group + Cutoff + (0 + Cutoff + Group:Cutoff | Study),
                   weights = w, ...)
    else if (model == "CICS")
      lme1 <- lmer(rescale(NN, distr) ~ Group + Cutoff + (Cutoff | Study),
                   weights = w, ...)
    else if (model == "DICS")
      lme1 <- lmer(rescale(NN, distr) ~ Group + Cutoff + (Cutoff + Group | Study),
                   weights = w, ...)
    else if (model == "CIDS")
      lme1 <- lmer(rescale(NN, distr) ~ Group + Cutoff + (Cutoff +  Group:Cutoff | Study),
                   weights = w, ...)
    else if (model == "DIDS")
      lme1 <- lmer(rescale(NN, distr) ~ Group + Cutoff + (Group * Cutoff | Study),
                   weights = w, ...)
  }
  else {
    if (model == "CI")
      lme1 <- lmer(rescale(NN, distr) ~ Group * Cutoff + (1 | Study),
                   weights = w, ...)
    else if (model == "DI")
      lme1 <- lmer(rescale(NN, distr) ~ Group * Cutoff + (1 + Group | Study),
                   weights = w, ...)
    else if (model == "CS")
      lme1 <- lmer(rescale(NN, distr) ~ Group * Cutoff + (0 + Cutoff | Study),
                   weights = w, ...)
    else if (model == "DS")
      lme1 <- lmer(rescale(NN, distr) ~ Group * Cutoff + (0 + Cutoff + Group:Cutoff | Study),
                   weights = w, ...)
    else if (model == "CICS")
      lme1 <- lmer(rescale(NN, distr) ~ Group * Cutoff + (Cutoff | Study),
                   weights = w, ...)
    else if (model == "DICS")
      lme1 <- lmer(rescale(NN, distr) ~ Group * Cutoff + (Cutoff + Group | Study),
                   weights = w, ...)
    else if (model == "CIDS")
      lme1 <- lmer(rescale(NN, distr) ~ Group * Cutoff + (Cutoff +  Group:Cutoff | Study),
                   weights = w, ...)
    else if (model == "DIDS")
      lme1 <- lmer(rescale(NN, distr) ~ Group * Cutoff + (Group * Cutoff | Study),
                   weights = w, ...)
  }
  ##
  slme1 <- summary(lme1)
  ##
  ## Fixed effects
  ##
  cf <- coef(slme1)
  vc <- vcov(slme1)
  ##
  ## Random effects: variance-covariance matrix
  ##
  V <- cov(slme1$varcor$Study)
  ##
  ## Extract regression coefficients:
  ## - alpha0, beta0 (non-diseased)
  ## - alpha1 and beta1 (diseased)
  ##  
  if (equalvar) {
    alpha0 <- cf[1, 1]
    alpha1 <- cf[1, 1] + cf[2, 1]
    beta0 <-  cf[3, 1]
    beta1 <-  cf[3, 1]
    ##
    varalpha0 <- vc[1, 1]
    varalpha1 <- vc[1, 1] + vc[2, 2] + 2 * vc[1, 2]
    varbeta0 <-  vc[3, 3]
    varbeta1 <-  vc[3, 3]
    ##
    covalpha0beta0 <- vc[1, 3]
    covalpha0beta1 <- covalpha0beta0
    covalpha0alpha1 <- vc[1, 1] + vc[1, 2]
    covalpha1beta0 <- vc[1, 3] + vc[2, 3]
    covalpha1beta1 <- covalpha1beta0
    ##
    covbeta0beta1 <- varbeta0
  }
  else {
    alpha0 <- cf[1, 1]
    alpha1 <- cf[1, 1] + cf[2, 1]
    beta0 <-  cf[3, 1]
    beta1 <-  cf[3, 1] + cf[4, 1]
    ##
    varalpha0 <- vc[1, 1]
    varalpha1 <- vc[1, 1] + vc[2, 2] + 2 * vc[1, 2]
    varbeta0 <-  vc[3, 3]
    varbeta1 <-  vc[3, 3] + vc[4, 4] + 2 * vc[3, 4]
    ##
    covalpha0beta0 <- vc[1, 3]
    covalpha0beta1 <- vc[1, 3] + vc[1, 4]
    covalpha0alpha1 <- vc[1, 1] + vc[1, 2]
    covalpha1beta1 <- vc[1, 3] + vc[1, 4] + vc[2, 3] + vc[2, 4]
    covalpha1beta0 <- vc[1, 3] + vc[2, 3]
    ##
    covbeta0beta1 <- vc[3, 3] + vc[3, 4]
  }
  ##
  ## Correlation of data must be positive
  ##
  if (beta0 <= 0 | beta1 <= 0)
    stop("Regression yields negative correlation. Try another model or get better data. :)")
  

  ##
  ##  
  ## (7) Compute parameters of the biomarker distributions and their
  ##     variances
  ##
  ##
  mean0 <- - alpha0 / beta0  # Mean disease-free
  sd0 <- 1 / beta0           # Standard deviation disease-free
  mean1 <- - alpha1 / beta1  # Mean diseased
  sd1 <- 1 / beta1           # Standard deviation diseased
  ##
  var.mean0 <- (alpha0^2) / (beta0^4) * varbeta0 + varalpha0 /
    (beta0^2) - 2 * alpha0 / (beta0^3) * covalpha0beta0
  var.mean1 <- (alpha1^2) / (beta1^4) * varbeta1 + varalpha1 /
    (beta1^2) - 2 * alpha1 / (beta1^3) * covalpha1beta1 
  ##
  var.sd0 <- varbeta0 / (beta0^4)
  var.sd1 <- varbeta1 / (beta1^4)
  ##
  if (mean1 < mean0)
    stop("Estimated distribution of diseased patients is left of non-diseased ones. Check if for your biomarker really higher values indicate illness.")
  
  
  ##
  ##
  ## (8) Distributions
  ##
  ##
  if (is.logistic) { 
    ## Cutoffs of two logistics, weighted with lambda and 1 - lambda
    wmean <- (1 - lambda) * mean0 + lambda * mean1
    ##
    if ((1 - lambda) * sd1 != lambda * sd0) {
      x0 <- wmean
      iterateResult <- saveIterate(x0, n.iter.max, tol, silent)
      iter <- iterateResult$iter
      optcut <- iterateResult$x
    }
    else
      optcut <- wmean
  }
  else if (is.normal) {
    ## Cutoffs of two normals, weighted with lambda and 1 - lambda
    turn <- (mean0 * sd1^2 - mean1 * sd0^2) / (sd1^2 - sd0^2)
    rad <- sqrt(sd0^2 * sd1^2 * (2 * (sd1^2 - sd0^2) *
                                 (log(sd1) - log(sd0) - logit(lambda)) +
                                 (mean1 - mean0)^2) / (sd1^2 - sd0^2)^2)
    x0 <- turn - rad
    x1 <- turn + rad
    ##
    if (sd0 < sd1)
      optcut <- x1
    else if (sd0 > sd1)
      optcut <- x0
    else
      optcut <- (-logit(lambda) * sd0^2 - 0.5 * (mean0^2 - mean1^2)) /
        (mean1 - mean0)
    ##
    if (sd1 != sd0) {
      ## Derivations of optimal cutoff function
      S <- sqrt(2 * (beta0^2 - beta1^2) * (log(beta0 / beta1) - logit(lambda)) +
                (alpha0 * beta1-alpha1 * beta0)^2)
      ##
      dalpha0 <- (-beta0 + beta1 / S * (alpha0 * beta1 - alpha1 * beta0)) /
        (beta0^2 - beta1^2)
      ##
      dalpha1 <- (beta1 - beta0 / S * (alpha0 * beta1 - alpha1 * beta0)) /
        (beta0^2 - beta1^2)
      ##
      dbeta0 <- (- alpha0 + 1 / (beta0 * S) * (beta0^2-beta1^2)) /
        (beta0^2-beta1^2)+
        (4 * beta0 * (log(beta0 / beta1)-logit(lambda)) -
         2 * alpha1 * (alpha0 * beta1-alpha1 * beta0)) /
        (2 * S * (beta0^2 - beta1^2)) -
        (2 * beta0 * (alpha1 * beta1 - alpha0 * beta0 + S)) /
        ((beta0^2 - beta1^2)^2)
      ##
      dbeta1 <- (alpha1 - 1 / (beta1 * S) * (beta0^2 - beta1^2)) /
        (beta0^2 - beta1^2) +
        (-4 * beta1 * (log(beta0 / beta1) - logit(lambda)) + 2 * alpha0 *
         (alpha0 * beta1 - alpha1 * beta0)) / (2 * S * (beta0^2 - beta1^2)) +
        (2 * beta1 * (alpha1 * beta1 - alpha0 * beta0 + S)) /
        ((beta0^2 - beta1^2)^2)
      ##
      ## Variance estimate of optimal cutoff
      ##
      var.optcut <- dalpha0^2 * varalpha0 + dalpha1^2 * varalpha1 +
                                                      dbeta0^2 * varbeta0 + dbeta1^2 * varbeta1 +
                                                                                     2 * dalpha0 * dalpha1 * covalpha0alpha1 + 2 * dalpha0 * dbeta0 * covalpha0beta0 +
                                                                                     2 * dalpha0 * dbeta1 * covalpha0beta1 + 2 * dalpha1 * dbeta0 * covalpha1beta0 +
                                                                                     2 * dalpha1 * dbeta1 * covalpha1beta1 + 2 * dbeta0 * dbeta1 * covbeta0beta1
    }
    else {
      ##
      ## Derivations of optimal cutoff function
      ##
      S <- logit(lambda) + 0.5 * (alpha1^2 - alpha0^2)
      ##
      dalpha0 <- (alpha1 * (alpha1 - alpha0) - S / beta0) /
        ((alpha1 - alpha0)^2)
      ##
      dalpha1 <- (-alpha0 * (alpha1 - alpha0) + S / beta0) /
        ((alpha1 - alpha0)^2)
      ##
      dbeta0 <- (-S / beta0^2) / (alpha1 - alpha0)
      ##
      ## Variance estimate of optimal cutoff
      ##
      var.optcut <- dalpha0^2 * varalpha0 + dalpha1^2 * varalpha1 + dbeta0^2 * varbeta0 +
                                                                             2 * dalpha0 * dalpha1 * covalpha0alpha1 + 2 * dalpha0 * dbeta0 * covalpha0beta0 +
                                                                             2 * dalpha1 * dbeta0 * covalpha1beta0
    }
  }
  
  
  ##
  ##
  ## (9) Calculate sensitivity and specificity at optimal cutpoint
  ##
  ##
  ci.y1 <- ci.y(optcut,
                alpha1, varalpha1, beta1, varbeta1, covalpha1beta1,
                var.diseased,
                level)
  ##
  ci.y0 <- ci.y(optcut,
                alpha0, varalpha0, beta0, varbeta0, covalpha1beta0,
                var.nondiseased,
                level)
  ##
  ## Calculate sensitivity and specificity at optimal cutpoint
  ##
  Se <- calcSens(ci.y1$TE, distr)
  lower.Se <- calcSens(ci.y1$lower, distr)
  upper.Se <- calcSens(ci.y1$upper, distr)
  ##
  Sp <- calcSpec(ci.y0$TE, distr)
  lower.Sp <- calcSpec(ci.y0$lower, distr)
  upper.Sp <- calcSpec(ci.y0$upper, distr)
  
  
  ##
  ##
  ## (10) List with results
  ##
  ##
  res <- list(TP = TP, FP = FP, TN = TN, FN = FN,
              cutoff = cutoff, studlab = studlab,
              ##
              distr = distr, model = model, equalvar = equalvar,
              lambda = lambda,
              ##
              level = level, log.cutoff = log.cutoff,
              incr = incr, method.weights = method.weights,
              ##
              k = k,
              ##
              optcut = if (log.cutoff) exp(optcut) else optcut,
              ##
              Se.optcut = Se,
              lower.Se.optcut = lower.Se,
              upper.Se.optcut = upper.Se,
              Sp.optcut = Sp,
              lower.Sp.optcut = lower.Sp,
              upper.Sp.optcut = upper.Sp,
              ##
              var.diseased = var.diseased,
              var.nondiseased = var.nondiseased,
              ##
              NN0 = (TN + incr) / (N0 + 2 * incr),
              NN1 = (FN + incr) / (N1 + 2 * incr),
              ##
              AIC = AIC(logLik(lme1)),
              BIC = BIC(lme1),
              ##
              data.lmer = list(Study = Study, Group = Group, Cutoff = Cutoff,
                               N = N, Negative = c(TN, FN), NN = NN),
              result.lmer = lme1,
              weights = w,
              ##
              regr = list(alpha0 = alpha0, varalpha0 = varalpha0,
                          beta0 = beta0, varbeta0 = varbeta0,
                          covalpha0beta0 = covalpha0beta0,
                          alpha1 = alpha1, varalpha1 = varalpha1,
                          beta1 = beta1, varbeta1 = varbeta1,
                          covalpha1beta1 = covalpha1beta1,
                          covalpha0alpha1 = covalpha0alpha1,
                          covalpha0beta1 = covalpha0beta1,
                          covalpha1beta0 = covalpha1beta0,
                          covbeta0beta1 = covbeta0beta1),
              ##
              dist = list(mean0 = mean0, var.mean0 = var.mean0,
                          sd0 = sd0, var.sd0 = var.sd0,
                          mean1 = mean1, var.mean1 = var.mean1,
                          sd1 = sd1, var.sd1 = var.sd1),
              ##
              workdata = list(),
              ##
              n.iter.max = n.iter.max, tol = tol, iter = iter,
              call = match.call()
              )
  
  
  class(res) <- "diagmeta"
  
  res
}
