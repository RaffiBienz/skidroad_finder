# Load packages or install if they do not exist
if (!require("terra", quietly = TRUE)) install.packages("raster")
if (!require("sf", quietly = TRUE)) install.packages("sp")
if (!require("imager", quietly = TRUE)) install.packages("imager")

