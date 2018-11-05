
### DONT READ THIS FILE####
# This document is not well documented. It contains functions I
# wrote or copied for simulation and model fitting hands on... 
library(loo)
library(glue)
library(dplyr)


# create loo object for each model in list_of_models
loo_list <- function(list_of_models, save_psis = FALSE) {
  my_loo <- list()
  for (i in 1:length(list_of_models)) {
    glue("calculating loo for{list_of_models[[i]]$formula}\n")
    my_loo[[i]] <- loo(list_of_models[[i]], save_psis = save_psis)
  }
  return(my_loo)
}


# inverse logit
inv_logit <- function(x) 1/(1 + exp(-x))

# thanks to Richard McElreath for his book an the rethinking package. The following three functions are copied from the rethinking package


# needed for hdpi and pi (see below)
concat <- function (...) {
    paste(..., collapse = "", sep = "")
}

# this is the HPDI function copied from Richard Mc Elreaths' rethinking package
hpdi <- function (samples, prob = 0.95) {
  class.samples <- class(samples)[1]
  coerce.list <- c("numeric", "matrix", "data.frame", "integer", 
      "array")
  if (class.samples %in% coerce.list) {
      samples <- coda::as.mcmc(samples)
  }
  x <- sapply(prob, function(p) coda::HPDinterval(samples, 
      prob = p))
  n <- length(prob)
  result <- rep(0, n * 2)
  for (i in 1:n) {
      low_idx <- n + 1 - i
      up_idx <- n + i
      result[low_idx] <- x[1, i]
      result[up_idx] <- x[2, i]
      names(result)[low_idx] <- concat("|", prob[i])
      names(result)[up_idx] <- concat(prob[i], "|")
  }
  return(result)
}

# this is the PI function copied from Richard Mc Elreaths' rethinking package
pi <- function (samples, prob = 0.95) {
  x <- sapply(prob, function(p) {
      a <- (1 - p)/2
      quantile(samples, probs = c(a, 1 - a))
  })
  n <- length(prob)
  result <- rep(0, n * 2)
  for (i in 1:n) {
      low_idx <- n + 1 - i
      up_idx <- n + i
      result[low_idx] <- x[1, i]
      result[up_idx] <- x[2, i]
      a <- (1 - prob[i])/2
      names(result)[low_idx] <- concat(round(a * 100, 0), "%")
      names(result)[up_idx] <- concat(round((1 - a) * 100, 
          0), "%")
  }
  return(result)
}

# attempt to create my own pp_check just to make sure it is what I think it is
pp_plot <- function(model, sample_number, y_name, lower = 0.3, upper = 0.3) {
  # calculate xlim 
  lower <- 
    min(model$data[, y_name]) - lower*min(model$data[, y_name])
  upper <- 
    max(model$data[, y_name]) + upper*max(model$data[, y_name])
  # pp_plot_data has 8000 simulated datasets. rows are invidiual 
  # subjects and columns the number of simulation
  pp_plot_data <- posterior_predict(model)
  # in case I use brms multiple imputation, pp_plot_data has 3 dim
  n_dim <- pp_plot_data %>% dim() %>% length()
  if (n_dim == 3) pp_plot_data <- pp_plot_data[, , 1]
  pp_plot_data <- pp_plot_data %>% t() %>% as.tibble()
  # number of datasets
  n <- dim(pp_plot_data)[2]
  pp_plot_data <- select(pp_plot_data, sample(1:n, sample_number, replace = F))
  p <- pp_plot_data %>%
        gather %>%
        ggplot(aes(value, group = key)) +
        geom_density(color = "grey50") +
        scale_color_discrete(guide = F) +
        geom_density(data = model$data, aes_q(as.name(y_name), group = "none"), size = 1.5) +
        xlim(c(lower, upper)) +
        ggtitle(as.character(model$family)[1])
}


# use violin + boxplot for pp check
pp_plot_v <- function(model, sample_number, y_name, lower = 0.3, upper = 0.3) {
  # calculate xlim 
  lower <- 
    min(model$data[, y_name]) - lower*min(model$data[, y_name])
  upper <- 
    max(model$data[, y_name]) + upper*max(model$data[, y_name])
  # pp_plot_data has 8000 simulated datasets. rows are invidiual 
  # subjects and columns the number of simulation
  pp_plot_data <- posterior_predict(model)
  # in case I use brms multiple imputation, pp_plot_data has 3 dim
  n_dim <- pp_plot_data %>% dim() %>% length()
  if (n_dim == 3) pp_plot_data <- pp_plot_data[, , 1]
  pp_plot_data <- pp_plot_data %>% t() %>% as.tibble()
  # number of datasets
  n <- dim(pp_plot_data)[2]
  pp_plot_data <- select(pp_plot_data, sample(1:n, sample_number, replace = F))
  p <- pp_plot_data %>%
        gather %>%
        ggplot(aes(key, value, group = key)) +
        geom_violin(color = "grey50") +
        geom_boxplot(width = 0.05, outlier.size = 0.8) +
        scale_color_discrete(guide = F) +
        geom_violin(data = model$data, aes_q(0, as.name(y_name), group = "none"), color = "firebrick") +
        geom_boxplot(data = model$data, aes_q(0, as.name(y_name), group = "none"), width = 0.08, outlier.size = 0.5) +
        coord_flip() +
        ggtitle(as.character(model$family)[1])
}

# use violin + points for pp check
pp_plot_v2 <- function(model, sample_number, y_name, lower = 0.3, upper = 0.3) {
  # calculate xlim (here ylim due to coord_flip)
  lower <- 
    min(model$data[, y_name]) - lower*min(model$data[, y_name])
  upper <- 
    max(model$data[, y_name]) + upper*max(model$data[, y_name])
  # pp_plot_data has 8000 simulated datasets. rows are invidiual 
  # subjects and columns the number of simulation
  pp_plot_data <- posterior_predict(model)
  # in case I use brms multiple imputation, pp_plot_data has 3 dim
  n_dim <- pp_plot_data %>% dim() %>% length()
  if (n_dim == 3) pp_plot_data <- pp_plot_data[, , 1]
  pp_plot_data <- pp_plot_data %>% t() %>% as.tibble()
  # number of datasets
  n <- dim(pp_plot_data)[2]
  pp_plot_data <- select(pp_plot_data, sample(1:n, sample_number, replace = F))
  p <- pp_plot_data %>%
        gather %>%
        ggplot(aes(key, value, group = key)) +
        geom_violin(color = "grey50") +
        geom_jitter(alpha = 0.5, width = 0.1) +
        scale_color_discrete(guide = F) +
        geom_violin(data = model$data, aes_q(0, as.name(y_name), group = "none"), color = "firebrick") +
        geom_jitter(data = model$data, aes_q(0, as.name(y_name), group = "none"), alpha = 0.5, width = 0.1) +
        ylim(c(lower, upper)) +
        coord_flip() +
        ggtitle(as.character(model$family)[1])
}


# return dataframe of student t simulated data either with or without true parameters
simulate_t <- function(b0, b1, N1, N2, sigma_0, sigma_1, nu = 10, true_values = TRUE) {
  N <- N1 + N2
  # how many observations per condition
  condition <- c(rep(0, N1), rep(1, N2))
  id <- 1:(N)
  mu <- b0 + b1 * condition
  # initialize df
  data <- tibble(id, mu, group = as.factor(condition))
  data <- data %>% 
    mutate(
      sigma = ifelse(condition, sigma_0, sigma_1),
      y = rt(df = nu, n = N) * sigma + mu)
  if(!true_values) {select(data, y, group) } else {data}
}

# return dataframe of gaussian simulated data either with or without true parameters
simulate_g <- function(b0, b1, N1, N2, sigma_0, sigma_1, true_values = TRUE) {
  N <- N1 + N2
  # how many observations per condition
  condition <- c(rep(0, N1), rep(1, N2))
  id <- 1:(N)
  mu <- b0 + b1 * condition
  # initialize df
  data <- tibble(id, mu, group = as.factor(condition))
  data <- data %>% 
    mutate(
      sigma = ifelse(condition, sigma_0, sigma_1),
      y = rnorm(n = N, mean = mu, sd = sigma))
  if(!true_values) {select(data, y, group) } else {data}
}
  
# returns a df with estimated parameters and the difference to the true parameters
true_diff <- function(model, true_values) {
  post <- model %>% as.tibble()
  post %>% mutate(
    b0 = b_Intercept,  
    sigma_0 = exp(b_sigma_Intercept),
    b1 = b_group1, 
    sigma_1 = exp((b_sigma_Intercept + b_sigma_group1))) %>%
    select(b0, sigma_0, b1, sigma_1) %>%
    gather(term, value) %>%
    group_by(term) %>%
    do(data.frame(
      estimate = mean(.$value))) %>% 
    add_column(true_values = true_values) %>%
    mutate(diff = true_values - estimate)
}

