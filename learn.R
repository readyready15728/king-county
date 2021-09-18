library(Metrics)
library(caret)
library(kernlab)
library(lubridate)
library(tidyverse)

# Here we go
tbl <- read_csv('kc-house-data.csv')

# Drop id column
tbl <- tbl %>% select(-id)

# Convert dates into year, month and day columns
tbl <- tbl %>% mutate(year=year(date), month=month(date), day=day(date))
# Drop original date column
tbl <- tbl %>% select(-date)

# waterfront should be Boolean
tbl <- tbl %>% mutate(waterfront=waterfront == 1)

# Create has_basement column
tbl <- tbl %>% mutate(has_basement=sqft_basement != 0)
# ...and has_been_renovated as well
tbl <- tbl %>% mutate(has_been_renovated=yr_renovated != 0)

# Split into training and testing sets, with fixed RNG seed
set.seed(42)
train_index <- createDataPartition(y = tbl$price, p=0.8, list=FALSE)
training <- tbl[train_index,]
testing <- tbl[-train_index,]

# Load or train model
model_path <- 'fit.rds'

if (file.exists(model_path)) {
  fit <- readRDS(model_path)
} else {
  # Train the model, again with fixed RNG seed
  train_control <- trainControl(
    method='repeatedcv',
    number=10,
    repeats=5,
    verboseIter=TRUE
  )
  sigma_svm <- median(
    kernlab::sigest(
      as.matrix(training %>% select(-price)),
      scaled = TRUE
    )
  )
  costs_svm <- c(0.25, 0.5, 1, 2, 4, 8, 16, 32)

  set.seed(42)
  fit <- train(
    price ~ .,
    data=training,
    method='svmRadial',
    trControl=train_control,
    preProcess=c('center', 'scale'),
    tuneGrid=expand.grid(sigma=sigma_svm, C=costs_svm),
    tuneLength=10
  )
  
  saveRDS(fit, 'fit.rds')
}

price_pred <- predict(fit, testing)
price_actual <- testing$price
print(rmse(price_pred, price_actual))
