# ArsenicVegetation

Code repository for the manuscript:
“Suppressive impacts of groundwater arsenic contamination on global vegetation growth”

## Overview
This repository contains the main analysis scripts used in this study, including modules for:
1. grid-based local comparison of vegetation anomalies across groundwater arsenic risk classes;
2. site-based statistical analyses using groundwater arsenic observations and vegetation indices;
3. process-based HYDRUS-1D simulations of arsenic transport and root water uptake;
4. pathway and importance analyses (SEM and random forest);
5. ecosystem service calculations and associated post-processing.

This repository is currently provided for peer-review purposes.

## Repository structure
- `matlab/` : MATLAB scripts for data processing, statistical analysis, visualization, and post-processing
- `r/` : R scripts for regression, SEM, and related statistical analyses
- `gee/` : Google Earth Engine scripts for ecosystem service calculations and remote sensing processing
- `data_demo/` : example input/output files for selected site-scale modules and intermediate processing steps
- `outputs_example/` : representative example outputs


## System requirements
### Operating systems
Tested in the following environments:
- Linux (server environment)
- Windows 10

### Software
- MATLAB (used in both Linux and Windows environments)
- Python (used in both Linux and Windows environments)
- R 4.4.1
- HYDRUS-1D (Windows 10)
- Google Earth Engine (web platform)

### Environment by module
- Data preprocessing: Linux server environment
- Module 1: grid-based local comparison of vegetation anomalies across groundwater arsenic risk classes — Linux
- Module 2: site-based statistical analyses using groundwater arsenic observations and vegetation indices — Linux
- Module 3: HYDRUS-1D simulations of arsenic transport and root water uptake — Windows 10
- Module 4: pathway and importance analyses (e.g., SEM and related R-based analyses) — R 4.4.1
- Module 5: ecosystem service calculations and related remote-sensing processing — Google Earth Engine

  
### R packages
Please install the required R packages before running the R scripts. These include packages used for regression, structural equation modeling, statistical analysis, and visualization.

### MATLAB dependencies
MATLAB was used for data processing, preprocessing, statistical analysis, and plotting. Some scripts may require standard MATLAB toolboxes used for matrix computation, statistics, and visualization.

### Hardware requirements
Representative example workflows and selected site-scale modules can be inspected or partially executed on a standard desktop computer. However, the full global preprocessing workflow was conducted on a high-memory Linux server environment and may require substantial memory and computational resources.

## Installation guide
### Instructions
1. Clone or download this repository.
2. Install MATLAB R2024a and R 4.4.1.
3. Install the required R packages listed in the corresponding scripts.
4. For the GEE scripts, a valid Google Earth Engine account is required.
5. Update file paths in the scripts according to your local directory structure before running.

### Typical installation time
Installation of the required software environment typically takes less than 60 minutes on a standard desktop computer, excluding external data download time.

