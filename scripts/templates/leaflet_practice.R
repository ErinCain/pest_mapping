#leaflet practice
install.packages("tmap")
install.packages("tmaptools")
install.packages("sf")
install.packages("leaflet")
install.packages("mapview")
library("tmap")
library("tmaptools")
library("sf")
library("leaflet")
library("mapview")
#leaflet('alameda_twnships') 

date_applications <-udc17_01

date_applications <- as.data.frame.matrix(date_applications) 
unique(date_applications$chem_code)
date_applications <- date_applications %>% 
  select(use_no, chem_code, lbs_chm_used, applic_dt, county_cd, base_ln_mer,
         township, tship_dir,
         range, range_dir,
         section) %>% 
  na.omit()

date_applications$county_cd <- sprintf("%02d", as.numeric(date_applications$county_cd))
date_applications$township <- sprintf("%02d", as.numeric(date_applications$township))
date_applications$range <- sprintf("%02d", as.numeric(date_applications$range))

#date_applications$CO_MTR = paste(date_applications$county_cd,date_applications$base_ln_mer,
#                                  date_applications$township, date_applications$tship_dir,
#                                  date_applications$range, date_applications$range_dir,
#                                  date_applications$section, sep="")

date_applications$CO_MTR = paste(date_applications$county_cd, date_applications$base_ln_mer,
                                 date_applications$township, date_applications$tship_dir,
                                 date_applications$range, date_applications$range_dir, sep="")
#date_applications$CO_MTR <- as.numeric(date_applications$CO_MTR)

date_applications %>% 
  select(use_no, chem_code, lbs_chm_used, applic_dt, CO_MTR)

alameda_twnships <- "/Users/ErinCain/Downloads/Alameda_townships/mtr_01_nad83.shp"
alameda_twnships <- read_shape(file=alameda_twnships, as.sf = TRUE)

merged_alameda <- full_join(alameda_twnships, date_applications, by='CO_MTR')
merged_alameda

s.sf <- merged_alameda

library(leaflet)
colors <- c('#fed98e', '#fe9929', '#d95f0e', '#993404')
mypalette <- colorBin(palette = colors, domain = s.sf$lbs_chem_used)
alameda_popup <- paste0("Township:", s.sf$CO_MTR, "Pounds Chemicals Applied", s.sf$lbs_chm_used)
alameda_projected <- sf::st_transform(s.sf, '+proj=longlat +datum=WGS84')

leaflet(alameda_projected) %>%
  addProviderTiles("CartoDB.Positron" ) %>%
  addPolygons(stroke = FALSE, 
              smoothFactor = .2,
              fillOpacity = .8, 
              popup = alameda_popup, 
              color = ~ mypalette(s.sf$lbs_chm_used))

