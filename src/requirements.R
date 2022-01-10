# Load packages or install if they do not exist
if (!require("raster", quietly = TRUE)) install.packages("raster")
if (!require("sp", quietly = TRUE)) install.packages("sp")
if (!require("rgdal", quietly = TRUE)) install.packages("rgdal")
if (!require("rgeos", quietly = TRUE)) install.packages("rgeos")
if (!require("imager", quietly = TRUE)) install.packages("imager")
if (!require("doParallel", quietly = TRUE)) install.packages("doParallel")
if (!require("foreach", quietly = TRUE)) install.packages("foreach")
