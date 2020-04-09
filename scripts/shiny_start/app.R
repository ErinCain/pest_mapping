library(shiny)
library(leaflet)

r_colors <- rgb(t(col2rgb(colors()) / 255))
names(r_colors) <- colors()

ui <- bootstrapPage(
  tags$style(type = "text/css", "html, body {width:100%;height:100%}"),
  leafletOutput("map", width = "100%", height = "100%"),
  absolutePanel(top = 100, right = 10,
                sliderInput("range", "CSCI Scores",  
                            sort(csci_scored_sites_tbl_1_$CSCI, decreasing = FALSE)[1], 
                            sort(csci_scored_sites_tbl_1_$CSCI, decreasing = TRUE)[1],
                            value = range(csci_scored_sites_tbl_1_$CSCI), step = 0.1)) 
  #  absolutePanel(top = 200, right = 10,
  #                sliderInput("range_pest", "Lbs Pesticide Applied",  
  #                            sort(combined_comtr_projected$lbs_applied_total, decreasing = FALSE)[1], 
  #                            sort(combined_comtr_projected$lbs_applied_total, decreasing = TRUE)[1],
  #                            value = range(combined_comtr_projected$lbs_applied_total), step = 0.1))
)

server <- function(input, output, session) {
  
  library(leaflet)
  library(dplyr)
  
  ### Data prep for pesticide application data 
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

  csci_scored_sites_tbl_1_ <- 
    read_excel("/Users/ErinCain/Documents/pest_mapping/data/CSCI_scores/csci_scored_sites_tbl (1).xlsx")
  
  csci_scored_sites_tbl_1_ %>% 
    transform(CSCI = as.numeric(csci_scored_sites_tbl_1_$CSCI)) 
  
  mutate(csci_scored_sites_tbl_1_, group = cut(CSCI, breaks = c(0, .5, .75, 1, Inf), labels = c("red", "orange","yellow", "green"))) -> csci_scored_sites_tbl_1_
  
  
  H20Icons <- iconList(red = makeIcon(
    "/Users/ErinCain/Documents/pest_mapping/data/CSCI_scores/RedDrop.png", 
    iconWidth = 30, iconHeight = 30),
    orange = makeIcon(
      "/Users/ErinCain/Documents/pest_mapping/data/CSCI_scores/yellowDrop.png",
      iconWidth = 30, iconHeight = 30),
    orange = makeIcon(
      "/Users/ErinCain/Documents/pest_mapping/data/CSCI_scores/orangeDrop.png",
      iconWidth = 30, iconHeight = 30),
    green = makeIcon(
      "/Users/ErinCain/Documents/pest_mapping/data/CSCI_scores/greenDrop.png", 
      iconWidth = 30, iconHeight = 30))

  
  filteredData <- reactive({
    csci_scored_sites_tbl_1_[csci_scored_sites_tbl_1_$CSCI >= input$range[1] & 
                               csci_scored_sites_tbl_1_$CSCI <= input$range[2],]
  })
  #  filteredPest <- reactive({
  #    combined_comtr_projected[combined_comtr_projected$lbs_applied_total >= input$range_pest[1] & 
  #                               combined_comtr_projected$lbs_applied_total <= input$range_pest[2],]
  #  })
  
  output$map <- renderLeaflet({
    leaflet(combined_comtr_projected) %>% 
      #Base Group
      addProviderTiles("CartoDB.Positron", group = "Base Map" ) %>% 
      #Pesticide Application 
      addPolygons(
        fillColor = ~pal(lbs_applied_total),
        weight = .05,
        opacity = 1,
        color = "white",
        dashArray = "3",
        fillOpacity = 0.7,
        highlight = highlightOptions(
          weight = 5,
          color = "#666",
          dashArray = "",
          fillOpacity = 0.7,
          bringToFront = TRUE),
        label = labels,
        group = 'Pesticide Application',
        # Label For Hover 
        labelOptions = labelOptions(
          style = list("font-weight" = "normal", padding = "3px 8px"),
          textsize = "15px",
          direction = "auto")) %>% 
      #Legend for TOTAL LBS APPLIED 
      addLegend(pal = pal, values = ~lbs_applied_total, opacity = 0.7, title = "Total lbs Chem Applied",
                position = "bottomright") %>%
      #CSCI Scores
      addMarkers(data = csci_scored_sites_tbl_1_, clusterOptions = 
                   markerClusterOptions(freezeAtZoom = 500, 
                                        iconCreateFunction = JS(" function(cluster) {
                                                                return new L.DivIcon({
                                                                html: '<div style=\"background-color:rgba(77,77,77,0.5)\"><span>' + cluster.getChildCount() + '</div><span>',
                                                                className: 'marker-cluster'
                                                                });}")), 
                 icon= ~H20Icons[group], label = ~as.character(CSCI), 
                 group = "California Stream Condition Index CSCI Scores") %>%
      addMarkers(data = CEDEN_cite_id, label = ~as.character(total_tu), group = "CEDEN Sites") %>%
      # Layers control
      addLayersControl(
        baseGroups = c("Base Map"),
        overlayGroups = c("Pesticide Application", "California Stream Condition Index CSCI Scores", "CEDEN Sites"),
        options = layersControlOptions(collapsed = FALSE) 
      )
    })
  
  # Incremental changes to the map Preformed in the observer (filtering CSCI scores and pest app pounds)
  observeEvent(input$range, {
    leafletProxy("map") %>%
      clearMarkers() %>%
      clearMarkerClusters() %>%
      addMarkers(data = filteredData(), icon= ~H20Icons[group], clusterOptions = markerClusterOptions(color = "blue"),
                 label = ~as.character(CSCI))
  })
  # Incremental changes to the map Preformed in the observer (app pounds)  
  #  observeEvent(input$range_pest, {
  #    leafletProxy("map") %>%
  #      clearShapes() %>%
  #      addPolygons(data = filteredPest(), 
  #                  fillColor = ~pal(lbs_applied_total), 
  #                  weight = .05, opacity = 1, color = "white", 
  #                  dashArray = "3", 
  #                  fillOpacity = 0.7, 
  #                  highlight = highlightOptions(weight = 5, color = "#666", dashArray = "", 
  #                                                                  fillOpacity = 0.7, bringToFront = TRUE), 
  #                  label = labels, 
  #                  group = 'Pesticide Application', labelOptions = labelOptions(style = 
  #                                                                                list("font-weight" = "normal", 
  #                                                                                     padding = "3px 8px"), 
  #                                                                              textsize = "15px", 
  #                                                                             direction = "auto")) %>% 
  #Legend for TOTAL LBS APPLIED 
  #    addLegend(pal = pal, values = ~lbs_applied_total, opacity = 0.7, title = "Total lbs Chem Applied",
  #              position = "bottomright")
  #  })
  }
shinyApp(ui, server)
