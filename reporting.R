library(pander)
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



#I use this function not for the analysis but only for reporting the estimates or test statistics.
print_estimates <- function(model, name, complete=TRUE, method='PB', fes='none', conf=95) {
  
  #determine the ci print 
  ci <- ifelse(conf==95, '95% CI', ifelse(conf==99, '99% CI', '99.9% CI'))
  #assign ci if delivered
  if(fes=='none') {
    lower <- ''
    upper <- ''
  } else {
    lower <- round(fes[fes$coefficient==name,'lower'], digits=2)
    upper <- round(fes[fes$coefficient==name,'upper'], digits=2)
  }

  #assign method printversion 
  df_sig <- ifelse(method=='PB', '_PBtest_', ifelse(method=='KR', '_F_', '$\\chi^2$'))
  
  # which string to return. 
  ifelse(method=='PB', ifelse(!complete, glue::glue('Estimate = {format(summary(model)$coefficients[name,1], digits=ifelse(summary(model)$coefficients[name,1]<1, 2, ifelse(summary(model)$coefficients[name,1]<10, 3, ifelse(summary(model)$coefficients[name,1]<100, 4, 5))))}({format(summary(model)$coefficients[name,2], digits=ifelse(summary(model)$coefficients[name,2]<1, 2, ifelse(summary(model)$coefficients[name,2]<10, 3, ifelse(summary(model)$coefficients[name,2]<100, 4, 5))))})'), glue::glue('Estimate = {format(summary(model)$coefficients[name,1], digits=ifelse(summary(model)$coefficients[name,1]<1, 2, ifelse(summary(model)$coefficients[name,1]<10, 3, ifelse(summary(model)$coefficients[name,1]<100, 4, 5))))}({format(summary(model)$coefficients[name,2], digits=ifelse(summary(model)$coefficients[name,2]<1, 2, ifelse(summary(model)$coefficients[name,2]<10, 3, ifelse(summary(model)$coefficients[name,2]<100, 4, 5))))}), {df_sig} = {format(model$anova_table[name,1], digits=ifelse(model$anova_table[name,1]<1, 2, ifelse(model$anova_table[name,1]<10, 3, ifelse(model$anova_table[name,1]<100, 4, 5))))},  {report_p(model$anova_table[name,4])})')), ifelse(method=='KR', ifelse(!complete, glue::glue('Estimate = {format(summary(model)$coefficients[name,1], digits=ifelse(summary(model)$coefficients[name,1]<1, 2, ifelse(summary(model)$coefficients[name,1]<10, 3, ifelse(summary(model)$coefficients[name,1]<100, 4, 5))))}({format(summary(model)$coefficients[name,2], digits=ifelse(summary(model)$coefficients[name,2]<1, 2, ifelse(summary(model)$coefficients[name,2]<10, 3, ifelse(summary(model)$coefficients[name,2]<100, 4, 5))))})'), glue::glue('Estimate = {format(summary(model)$coefficients[name,1], digits=ifelse(summary(model)$coefficients[name,1]<1, 2, ifelse(summary(model)$coefficients[name,1]<10, 3, ifelse(summary(model)$coefficients[name,1]<100, 4, 5))))}({format(summary(model)$coefficients[name,2], digits=ifelse(summary(model)$coefficients[name,2]<1, 2, ifelse(summary(model)$coefficients[name,2]<10, 3, ifelse(summary(model)$coefficients[name,2]<100, 4, 5))))}), {df_sig}({model$anova_table[name,1]},{format(model$anova_table[name,2], digits=ifelse(model$anova_table[name,2]<1, 2, ifelse(model$anova_table[name,2]<10, 3, ifelse(model$anova_table[name,2]<100, 4, 5))))}) = {format(model$anova_table[name,3], digits=ifelse(model$anova_table[name,3]<1, 2, ifelse(model$anova_table[name,3]<10, 3, ifelse(model$anova_table[name,3]<100, 4, 5))))}, {report_p(model$anova_table[name,4])}, {ci} [{lower}, {upper}])')), ifelse(!complete, glue::glue('Estimate = {format(summary(model)$coefficients[name,1], digits=ifelse(summary(model)$coefficients[name,1]<1, 2, ifelse(summary(model)$coefficients[name,1]<10, 3, ifelse(summary(model)$coefficients[name,1]<100, 4, 5))))}({format(summary(model)$coefficients[name,2], digits=ifelse(summary(model)$coefficients[name,2]<1, 2, ifelse(summary(model)$coefficients[name,2]<10, 3, ifelse(summary(model)$coefficients[name,2]<100, 4, 5))))})'), glue::glue('Estimate = {format(summary(model)$coefficients[name,1], digits=ifelse(summary(model)$coefficients[name,1]<1, 2, ifelse(summary(model)$coefficients[name,1]<10, 3, ifelse(summary(model)$coefficients[name,1]<100, 4, 5))))}({format(summary(model)$coefficients[name,2], digits=ifelse(summary(model)$coefficients[name,2]<1, 2, ifelse(summary(model)$coefficients[name,2]<10, 3, ifelse(summary(model)$coefficients[name,2]<100, 4, 5))))}), {df_sig}({format(model$anova_table[name,3], digits=ifelse(model$anova_table[name,3]<1, 2, ifelse(model$anova_table[name,3]<10, 3, ifelse(model$anova_table[name,3]<100, 4, 5))))}) = {format(model$anova_table[name,2], digits=ifelse(model$anova_table[name,2]<1, 2, ifelse(model$anova_table[name,2]<10, 3, ifelse(model$anova_table[name,2]<100, 4, 5))))}, {report_p(model$anova_table[name,4])})'))))
  
}

#report only model comparison stats from the anova table (required for factors with more than 2 levels)
print_comp <- function(model, name, method='PB') {
  
  df_sig <- ifelse(method=='PB', '_PBtest_', ifelse(method=='KR', '_F_', '$\\chi^2$'))
  
  ifelse(method=='PB', glue::glue('{df_sig} = {format(model$anova_table[name,1], digits=ifelse(model$anova_table[name,1]<1, 2, ifelse(model$anova_table[name,1]<10, 3, ifelse(model$anova_table[name,1]<100, 4, 5))))},  {report_p(model$anova_table[name,4])})'), ifelse(method=='KR',  glue::glue('{df_sig}({model$anova_table[name,1]},{format(model$anova_table[name,2], digits=ifelse(model$anova_table[name,2]<1, 2, ifelse(model$anova_table[name,2]<10, 3, ifelse(model$anova_table[name,2]<100, 4, 5))))}) = {format(model$anova_table[name,3], digits=ifelse(model$anova_table[name,3]<1, 2, ifelse(model$anova_table[name,3]<10, 3, ifelse(model$anova_table[name,3]<100, 4, 5))))}, {report_p(model$anova_table[name,4])})'), glue::glue('{df_sig}({format(model$anova_table[name,3], digits=ifelse(model$anova_table[name,3]<1, 2, ifelse(model$anova_table[name,3]<10, 3, ifelse(model$anova_table[name,3]<100, 4, 5))))}) = {format(model$anova_table[name,2], digits=ifelse(model$anova_table[name,2]<1, 2, ifelse(model$anova_table[name,2]<10, 3, ifelse(model$anova_table[name,2]<100, 4, 5))))}, {report_p(model$anova_table[name,4])})')))
  
}



### --- for PCA --- ###

make_bold <- function(x, cut = 0.4) {
  ifelse(x>=cut, glue("**{round(x, digits = 2)}**"), glue("{round(x, digits = 2)}"))
}

attr(make_bold, "comment") <- "make_bold adds markdown syntax such that significant values will be printed bold"

# returns rmarkdown pca table 
pca_table <- function(pca_object, cut = 0.4, caption = 'Component loadings', cr_alpha = "none") {
  pca_tab <- as.data.frame(unclass(pca_object$loadings))
  fac_names <- rownames(pca_tab)
  # format loadings
  pca_tab <- mutate_all(pca_tab, funs(make_bold))
  rownames(pca_tab) <- fac_names
  # optional: Implement cronbach's in table
  if (class(cr_alpha) == "list") {
    pca_tab["**Cronbach's Alpha**",] <- NA
    for (i in 1:5) {
      value <- round(cr_alpha[[i]]$total[1,1], digits = 2)
      pca_tab["**Cronbach's Alpha**", i] <- value
    }
  }
  # eigenvalues and explained variance
  eigen_and_var <- as_data_frame(pca_object$Vaccounted[1:2,])
  rownames(eigen_and_var) <- c("**Eigenvalues**", "**Variance explained (%)**")
  eigen_and_var[2,] <-  eigen_and_var[2,] * 100 
  eigen_and_var <- round(eigen_and_var, digits = 2)
  pca_tab <- rbind(pca_tab, eigen_and_var)
  panderOptions("table.emphasize.rownames", FALSE)
  pander(pca_tab, caption = caption)
}


attr(pca_table, "comment") <- "pca_table returns table in markdown syntax for reporting a principal component analysis"

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
