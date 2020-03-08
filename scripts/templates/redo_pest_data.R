library(readr)
library(magrittr)
udc17_01 <- read_csv("documents/pest_mapping/mapping_practice/data/pest_data/udc17_01.txt")
date_applications <- udc17_01

#unique(date_applications$chem_code)

date_applications <- date_applications[1:10,]
date_applications

date_applications <- date_applications %>% select(use_no, chem_code, lbs_chm_used, applic_dt, county_cd, base_ln_mer,
         township, tship_dir,
         range, range_dir,
         section) %>% 
  na.omit()

#date_applications$county_cd <- sprintf("%02d", as.numeric(date_applications$county_cd))
#date_applications$township <- sprintf("%02d", as.numeric(date_applications$township))
#date_applications$range <- sprintf("%02d", as.numeric(date_applications$range))

#date_applications$CO_MTR = paste(date_applications$county_cd,date_applications$base_ln_mer,
 #                                 date_applications$township, date_applications$tship_dir,
  #                                date_applications$range, date_applications$range_dir,
  #                                date_applications$section, sep="")

#date_applications$CO_MTR = paste(date_applications$county_cd, date_applications$base_ln_mer,
#                                 date_applications$township, date_applications$tship_dir,
#                                 date_applications$range, date_applications$range_dir, sep="")
#date_applications$CO_MTR <- as.numeric(date_applications$CO_MTR)

#date_applications %>% 
#  select(use_no, chem_code, lbs_chm_used, applic_dt, CO_MTR)
