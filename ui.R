library(shiny)
library(leaflet)

# Define the UI
ui <- fluidPage(
  # Application title and styling
  titlePanel(
    div(
      style = "background-color: #001f3f; padding: 10px; color: #ffffff; font-size: 34px; font-weight: bold; text-align: center; border-radius: 10px 10px 0 0;",
      "Bike-sharing Demand Prediction App"
    )
  ),
  padding = 5,
  
  # Custom CSS for map and popup styling
  tags$head(
    tags$style(
      HTML(".leaflet-container { background: #001f3f; }"),  # Adjust map background color
      HTML(".leaflet-popup-content-wrapper, .leaflet-popup-tip { background: #fde3a7; color: #333333; }")  # Adjust popup styling
    )
  ),
  
  # Create a sidebar layout
  sidebarLayout(
    # Create a sidebar to select a city
    sidebarPanel(
      style = "background-color: #001f3f; color: #ffffff; padding: 10px; border-radius: 0 0 10px 0; box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);",
      h3(style = "text-align: center; margin-bottom: 20px;", "Select a City"),
      div(
        style = "margin-bottom: 20px;",
        selectInput(
          "city_dropdown",  # Update input ID
          label = NULL,  # No label to save space
          choices = c("All", "Seoul", "Suzhou", "London", "New York", "Paris"),  # Updated city names
          selected = "All"  # Set default selected city
        )
      ),
      plotOutput("bike_line", height = "300px", click = "plot_click"),  # Output plot for bike prediction trend line
      plotOutput("humidity_pred_chart", height = "300px"),  # Output plot for humidity vs bike prediction
      plotOutput("temp_line", height = "300px"),  # Output plot for temperature trend
      verbatimTextOutput("bike_date_output")  # Output for clicked plot data
    ),
    
    # Create a main panel to show the leaflet map
    mainPanel(
      leafletOutput("city_bike_map", height = 800),
      style = "border-radius: 0 10px 10px 0; box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);"
    )
  )
)