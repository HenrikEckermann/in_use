library(glue)


### --- for LME --- ###

# returns apa p value as a string 
report_p <- function(p, p_str = T) {
  if(p_str) {
    ifelse(p < 0.001, paste('_p_ <', '.001'),  paste('_p_ =', substring(as.character(p), 2,5)))
  }else{
    ifelse(p < 0.001, '< .001',  substring(as.character(format(p, nsmall =3)), 2,5))
  }
}



# same as above but returns *, ** or ***
report_star <- function(p) {
  return(ifelse(p < 0.001, '***', ifelse(p < 0.01, '**', ifelse(p < 0.05, '*', ' '))))
}

report_star_nondirectional <- function(p) {
  return(ifelse(p < 0.0005 | p > 0.9995, '***', ifelse(p < 0.005 | p > 0.995, '**', ifelse(p < 0.025 | p > 0.975, '*', ' '))))
}

# same as above but for latex 
report_star_latex <- function(value, p) {
  return(ifelse(p < 0.001, glue("$[value]^{***}$", .open = "[", .close = "]"), ifelse(p < 0.01, glue("$[value]^{**}$", .open = "[", .close = "]"), ifelse(p < 0.05, glue("$[value]^{*}$", .open = "[", .close = "]"), glue("${value}$")))))
}

report_f <- function(f, df1, df2, p, rsquare = 0) {
  f <- round(f, 2)
  rep_p <- report_p(p)
  ifelse(rsquare ==0, 
    glue("_F_({df1},{df2}) = {f}, {rep_p}"),
    glue("$R^2$ = {rsquare}, _F_({df1},{df2}) = {f}, {rep_p}")
  )
  
}




### --- for PCA --- ###

make_bold <- function(x, cut = 0.4) {
  ifelse(x>=cut, glue("**{round(x, digits = 2)}**"), glue("{round(x, digits = 2)}"))
}

attr(make_bold, "comment") <- "make_bold adds markdown syntax such that significant values will be printed bold"



report_chi <- function(chi, df, p) {
  return(glue("$\\chi^2$({df}) = {round(chi, digits = 2)}, {report_p(p)}"))
}


# qqplot 
# NOTE: Respect to user Rentrop (https://stackoverflow.com/questions/4357031/qqnorm-and-qqline-in-ggplot2/)
# I only made minor adjustments to make the plot consistent with the design for the other plots of my takehome exam
gg_qq <- function(x, distribution = "norm", ..., line.estimate = NULL, conf = 0.95,
                  labels = names(x)){
  q.function <- eval(parse(text = paste0("q", distribution)))
  d.function <- eval(parse(text = paste0("d", distribution)))
  x <- na.omit(x)
  ord <- order(x)
  n <- length(x)
  P <- ppoints(length(x))
  df <- data.frame(ord.x = x[ord], z = q.function(P, ...))
  
  if(is.null(line.estimate)){
    Q.x <- quantile(df$ord.x, c(0.25, 0.75))
    Q.z <- q.function(c(0.25, 0.75), ...)
    b <- diff(Q.x)/diff(Q.z)
    coef <- c(Q.x[1] - b * Q.z[1], b)
  } else {
    coef <- coef(line.estimate(ord.x ~ z))
  }
  
  zz <- qnorm(1 - (1 - conf)/2)
  SE <- (coef[2]/d.function(df$z)) * sqrt(P * (1 - P)/n)
  fit.value <- coef[1] + coef[2] * df$z
  df$upper <- fit.value + zz * SE
  df$lower <- fit.value - zz * SE
  
  if(!is.null(labels)){ 
    df$label <- ifelse(df$ord.x > df$upper | df$ord.x < df$lower, labels[ord],"")
  }
  
  p <- ggplot(df, aes(x=z, y=ord.x)) +
    geom_point() + 
    geom_abline(intercept = coef[1], slope = coef[2]) +
    geom_ribbon(aes(ymin = lower, ymax = upper), alpha=0.2) 
  return(p)
  coef
}
