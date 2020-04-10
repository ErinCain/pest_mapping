library(shiny)
library(leaflet)
for (pkg in c("leaflet", "rgdal", "dataRetrieval")) {
  if (!pkg %in% rownames(utils::installed.packages()))
    utils::install.packages(pkg, repos = "https://cloud.r-project.org/")
}
grp <- c("USGS Topo", "USGS Imagery Only", "USGS Imagery Topo", "USGS Shaded Relief", "Hydrography")
att <- paste0("<a href='https://www.usgs.gov/'>",
              "U.S. Geological Survey</a> | ",
              "<a href='https://www.usgs.gov/laws/policies_notices.html'>",
              "Policies</a>")

ui <- bootstrapPage(
  tags$style(type = "text/css", "html, body {width:100%;height:100%}"),
  
  # Map output with map sizing 
  leafletOutput("map", width = "100%", height = "100%"),
  
  #Slider input for changing CSCI Scores 
  absolutePanel(top = 150, right = 10,
                sliderInput("range", "CSCI Scores",  
                            sort(csci_scored_sites_tbl_1_$CSCI, decreasing = FALSE)[1], 
                            sort(csci_scored_sites_tbl_1_$CSCI, decreasing = TRUE)[1],
                            value = range(csci_scored_sites_tbl_1_$CSCI), step = 0.1)) 
  #If I want to make slider for pesticide application 
  #  absolutePanel(top = 200, right = 10,
  #                sliderInput("range_pest", "Lbs Pesticide Applied",  
  #                            sort(combined_comtr_projected$lbs_applied_total, decreasing = FALSE)[1], 
  #                            sort(combined_comtr_projected$lbs_applied_total, decreasing = TRUE)[1],
  #                            value = range(combined_comtr_projected$lbs_applied_total), step = 0.1))
)

server <- function(input, output, session) {
  
  library(leaflet)
  library(dplyr)
  ## USGS TOPO DATA 
  GetURL <- function(service, host = "basemap.nationalmap.gov") { 
    sprintf("https://%s/arcgis/services/%s/MapServer/WmsServer", host, service)
  }
  ### Data prep for pesticide application data 
  s.sf <- combined_comtr
  colors <- c('#fed98e', '#fe9929', '#d95f0e', '#993404')
  mypalette <- colorBin(palette = colors, domain = s.sf$lbs_applied_total)
  popup <- paste0("Township:", s.sf$CO_MTR, "Pounds Chemicals Applied", s.sf$lbs_applied_total)
  combined_comtr_projected <- sf::st_transform(s.sf, '+proj=longlat +datum=WGS84')
  
  bins <- c(0, 100, 500, 1000, 5000, 10000, 100000, 400000, Inf)
  pal <- colorBin("YlOrRd", domain = s.sf$lbs_applied_total, bins = bins)
  labels <- sprintf("Township Label <strong>%s</strong><br/>%g lbs / township",
                    s.sf$CO_MTR, s.sf$lbs_applied_total) %>% lapply(htmltools::HTML)

  csci_scored_sites_tbl_1_ <- 
    read_excel("/Users/ErinCain/Documents/pest_mapping/data/CSCI_scores/csci_scored_sites_tbl (1).xlsx")
  
  csci_scored_sites_tbl_1_ %>% 
    transform(CSCI = as.numeric(csci_scored_sites_tbl_1_$CSCI)) 
  
  mutate(csci_scored_sites_tbl_1_, group = cut(CSCI, breaks = c(0, .5, .75, 1, Inf), labels = c("red", "orange","yellow", "green"))) -> csci_scored_sites_tbl_1_
  
  # H20 ICONS 
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
        group = 'Pesticide Application',
        # Label For Hover With Lbs information 
        labelOptions = labelOptions(
          style = list("font-weight" = "normal", padding = "3px 8px"),
          textsize = "15px",
          direction = "auto")) %>% 
      #Legend for TOTAL LBS APPLIED 
      addLegend(pal = pal, values = ~lbs_applied_total, opacity = 0.7, title = "Total lbs Chem Applied",
                position = "bottomright") %>%
      #CSCI Scores - adds a marker for each csci site and gives the score. Makers are clustered in groups 
      addMarkers(data = csci_scored_sites_tbl_1_, clusterOptions = 
                   markerClusterOptions(), 
                 icon= ~H20Icons[group], label = ~as.character(CSCI), 
                 group = "California Stream Condition Index CSCI Scores") %>%
      #Attempt to add markers of CEDEN sites...but not showing up
      # addMarkers(data = CEDEN_cite_id, label = ~as.character(total_tu), group = "CEDEN Sites") %>%
      # Layers control
      addLayersControl(
        baseGroups = c("Base Map"),
        overlayGroups = c("Pesticide Application", 
                          "CEDEN Sites", "USGS Topo", "Hydrography"),
        options = layersControlOptions(collapsed = FALSE) 
      )
    })
  
  # Incremental changes to the map Preformed in the observer (filtering CSCI scores and pest app pounds)
  observeEvent(input$range, {
    leafletProxy("map") %>%
      clearMarkers() %>%
      clearMarkerClusters() %>%
      addMarkers(data = filteredData(), icon= ~H20Icons[group], clusterOptions = markerClusterOptions(),
                 label = ~as.character(CSCI))
  })
  }
shinyApp(ui, server)
