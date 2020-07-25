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

#Create Dataframe function
create_dataframe <- function(file_1, file_2) {
  pest_data <- read.csv(file = file_1)
  pest_data <- pest_data %>% 
    select(use_no, chem_code, lbs_chm_used, applic_dt, county_cd, base_ln_mer,
           township, tship_dir, range, range_dir, section,
           CO_MTR = comtrs) %>% 
    na.omit() %>%
    mutate(CO_MTR = substr(CO_MTR, start = 1, stop = 9))
  
  
  townships <- st_read(dsn = file_2, quiet = T)
  
  merged <- full_join(townships, pest_data, by='CO_MTR')
  colnames(merged)[3:4] <- c("TownshipMTR", "MTR_ID")
  return(merged)
}
#Forming Sac Counties
shapes_list <-c('data/pur2017/udc17_04.txt', 
                'data/pur2017/udc17_11.txt',
                'data/pur2017/udc17_17.txt', 
                'data/pur2017/udc17_32.txt',
                'data/pur2017/udc17_45.txt', 
                'data/pur2017/udc17_51.txt',
                'data/pur2017/udc17_52.txt', 
                'data/pur2017/udc17_57.txt',
                'data/pur2017/udc17_58.txt', 
                'data/pur2017/udc17_06.txt', 
                'data/pur2017/udc17_39.txt', 
                'data/pur2017/udc17_34.txt',
                'data/pur2017/udc17_50.txt', 
                'data/pur2017/udc17_24.txt',
                'data/pur2017/udc17_20.txt', 
                'data/pur2017/udc17_10.txt',
                'data/pur2017/udc17_16.txt', 
                'data/pur2017/udc17_54.txt')
pest_list <-c('data/townships/Butte_townships/mtr_04_nad83.shp',
              'data/townships/Glenn_townships/mtr_11_nad83.shp',
              'data/townships/Lake_townships/mtr_17_nad83.shp',
              'data/townships/Plumas_townships/mtr_32_nad83.shp',
              'data/townships/Shasta_townships/mtr_45_nad83.shp',
              'data/townships/Sutter_townships/mtr_51_nad83.shp',
              'data/townships/Tehama_townships/mtr_52_nad83.shp',
              'data/townships/Yolo_townships/mtr_57_nad83.shp',
              'data/townships/Yuba_townships/mtr_58_nad83.shp',
              'data/townships/Colusa_townships/mtr_06_nad83.shp',
              'data/townships/San_Joaquin_townships/mtr_39_nad83.shp',
              'data/townships/Sacramento_townships/mtr_34_nad83.shp',
              'data/townships/Stanislaus_townships/mtr_50_nad83.shp',
              'data/townships/Merced_townships/Merced_townships_r.shp',
              'data/townships/Madera_townships/mtr_20_nad83.shp',
              'data/townships/Fresno_townships/Fresno_Townships_r.shp',
              'data/townships/Kings_townships/mtr_16_nad83.shp',
              'data/townships/Tulare_townships/mtr_54_nad83.shp')
list_tables <- mapply(create_dataframe, shapes_list, pest_list, SIMPLIFY = FALSE)
create_dataframe('data/pur2017/udc17_04.txt', 'data/townships/Butte_townships/mtr_04_nad83.shp')
sac_counties <- do.call('rbind', list_tables)

#Forming combined cometr to use on leaflet
combined_comtr <- sac_counties %>%  
  group_by(CO_MTR) %>% 
  summarise(lbs_applied_total = sum(lbs_chm_used, na.rm = T))

#save shapefile as r object 
s.sf <- combined_comtr
saveRDS(s.sf, file = "combined_comtr.RDS")

