library(randomForest)
library(tidyverse)



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
      data[[id_name]], 
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

rf_model_fit <- function(models_and_data, outcome) {
  p <- map(models_and_data, function(model_and_data) {
    model <- model_and_data[[1]]
    test <- model_and_data[[2]]
    preds <- predict(model, test)
    p <- cor.test(test[[outcome]], preds)
    p <- round(p[4]$estimate, 3)
    rsq <- mean(model$rsq) %>% round(3)
    list(p, rsq)
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
