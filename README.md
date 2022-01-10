# Forest skid road detection with lidar data
Created by Raffael Bienz. As a final project for a DAS in Data Science. Supervisor: Marco Willi

The example data was kindly provided by the Kanton of Aargau.

## Data required
Two datasets are required for the algorithm to work:
- Ground structure dataset of the area of interest (tif, with a 0.5 m resolution). Calculated based on Lidar data. For the Method see: https://github.com/RaffiBienz/dtmanalyzer
- Forest delineation of the area of interest (polygons as shapefile).

## Algorithm
A combination of R and Python are used. R is used for geoprocessing tasks during pre- and post-processing. Python is used for the semantic segmentation of the ground structure data. For the semantic segmentation a U-Net architecture is used. For the vectorization of the segmentation masks a region growing algorithm was developed.


## Usage

### Clone repository and download model
```
git clone https://github.com/RaffiBienz/skidroad_finder.git
```

Download the model from the link and put in the model folder: https://drive.google.com/file/d/1-19k1sK8yHX16nlxd5rZcjLhEjcobTg0

### Setup Python (with Anaconda)

Install Anaconda (https://docs.anaconda.com/anaconda/install/index.html)

Open Anaconda Prompt, change the directory to the root folder and type:
```
conda create -y -n skidroad_finder python==3.8
conda activate skidroad_finder
pip install -r .\src\requirements.txt
```

### Setup R
- Install R and if desired RStudio (https://www.r-project.org/).
- Required packages: rgdal, rgeos, raster, imager, doParallel, foreach, sp (see requirements.R). These packages are automatically installed when, main.R is run.
- Open config.R and set configurations. Especially, add the path to the python or the conda environment in config.R (Typically: C:/Users/USERNAME/.conda/envs/skidroad_finder/python.exe). If python is defined as a environment variable just type "python" in config.R.

### Execute script
Execute main.R in the src folder. 

```
Rscript main.R
```

Interim results per forest delineation element are saved in the wd folder. The final products over the whole area of interest are saved in the results folder. The final segmentation mask is saved as raster dataset (tif). The vectorized segmentation mask is saved as a shapefile (shp).

### Docker
Alternatively to the above setup, you can also use the Dockerfile provided. Open a command prompt, cd into the root folder and execute:

```
docker build -t skidroad_finder .
docker run skidroad_finder
```




![](example.png)