library(randomForest)
library(tidyverse)
source("https://raw.githubusercontent.com/HenrikEckermann/in_use/master/reporting.R")

#########################
### Random Forests ### --------------------------------------
#########################


rf_cv <- function(
  data, 
  predictors,
  outcome,
  p = 0.8, 
  times = 10,
  ntree = 5000
  ) {
    train_indeces <- caret::createDataPartition(
      data[[outcome]], 
      p = p, 
      times = times)
    map(train_indeces, function(ind) {
      train <- data[ind, ]
      test <- data[-ind, ]
      model <- randomForest(
        y = train[[outcome]],
        x = select(train, predictors),
        ntree = ntree,
        importance = TRUE
      )
      list(model, test)
      })
    }

rf_model_fit <- function(models_and_data, outcome, regression = TRUE) {
  p <- map(models_and_data, function(model_and_data) {
    
    model <- model_and_data[[1]]
    test <- model_and_data[[2]]
    if (regression) {
      preds <- predict(model, test)
      p <- cor.test(test[[outcome]], preds)
      p <- round(p[4]$estimate, 3)
      rsq <- mean(model$rsq) %>% round(3)
      list(p, rsq)
    } else {
      pred_prob <- predict(model, test, type = "prob")
      log_l <- MLmetrics::LogLoss(pred_prob[, 2], as.numeric(test$group) - 1)
      oob <- model$err.rate %>% as_tibble() %>% summarise_all(median)
      metric <- oob %>% mutate(log_l = log_l) %>%
        select(log_l, oob_avg = OOB, "0", "1")
      list(metric)
    }

    
  })
  p
}

rf_summary <- function(
  data, 
  predictors,
  outcome,
  p = 0.8, 
  times = 10,
  ntree = 5000,
  regression = TRUE) {
    model_and_data <- rf_cv(
      data,
      predictors,
      outcome,
      p = p, 
      times = times,
      ntree = ntree)
    metric <- rf_model_fit(model_and_data, outcome = outcome, regression = regression)
    if (regression) {
      p <- map_dfr(metric, function(list) {
        list[[1]]
       }) %>% gather(sample, value) %>%
        summarise(mean = mean(value), sd = sd(value))
        
      rsq <- map_dfr(metric, function(list) {
        list[[2]]
       }) %>% gather(sample, value) %>%
        summarise(mean = mean(value), sd = sd(value))
        
      list("p" = p, "rsq" = rsq)
      
    } else {
      map_dfr(metric, ~bind_rows(.x)) %>%
      select(oob_class_0 = "0", oob_class_1 = "1", everything()) %>%
      gather(statistic, value) %>% 
      group_by(statistic) %>%
      summarise(
        median = median(value), 
        sd = sd(value), 
        lower = quantile(value, 0.025), 
        upper = quantile(value, 0.975)
      ) %>%
      mutate_if(is.numeric, round, 3)
    }
  }
  
plot_importance <- function(model, regression = T) {
  if (regression) {
    var_imp <- importance(model, type = 1)
    var_imp <- var_imp %>% as.data.frame() %>%
    rownames_to_column("variable") %>%
    select(variable, inc_mse = `%IncMSE`) %>%
    arrange(inc_mse) %>%
    mutate(variable = factor(variable, level = variable))
    ggplot(var_imp, aes(variable, inc_mse)) +
      geom_col() +
      coord_flip() 
  } else {
    print("Please program this function for classification")  }
}





#########################
### Model diagnostics ### --------------------------------------
#########################

lm_diag <- function(model, data, Y) {
  diag_df <- data %>%
  mutate( 
    sresid = resid(model), 
    fitted = fitted(model)
  ) %>% 
  mutate(sresid = scale(sresid)[, 1])
  

  # distribution of the scaled residuals
  p_resid <- ggplot(diag_df, aes(sresid)) +
      geom_density() +
      ylab('Density') + xlab('Standardized Redsiduals') +
      theme_minimal()

  ## qq plot (source code for gg_qq in script)
  qq <- 
    gg_qq(diag_df$sresid)+ 
    theme_minimal() + 
    xlab('Theoretical') + ylab('Sample')

  # fitted vs sresid 
  fit_resid <- 
    ggplot(diag_df, aes(fitted, sresid)) +
      geom_point(alpha = 0.6) +
      geom_smooth(se = F, color = "#f94c39") +
      geom_point(
        data = filter(diag_df, abs(sresid) > 3.5), 
        aes(fitted, sresid), color='red'
      ) +
      ggrepel::geom_text_repel(
        data = filter(diag_df, abs(sresid) > 3.5), 
        aes(fitted, y = sresid, label = id), size = 3
      ) +
      ylab('Standardized Residuals') + xlab('Fitted Values') +
      scale_y_continuous(breaks=c(-4, -3, -2, -1, 0, 1, 2, 3, 4))+
      theme_minimal()

  # Fitted vs observed
  fit_obs <- 
    ggplot(diag_df, aes_string("fitted", glue("{Y}"))) +
      geom_point(alpha = 0.6) +
      geom_smooth(se = F, color = '#f94c39') +
      ylab(glue("Observed {Y}")) + xlab('Fitted Values') +
      theme_minimal()
      
  (p_resid + qq) /
    (fit_resid + fit_obs)
}