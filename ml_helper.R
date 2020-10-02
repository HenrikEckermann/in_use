
library(tidyverse)
library(furrr)



#########################
###     ML General    ### --------------------------------------
#########################

# returns df of our eval metrics (logloss and F1)
model_eval <- function(
  model, 
  testdata, 
  features,
  y,  
  model_type = "randomForest", 
  classification = TRUE,
  null_test = FALSE,
  null_dist = if(null_test) null_dist else NULL
  ) {
    
    if (classification) {
      
      # what we need for all classfication models
      y_true <- as.numeric(testdata[[y]]) -1
      
      # for most models we can get predictions like this
      if (model_type == "randomForest") {
        y_pred_resp <- predict(model, newdata = testdata, type = "response")
        y_pred_resp <- as.numeric(y_pred_resp) -1
        y_pred_prob <- predict(model, newdata = testdata, type = "prob")[, 2]
        
      # for xgb models we need a xgb.DMatrix
      } else if (model_type == "XGBoost") {
        testdata_xgb <- select(testdata, features) %>% as.matrix()
        testdata_xgb <- xgb.DMatrix(data = testdata_xgb, label = y_true)
        y_pred_prob <- predict(model, testdata_xgb)
        y_pred_resp <- ifelse(y_pred_prob == 0.5, 
          rbinom(n = 1, size = 1, p = 0.5), ifelse(y_pred_prob > 0.5,
            1, 0))
      }
      # logloss 
      log_l <- MLmetrics::LogLoss(y_pred_prob, y_true)
      
      # F1 scores
      f_one <- MLmetrics::F1_Score(
        factor(y_true, levels = c("0", "1")), 
        factor(y_pred_resp, levels = c("0", "1"))
      )
      metric <- tibble(logloss = log_l, F1 = f_one)
      return(metric)
    } else {
      preds <- predict(model, newdata = testdata)
      p <- cor.test(testdata[[y]], preds)
      if (null_test) {
        p_value <- mean(null_dist > p[4]$estimate)
      }
      p <- round(p[4]$estimate, 3)
      rsq <- mean(model$rsq) %>% round(3)
      
      metric <- tibble(
        r = p, 
        rsq = rsq,
        p_value = p_value)
      return(metric)
    }
    
    
    
}


# returns null distribution or pearson cor for given test data 
rf_null <- function(
  y,
  features,
  train = train,
  test = test,
  n_perm = 1e3,
  ntree = 5000
  ) {
    
    p_null <- future_map_dbl(c(1:n_perm), function(iter) {
      # permute outcome   
      train_perm <- train 
      test_perm <- test
      train_perm$y_perm <- sample(
        train[[y]],
        replace = FALSE,
        size = dim(train)[1])
      train_perm <- select(train_perm, -y)
      
      test_perm$y_perm <- sample(
        test[[y]],
        replace = FALSE,
        size = dim(test)[1])
      test_perm <- select(test_perm, -y)
    
      # fit null model randomForest 
      null_model <- randomForest::randomForest(
        y = train_perm$y_perm,
        x = select(train, features),
        ntree = ntree,
        importance = FALSE
      )
      
      # obtain pearson 
      pred <- predict(null_model, newdata = test_perm)
      pearson_r <- cor.test(test_perm$y_perm, pred)
      return(pearson_r$estimate[[1]])
    })
    return(p_null)  
}


# returns a list of lists where each list has a fitted model and the
# corresponding testdata as items 
fit_cv <- function(
  data, 
  features,
  y,
  p = 0.8, 
  k = 10,
  model_type = "randomForest",
  null_test = FALSE,
  n_perm <- if (null_test) 1e3 else NULL
  ...
  ) {
    
    dots <- list(...)
    
    # generate k datasets
    train_indeces <- caret::createDataPartition(
      data[[y]], 
      p = p, 
      times = k)
    
    # this will return a list of lists that each contain a fitted model and 
    # the corresponding test dataset 
    models_and_testdata <- map(train_indeces, function(ind) {
      train <- data[ind, ]
      test <- data[-ind, ]
      

    
      # fit randomForest 
      if (model_type == "randomForest") {
        model <- randomForest::randomForest(
          y = train[[y]],
          x = select(train, features),
          ntree = dots$ntree,
          importance = TRUE
        )
      } else if (model_type == "XGBoost") {
    
        # prepare xgb data matrix object
        labels_train <- train[[y]] %>% as.numeric() -1 # one-hot-coding
        labels_test <- test[[y]] %>% as.numeric() -1
        train_xgb <- select(train, features) %>% as.matrix()
        test_xgb <- select(test, features) %>% as.matrix()
        train_xgb <- xgb.DMatrix(data = train_xgb, label = labels_train)
        test_xgb <- xgb.DMatrix(data = test_xgb, label = labels_test)
    
        # set model parameters (this should be put in ... at some point)
        params <- list(
          booster = "gbtree",
          objective = "binary:logistic",
          eta = 0.3,
          gamma = 0,
          max_depth = 6,
          min_child_weight = 1,
          subsample = 1,
          colsample_bytree = 1
        )
    
        # fit model 
        model <- xgb.train(
          params = params,
          data = train_xgb, 
          nrounds = 10,
          watchlist = list(val = test_xgb, train = train_xgb),
          print_every_n = 10, 
          early_stop_round = 10,
          maximize = FALSE,
          eval_metric = "logloss",
          verbose = 0
        )
      }
      
      if (null_test) {
        null_dist <- rf_null(
          y,
          features,
          train,
          test,
          ntree = dots$ntree,
          n_perm = n_perm
        )
        
        return(list(model, test, null_dist))
      } else {
        # return fitted model and corresponding test data set
        list(model, test)
      }

    })
    return(models_and_testdata)
}







# summarises eval metrics 
summarize_metrics <- function(
  models_and_data, 
  y, 
  model_type = "randomForest", 
  features = features, 
  classification = TRUE
  ) {
    map_dfr(models_and_data, function(model_and_data) {
      model <- model_and_data[[1]]
      testdata <- model_and_data[[2]]
      model_eval(model, testdata, features = features, y = y, model_type = model_type, classification = classification) 
    }) %>%
      gather(metric, value) %>%
      group_by(metric) %>%
      summarise(mean = mean(value), sd = sd(value)) %>%
      mutate_if(is.numeric, round, 2)
}
  
plot_importance <- function(model, regression = T, top_n = NULL) {
  if (regression) {
    var_imp <- importance(model, type = 1)
    var_imp <- var_imp %>% as.data.frame() %>%
    rownames_to_column("variable") %>%
    select(variable, inc_mse = `%IncMSE`) %>%
    arrange(inc_mse) %>%
    mutate(variable = factor(variable, level = variable))
    if (!is.null(top_n)) {
      var_imp <- tail(var_imp, top_n)
    }
    ggplot(var_imp, aes(variable, inc_mse)) +
      geom_col() +
      coord_flip() 
  } else {
    print("Please program this function for classification")  }
}

extract_importance <- function(model, n = 10) {
      var_imp <- importance(model, type = 1)
      var_imp <- var_imp %>% as.data.frame() %>%
        rownames_to_column("variable") %>%
        select(variable, inc_mse = `%IncMSE`) %>%
        arrange(inc_mse) %>%
        mutate(variable = factor(variable, level = variable)) %>%
        tail(n)
      return(var_imp)  
}




#########################
###   Random Forests  ### --------------------------------------
#########################


# Feature selection based on RF importance scores.
# models_and_data is a list of list where each list contains a model object [1]
# and the corresponding testdata [2] According to workflow in this script
select_features <- function(
  models_and_data, 
  id_name = "id", 
  n_features = 50,
  regression = TRUE,
  ranger = FALSE,
  importance_measure = ifelse(regression, "%IncMSE", "MeanDecreaseAccuracy")) {
  top_predictors <- map(models_and_data, function(model_and_data) {
    model <- model_and_data[[1]]
  
  
    top_predictors <- importance(model, type = 1, scale = F) %>%
      as.data.frame() %>%
      rownames_to_column(id_name) %>%
      arrange(desc(all_of(importance_measure))) %>%
      select(id_name) %>%
      head(n_features)
    }
  )
  
  # only intersection of all k model is used
  selected_features <- Reduce(intersect, top_predictors)
  return(selected_features)
}









rf_cv <- function(
  data, 
  features,
  y,
  p = 0.8, 
  k = 10,
  ntree = 5000,
  null_test = FALSE,
  n_perm <- if (null_test) 1e3 else NULL
  ) {
    train_indeces <- caret::createDataPartition(
      data[[y]], 
      p = p, 
      times = k)
      
    map(train_indeces, function(ind) {
      train <- data[ind, ]
      test <- data[-ind, ]
      model <- randomForest::randomForest(
        y = train[[y]],
        x = select(train, features),
        ntree = ntree,
        importance = TRUE
      )
      
      if (null_test) {
        null_dist <- rf_null(
          y,
          features,
          train,
          test,
          ntree = ntree,
          n_perm = n_perm
        )
        
        return(list(model, test, null_dist))
      } else {
        # return fitted model and corresponding test data set
        list(model, test)
      }
      })
    }

rf_model_fit <- function(
  models_and_data, 
  y, 
  regression = TRUE, 
  null_test = FALSE
  ) {
    p <- map(models_and_data, function(model_and_data) {
      
      model <- model_and_data[[1]]
      test <- model_and_data[[2]]
      if (null_test) {
        null_dist <- model_and_data[[3]]
      }
      if (regression) {
        preds <- predict(model, newdata = test)
        p <- cor.test(test[[y]], preds)
        rsq <- mean(model$rsq) %>% round(3)
        if (null_test) {
          p_value <- mean(null_dist > p[4]$estimate)
          list(round(p[4]$estimate, 3), rsq, p_value)
        } else {
          list(round(p[4]$estimate, 3), rsq)
        }
        
      } else {
        y_true <- as.numeric(test[[y]]) -1
        pred_prob <- predict(model, newdata = test, type = "prob")
        log_l <- MLmetrics::LogLoss(pred_prob[, 2], y_true)
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
  features,
  y,
  p = 0.8, 
  k = 10,
  ntree = 5000,
  regression = TRUE,
  null_test = FALSE
  ) {
    model_and_data <- rf_cv(
      data,
      features,
      y,
      p = p, 
      k = k,
      ntree = ntree,
      null_test = null_test
    )
    metric <- rf_model_fit(
      model_and_data, 
      y = y, 
      regression = regression,
      null_test = null_test
    )
    if (regression) {
      p <- map_dfr(metric, function(list) {
        list[[1]]
       }) %>% gather(sample, value) %>%
        summarise(mean = mean(value), median = median(value), sd = sd(value))
        
      rsq <- map_dfr(metric, function(list) {
        list[[2]]
       }) %>% gather(sample, value) %>%
        summarise(mean = mean(value), median = median(value), sd = sd(value))
        
      if (null_test) {
        df1 <- map_dfr(metric, function(list) {
          list[[1]]
          }) %>% gather(sample, r)
        df2 <- map_dfr(metric, function(list) {
          list[[3]]
          }) %>% gather(sample, p_value)
        p_value <- bind_cols(df1, df2) %>% filter(r == median(r)) %>%
          .$p_value
        p_value <- p_value[1]
      }
      
      if (null_test) {
        list("p" = p, "rsq" = rsq, "p_value" = p_value)
      } else {
        list("p" = p, "rsq" = rsq)
      }
      
      
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
      mutate_if(is.numeric, round, 2)
    }
  }
  
plot_importance <- function(model, regression = T, top_n = NULL) {
  if (regression) {
    var_imp <- importance(model, type = 1)
    var_imp <- var_imp %>% as.data.frame() %>%
    rownames_to_column("variable") %>%
    select(variable, inc_mse = `%IncMSE`) %>%
    arrange(inc_mse) %>%
    mutate(variable = factor(variable, level = variable))
    if (!is.null(top_n)) {
      var_imp <- tail(var_imp, top_n)
    }
    ggplot(var_imp, aes(variable, inc_mse)) +
      geom_col() +
      coord_flip() 
  } else {
    print("Please program this function for classification")  }
}

extract_importance <- function(model, n = 10) {
      var_imp <- importance(model, type = 1)
      var_imp <- var_imp %>% as.data.frame() %>%
        rownames_to_column("variable") %>%
        select(variable, inc_mse = `%IncMSE`) %>%
        arrange(inc_mse) %>%
        mutate(variable = factor(variable, level = variable)) %>%
        tail(n)
      return(var_imp)  
}




#########################
###    Regression     ### --------------------------------------
#########################

# to plot simple regression or counterfactual plots 
# model is brms model (might work with other lm models too)
# specify x2 for counterfactual plots
plot_regression <- function(
  model, x, y, 
  points = TRUE, 
  counterfactual = FALSE, 
  x2 = NULL) {
    
    
    n <- length(model$data[[x2]])
    if (counterfactual) {
      newdata <- tibble(
        x_rep = seq(
          from = min(model$data[[x]]), 
          to = max(model$data[[x]]), 
          length.out = n),
        x2_rep = mean(model$data[[x2]])
      )
      colnames(newdata) <- c(x, x2)
    } else {
      newdata <- tibble(
        x_rep = seq(
          from = min(model$data[[x]]), 
          to = max(model$data[[x]]), 
          length.out = n)
        )
      colnames(newdata) <- c(x)
    }

    df <- fitted(model, newdata = newdata) %>% 
      as_tibble() %>%  
      rename(
        f_ll = Q2.5,
        f_ul = Q97.5
    ) 
    pred <- predict(model, newdata = newdata) %>% 
             as_tibble() %>%
             transmute(p_ll = Q2.5, p_ul = Q97.5)
    df <- bind_cols(newdata, pred, df)
      
    if(!counterfactual) {
      p <- ggplot(df, aes_string(x, "Estimate")) +
          geom_smooth(aes(ymin = f_ll, ymax = f_ul), stat = "identity")
          
    } else if(counterfactual) {

        p <- ggplot(df, aes_string(x = x, y = "Estimate")) +
              geom_ribbon(aes(ymin = p_ll, ymax = p_ul), alpha = 1/5) +
              geom_smooth(aes(ymin = f_ll, ymax = f_ul), stat = "identity") +
              coord_cartesian(xlim = range(model$data[[x]]))
    }
    
    # add real data points
    if(points) {
      p <- p + geom_point(data = model$data, aes_string(x, y))
    }
    
    return(p)
}



# diagnostic plots for frequentist regression (lm or lme4)
lm_diag <- function(model, data, Y) {
  # need some helper function defined elsewhere
  source("https://raw.githubusercontent.com/HenrikEckermann/in_use/master/reporting.R")
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
