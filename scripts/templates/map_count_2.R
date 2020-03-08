#leaflet practice
library("tmap")
library("tmaptools")
library("sf")
library("leaflet")
library("mapview")

#leaflet('alameda_twnsips') 

alpine_pest <-udc17_02

alpine_pest <- as.data.frame.matrix(alpine_pest) 
unique(alpine_pest$chem_code)
alpine_pest <- alpine_pest %>% select(use_no, chem_code, lbs_chm_used, applic_dt, county_cd, base_ln_mer,
         township, tship_dir,
         range, range_dir,
         section) %>% na.omit()

alpine_pest$county_cd <- sprintf("%02d", as.numeric(alpine_pest$county_cd))
alpine_pest$township <- sprintf("%02d", as.numeric(alpine_pest$township))
alpine_pest$range <- sprintf("%02d", as.numeric(alpine_pest$range))

#date_applications$CO_MTR = paste(date_applications$county_cd,date_applications$base_ln_mer,
#                                  date_applications$township, date_applications$tship_dir,
#                                  date_applications$range, date_applications$range_dir,
#                                  date_applications$section, sep="")

alpine_pest$CO_MTR = paste(alpine_pest$county_cd, alpine_pest$base_ln_mer,
                                 alpine_pest$township, alpine_pest$tship_dir,
                                 alpine_pest$range, alpine_pest$range_dir, sep="")
#date_applications$CO_MTR <- as.numeric(date_applications$CO_MTR)

alpine_pest %>% 
  select(use_no, chem_code, lbs_chm_used, applic_dt, CO_MTR)

alpine_twnships <- "/Users/ErinCain/Downloads/Alpine_townships/mtr_02_nad83.shp"

alpine_twnships <- read_shape(file=alpine_twnships, as.sf = TRUE)

merged_alpine <- full_join(alpine_twnships, alpine_pest, by='CO_MTR')
merged_alpine


s.sf <- merged_alpine

library(leaflet)
colors <- c('#fed98e', '#fe9929', '#d95f0e', '#993404')
mypalette <- colorBin(palette = colors, domain = s.sf$lbs_chem_used)
alpine_popup <- paste0("Township:", s.sf$CO_MTR, "Pounds Chemicals Applied", s.sf$lbs_chm_used)
alpine_projected <- sf::st_transform(s.sf, '+proj=longlat +datum=WGS84')

leaflet(alpine_projected) %>%
  addProviderTiles("CartoDB.Positron" ) %>%
  addPolygons(stroke = FALSE, 
              smoothFactor = .2,
              fillOpacity = .8, 
              popup = alpine_popup, 
              color = ~ mypalette(s.sf$lbs_chm_used))

