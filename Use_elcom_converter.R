# Title: VERA data to ELCOM files
# Author: Adrienne Breef-Pilz
# Created: 24 Sept. 2024
# Edited

# This file reads in qaqced files from the Virginia Reservoirs and puts them into the targets files for VERA.
# The next step is to take the file in the targets file and put it in the format for ELCOM


# Load data packages
pacman::p_load(tidyverse, here)

# Get the functions we need
# get the function to make the ELCOM files
source(paste0(here(),"/Data/DataNotYetUploadedToEDI/Make_ELCOM_files/convert_elcom.R"))

# Founctions for the targets file. Depends which file you are trying to make

# function to make the INFLOW targets file
source("https://raw.githubusercontent.com/LTREB-reservoirs/vera4cast/main/targets/target_functions/target_generation_inflow_hourly.R")


# function to make the MET targets file
source("https://raw.githubusercontent.com/LTREB-reservoirs/vera4cast/main/targets/target_functions/meteorology/target_generation_met.R")


## Make the targets data file
# Create the data file of Inflow data from EDI and current file
data_files <- target_generation_inflow_hourly(current_data_file="https://raw.githubusercontent.com/FLARE-forecast/FCRE-data/fcre-weir-data-qaqc/FCRWeir_L1.csv",
                                        edi_data_file="https://pasta.lternet.edu/package/data/eml/edi/202/10/c065ff822e73c747f378efe47f5af12b")



# MET targets file

met_EDI <- "https://pasta.lternet.edu/package/data/eml/edi/389/8/d4c74bbb3b86ea293e5c52136347fbb0"

met_L1 <- "https://raw.githubusercontent.com/FLARE-forecast/FCRE-data/fcre-metstation-data-qaqc/FCRmet_L1.csv"

# run the targets file

emet <- target_generation_met(current_met = met_L1, historic_met = met_EDI, time_interval = "hourly")

### Make ELCOM files

# Now use the ELCOM function to make a new data frame

convert_elcom_files(
    data=data_files, # name of the targets file
    column_header = c("TIME", "INFLOW", "WTR_TEMP", "SALINITY"), # Name of the columns you want in the proper ELCOM Names
    start_time = "2015-07-01", # file start date
    outfile = "/Data/DataNotYetUploadedToEDI/Make_ELCOM_files/elcom_inflow23.txt") # name of the file and where to save it

# List of column headers to choose from:
# Inflow
# column_header <- c("TIME", "INFLOW", "WTR_TEMP", "SALINITY")

# Weather
# column_header <- c("TIME", "AIR_TEMP", "WIND_SPEED", "WIND_DIR", "SOLAR_RAD", "LW_RAD_IN", "REL_HUM", "RAIN")
