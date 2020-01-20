fit_rf <- function(y, meta, features, df) {
    # random (50/50) split of samples_ids
    n <- length(meta_temp$sample_id)
    train_samples <- sample(meta_temp$sample_id, n/2, replace = FALSE)
    # define train and test set
    train_data <- df %>% # df contains all features and outcomes
        filter(sample_id %in% train_samples) %>%
        select(y, features)
    test_data <- df %>% 
        filter(
          !sample_id %in% train_samples & 
          sample_id %in% meta_temp$sample_id) %>%
        select(y, features)
    
    # if there are missing data in the predictors I need to impute
    # Note for Gilles: There is no missing data in the models where I have these problems so you can ignore this section until "fit RF"
    if (sum(is.na(train_data)) > 0) {
      train_data <- rfImpute(
        x = as.formula(glue("{y} ~ .")), 
        data = train_data)  
    }
    if (sum(is.na(test_data)) > 0) {
      test_data <- rfImpute(
        x = as.formula(glue("{y} ~ .")), 
        data = test_data) 
    }
    # fit RF model 
    fit <- randomForest(
        formula = as.formula(glue("{y} ~ .")),
        data = train_data,
        ntree = 3e4)
    # obtain RMSE & Pearson
    pred <- predict(fit, newdata = test_data)
    fit_rmse <- rmse(actual = test_data[[y]], predicted = pred)
    pearson_r <- cor.test(test_data[[y]], pred)
    list(
      timepoint = meta$time[1], 
      n_samples = n, 
      "y" = y, 
      "rmse" = fit_rmse, 
      "pearson_r" = pearson_r$estimate[[1]], 
      "p_value" = pearson_r$p.value)   
}