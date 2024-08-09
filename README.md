# **Bike-sharing Demand Prediction Application using R**
This project serves as the Capstone for IBM's Data Science using R Programming Training. The objective of this project is to analyze how weather conditions influence the demand for bike-sharing in urban areas. With bike-sharing programs being a popular transportation option in cities worldwide, it's crucial to optimize the availability and accessibility of rental bikes while minimizing operational costs. By predicting the number of bikes required each hour based on current weather conditions, this application aims to support cities in efficiently managing their bike-sharing systems.

## **Project Overview**
The project involves the following key tasks:

### **1. Data Collection and Understanding**
Data was collected from multiple sources using web scraping techniques. The data includes information on weather conditions and bike rental records, which were then combined to create a comprehensive dataset for analysis.

### **2. Data Wrangling and Preparation**
Data wrangling was performed to clean and prepare the dataset for analysis. This included:
  * Regular Expressions: Used to extract and format relevant information from the raw data.
  * Tidyverse: Leveraged for data manipulation tasks, including handling missing values, converting data types, and standardizing formats.
    
### **3. Exploratory Data Analysis (EDA)**
EDA was conducted to explore the relationships between weather conditions and bike rental demand. This involved:
* SQL Queries: Used to perform complex data analysis tasks.
* Data Visualization: Created using Tidyverse and ggplot2 to identify patterns and correlations in the data.
  
### **4. Data Modeling**
A linear regression model was developed to predict bike-sharing demand based on weather conditions. This involved:
* Model Development: Using the Tidymodels framework to build and train the regression model.
* Model Evaluation: Metrics such as R-squared, Mean Absolute Error (MAE), and Root Mean Squared Error (RMSE) were used to evaluate the model's performance and refine it accordingly.
  
### **5. Interactive Dashboard Development**
An interactive dashboard was built using R Shiny to allow users to explore the data and model predictions dynamically. The dashboard provides real-time insights into bike demand based on current weather conditions, making it a valuable tool for urban planners and transportation authorities.

### **6. Deployment**
The final application was deployed on ShinyApps, making it accessible to a broader audience. Users can interact with the dashboard to explore how different weather conditions impact bike-sharing demand.

## **Tools and Technologies**
* Programming Language: R
* Interactive Programming Tool: R Studio
* Data Manipulation: tidyverse, lubridate, tibble, purr
* Data Analysis: corrplot
* ML Model Evaluation: tidymodels, broom, Metrics, parsnip
* Data Visualization: ggplot, knitr
* Report Deployment: ShinyApps

## **Conclusion**
This Bike-sharing Demand Prediction Application provides a practical solution for cities to manage their bike-sharing programs more efficiently. By accurately predicting bike demand based on weather conditions, the application can help optimize the allocation of resources, ensuring that bikes are available where and when they are needed the most.

Link to the Application: [Bike-sharing Demand Prediction App](https://ge6xjr-kendrick-moreno.shinyapps.io/BikeSharingApp/)
