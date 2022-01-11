#-----------------------------------------------------------------------------#
#### Automatic detection of strip roads ####
# R.Bienz 06.01.2022
#-----------------------------------------------------------------------------#
# Set Working directory
wd <- "."
setwd(wd)
print(paste("Current working directory:",getwd()))

# Load libraries (and install if not yet)
source("src/requirements.R")

# Load configurations
source("src/config.R")

# Load custom functions
source("src/raster_processing.R")
source("src/line_finder.R")

# create folders
dir.create(file.path("wd"), showWarnings = FALSE)
dir.create(file.path("temp"), showWarnings = FALSE)
dir.create(file.path("results"), showWarnings = FALSE)

# Set raster processing options
rasterOptions(tmpdir= file.path(getwd(),"temp"),todisk=TRUE, progress="")

#-----------------------------------------------------------------------------#
#### Load data ####
# Forest delineation
fd <- readOGR(dsn=path_delineation,layer = name_delineation,encoding = "ESRI Shapefile", verbose = FALSE)
fd@data$id <- 1:nrow(fd) # Create ID variable

# Ground structure data
structure <- raster(path_ground)

#-----------------------------------------------------------------------------#
#### Split each forest area in tiles for prediction ####

registerDoParallel(number_of_cores) # for parallel processing

# Create target folder for predictions
path_target <- "wd/prediction/"
dir.create(path_target, recursive = TRUE, showWarnings=FALSE)


# Create a id raster for the whole area of interest
grid_id <- raster(resolution=window_size, ext=extent(fd)+200)
grid_id[] <- 1:ncell(grid_id)
crs(grid_id) <- crs(fd)
writeRaster(grid_id, paste0(path_target,"grid_id.tif"), overwrite=TRUE)

# Execute prediction for each forest delineation (fd) element separately
for (w in fd@data$id){
  # Create windows for each fd element (model input)
  preprocess_raster(structure, fd, path_target, w, window_size, grid_id)
  
  # Execute segmentation for each fd element with python
  wa_ras_mask <-  raster(paste0(path_target,w,"/wa_ras_mask_",w,".tif"))
  path_data <- file.path(getwd(), path_target,w)
  if (length(list.files(paste0(path_data,"/masks"))) < sum(!is.na(wa_ras_mask[]))*4){ # check if already done
    system(paste0(path_python, " \"", file.path(getwd(),path_script), "\" ", w, " \"", file.path(getwd(), path_model), "\" ", "\"", path_data, "\""),wait=T, intern=T,invisible = T)
  } 
  print(paste0(w," segmentation executed."))
  
  # Join results for each fd element ####
  postprocess_raster(path_target, w, threshold_segmentation)

  if (remove_tempfiles){
    unlink(file.path(path_target,w,"pics"), recursive = TRUE)
    unlink(file.path(path_target,w,"masks"), recursive = TRUE)
  }
  removeTmpFiles(h=0)
  
  # Vektorize segmentation
  if (vectorize_segmentation){
    line_finder(path_target, w, thresh_min_area, thresh_thinning, win_size)
  }
  
}

#-----------------------------------------------------------------------------#
#### Join final results for the whole are of interest ####
# Raster
combine_rasters(path_target, name_raster_output)

# Polylines
combine_lines(path_target, name_line_output)

# Clip lines to forest area
if (clip_lines){
  lines <- readOGR(dsn="results",layer = name_line_output,encoding = "ESRI Shapefile", verbose = FALSE)
  lines_clip <- crop(lines, fd)
  writeOGR(lines_clip, dsn="results", layer=paste0(name_line_output,"_clip"), driver = "ESRI Shapefile", overwrite_layer = T)
}

# Cleanup
removeTmpFiles(h=0)
unlink(file.path("temp"), recursive = TRUE)
if (remove_interim_results) {unlink(file.path("wd"), recursive = TRUE)}






