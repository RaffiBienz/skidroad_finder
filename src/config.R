#-----------------------------------------------------------------------------#
#### Configuration file ####
# Set your parameters and paths in this file
#-----------------------------------------------------------------------------#

# General setup
number_of_cores <- 7 # Number of cores used for certain calculations
remove_tempfiles <- TRUE # Should temporary files be removed?
remove_interim_results <- FALSE # Should results for each area be removed? If set to TRUE, temporary files are also removed.

# Path to the ground structure dataset
# See https://github.com/RaffiBienz/dtmanalyzer for calculation
path_ground <- file.path("data/example_ground_structure.tif")

# Path to the forest delineation (or delineation of areas of interest)
path_delineation <- file.path("data")
name_delineation <- "example_forest_delineation"

# Python setup
#path_python <- file.path("C:/Users/Raffi/.conda/envs/road_finder2/python.exe") 
path_python = "python" # Path to python environment
path_script <- file.path("/src/predict_segmentation.py")

# Path to the pretrained model
path_model <- file.path("model/road_finder_model.h5")

# Global variables
window_size <- 150 # size for segmentation windows (model was trained for 150x150 m windows)
threshold_segmentation <- 0.5 # all pixels in the segmentation output above this value will be classified as strip roads
name_raster_output <- "forest_roads"

# Vectorizer setup
vectorize_segmentation <- TRUE
clip_lines <- TRUE # clip lines to forest delineation?
name_line_output <- "forest_roads"
thresh_min_area <- 20 # minimum area in m2
thresh_thinning <- 7 # minimum number of positive neighbors
win_size <- 2.5 # window size for line finder
