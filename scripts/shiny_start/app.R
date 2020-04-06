library(shiny)
library(leaflet)

r_colors <- rgb(t(col2rgb(colors()) / 255))
names(r_colors) <- colors()

ui <- fluidPage(
  leafletOutput("mymap")
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
  #labels <- paste0("<strong> Township </strong>", 
  #                      s.sf$CO_MTR, 
  #                      "<br><strong> Lbs of chem applied 2017: </strong>", 
  #                      s.sf$lbs_applied_total)
  ### Data prep for CSCI score map 
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

  
  output$mymap <- renderLeaflet(
    leaflet(combined_comtr_projected) %>%
      addProviderTiles("CartoDB.Positron" ) %>% addPolygons(
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
        labelOptions = labelOptions(
          style = list("font-weight" = "normal", padding = "3px 8px"),
          textsize = "15px",
          direction = "auto")) %>% 
      addLegend(pal = pal, values = ~lbs_applied_total, opacity = 0.7, title = "Total lbs Chem Applied",
                position = "bottomright") %>%
      addMarkers(data = csci_scored_sites_tbl_1_, clusterOptions = markerClusterOptions(), 
                 icon= ~H20Icons[group], 
                 label = ~as.character(CSCI))
  )
  }

shinyApp(ui, server)