# make an ELCOM file from the targets file
# Author: Adrienne Breef-Pilz
# Create: 28 Mar 2024
# Edit: 24 Sept. 2024- made it for all files 



# packages
pacman::p_load(tidyverse, here)

convert_elcom_files <- function(
    data, 
    column_header, 
    start_time,
    outfile)
{
  
  # Use the here function to get the working directory 
  wd <- here()
  
# pivot wider

wide_inflow <- data |>
  select(datetime, variable, observation)|>
  pivot_wider(id_cols=datetime, names_from = variable, values_from = observation)

# order datetime
wide_inflow <- wide_inflow[order(wide_inflow$datetime),]

# change datetime from EST to UTC
wide_in <- wide_inflow|>
  filter(datetime>as.Date(start_time))|>
  mutate(sampledatetime_local = force_tz(as.POSIXct(datetime), tz="EST", roll_dst = c('pre'))) |>  ## ADDED PRE TO FIX NA ISSUE
  mutate(sampledatetime_utc = with_tz(sampledatetime_local, tz = 'UTC'))
  

# convert date time to YYYYDOY

inflow <- wide_in |>
  #select(sampledatetime_utc, Flow_cms, Inflow_Temp_cms)|>
  dplyr::mutate(
    year = lubridate::year(sampledatetime_utc),
    hour = lubridate::hour(sampledatetime_utc),
    doy = round(lubridate::yday(sampledatetime_utc) + hour/24, digits = 4))|>
  mutate_if(is.numeric, round, digits = 4)

    #Flow_cms = round(Flow_cms, digits = 4))



# add leading 0s so when paste together have YYYYDOY
inflow2 <- inflow%>%
  mutate(
    doy = ifelse(doy<10, paste0("00",doy), 
                 ifelse(doy>=10 & doy<100, paste0("0",doy),doy)))


# paste to make the time column with YYYYDOY 
inflow2$TIME <- paste0(inflow2$year,inflow2$doy)

options(digits=11)

inflow2$TIME <- round(as.numeric(inflow2$TIME), digits = 4)

inflow2$TIME <- format(inflow2$TIME)

# Rename column names to ELCOM names.
# This will have to be expaneded upon if we need to make more files. Right now this is just column names for the inflow and weather

lookup <- c(
  # Inflow headers
  INFLOW = "Flow_cms", WTR_TEMP = "Inflow_Temp_cms",
  #Weather headers
            AIR_TEMP = "AirTemp_C_mean",
            WIND_SPEED ="WindSpeed_ms_mean", WIND_DIR = "WindDir_degrees_mean",
            SOLAR_RAD = "ShortwaveRadiationUp_Wm2_mean",
            LW_RAD_IN = "InfraredRadiationUp_Wm2_mean",
            REL_HUM = "RH_percent_mean", RAIN = "Rain_mm_sum")


# if using inflow then add in salinity. Maybe make this an argument or figure out if we need to make it dynamic
if("INFLOW" %in% column_header){
  inflow2 <- inflow2|>
    mutate(SALINITY = 0)
           
}

# rename the headers from the list above and select the column headers from the argument in the function
inflow2 <- inflow2 |>
  rename(any_of(lookup))|>
  select(all_of(column_header))


# Convert humidity and Rain
if("REL_HUM" %in% column_header){
  
  # relativity needs to be between 0 and 1 so wen need to divide by 100
  inflow2<- inflow2|>
    mutate(
  REL_HUM = REL_HUM/100)
}
  
# Rain needs to be m/day. The file we have is mm/hr

# convert mm/hr to m/day for rain data
  if("RAIN" %in% column_header){
    inflow2<- inflow2|>
      mutate(
        RAIN = RAIN*0.024)
  }
  
 

# drop na for now

wedf <- inflow2|>
  drop_na()


## Make the headers for the file

# add in the header to the top of the file. 

# count the number of columns minus 1 
number_data_sets <- length(column_header)-1

# this creates the sequence to list number the columns in the header
q <- 0:number_data_sets

# The top header is the number of data sets and how many seconds between data. For now everything is 0
heading <- paste0(number_data_sets, " data sets\n0 seconds between data")

# The second header is the numbers above the column headers. 
heading2 <- paste0(q, collapse = "\t")


# write the data file to a text file so we can read it in again to add headers onto the file

write.table(wedf, 
            file = paste0(wd, outfile),
            row.names = F,
            col.names = T,
            quote = F, 
            sep = '\t')

# this is where the text file we just saved should be
file_path <- paste0(wd, outfile)

# Read the existing content of the file
existing_content <- readLines(file_path)

# Combine the heading with the existing content
updated_content <- c(heading,heading2, existing_content)

# make everything a character
wert <- wedf%>%
mutate_all(as.character)

# Write the updated content back to the file
writeLines(updated_content, file_path)

print(paste0("ELCOM file created and saved to ", file_path))
}

