library("shiny")
library("DT")
library("ggplot2")
library("ncdf4")
library("stringr")
library('tidyverse')
library("dplyr")
library(shinyrAtlantis)

source('/home/por07g/Documents/Code_Tools/shinyRAtlantis/Fork_git/shinyrAtlantis/R/shforce.R')
exchange.file    <- 'Creating_Hydro/out_EAAM/EAAM_hydro.nc'
salinity.file    <- "Creating_Hydro/out_EAAM/EAAM_salt.nc"       # this file is not included in the package
temperature.file <- "Creating_Hydro/out_EAAM/EAAM_temp.nc"       # this file is not included in the package
bgm.file         <- "Creating_Hydro/EAA29_ll_v2.bgm" # this file is not included in the package
cum.depth = c(0, 20, 50, 100, 200, 300, 400, 750, 1000, 2000, 5000)

input.object <- make.sh.forcings.object(
  bgm.file         = bgm.file,
  exchange.file    = exchange.file,
  cum.depth        = cum.depth,
  temperature.file = temperature.file,
  salinity.file    = salinity.file
)

debug(sh.forcings)
sh.forcings(input.object)
