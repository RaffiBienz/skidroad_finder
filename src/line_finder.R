#------------------------------------------------------------------------------------------------------------------------#
#### Functions to find lines in segmentation outputs ####
#------------------------------------------------------------------------------------------------------------------------#

# Start- endpoint finder
thresh_pix <- 1
point_finder <- function(x){
  if (is.na(x[13]) | x[13]==0) {
    0
  } else{
    m <- matrix(x,ncol=5,byrow=T)
    o <- sum(m[c(1,2),], na.rm=T)
    u <- sum(m[c(4,5),], na.rm=T)
    r <- sum(m[,c(4,5)], na.rm=T)
    l <- sum(m[,c(1,2)], na.rm=T)
    
    con <- (o==0 & r==0) | (o==0 & l==0) | (u==0 & r==0) | (u==0 & l==0)
    if (con) {1} else {0}
  }
}


# Line finder for each fd element
line_finder <- function(path_target, w, thresh_min_area, thresh_thinning, win_size){
  path_folder <- file.path(path_target,w)
  if (!file.exists(paste0(path_folder,"/lines_",w,".shp"))){
    if (file.exists(paste0(path_folder,"/ras_results_",w,".tif"))){
      system.time({
      # Load data
      seg <- raster(paste0(path_folder,"/ras_results_",w,".tif"))

      # Thinning of raster
      seg_f1 <- focal(seg, w=matrix(1,3,3), fun=sum, na.rm=T)
      seg_f1[seg_f1[]<thresh_thinning] <- 0
      seg_f1[seg_f1[]>=thresh_thinning] <- 1


      # Finding start points of lines
      start_points <- focal(seg_f1, w=matrix(1,5,5), fun=point_finder)

      # Search for lines from start points
      coords_start <- xyFromCell(start_points, which(start_points[]==1))
      coords_todo <- xyFromCell(seg_f1, which(seg_f1[]==1))
      lines <- list()
      new_line <- TRUE
      while(length(coords_start)>2){
        if (new_line){
          coord_centre <- coords_start[1,]
          line <- data.frame(x=coord_centre[1], y=coord_centre[2])
        }
        
        dis <- pointDistance(coord_centre, coords_todo, lonlat = F)
  
        bool_sel <- dis<=win_size
        if (sum(bool_sel) > 1){
          coords_sel <- coords_todo[bool_sel,]
          coord_centre <- c(mean(coords_sel[,1]),mean(coords_sel[,2]))
          line[nrow(line)+1,] <- coord_centre
          coords_todo <- coords_todo[!bool_sel,]
          new_line <- FALSE
          
        } else {
          if (nrow(line)>1){lines[[length(lines)+1]] <- line}
          coords_start <- coords_start[-1,]
          new_line <- TRUE
        }
      }

      # Contine search for lines from pixels not yet used
      new_line <- TRUE
      while(length(coords_todo)>2){
        if (new_line){
          coord_centre <- coords_todo[1,]
          line <- data.frame(x=coord_centre[1], y=coord_centre[2])
        }
        
        dis <- pointDistance(coord_centre, coords_todo, lonlat = F)
        bool_sel <- dis<=win_size
        if (sum(bool_sel) > 1){
          coords_sel <- coords_todo[bool_sel,]
          coord_centre <- c(mean(coords_sel[,1]),mean(coords_sel[,2]))
          line[nrow(line)+1,] <- coord_centre
          coords_todo <- coords_todo[!bool_sel,]
          new_line <- FALSE
          
        } else {
          if (nrow(line)>1){lines[[length(lines)+1]] <- line}
          coords_todo <- coords_todo[-1,]
          new_line <- TRUE
        }
      }

      # Create list of lines
      if (length(lines)>0){
        list_lines <- list()
        for (i in 1:length(lines)){
          l_coords <- lines[[i]]
          lin <- Line(l_coords)
          lin_id <- Lines(list(lin),ID=i)
          list_lines[[i]] <- lin_id
        }
        
        # Save lines
        sl <- SpatialLines(list_lines)
        sldf <- SpatialLinesDataFrame(sl, data.frame(id=1:length(lines)))
        writeOGR(sldf, dsn=path_folder, layer=paste0("lines_",w), driver = "ESRI Shapefile", overwrite_layer = T)
      }
      print(paste0(w, " segmentation vectorized."))
      })
    }
  }
}

# Combine all lines
combine_lines <- function(path_target, name_line_output){
  forest_ids <- as.numeric(list.dirs(path_target,recursive = FALSE, full.names = FALSE))
  for(w in forest_ids) {
    if (file.exists(paste0(path_target,w,"/lines_",w,".shp"))){
      temp <- readOGR(dsn=paste0(path_target,w),layer = paste0("lines_",w),encoding = "ESRI Shapefile", verbose = FALSE)
      if (exists("lines_comb")){
        lines_comb <- bind(lines_comb,temp)
      } else {lines_comb <- temp}
    }
  }
  
  # Remove small segments
  drop_list <- c()
  for (i in 1:nrow(lines_comb)){
    n <- nrow(lines_comb@lines[[i]]@Lines[[1]]@coords)
    if (n<3){drop_list <- c(drop_list,i)}
  }
  lines_comb <- lines_comb[-drop_list,]
  
  writeOGR(lines_comb, dsn="results", layer=name_line_output, driver = "ESRI Shapefile", overwrite_layer = T)
  remove(lines_comb)
  print("Lines combined.")
}
