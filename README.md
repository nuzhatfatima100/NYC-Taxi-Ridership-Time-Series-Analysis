# NYC Taxi Ridership Time Series Forecasting 🚕📈  

## **Project Overview**  
This project analyzes **NYC taxi ridership trends** and forecasts future demand using **time series modeling**. The dataset, sourced from the [NYC Taxi & Limousine Commission](https://www.kaggle.com/datasets/julienjta/nyc-taxi-traffic), contains passenger count data from **July 2014 to January 2015** in **30-minute intervals**.  

Our objective is to **identify seasonal patterns, anomalies, and major event impacts** (e.g., NYC Marathon, Christmas, Blizzard) and develop an **optimal forecasting model** for predicting taxi demand.  

---

## **Key Findings & Insights**  
- 🚀 **Demand Spikes**: NYC Marathon, Halloween, and New Year’s Eve showed **peak taxi ridership**.  
- ❄️ **Weather Impact**: A **blizzard in January 2015** caused a **steep decline in ridership**.  
- ⏰ **Time-Based Trends**: Ridership follows **strong daily and weekly seasonality**, with **peak demand during rush hours (8 AM & 6 PM)**.  
- 📊 **Forecasting Performance**:  
  - **ARIMA(3,1,2)(1,1,2)** achieved the **lowest MAPE (9.8%) and RMSE (2,475)**, making it the best model for forecasting.  
  - **Two-Level Forecasting (Quadratic Trend + Moving Average)** performed well but had limitations in capturing extreme peaks.  

---

## **Dataset** 📂  
- **Source**: [NYC Taxi Traffic Dataset](https://www.kaggle.com/datasets/julienjta/nyc-taxi-traffic)  
- **Timeframe**: July 1, 2014 – January 31, 2015  
- **Granularity**: 30-minute intervals (aggregated to hourly for analysis)  
- **Features**:  
  - `timestamp`: Date and time of each record  
  - `value`: Number of taxi passengers in that time interval  

---

## **Methods & Approach**  
### **📌 Data Preprocessing**  
- Cleaned and **aggregated raw 30-minute data into hourly intervals**.  
- Handled **missing values and outliers** (e.g., extreme low ridership during storms).  

### **📈 Time Series Modeling & Forecasting**  
We tested multiple forecasting models and evaluated their performance using **Mean Absolute Percentage Error (MAPE) and Root Mean Square Error (RMSE)**:  
✅ **Linear Regression with Seasonality** – Baseline model for trend & seasonality.  
✅ **Two-Level Forecasting** – Combined regression with **moving averages** to improve accuracy.  
✅ **Auto ARIMA** – Automates model selection but overfitted the training data.  
✅ **Holt-Winters Exponential Smoothing** – Captured seasonality but performed poorly on unseen data.  
✅ **ARIMA(3,1,2)(1,1,2)** – **Best model with lowest forecasting error**.  

---

## **Technologies & Tools Used** 🛠️  
- **Programming**: R (forecast, ggplot2, zoo, xts)  
- **Time Series Analysis**: ARIMA, Auto ARIMA, Holt-Winters, Two-Level Forecasting  
- **Data Visualization**: ggplot2 for trend analysis & event impact visualization  
- **Statistical Evaluation**: ACF/PACF plots, MAPE, RMSE for model comparison  

---

## **Results & Model Comparison**  
| Model | MAPE (%) | RMSE | Notes |
|--------|--------|--------|--------------------------------------|
| **Linear Regression + Seasonality** | 20.5 | 6,800 | Baseline model, underfits data |
| **Quadratic Trend + Seasonality** | 15.8 | 5,200 | Improved, but still high error |
| **Holt-Winters (HW-ZZZ)** | 14.7 | 3,455 | Overfitting, some negative forecasts |
| **Two-Level Forecast (LTS + MA-24)** | 12.3 | 7,905 | Better MAPE but higher RMSE |
| **Auto ARIMA** | 10.1 | 4,200 | Overfits training data |
| **ARIMA(3,1,2)(1,1,2) ✅** | **9.8** | **2,475** | 🔥 **Best model, lowest error** 🔥 |

---

## **Visualization Examples**  
### 📊 NYC Taxi Ridership Over Time  
![Ridership Trends](plots/ridership_trends.png)  

### 🚀 Peak Demand During Major Events  
![Event Impact](plots/event_impact.png)  

---

## **Future Improvements** 🏆  
- **Test deep learning models** (LSTMs, Facebook Prophet) for improved forecasting.  
- **Integrate external factors** (weather, ride-sharing competition) for better accuracy.  
- **Deploy a live forecasting dashboard** to predict taxi demand in real-time.  

---

## **How to Run the Code** 💻  
1️⃣ **Clone the Repository**  
```bash
git clone https://github.com/your-username/NYC-Taxi-Ridership-Analysis.git
cd NYC-Taxi-Ridership-Analysis


