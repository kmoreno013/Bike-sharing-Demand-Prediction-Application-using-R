library(shiny)
library(leaflet)
library(dplyr)
library(ggplot2)

# Assuming you have defined cities_max_bike dataframe with required fields

# Define color factor
color_levels <- colorFactor(c("green", "yellow", "red"), levels = c("small", "medium", "large"))

# Function to test weather data generation
test_weather_data_generation <- function() {
  # Generate or retrieve city_weather_bike_df
  # Replace this with your actual function or data import logic
  city_weather_bike_df <- generate_city_weather_bike_data()
  return(city_weather_bike_df)
}

# Clean and process weather data
clean_and_process_weather_data <- function(city_weather_bike_df) {
  # Extracting Temperature, Visibility, Humidity, Wind Speed, and Datetime using regular expressions
  city_weather_bike_df$TEMPERATURE <- as.numeric(gsub(".*Temperature: (\\d+\\.\\d+) C.*", "\\1", city_weather_bike_df$DETAILED_LABEL, perl = TRUE))
  city_weather_bike_df$VISIBILITY <- as.numeric(gsub(".*Visibility: (\\d+) m.*", "\\1", city_weather_bike_df$DETAILED_LABEL, perl = TRUE))
  city_weather_bike_df$HUMIDITY <- as.numeric(gsub(".*Humidity: (\\d+) %.*", "\\1", city_weather_bike_df$DETAILED_LABEL, perl = TRUE))
  city_weather_bike_df$WIND_SPEED <- as.numeric(gsub(".*Wind Speed: (\\d+\\.\\d+) m/s.*", "\\1", city_weather_bike_df$DETAILED_LABEL, perl = TRUE))
  city_weather_bike_df$FORECAST_DATETIME <- as.POSIXct(gsub(".*Datetime: (\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}) .*", "\\1", city_weather_bike_df$DETAILED_LABEL, perl = TRUE), format = "%Y-%m-%d %H:%M:%S")
  
  # Clean up city_weather_bike_df: Remove rows with NA values in critical weather columns
  city_weather_bike_df <- city_weather_bike_df %>%
    filter(!is.na(TEMPERATURE) & !is.na(VISIBILITY) & !is.na(HUMIDITY) & !is.na(WIND_SPEED) & !is.na(FORECAST_DATETIME))
  
  return(city_weather_bike_df)
}

# Create a Shiny server
shinyServer(function(input, output, session) {
  
  # Test generate_city_weather_bike_data() function
  city_weather_bike_df <- test_weather_data_generation()
  city_weather_bike_df <- clean_and_process_weather_data(city_weather_bike_df)
  
  # Calculate cities_max_bike dataframe
  cities_max_bike <- city_weather_bike_df %>%
    group_by(CITY_ASCII) %>%
    summarise(
      max_bike_prediction = max(BIKE_PREDICTION, na.rm = TRUE),
      lat = mean(LAT, na.rm = TRUE),
      lng = mean(LNG, na.rm = TRUE),
      LABEL = unique(gsub("<b><a href=''>.*?</a></b></br><b>(.*?)</b></br>", "\\1", LABEL, perl = TRUE)),
      TEMPERATURE = mean(TEMPERATURE, na.rm = TRUE),
      VISIBILITY = mean(VISIBILITY, na.rm = TRUE),
      HUMIDITY = mean(HUMIDITY, na.rm = TRUE),
      WIND_SPEED = mean(WIND_SPEED, na.rm = TRUE),
      FORECAST_DATETIME = max(FORECAST_DATETIME, na.rm = TRUE)  # Assuming you want the latest datetime
    )
  
  # Calculate BIKE_PREDICTION_LEVEL
  cities_max_bike <- cities_max_bike %>%
    mutate(
      BIKE_PREDICTION_LEVEL = case_when(
        max_bike_prediction <= 50 ~ "small",
        max_bike_prediction <= 100 ~ "medium",
        TRUE ~ "large"
      )
    )
  
  # Observe drop-down event
  observeEvent(input$city_dropdown, {
    selected_city <- input$city_dropdown
    
    if (selected_city == "All") {
      output$city_bike_map <- renderLeaflet({
        leaflet(cities_max_bike) %>%
          addTiles() %>%
          addCircleMarkers(
            ~lng, ~lat,
            radius = ~ifelse(BIKE_PREDICTION_LEVEL == "small", 6,
                             ifelse(BIKE_PREDICTION_LEVEL == "medium", 10, 12)),
            fillColor = ~color_levels(BIKE_PREDICTION_LEVEL),
            color = "#000000",
            stroke = TRUE,
            weight = 1,
            fillOpacity = 0.7,
            popup = ~paste0("City: ", CITY_ASCII, "<br>Weather: ", LABEL, "<br>Max Bike Prediction: ", max_bike_prediction)
          )
      })
      
      plot_data <- city_weather_bike_df
    } else {
      city_data <- filter(cities_max_bike, CITY_ASCII == selected_city)
      
      output$city_bike_map <- renderLeaflet({
        leaflet(city_data) %>%
          addTiles() %>%
          addMarkers(
            ~lng, ~lat,
            popup = ~paste0("City: ", CITY_ASCII, "<br>Weather: ", LABEL, "<br>Max Bike Prediction: ", max_bike_prediction,
                            "<br>Temperature: ", TEMPERATURE, " C",
                            "<br>Visibility: ", VISIBILITY, " m",
                            "<br>Humidity: ", HUMIDITY, " %",
                            "<br>Wind Speed: ", WIND_SPEED, " m/s")
          )
      })
      
      plot_data <- filter(city_weather_bike_df, CITY_ASCII == selected_city)
    }
    
    # Render temperature trend plot
    output$temp_line <- renderPlot({
      ggplot(plot_data, aes(x = FORECAST_DATETIME, y = TEMPERATURE)) +
        geom_line(color = "blue") +
        geom_point(color = "red") +
        geom_text(aes(label = round(TEMPERATURE, 1)), vjust = -1, hjust = 0.5) +
        labs(title = paste("Temperature Trend in", selected_city), x = "DateTime", y = "Temperature (C)") +
        theme_minimal()
    })
    
    # Render bike prediction trend plot
    output$bike_line <- renderPlot({
      ggplot(plot_data, aes(x = FORECAST_DATETIME, y = BIKE_PREDICTION)) +
        geom_line(color = "green") +
        geom_point(color = "orange") +
        geom_text(aes(label = round(BIKE_PREDICTION, 1)), vjust = -1, hjust = 0.5) +
        labs(title = paste("Bike-sharing Demand Prediction Trend in", selected_city), x = "DateTime", y = "Bike Prediction") +
        theme_minimal()
    })
    
    # Render humidity vs bike prediction plot
    output$humidity_pred_chart <- renderPlot({
      ggplot(plot_data, aes(x = HUMIDITY, y = BIKE_PREDICTION)) +
        geom_point(color = "purple") +
        geom_smooth(method = "lm", formula = y ~ poly(x, 4), color = "darkblue") +
        labs(title = paste("Humidity vs Bike Prediction in", selected_city), x = "Humidity (%)", y = "Bike Prediction") +
        theme_minimal()
    })
  })
  
  # Render text output for clicked plot data
  output$bike_date_output <- renderText({
    click <- input$plot_click
    if (is.null(click)) {
      return("Click on the plot to see the details.")
    } else {
      paste("DateTime:", click$x, "\nBike Prediction:", click$y)
    }
  })
})
