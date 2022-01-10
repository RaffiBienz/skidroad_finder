#------------------------------------------------------------------------------------------------------------------------#
#### Functions to process rasters (ground structure map) ####
#------------------------------------------------------------------------------------------------------------------------#

# Cut raster to windows and save windows as jpg
preprocess_raster <- function(structure, fd, path_target, w, window_size, grid_id){
  # Create target folder for fd element
  path_wa_folder <- paste0(path_target,w) 
  dir.create(path_wa_folder, recursive = TRUE)
  
  # Buffer fd element
  wa_buf <- buffer(fd[w,],window_size/2)
  wa_ras_crop <- crop(grid_id,wa_buf)
  wa_ras_mask <-mask(wa_ras_crop,wa_buf)
  
  # Export id raster for fd element
  writeRaster(wa_ras_mask, paste0(path_target,w,"/wa_ras_mask_",w,".tif"), overwrite=T)
  
  # Subfolder for tiles
  path_pics <- paste0(path_target,w,"/pics/")
  dir.create(path_pics, recursive = TRUE)
  
  # Cut forest area of fd element to window size
  foreach (i = 1:ncell(wa_ras_mask), .packages = c("raster","rgdal","rgeos","imager"), .verbose = F) %dopar% {
    id_cell <- wa_ras_mask[i]
    if (!is.na(id_cell)){
      path_pic <- paste0(path_pics, "/tile_", id_cell, ".jpg")
      if (!file.exists(path_pic)){
        coor_cell <- xyFromCell(wa_ras_mask, i)
        cell_ext <- extent(c(coor_cell[1]-window_size/2, coor_cell[1]+window_size/2, coor_cell[2]-window_size/2, coor_cell[2]+window_size/2))
        str_cell <- crop(structure, cell_ext)
        cimg <- as.cimg(c(str_cell[]),x=ncol(str_cell),y=nrow(str_cell),cc=1)
        save.image(cimg, path_pic,quality=1)
      }
    }
  }
  print(paste0(w," windows exported."))
}

# Join results for each fd element
postprocess_raster <- function(path_target, w, threshold_segmentation) {
  if (!file.exists(paste0(path_target,w,"/ras_results_", w,".tif"))){
    path_masks <- paste0(path_target,w,"/masks/")
    path_pics <- paste0(path_target,w,"/pics/")
    files <- list.files(path_masks)
    
    wa_ras_mask <- raster(paste0(path_target,w,"/wa_ras_mask_",w,".tif"))
    ids <- wa_ras_mask[]
    ids <- ids[!is.na(ids)]
    
    if (length(ids)>0){
      
      empty <- load.image(paste0(path_pics,"tile_",ids[!is.na(ids)][1],".jpg"))
      empty[] <- 0
      
      n_r <- nrow(wa_ras_mask)
      n_c <- ncol(wa_ras_mask)
      
      for (r in 1:n_r){
        for (c in 1:n_c){
          id <- wa_ras_mask[r,c]
          if (is.na(id)){
            if(c==1){img_line <- empty} else {img_line <- imappend(imlist(img_line,empty),"x")}
          } else{
            t1 <- load.image(paste0(path_masks,"tile_",id,"_",0,".jpg"))
            t2 <- load.image(paste0(path_masks,"tile_",id,"_",1,".jpg"))
            t3 <- load.image(paste0(path_masks,"tile_",id,"_",2,".jpg"))
            t4 <- load.image(paste0(path_masks,"tile_",id,"_",3,".jpg"))
            l1 <- imappend(imlist(t1,t2),"x")
            l2 <- imappend(imlist(t3,t4),"x")
            tile <- imappend(imlist(l1,l2),"y")
            if(c==1){img_line <- tile}
            else {img_line <- imappend(imlist(img_line,tile),"x")}
          }
        }
        if (r==1){img_tot <- img_line} else{img_tot <- imappend(imlist(img_tot,img_line),"y")}
      }
      img_tot[img_tot<threshold_segmentation] <- 0
      img_tot[img_tot>=threshold_segmentation] <- 1
      
      img_ras <- raster(matrix(img_tot[],ncol = nrow(img_tot),byrow=T))
      crs(img_ras) <- crs(wa_ras_mask)
      extent(img_ras) <- extent(wa_ras_mask)
      origin(img_ras) <- origin(wa_ras_mask)
      writeRaster(img_ras, paste0(path_target,w,"/ras_results_", w,".tif"), overwrite=T)
    }
  } 
  print(paste0(w," segmentation outputs joined."))
}

# Join all rasters for the area of interest
combine_rasters <- function(path_target, name_raster_output){
  forest_ids <- as.numeric(list.dirs(path_target,recursive = FALSE, full.names = FALSE))
  
  ras_names <- c()
  for(i in forest_ids) {
    if (file.exists(paste0(path_target,i,"/ras_results_",i,".tif"))){
      assign(paste0("ras_",i), raster(paste0(path_target,i,"/ras_results_",i,".tif")))
      ras_names <- c(ras_names, paste0("ras_",i))
    }
  } 
  
  raster_list <- list() 
  for (i in ras_names){
    raster_list <- append(raster_list,eval(as.symbol(i)))}
  
  raster_list$fun <- max
  
  if (length(raster_list) > 2){
    mos <- do.call(mosaic, raster_list)
    writeRaster(mos,filename=file.path("results", paste0(name_raster_output,".tif")),overwrite=T,datatype='INT4S')
  } else if (length(raster_list) == 2){
    writeRaster(raster_list[[1]],filename=file.path("results", paste0(name_raster_output,".tif")),overwrite=T,datatype='INT4S')
  } else { print("No strip roads found.")}
  print("All rasters combined.")
}

