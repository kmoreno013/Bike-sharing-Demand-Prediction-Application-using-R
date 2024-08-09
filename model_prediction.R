require(tidyverse)
require(httr)

# Get weather forecast data by cities from CSV
get_weather_forecaset_by_cities <- function(csv_file){
  # Read the weather forecast data from the CSV file with explicit column types
  weather_data <- read_csv(csv_file, col_types = cols(
    CITY = col_character(),
    WEATHER = col_character(),
    VISIBILITY = col_double(),
    TEMP = col_double(),
    TEMP_MIN = col_double(),
    TEMP_MAX = col_double(),
    PRESSURE = col_double(),
    HUMIDITY = col_double(),
    WIND_SPEED = col_double(),
    WIND_DEG = col_double(),
    SEASON = col_character(),
    FORECAST_DATETIME = col_datetime(format = "%Y-%m-%d %H:%M:%S")
  ), show_col_types = FALSE)
  
  # Check for missing columns
  required_columns <- c("CITY", "WEATHER", "TEMP", "VISIBILITY", "HUMIDITY", "WIND_SPEED", "FORECAST_DATETIME")
  missing_columns <- setdiff(required_columns, colnames(weather_data))
  if (length(missing_columns) > 0) {
    stop(paste("Missing columns in the CSV file:", paste(missing_columns, collapse = ", ")))
  }
  
  # Extract necessary columns
  city <- weather_data$CITY
  weather <- weather_data$WEATHER
  temperature <- weather_data$TEMP
  visibility <- weather_data$VISIBILITY
  humidity <- weather_data$HUMIDITY
  wind_speed <- weather_data$WIND_SPEED
  forecast_date <- weather_data$FORECAST_DATETIME
  
  # Calculate seasons and hours based on forecast_date
  seasons <- weather_data$SEASON
  hours <- as.numeric(strftime(forecast_date, format="%H"))
  weather_labels <- c()
  weather_details_labels <- c()
  
  for(i in 1:nrow(weather_data)) {
    forecast_datetime <- weather_data$FORECAST_DATETIME[i]
    if (is.na(forecast_datetime)) {
      next
    }
    
    # Add a HTML label to be shown on Leaflet
    weather_label <- paste(sep = "",
                           "<b><a href=''>",
                           weather_data$CITY[i], 
                           "</a></b>", "</br>", 
                           "<b>", weather_data$WEATHER[i], "</b></br>")
    # Add a detailed HTML label to be shown on Leaflet
    weather_detail_label <- paste(sep = "",
                                  "<b><a href=''>",
                                  weather_data$CITY[i], 
                                  "</a></b>", "</br>", 
                                  "<b>", weather_data$WEATHER[i], "</b></br>",
                                  "Temperature: ", weather_data$TEMP[i], " C </br>",
                                  "Visibility: ", weather_data$VISIBILITY[i], " m </br>",
                                  "Humidity: ", weather_data$HUMIDITY[i], " % </br>", 
                                  "Wind Speed: ", weather_data$WIND_SPEED[i], " m/s </br>", 
                                  "Datetime: ", forecast_datetime, " </br>")
    weather_labels <- c(weather_labels, weather_label)
    weather_details_labels <- c(weather_details_labels, weather_detail_label)
  }
  
  # Create and return a tibble
  weather_df <- tibble(CITY_ASCII=city, WEATHER=weather, 
                       TEMPERATURE=temperature,
                       VISIBILITY=visibility, 
                       HUMIDITY=humidity, 
                       WIND_SPEED=wind_speed, SEASONS=seasons, HOURS=hours, FORECASTDATETIME=forecast_date, 
                       LABEL=weather_labels, DETAILED_LABEL=weather_details_labels)
  
  return(weather_df)
}

# Load a saved regression model (variables and coefficients) from csv
load_saved_model <- function(model_name){
  model <- read_csv(model_name)
  model <- model %>% 
    mutate(Variable = gsub('"', '', Variable))
  coefs <- setNames(model$Coef, as.list(model$Variable))
  return(coefs)
}

# Predict bike-sharing demand using a saved regression model
predict_bike_demand <- function(TEMPERATURE, HUMIDITY, WIND_SPEED, VISIBILITY, SEASONS, HOURS){
  model <- load_saved_model("model.csv")
  
  # Debugging: Check the size of input vectors
  message("Input sizes - TEMPERATURE: ", length(TEMPERATURE), 
          ", HUMIDITY: ", length(HUMIDITY), 
          ", WIND_SPEED: ", length(WIND_SPEED), 
          ", VISIBILITY: ", length(VISIBILITY), 
          ", SEASONS: ", length(SEASONS), 
          ", HOURS: ", length(HOURS))
  
  if (any(is.na(c(TEMPERATURE, HUMIDITY, WIND_SPEED, VISIBILITY, SEASONS, HOURS)))) {
    stop("Input vectors contain missing values.")
  }
  
  # Calculate weather terms
  weather_terms <- model['Intercept'] + TEMPERATURE * model['TEMPERATURE'] + HUMIDITY * model['HUMIDITY'] +
    WIND_SPEED * model['WIND_SPEED'] + VISIBILITY * model['VISIBILITY']
  
  # Handle NA values
  weather_terms[is.na(weather_terms)] <- 0
  
  # Debugging: Check the calculated weather terms
  message("Weather terms calculated: ", paste(weather_terms, collapse = ", "))
  
  # Calculate season terms
  season_terms <- sapply(SEASONS, function(season) {
    term <- switch(season, 
                   'SPRING' = model['SPRING'],
                   'SUMMER' = model['SUMMER'],
                   'AUTUMN' = model['AUTUMN'],
                   'WINTER' = model['WINTER'],
                   0)
    if (is.na(term)) term <- 0
    term
  })
  
  # Ensure season_terms matches the length of input vectors
  if (length(season_terms) != length(TEMPERATURE)) {
    stop("Season terms calculation resulted in incorrect length.")
  }
  
  # Debugging: Check the calculated season terms
  message("Season terms calculated: ", paste(season_terms, collapse = ", "))
  
  # Calculate hour terms
  hour_terms <- sapply(HOURS, function(hour) {
    term <- model[as.character(hour)]
    if (is.na(term)) term <- 0
    term
  })
  
  # Ensure hour_terms matches the length of input vectors
  if (length(hour_terms) != length(TEMPERATURE)) {
    stop("Hour terms calculation resulted in incorrect length.")
  }
  
  # Debugging: Check the calculated hour terms
  message("Hour terms calculated: ", paste(hour_terms, collapse = ", "))
  
  # Calculate regression terms
  regression_terms <- as.integer(weather_terms + season_terms + hour_terms)
  regression_terms[is.na(regression_terms)] <- 0
  
  # Debugging: Check the final regression terms
  message("Regression terms calculated: ", paste(regression_terms, collapse = ", "))
  
  # Ensure non-negative values
  regression_terms <- pmax(regression_terms, 0)
  
  return(regression_terms)
}


# Define a bike-sharing demand level, used for leaflet visualization
calculate_bike_prediction_level <- function(predictions) {
  levels <- c()
  for(prediction in predictions){
    if(prediction <= 1000 && prediction >= 0)
      levels <- c(levels, 'small')
    else if (prediction > 1000 && prediction < 3000)
      levels <- c(levels, 'medium')
    else
      levels <- c(levels, 'large')
  }
  return(levels)
}

# Generate a data frame containing weather forecasting and bike prediction data
generate_city_weather_bike_data <- function (){
  cities_df <- read_csv("selected_cities.csv")
  weather_df <- get_weather_forecaset_by_cities("cities_weather_forecast.csv")
  
  # Ensure that weather_df is not empty
  if (nrow(weather_df) == 0) {
    stop("Weather data frame is empty.")
  }
  
  results <- weather_df %>% 
    mutate(BIKE_PREDICTION=predict_bike_demand(TEMPERATURE, HUMIDITY, WIND_SPEED, VISIBILITY, SEASONS, HOURS)) %>%
    mutate(BIKE_PREDICTION_LEVEL=calculate_bike_prediction_level(BIKE_PREDICTION))
  
  cities_bike_pred <- cities_df %>% left_join(results, by = c("CITY_ASCII" = "CITY_ASCII")) %>% 
    select(CITY_ASCII, LNG, LAT, TEMPERATURE, HUMIDITY, BIKE_PREDICTION, BIKE_PREDICTION_LEVEL, LABEL, DETAILED_LABEL, FORECASTDATETIME)
  return(cities_bike_pred)
}
