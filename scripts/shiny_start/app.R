library(shiny)
library(leaflet)

r_colors <- rgb(t(col2rgb(colors()) / 255))
names(r_colors) <- colors()

ui <- fluidPage(
  leafletOutput("mymap"),
  p(),
  actionButton("recalc", "New points")
)

server <- function(input, output, session) {
  
  
  points <- eventReactive(input$recalc, { cbind(rnorm(40) * 2 + 13, 
                                                rnorm(40) + 48)}, ignoreNULL = FALSE)
  library(leaflet)
  s.sf <- combined_comtr
  colors <- c('#fed98e', '#fe9929', '#d95f0e', '#993404')
  mypalette <- colorBin(palette = colors, domain = s.sf$lbs_applied_total)
  popup <- paste0("Township:", s.sf$CO_MTR, "Pounds Chemicals Applied", s.sf$lbs_applied_total)
  combined_comtr_projected <- sf::st_transform(s.sf, '+proj=longlat +datum=WGS84')
  
  bins <- c(0, 100, 500, 1000, 5000, 10000, 100000, 400000, Inf)
  pal <- colorBin("YlOrRd", domain = s.sf$lbs_applied_total, bins = bins)
  labels <- sprintf("Township Label <strong>%s</strong><br/>%g lbs / township",
                    s.sf$CO_MTR, s.sf$lbs_applied_total) %>% 
    lapply(htmltools::HTML)
  
  output$mymap <- leaflet(combined_comtr_projected) %>%
    addProviderTiles("CartoDB.Positron" ) %>% addPolygons(
      fillColor = ~pal(lbs_applied_total),
      weight = .05,
      opacity = 1,
      color = "white",
      dashArray = "3",
      fillOpacity = 0.5,
      highlight = highlightOptions(
        weight = 5,
        color = "#666",
        dashArray = "",
        fillOpacity = 0.7,
        bringToFront = TRUE),
      label = labels,
      labelOptions = labelOptions(
        style = list("font-weight" = "normal", padding = "3px 8px"),
        textsize = "15px",
        direction = "auto")) %>% 
    addLegend(pal = pal, values = ~lbs_applied_total, opacity = 0.7, title = "Total lbs Chem Applied",
              position = "bottomright")
  }

shinyApp(ui, server)