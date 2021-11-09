library(Metrics)
library(caret)
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
    repeats=3,
    verboseIter=TRUE
  )

  set.seed(42)
  fit <- train(
    price ~ .,
    data=training,
    method='svmRadial',
    trControl=train_control,
    preProcess=c('center', 'scale'),
    tuneLength=10,
  )
  
  saveRDS(fit, model_path)
}

price_pred <- predict(fit, training)
price_actual <- training$price
print(rmse(price_pred, price_actual))
