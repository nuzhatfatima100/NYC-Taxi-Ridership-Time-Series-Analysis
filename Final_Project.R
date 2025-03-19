setwd("~/Desktop/coursework/Time Series Analytics/final-project")

library(forecast)
library(zoo)
library(xts)
library(ggplot2)


taxi_data <- read.csv('nyc_taxi.csv')

head(taxi_data)

taxi_data$timestamp <- as.POSIXct(taxi_data$timestamp, format = "%Y-%m-%d %H:%M:%S")

# Round the timestamp to the previous hour (round down)
taxi_data$timestamp_adjusted <- floor(as.numeric(taxi_data$timestamp) / 3600) * 3600
taxi_data$timestamp_adjusted <- as.POSIXct(taxi_data$timestamp_adjusted, origin = "1970-01-01")

head(taxi_data)

taxi_xts <- xts(taxi_data$value, order.by = taxi_data$timestamp_adjusted)

colnames(taxi_xts) <- "value"


taxi_hourly <- period.apply(taxi_xts, endpoints(taxi_xts, on = "hours"), FUN = sum)  # Sum values every hour

head(taxi_hourly)
tail(taxi_hourly)

# Create the 'ts' object
taxi_ts <- ts(
  data = taxi_hourly$value,
  start = c(182, 1),  # July 1, 00:00:00 (day 182, hour 1)
  frequency = 24       # 24 hours/day
)

# Check the result
head(taxi_ts)
tail(taxi_ts)


plot(taxi_hourly, 
     main = "Hourly Taxi Data (2014-07-01 to 2015-01-31)",
     xlab = "Time", 
     ylab = "Number of Passengers", 
     col = "blue",
     major.ticks = "months") 


taxi_daily <- apply.daily(taxi_xts, sum)

# Create a 'ts' object for daily data
taxi_daily_ts <- ts(
  data = taxi_daily$value,
  start = c(182, 1),  # July 1, 2014 (Day 182)
  frequency = 1        # Daily frequency
)

head(taxi_daily_ts)
tail(taxi_daily_ts)


# Plot Daily Data
plot(taxi_daily, 
     main = "Daily Taxi Passenger Data (2014-07-01 to 2015-01-31)",
     xlab = "Time", 
     ylab = "Number of Passengers", 
     col = "red",
     major.ticks = "months")



# Plotting graphs for important events that happened from July 2014 to January 2015 in NYC

plot_event_days <- function(start_date, end_date = start_date, data, y_min = 0, y_max = 80000) {
  start_time <- as.POSIXct(paste(start_date, "00:00:00"))
  end_time <- as.POSIXct(paste(end_date, "23:59:59"))  # Ensure full range is included
  
  filtered_data <- window(data, start = start_time, end = end_time)
  
  plot(index(filtered_data), coredata(filtered_data), type = "l",
       main = paste("Taxi Ridership from", start_date, "to", end_date),
       xlab = "", ylab = "Number of Passengers",
       col = "blue", lwd = 2, xaxt = "n", yaxt = "n",
       ylim = c(y_min, y_max), 
       panel.first = grid(col = "gray80", lty = "dotted"))
  
  # Format x-axis to show both date and hour for clarity
  axis(1, 
       at = index(filtered_data), 
       labels = format(index(filtered_data), "%b %d %H:%M"),  
       las = 2, cex.axis = 0.8)
  
  # Format y-axis with whole numbers
  axis(2, 
       at = seq(y_min, y_max, by = 10000),  
       labels = format(seq(y_min, y_max, by = 10000), scientific = FALSE), 
       las = 1, cex.axis = 0.8)
  
  points(index(filtered_data), coredata(filtered_data), pch = 16, col = "blue")
}




# 4th of July Independence Day
plot_event_days(start_date = "2014-07-04", data = taxi_hourly)

# October 31, 2014 – Halloween (Parades, parties)
plot_event_days(start_date = "2014-10-31", data = taxi_hourly)

# November 2, 2014 – NYC Marathon (Major street closures)
plot_event_days(start_date = "2014-11-02", data = taxi_hourly)

# December 24 and 25, 2014 – Christmas 
plot_event_days(start_date = "2014-12-24", end_date = "2014-12-25", data = taxi_hourly)

# December 31, 2014 and 1st Jan 2015 – New Year
plot_event_days(start_date = "2014-12-31", end_date = "2015-01-01", data = taxi_hourly)

# January 26 2015 - Snow Storm
plot_event_days(start_date = "2015-01-26", end_date = "2015-01-27", data = taxi_hourly)



# Partitioning the data
nValid <- 720 # month of January 
nTrain <- length(taxi_ts) - nValid 
train.ts <- window(taxi_ts, start = c(182, 1), end = c(182, nTrain))
valid.ts <- window(taxi_ts, start = c(182, nTrain + 1), 
                   end = c(182, nTrain + nValid))

length(valid.ts)
nTrain
nValid


Acf(taxi_ts, lag.max=24, main = "Autocorrelation of data")

# Regression model with linear trend and seasonality
linear_trend_seasonality_model <- tslm(train.ts ~ trend + season)
summary(linear_trend_seasonality_model)

forecast_linear_trend_seasonal <- forecast(linear_trend_seasonality_model, h = nValid)
print(head(forecast_linear_trend_seasonal$mean))

acc_linear_seasonal <- accuracy(forecast_linear_trend_seasonal, valid.ts)
print(acc_linear_seasonal)


# Create the forecast table with correct timestamps
forecast_table <- data.frame(
  Actual_Ridership = as.numeric(valid.ts),
  Regression_Forecast = as.numeric(forecast_linear_trend_seasonal$mean)
)

# Print first few rows
head(forecast_table)


# Two-Level Forecast with Regression + Trailing Moving Average on Residuals

# Regression Residuals
residuals_train_lts <- residuals(linear_trend_seasonality_model)

Acf(residuals_train_lts, main = "Autocorrelation of Regression Residuals", lag.max = 24)

# Applying trailing MA (window width = 24) to residuals
ma12_residuals_lts <- rollmean(residuals_train_lts, k = 24, fill = NA, align = "right")

# Forecasting residuals using trailing MA in validation period
ma12_residuals_forecast_lts <- forecast(ma12_residuals_lts, h = nValid)

print(ma12_residuals_forecast_lts$mean)

two_level_forecast_lts <- forecast_linear_trend_seasonal$mean + ma12_residuals_forecast_lts$mean


forecast_table <- data.frame(
  Actual_Ridership = as.numeric(valid.ts),
  Regression_Forecast = as.numeric(forecast_linear_trend_seasonal$mean),
  Residual_MA_Forecast = as.numeric(ma12_residuals_forecast_lts$mean),
  Two_Level_Forecast = as.numeric(two_level_forecast_lts)
)

print(head(forecast_table))

acc_two_level_forecast_lts <- accuracy(two_level_forecast_lts, valid.ts)
print(acc_two_level_forecast_lts)


# Create a sequence of time values based on the start of valid.ts
start_time <- as.POSIXct("2015-01-01 00:00:00")  # Adjust if needed
time_sequence <- seq(from = start_time, by = "hour", length.out = nrow(forecast_table))

# Add the generated time sequence to the dataframe
forecast_table$Time <- time_sequence

# Simple line plot
plot(forecast_table$Time, forecast_table$Actual_Ridership, type = "l", col = "black", lwd = 1,
     xlab = "Time", ylab = "Ridership", main = "Actual vs Forecasted Ridership on validation set")

lines(forecast_table$Time, forecast_table$Regression_Forecast, col = "red", lwd = 1)
lines(forecast_table$Time, forecast_table$Two_Level_Forecast, col = "blue", lwd = 1)

legend("topright", legend = c("Actual", "Regression", "Two-Level"),
       col = c("black", "red", "blue"), lwd = 2)


# Regression model with quadratic trend and seasonality
quadratic_trend_seasonality_model <- tslm(train.ts ~ trend + I(trend^2) + season)
summary(quadratic_trend_seasonality_model)


forecast_quadratic_trend_seasonal <- forecast(quadratic_trend_seasonality_model, h = nValid)
print(forecast_quadratic_trend_seasonal$mean)

acc_quadratic_seasonal <- accuracy(forecast_quadratic_trend_seasonal, valid.ts)
print(acc_quadratic_seasonal)


# two level forecasts with Trailing MA of window 12
residuals_train_qts <- residuals(quadratic_trend_seasonality_model)

Acf(residuals_train_qts, main = "Autocorrelation of Regression Residuals", lag.max=24)

# Applying trailing MA (window width = 24) to residuals
ma12_residuals <- rollmean(residuals_train_qts, k = 24, fill = NA, align = "right")

# Forecasting residuals using trailing MA in validation period
ma12_residuals_forecast <- forecast(ma12_residuals, h = nValid)

print(ma12_residuals_forecast$mean)

two_level_forecast_qts <- forecast_quadratic_trend_seasonal$mean + ma12_residuals_forecast$mean

forecast_table <- data.frame(
  Actual_Ridership = as.numeric(valid.ts),
  Regression_Forecast = as.numeric(forecast_quadratic_trend_seasonal$mean),
  Residual_MA_Forecast = as.numeric(ma12_residuals_forecast$mean),
  Two_Level_Forecast = as.numeric(two_level_forecast_qts)
)

print(head(forecast_table))

acc_two_level_qts <- accuracy(two_level_forecast_qts, valid.ts)
print(acc_two_level_qts)


# Create a sequence of time values based on the start of valid.ts
start_time <- as.POSIXct("2015-01-01 00:00:00")  # Adjust if needed
time_sequence <- seq(from = start_time, by = "hour", length.out = nrow(forecast_table))

# Add the generated time sequence to the dataframe
forecast_table$Time <- time_sequence

# Simple line plot
plot(forecast_table$Time, forecast_table$Actual_Ridership, type = "l", col = "black", lwd = 1,
     xlab = "Time", ylab = "Ridership", main = "Actual vs Forecasted Ridership on validation set")

lines(forecast_table$Time, forecast_table$Regression_Forecast, col = "red", lwd = 1)
lines(forecast_table$Time, forecast_table$Two_Level_Forecast, col = "blue", lwd = 1)

legend("topright", legend = c("Actual", "Regression", "Two-Level"),
       col = c("black", "red", "blue"), lwd = 2)


# Auto Arima Model
auto_arima_model <- auto.arima(train.ts)

summary(auto_arima_model)

# Forecast for the validation period
auto_arima_forecast <- forecast(auto_arima_model, h = nValid)

print(auto_arima_forecast$mean)

acc_auto_arima <- accuracy(auto_arima_forecast, valid.ts)
print(acc_auto_arima)

auto_arima_residuals <- residuals(auto_arima_model)

Acf(auto_arima_residuals, main = "Autocorrelation of auto ARIMA Residuals", lag.max=24)

forecast_table <- data.frame(
  Actual_Ridership = as.numeric(valid.ts),
  Auto_ARIMA_forecast = as.numeric(auto_arima_forecast$mean)
)

# Create a sequence of time values based on the start of valid.ts
start_time <- as.POSIXct("2015-01-01 00:00:00")  # Adjust if needed
time_sequence <- seq(from = start_time, by = "hour", length.out = nrow(forecast_table))

# Add the generated time sequence to the dataframe
forecast_table$Time <- time_sequence

# Simple line plot
plot(forecast_table$Time, forecast_table$Actual_Ridership, type = "l", col = "black", lwd = 1,
     xlab = "Time", ylab = "Ridership", main = "Actual vs Forecasted Ridership on validation set")

lines(forecast_table$Time, forecast_table$Auto_ARIMA_forecast, col = "red", lwd = 1)

legend("topright", legend = c("Actual", "Auto ARIMA"),
       col = c("black", "red"), lwd = 2)

# Creating Holt-Winter's (HW) exponential smoothing for partitioned data.
# Use ets() function with model = "ZZZ", i.e., automatic selection of
# error, trend, and seasonality options.
hw.ZZZ <- ets(train.ts, model = "ZZZ")

summary(hw.ZZZ)

hw_ZZZ_forecast <- forecast(hw.ZZZ, h = nValid)
print(head(hw_ZZZ_forecast$mean))

acc_hw_ZZZ <- accuracy(hw_ZZZ_forecast, valid.ts)
print(acc_hw_ZZZ)

residuals_hw_ZZZ <- residuals(hw.ZZZ)

Acf(residuals_hw_ZZZ, main = "Autocorrelation of Residuals", lag.max=24)

# Fit AR(1) model to HW residuals
ar1_hw_for_residuals <- Arima(residuals_hw_ZZZ, order = c(1, 0, 0)) 

# Forecasting residuals using trailing MA in validation period
ar1_hw_residuals_forecast <- forecast(ar1_hw_for_residuals, h = nValid)

# residuals of residuals
ar1_residuals_of_residuals <- residuals(ar1_hw_for_residuals)

Acf(ar1_residuals_of_residuals, main = "ACF of Residuals of Residuals", lag.max=24)

two_level_forecast_HW <- hw_ZZZ_forecast$mean + ar1_hw_residuals_forecast$mean

acc_two_level_HW <- accuracy(two_level_forecast_HW, valid.ts)
print(acc_two_level_HW)

forecast_table <- data.frame(
  Actual_Ridership = as.numeric(valid.ts),
  HW_Forecast = as.numeric(hw_ZZZ_forecast$mean),
  AR1_Residual_Forecast = as.numeric(ar1_hw_residuals_forecast$mean),
  Two_Level_Forecast = as.numeric(two_level_forecast_HW)
)

print(head(forecast_table))


# Create a sequence of time values based on the start of valid.ts
start_time <- as.POSIXct("2015-01-01 00:00:00")  # Adjust if needed
time_sequence <- seq(from = start_time, by = "hour", length.out = nrow(forecast_table))

# Add the generated time sequence to the dataframe
forecast_table$Time <- time_sequence

# Simple line plot
plot(forecast_table$Time, forecast_table$Actual_Ridership, type = "l", col = "black", lwd = 1,
     xlab = "Time", ylab = "Ridership", main = "Actual vs Forecasted Ridership on validation set")

lines(forecast_table$Time, forecast_table$HW_Forecast, col = "red", lwd = 1)
lines(forecast_table$Time, forecast_table$Two_Level_Forecast, col = "blue", lwd = 1)

legend("topright", legend = c("Actual", "HW", "Two-Level"),
       col = c("black", "red", "blue"), lwd = 2)



###improved to ARIMA(3,1,2)(1,1,2) model

# 1.Use Arima() function to fit ARIMA(3,1,2)(1,1,2) model for trend and seasonality in train data.

train.arima.seas <- Arima(train.ts, order = c(3,1,2), 
                          seasonal = c(1,1,2)) 
summary(train.arima.seas)

#2. in validation data, apply forecast() function to make predictions for ts with RIMA(3,1,2)(1,1,2) model

train.arima.seas.pred <- forecast(train.arima.seas, h = nValid, level = 0)
train.arima.seas.pred

# Use Acf() function to create autocorrelation chart of ARIMA(3,1,2)(1,1,2) 
# model residuals.
Acf(train.arima.seas$residuals, lag.max = 24, 
    main = "Autocorrelations of ARIMA(3,1,2)(1,1,2) Model Residuals")

#3.accuracy performance in validation data
round(accuracy(train.arima.seas.pred$mean, valid.ts), 3)

acc_arima <- accuracy(train.arima.seas.pred$mean, valid.ts)
print(acc_arima)

forecast_table <- data.frame(
  Actual_Ridership = as.numeric(valid.ts),
  ARIMA_forecast = as.numeric(train.arima.seas.pred$mean)
)

print(head(forecast_table))

# Create a sequence of time values based on the start of valid.ts
start_time <- as.POSIXct("2015-01-01 00:00:00")  # Adjust if needed
time_sequence <- seq(from = start_time, by = "hour", length.out = nrow(forecast_table))

# Add the generated time sequence to the dataframe
forecast_table$Time <- time_sequence

# Simple line plot
plot(forecast_table$Time, forecast_table$Actual_Ridership, type = "l", col = "black", lwd = 1,
     xlab = "Time", ylab = "Ridership", main = "Actual vs Forecasted Ridership on validation set")

lines(forecast_table$Time, forecast_table$ARIMA_forecast, col = "red", lwd = 1)

legend("topright", legend = c("Actual", "ARIMA"),
       col = c("black", "red"), lwd = 2)

accuracy_table <- data.frame(
  Model = c("Linear Trend & Seasonality", "Quadratic Trend & Seasonality" ,"HW-ZZZ", "Two-Level Forecast (LTS+MA-12)","Two-Level Forecast (QTS+MA-12)","Two-Level Forecast (HW-ZZZ+AR1)", "Auto Arima", "ARIMA(3,1,2)(1,1,2)"),
  MAPE = c(acc_linear_seasonal["Test set","MAPE"], acc_quadratic_seasonal["Test set","MAPE"],acc_hw_ZZZ["Test set","MAPE"],  acc_two_level_forecast_lts["Test set","MAPE"], acc_two_level_qts["Test set", "MAPE"], acc_two_level_HW["Test set", "MAPE"],  acc_auto_arima["Test set", "MAPE"], acc_arima["Test set", "MAPE"]),
  RMSE = c(acc_linear_seasonal["Test set","RMSE"], acc_quadratic_seasonal["Test set","RMSE"],acc_hw_ZZZ["Test set","RMSE"],  acc_two_level_forecast_lts["Test set","RMSE"], acc_two_level_qts["Test set", "RMSE"], acc_two_level_HW["Test set", "RMSE"],  acc_auto_arima["Test set", "RMSE"], acc_arima["Test set", "RMSE"])
)

print(accuracy_table)











