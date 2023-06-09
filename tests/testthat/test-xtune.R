#' @import lbfgs

set.seed(123456)
test_that("estimates by empirical bayes tuning and lbfgs direct update match, single tuning parameters", {
  n = 30
  p = 50
  X <- matrix(rnorm(2*n*p,0,1),nrow=2*n,ncol=p)
  betas=rnorm(n = p, s = 1)
  Y <- X%*%betas + rnorm(2*n,0,1)
  Z_int = matrix(rep(1,p),ncol = 1)
  sigma.square.est = estimateVariance(X,Y)
  xtune.reweighted = xtune(X,Y,sigma.square = sigma.square.est, family = "linear", control = list(margin = 1e-4,margin_inner=1e-4,compute.likelihood=T))
  lbfgs_result=lbfgs(approx_likelihood.xtune, score_function, input_X = X, input_Y = Y, input_Z = Z_int,
                     sigma.square.est = sigma.square.est, input_c = 0.5, rep(0,ncol(Z_int)), invisible = 1,epsilon = 1e-4)
  expect_equal(xtune.reweighted$likelihood.score[length(-xtune.reweighted$likelihood.score)],lbfgs_result$value,tolerance=1e-4)
  expect_equal(mean(sum(lbfgs_result$par-xtune.reweighted$alpha.est[1])^2),0,tolerance=1e-4)
}
)


test_that("estimates by xtune reweighted-L2 and lbfgs match, multiple tuning parameters", {
  n = 20
  p = 30
  q = 3
  X <- matrix(rnorm(2*n*p,0,1),nrow=2*n,ncol=p)
  betas=rnorm(n = p, s = 1)
  Y <- X%*%betas + rnorm(2*n,0,1)
  Z= matrix(rnorm(p*q,0,1),ncol=q,nrow=p)
  Z_int = cbind(1,Z)
  sigma.square.est = estimateVariance(X,Y)
  xtune.reweighted = xtune(X,Y,Z,sigma.square = sigma.square.est, family = "linear",control = list(margin = 1e-4,margin_inner=1e-4,compute.likelihood=T))
  lbfgs_result=lbfgs(approx_likelihood.xtune, score_function, input_X = X, input_Y = Y, input_Z = Z_int,
                     sigma.square.est = sigma.square.est, input_c = 0.5, rep(0,ncol(Z_int)), invisible = 1,epsilon = 1e-4)
  expect_equal(xtune.reweighted$likelihood.score[length(-xtune.reweighted$likelihood.score)],lbfgs_result$value,tolerance=1e-4)
  expect_equal(mean(sum(lbfgs_result$par-xtune.reweighted$alpha.est)^2),0,tolerance=1e-3)
  expect_length(xtune.reweighted$penalty.vector,ncol(X))
}
)

test_that("update lasso and update ridge are equivalent for alpha estimate", {
  n = 50
  p = 10
  q = 2
  X <- matrix(rnorm(n*p,0,1),nrow=n,ncol=p)
  betas=rnorm(n = p, s = 1)
  Y <- X%*%betas + rnorm(n,0,1)
  Z= matrix(rnorm(p*q,0,1),ncol=q,nrow=p)
  sigma.square.est = estimateVariance(X,Y)
  out.lasso=xtune(X,Y,Z,sigma.square = sigma.square.est, family = "linear", c = 1, control = list(margin = 1e-4,margin_inner=1e-4,compute.likelihood=T))
  out.ridge=xtune(X,Y,Z,sigma.square = sigma.square.est,family = "linear", c = 0, control = list(margin = 1e-4,margin_inner=1e-4,compute.likelihood=T))
  expect_equal(mean(sum(log(2) - 2*cbind(1,Z)%*%out.lasso$alpha.est + cbind(1,Z)%*%out.ridge$alpha.est)^2),0,tolerance=1e-4)

  Y <- rbinom(n,1,0.5)
  expect_equal(xtune(X,Y,Z)$family,"binary")
}
)

