
library(tidyverse)
library(furrr)
library(mlr) 
library(tuneRanger)
library(ranger)


#########################
###     ML General    ### --------------------------------------
#########################

# get very rough estimate of a good ntree/computation trade off 
plot_ntree <- function(x, y, ntree = 1e4) {
  ntreeplot <- randomForest::randomForest(
    x = x,
    y = y,
    ntree = ntree
  )
  plot(ntreeplot)
}

# returns df of our eval metrics (logloss and F1)
model_eval <- function(
  model, 
  testdata, 
  features,
  y,  
  model_type = "ranger", 
  classification = TRUE,
  null_test = FALSE,
  null_dist = if(null_test) null_dist else NULL
  ) {
    
    if (classification) {
      
      # we need the groups as 0/1 values
      y_true <- as.numeric(testdata[[y]]) -1
      
      # obtain predictions (this is little different for each algorithm)
      # randomForest
      if (model_type == "randomForest") {
        y_pred_resp <- predict(model, newdata = testdata, type = "response")
        y_pred_resp <- as.numeric(y_pred_resp) -1
        y_pred_prob <- predict(model, newdata = testdata, type = "prob")[, 2]
      # ranger
      } else if (model_type == "ranger") {
        y_pred_resp <- predict(model, data = testdata)$predictions
        y_pred_resp <- as.numeric(y_pred_resp) -1
        # to obtain prob you need to fit a prob tree to begin with
        y_pred_prob <- predict(model, data = testdata)$predictions
      }
      # for xgb models we need a xgb.DMatrix
      } else if (model_type == "XGBoost") {
        testdata_xgb <- select(testdata, all_of(features)) %>% as.matrix()
        testdata_xgb <- xgb.DMatrix(data = testdata_xgb, label = y_true)
        y_pred_prob <- predict(model, testdata_xgb)
        y_pred_resp <- ifelse(y_pred_prob == 0.5, 
          rbinom(n = 1, size = 1, p = 0.5), ifelse(y_pred_prob > 0.5,
            1, 0))

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
      if (model_type == "randomForest") {
        y_pred <- predict(model, newdata = testdata, type = "response")
      # ranger
      } else if (model_type == "ranger") {
        y_pred <- predict(model, data = testdata)$predictions
      }

      p <- cor.test(testdata[[y]], y_pred)
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
  n_perm = 500,
  ntree = 500
  ) {
    
    p_null <- future_map_dbl(c(1:n_perm), function(iter) {
      # permute outcome   
      train_perm = train 
      test_perm <- test
      train_perm$y_perm <- sample(
        train[[y]],
        replace = FALSE,
        size = dim(train)[1])
      train_perm <- select(train_perm, -all_of(y))
      
      test_perm$y_perm <- sample(
        test[[y]],
        replace = FALSE,
        size = dim(test)[1])
      test_perm <- select(test_perm, -all_of(y))
    
      # fit null model ranger
      null_model <- ranger::ranger(
        y = train_perm$y_perm,
        x = select(train, all_of(features)),
        num.trees  = ntree,
        importance = "none",
        probability = probability
      )
      
      # obtain pearson 
      y_pred <- predict(null_model, data = test_perm)$predictions
      pearson_r <- cor.test(test_perm$y_perm, y_pred)
      return(pearson_r$estimate[[1]])
    })
    return(p_null)  
}


# # returns a list of lists where each list has a fitted model and the
# # corresponding testdata as items 
# fit_cv <- function(
#   data, 
#   features,
#   y,
#   method = "cv",
#   p = ifelse(method == "resample", 0.8, NULL),
#   k = 10,
#   model_type = "ranger",
#   null_test = FALSE,
#   n_perm = if (null_test) 500 else NULL,
#   ...
#   ) {
# 
#     dots <- list(...)
# 
#     # cv/resample 
#     if (method == "cv") {
#       train_indeces <- caret::createFolds(
#         data[[y]], 
#         k = k,
#         returnTrain = TRUE)
# 
#     } else if (method == "resample") {
#       train_indeces <- caret::createDataPartition(
#         data[[y]], 
#         p = p, 
#         times = k)
#     }
# 
# 
#     # this will return a list of lists that each contain a fitted model and 
#     # the corresponding test dataset 
#     models_and_testdata <- map(train_indeces, function(ind) {
#       train <- data[ind, ]
#       test <- data[-ind, ]
# 
# 
# 
#       # fit randomForest 
#       if (model_type == "randomForest") {
#         model <- randomForest::randomForest(
#           y = train[[y]],
#           x = select(train, all_of(features)),
#           ntree = dots$ntree,
#           importance = "permutation"
#         )
#       } else if (model_type == "ranger") {
#         model <- ranger::ranger(
#           y = train[[y]],
#           x = select(train, all_of(features)),
#           ntree = dots$ntree,
#           importance = "permutation",
#           probability = probability
#         )
#       } else if (model_type == "XGBoost") {
#         # prepare xgb data matrix object
#         labels_train <- train[[y]] %>% as.numeric() -1 # one-hot-coding
#         labels_test <- test[[y]] %>% as.numeric() -1
#         train_xgb <- select(train, all_of(features)) %>% as.matrix()
#         test_xgb <- select(test, all_of(features)) %>% as.matrix()
#         train_xgb <- xgb.DMatrix(data = train_xgb, label = labels_train)
#         test_xgb <- xgb.DMatrix(data = test_xgb, label = labels_test)
# 
#         # set model parameters (this should be put in ... at some point)
#         params <- list(
#           booster = "gbtree",
#           objective = "binary:logistic",
#           eta = 0.3,
#           gamma = 0,
#           max_depth = 6,
#           min_child_weight = 1,
#           subsample = 1,
#           colsample_bytree = 1
#         )
# 
#         # fit model 
#         model <- xgb.train(
#           params = params,
#           data = train_xgb, 
#           nrounds = 10,
#           watchlist = list(val = test_xgb, train = train_xgb),
#           print_every_n = 10, 
#           early_stop_round = 10,
#           maximize = FALSE,
#           eval_metric = "logloss",
#           verbose = 0
#         )
#       }
# 
#       if (null_test) {
#         null_dist <- rf_null(
#           y,
#           features,
#           train,
#           test,
#           ntree = dots$ntree,
#           n_perm = n_perm
#         )
# 
#         return(list(model, test, null_dist))
#       } else {
#         # return fitted model and corresponding test data set
#         list(model, test)
#       }
# 
#     })
#     return(models_and_testdata)
# }







# summarises eval metrics 
summarize_metrics <- function(
  models_and_data, 
  y, 
  model_type = "ranger", 
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
  
plot_importance <- function(model, top_n = NULL) {
  var_imp <- importance(model, type = 1)
  var_imp <- var_imp %>% as.data.frame() 
  imp_name <- colnames(var_imp)[1]
  
  var_imp <- var_imp %>%
    rownames_to_column("features") %>%
    select(features, importance = all_of(imp_name)) %>%
    arrange(importance) %>%
    mutate(features = factor(features, level = features))
  if (!is.null(top_n)) {
    var_imp <- tail(var_imp, top_n)
  }
  ggplot(var_imp, aes(features, importance)) +
    geom_col() +
    coord_flip() 

}

extract_importance <- function(model, n = 10) {
  var_imp <- importance(model, type = 1)
  var_imp <- var_imp %>% as.data.frame() 
  imp_name <- colnames(var_imp)[1]
  var_imp <- var_imp %>%
    rownames_to_column("features") %>%
    select(features, importance = all_of(imp_name)) %>%
    arrange(importance) %>%
    mutate(features = factor(features, level = features)) %>%
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
  n_features = 50) {
  top_predictors <- map(models_and_data, function(model_and_data) {
    model <- model_and_data[[1]]
  
  
    top_predictors <- importance(model, type = 1) %>%
      as.data.frame()
    imp_name <- colnames(top_predictors)[1]
    top_predictors <- top_predictors %>%
      rownames_to_column(id_name) %>%
      arrange(desc(all_of(imp_name))) %>%
      select(all_of(id_name)) %>%
      head(n_features)
    }
  )
  
  # only intersection of all k model is used
  selected_features <- Reduce(intersect, top_predictors)
  return(selected_features)
}



tune_rf <- function(
  data, 
  features, 
  y, 
  regression = TRUE,
  measure = NULL, 
  iters = 70, 
  iters.warmup = 30,
  time.budget = NULL, 
  num.threads = NULL, 
  ntree = 1000,
  parameters = list(
    replace = FALSE, 
    respect.unordered.factors = "order"
  ), 
  tune.parameters = c(
    "mtry", 
    "min.node.size",
    "sample.fraction"
  ), 
  save.file.path = NULL, 
  build.final.model = FALSE,
  show.info = getOption("mlrMBO.show.info", TRUE)
  ) {
    # names must be compatible with mlr 
    d <- select(data, all_of(features), all_of(y))
    colnames(d) <- make.names(colnames(d), unique = T)
    if (regression) {
      tune_task <- makeRegrTask(
        data = d,
        target = y
      )
    } else {
      tune_task <- makeClassifTask(
        data = d,
        target = y
      )
    }

    estimateTimeTuneRanger(tune_task)
    res <- tuneRanger(
      tune_task, 
      measure = measure, 
      iters = iters, 
      iters.warmup = iters.warmup,
      time.budget = time.budget, 
      num.threads = num.threads, 
      num.trees = ntree,
      parameters = parameters, 
      tune.parameters = tune.parameters,
      save.file.path = save.file.path, 
      build.final.model = build.final.model,
      show.info = show.info
    )
    res
}




rf_cv <- function(
  data, 
  features,
  y,
  method = "cv",
  p = ifelse(method == "resample", 0.8, NULL),
  k = 10,
  ntree = 500,
  null_test = FALSE,
  n_perm = if (null_test) 500 else NULL,
  regression = TRUE, 
  probability = ifelse(regression, FALSE, TRUE),
  ...
  ) {
    
    # additional arguments for ranger 
    dots <- list(...)
    ranger_params <- list()
    if ("mtry" %in% names(dots)) {
      ranger_params[["mtry"]] <- dots[["mtry"]]
    }  else {
      ranger_params[["mtry"]] <- NULL
    }
    if ("min.node.size" %in% names(dots)) {
      ranger_params[["min.node.size"]] <- dots[["min.node.size"]]
    }  else {
      ranger_params[["min.node.size"]] <- NULL
    }
    if ("replace" %in% names(dots)) {
      ranger_params[["replace"]] <- dots[["replace"]]
    }  else {
      ranger_params[["replace"]] <- FALSE
    }   
    if ("sample.fraction" %in% names(dots)) {
      ranger_params[["sample.fraction"]] <- dots[["sample.fraction"]]
    }  else {
      ranger_params[["sample.fraction"]] <- ifelse(ranger_params[["replace"]], 1, 0.632)
    } 
    if ("splitrule" %in% names(dots)) {
      ranger_params[["splitrule"]] <- dots[["splitrule"]]
    }  else {
      ranger_params[["splitrule"]] <- NULL
    } 
    if ("num.random.splits" %in% names(dots)) {
      ranger_params[["num.random.splits"]] <- dots[["num.random.splits"]]
    }  else {
      ranger_params[["num.random.splits"]] <- 1
    } 
    if ("scale.permutation.importance" %in% names(dots)) {
      ranger_params[["scale.permutation.importance"]] <- dots[["scale.permutation.importance"]]
    }  else {
      ranger_params[["scale.permutation.importance"]] <- FALSE
    }
    if ("importance" %in% names(dots)) {
      ranger_params[["importance"]] <- dots[["importance"]]
    }  else {
      ranger_params[["importance"]] <- "permutation"
    }
    
    

    # cv/resample 
    if (method == "cv") {
      train_indeces <- caret::createFolds(
        data[[y]], 
        k = k,
        returnTrain = TRUE)
      
    } else if (method == "resample") {
      train_indeces <- caret::createDataPartition(
        data[[y]], 
        p = p, 
        times = k)
    }
    

    map(train_indeces, function(ind) {
      train <- data[ind, ]
      test <- data[-ind, ]
      model <- ranger::ranger(
        y = train[[y]],
        x = select(train, all_of(features)),
        num.trees  = ntree,
        importance = ranger_params[["importance"]],
        probability = probability,
        mtry = ranger_params[["mtry"]],
        min.node.size = ranger_params[["min.node.size"]],
        replace = ranger_params[["replace"]],
        sample.fraction = ranger_params[["sample.fraction"]],
        splitrule = ranger_params[["splitrule"]],
        num.random.splits = ranger_params[["num.random.splits"]],
        scale.permutation.importance = ranger_params[["scale.permutation.importance"]]        
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


# repeated cv/resampling
rf_rcv <- function(
  data, 
  features,
  y,
  method = "cv",
  p = ifelse(method == "resample", 0.8, NULL),
  k = 10,
  ntree = 500,
  null_test = FALSE,
  n_perm = if (null_test) 500 else NULL,
  regression = TRUE,
  probability = ifelse(regression, FALSE, TRUE),
  repeated = 10) {
    
    all_model_and_data <- map(c(1:repeated), function(rep) {
      model_and_data <- rf_cv(
        data, 
        features,
        y,
        method = method,
        p = p,
        k = k,
        ntree = ntree,
        null_test = null_test,
        n_perm = n_perm,
        regression = regression,
        probability = probability
      )
    })
    flatten(all_model_and_data)
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
        y_pred <- predict(model, data = test)$predictions
        p <- cor.test(test[[y]], y_pred)
        rsq <- model$r.squared %>% round(3)
        if (null_test) {
          p_value <- mean(null_dist > p[4]$estimate)
          list(round(p[4]$estimate, 3), rsq, p_value)
        } else {
          list(round(p[4]$estimate, 3), rsq)
        }
        
      } else {
        y_true <- as.numeric(test[[y]]) -1
        # only works if you specified ranger as probability tree
        y_pred_prob <- predict(model, data = test)$predictions
        log_l <- MLmetrics::LogLoss(y_pred_prob[, 2], y_true)
        oob <- model$prediction.error
        metric <- tibble(oob = oob, log_l = log_l) 
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
  ntree = 500,
  regression = TRUE,
  null_test = FALSE,
  probability = ifelse(regression, FALSE, TRUE)
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




get_oob <- function(model_and_data, summarise = TRUE) {
  metric <- map_dfc(model_and_data, function(md) {
    md[[1]]$prediction.error
  }) %>% pivot_longer(everything(), names_to = "fold", values_to = "oob")
    
  if (summarise) {
    metric <- metric %>%
      summarise(
        median = median(oob),
        mean = mean(oob),
        sd = sd(oob),
        lower = quantile(oob, 0.025),
        upper = quantile(oob, 0.975)
        )
      }
  metric
}

# thanks to Artem Sokolov: https://stackoverflow.com/questions/45676745/how-to-calculate-the-auc-value-for-a-ranger-rf-model
auc_roc <- function(scores, labels){
  stopifnot( length(scores) == length(labels) )
  jp <- which( labels > 0 ); np <- length( jp )
  jn <- which( labels <= 0); nn <- length( jn )
  s0 <- sum( rank(scores)[jp] )
  (s0 - np*(np+1) / 2) / (np*nn)
}


get_auc <- function(model_and_data, y, summarise = TRUE) {
  metric <- map_dfr(model_and_data, function(md) {
    fit <- md[[1]]
    test <- md[[2]]
    y_pred <- predict(fit, data = test)$predictions[, 2]
    y_true <- as.numeric(test[[y]]) - 1
    list(auc = auc_roc(y_pred, y_true))
    }) %>% pivot_longer(everything(), names_to = "fold", values_to = "auc")
    
  if (summarise) {
    metric <- metric %>%
      summarise(
        median = median(auc),
        mean = mean(auc),
        sd = sd(auc),
        lower = ifelse(berryFunctions::is.error(quantile(auc, 0.025)), NA, quantile(auc, 0.025)),
        upper = ifelse(berryFunctions::is.error(quantile(auc, 0.975)), NA, quantile(auc, 0.975))
      )
    }
  metric
}

get_pearson <- function(model_and_data, y, summarise = TRUE) {
  metric <- map_dfr(model_and_data, function(md) {
    fit <- md[[1]]
    test <- md[[2]]
    y_pred <- predict(fit, data = test)$predictions
    y_true <- test[[y]]
    p <- cor.test(y_true, y_pred)
    list(pearson = round(p[4]$estimate, 3))
  }) %>% pivot_longer(everything(), names_to = "fold", values_to = "pearson")
    
  if (summarise) {
    metric <- metric %>%
      summarise(
        median = median(pearson),
        mean = mean(pearson),
        sd = sd(pearson),
        lower = ifelse(berryFunctions::is.error(quantile(pearson, 0.025)), NA, quantile(pearson, 0.025)),
        upper = ifelse(berryFunctions::is.error(quantile(pearson, 0.975)), NA, quantile(pearson, 0.975))
      )
    }
  metric
}


get_rsq <- function(model_and_data, y, summarise = TRUE) {
  metric <- map_dfr(model_and_data, function(md) {
    fit <- md[[1]]
    list(rsq = fit$r.squared)
  }) %>% pivot_longer(everything(), names_to = "fold", values_to = "rsq")
    
  if (summarise) {
    metric <- metric %>%
      summarise(
        median = median(rsq),
        mean = mean(rsq),
        sd = sd(rsq),
        lower = quantile(rsq, 0.025),
        upper = quantile(rsq, 0.975)
      )
    }
  metric
}



get_null <- function(
  
)



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
    y_pred <- predict(model, newdata = newdata) %>% 
             as_tibble() %>%
             transmute(p_ll = Q2.5, p_ul = Q97.5)
    df <- bind_cols(newdata, y_pred, df)
      
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
