library(shiny)
library(leaflet)
library(sf)
library(sp)
library(readtext)
library(tidyverse)
library(dplyr)
library(tidyverse)
library(readr)
library(readxl)
library(shinythemes)

# Load data for usgs topo map and hdrolog map to r 
grp <- c("USGS Topo", "USGS Imagery Only", "USGS Imagery Topo", "USGS Shaded Relief", "Hydrography")
att <- paste0("<a href='https://www.usgs.gov/'>",
              "U.S. Geological Survey</a> | ",
              "<a href='https://www.usgs.gov/laws/policies_notices.html'>",
              "Policies</a>")

# Define csci scores table from excel
csci_scored_sites_tbl_1_ <- 
  readxl::read_excel("./data/CSCI_scores/csci_scored_sites.xlsx")

# Define combined_comtrs from RDS file 
combined_comtrs <- 
  readRDS("data/combined_comtr.RDS")

# Server with leaflet map design 
server <- function(input, output, session) {
  
  library(leaflet)
  library(dplyr)
  
  ## USGS TOPO DATA 
  
  GetURL <- function(service, host = "basemap.nationalmap.gov") { 
    sprintf("https://%s/arcgis/services/%s/MapServer/WmsServer", host, service)
  }
  
  ### Data prep for pesticide application data 
  s.sf <- combined_comtrs
  colors <- c('#fed98e', '#fe9929', '#d95f0e', '#993404')
  mypalette <- colorBin(palette = colors, domain = s.sf$lbs_applied_total)
  popup <- paste0("Township:", s.sf$CO_MTR, "Pounds Chemicals Applied", s.sf$lbs_applied_total)
  combined_comtr_projected <- sf::st_transform(s.sf, '+proj=longlat +datum=WGS84')
  
  bins <- c(0, 100, 500, 1000, 5000, 10000, 100000, 400000, Inf)
  pal <- colorBin("YlOrRd", domain = s.sf$lbs_applied_total, bins = bins)
  labels <- sprintf("Township Label <strong>%s</strong><br/>%g lbs / township",
                    s.sf$CO_MTR, s.sf$lbs_applied_total) %>% lapply(htmltools::HTML)
  
  csci_scored_sites_tbl_1_ <- 
    readxl::read_excel("./data/CSCI_scores/csci_scored_sites.xlsx")
  
  csci_scored_sites_tbl_1_ = csci_scored_sites_tbl_1_ %>%
    mutate(CSCI = as.numeric(CSCI),
           group = cut(CSCI, breaks = c(0, .5, .75, 1, Inf), labels = c("red", "orange","yellow", "green")))
  
  # H20 ICONS 
  H20Icons <- iconList(
    red = makeIcon(
      "./data/CSCI_scores/RedDrop.png",
      iconWidth = 38, iconHeight = 95,
      iconAnchorX = 22, iconAnchorY = 94),# iconWidth = 30, iconHeight = 30),
    orange = makeIcon(
      "./data/CSCI_scores/yellowDrop.png", iconWidth = 38, iconHeight = 95,
      iconAnchorX = 22, iconAnchorY = 94),#, iconWidth = 30, iconHeight = 30),
    orange = makeIcon(
      "./data/CSCI_scores/orangeDrop.png",  iconWidth = 38, iconHeight = 95,
      iconAnchorX = 22, iconAnchorY = 94),# iconWidth = 30, iconHeight = 30),
    green = makeIcon(
      "./data/CSCI_scores/greenDrop.png",  iconWidth = 38, iconHeight = 95,
      iconAnchorX = 22, iconAnchorY = 94))
  
  filteredData <- reactive({
    csci_scored_sites_tbl_1_[csci_scored_sites_tbl_1_$CSCI >= input$range[1] & 
                               csci_scored_sites_tbl_1_$CSCI <= input$range[2],]
  })
  
  # Create Leaflet map 
  # 
  # <span style="padding-right:3px; padding-top: 3px; display:inline-block;">
  #   
  #   <img class="manImg" src="./data/CSCI_scores/greenDrop.png"></img>
  #   
  #   </span>
  
  marker_js <- JS("function(cluster) {
                  var html = '<div style=\"background-color:rgba(87, 202, 222, 0.9)\"><span>' + '' + '</div><span>'
                  return new L.DivIcon({html: html, className: 'marker-cluster'});
                  }")
  
  output$map <- renderLeaflet({
    leaflet(combined_comtr_projected) %>% 
      #Base Group
      addProviderTiles("CartoDB.Positron", group = "Base Map" ) %>% 
      # USGS Map
      addWMSTiles(GetURL("USGSTopo"), group = "USGS Topo", layers ="0") %>%
      # Hydro Map added
      addWMSTiles(GetURL("USGSHydroCached"), group = "Hydrography", 
                  options = WMSTileOptions(format = "image/png", transparent = TRUE), layers = "0") %>%
      #Pesticide Application Shapes
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
        group = 'Pesticide Application per Township',
        # Label For Hover With Lbs information 
        labelOptions = labelOptions(
          style = list("font-weight" = "normal", padding = "3px 8px"),
          textsize = "15px",
          direction = "auto")) %>% 
      #Legend for TOTAL LBS APPLIED 
      addLegend(pal = pal, values = ~lbs_applied_total, opacity = 0.7, title = "Total lbs Chem Applied",
                position = "bottomright") %>%
      #CSCI Scores - adds a marker for each csci site and gives the score. Makers are clustered in groups 
      addCircleMarkers(data = filteredData(), 
                       label = ~as.character(CSCI), 
                       color = ~group,
                       radius = 15,
                       opacity = .8,
                       fillOpacity = .5,
                       clusterOptions = markerClusterOptions(iconCreateFunction = marker_js), labelOptions = labelOptions(opacity = 0)) %>%
      # addMarkers(data = filteredData(), icon= ~H20Icons[group], label = ~as.character(CSCI), 
      #            # layerId = 'markers',
      #            # clusterId = ~COUNTY,
      #            clusterOptions =   markerClusterOptions(), 
      #            group = "California Stream Condition Index CSCI Scores") %>%
      addLayersControl(
        baseGroups = c("Base Map"),
        overlayGroups = c("Pesticide Application per Township", 
                          "USGS Topo", "Hydrography"),
        options = layersControlOptions(collapsed = FALSE) 
      )
  })
  
  
  
  # Incremental changes to the map Performed in the observer (filtering CSCI scores and pest app pounds)
    # observeEvent(input$range, {
    #   leafletProxy("map") %>%
    #     removeMarker(layerId = 'markers') %>%
    #     removeMarkerCluster(layerId = 'markers') %>%
    #     #clearMarkerClusters() %>%
    #     addCircleMarkers(data = filteredData(), 
    #                      label = ~as.character(CSCI), 
    #                      color = ~group,
    #                      radius = 20,
    #                      opacit = .8,
    #                      fillOpacity = .5,
    #                      clusterOptions = markerClusterOptions(iconCreateFunction = marker_js))
    #     # addMarkers(data = filteredData(), icon= ~H20Icons[group],
    #     #            clusterOptions =   markerClusterOptions(iconCreateFunction = marker_js),
    #     #            label = ~as.character(CSCI))
    # })
}


#UI design of app and about page 

ui <- navbarPage("Pesticide Application and CSCI Index", theme = shinytheme("simplex"),
                 tabPanel("Map", tags$style(type = "text/css", "html, body {width:100%;height:100%}"),
                          leafletOutput("map", width = "100%", height = "750px"),
                          absolutePanel(top = 180, right = 10,
                                        sliderInput("range", "CSCI Scores",  min = 0, max = 1.6,
                                                    value = range(csci_scored_sites_tbl_1_$CSCI), step = 0.1))), 
                 tabPanel("About", includeMarkdown("about.Rmd")))

shinyApp(ui, server)
