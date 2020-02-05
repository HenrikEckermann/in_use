library(randomForest)
library(tidyverse)
source("https://raw.githubusercontent.com/HenrikEckermann/in_use/master/reporting.R")



rf_cv <- function(
  data, 
  predictors,
  outcome,
  p = 0.8, 
  times = 10, 
  id_name = "id",
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
    }

    
  })
  p
}

rf_cor <- function(
  data, 
  predictors,
  outcome,
  p = 0.8, 
  times = 10, 
  id_name = "id",
  ntree = 5000) {
    model_and_data <- rf_cv(
      data,
      predictors,
      outcome,
      p = p, 
      times = times, 
      id_name = id_name,
      ntree = ntree)
    p <- rf_model_fit(model_and_data, outcome = outcome)
    p <- map_dfr(p, function(list) {
      list[[1]]
     }) %>% gather(sample, value) %>%
      summarise(mean = mean(value), sd = sd(value))
      
    rsq <- rf_model_fit(model_and_data, outcome = outcome)
    rsq <- map_dfr(rsq, function(list) {
      list[[2]]
     }) %>% gather(sample, value) %>%
      summarise(mean = mean(value), sd = sd(value))
    list("p" = p, "rsq" = rsq)
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