# ArsenicVegetation

Code repository for the manuscript:
“Suppressive impacts of groundwater arsenic contamination on global vegetation growth”

## Overview
This repository contains the main analysis scripts used in this study, including modules for:
1. grid-based local comparison of vegetation anomalies across groundwater arsenic risk classes;
2. site-based statistical analyses using groundwater arsenic observations and vegetation indices;
3. process-based HYDRUS-1D simulations of arsenic transport and root water uptake;
4. pathway and importance analyses (e.g.,SEM);
5. ecosystem service calculations and associated post-processing.

This repository is currently provided for peer-review purposes.

## Repository structure
- `MainCode-DataPreprocess/` : main preprocessing scripts for large public global datasets
- `MainCode-DataAnalysis/` : main MATLAB-based analytical scripts for vegetation anomaly analysis, site-based statistical analyses, and ecosystem service calculations
- `Hydrus1D_Batch/` : HYDRUS-1D-related scripts, input preparation files, and post-processing scripts for process-based simulations
- `R-code/` : R scripts for SEM and related statistical analyses

## Script organization and workflow
This repository is organized as a modular workflow rather than a single one-click pipeline.

The main workflow is implemented in `MainCode-DataPreprocess/` and `MainCode-DataAnalysis/`, which were primarily run in the Linux server environment. These scripts preprocess the original public datasets, generate harmonized analysis inputs, and produce intermediate outputs for downstream modules.

The `Hydrus1D_Batch/` folder and the `R-code/` folder are independent downstream modules. They do not operate as fully standalone components, but use selected intermediate datasets generated from the main preprocessing and analysis workflow:
- `Hydrus1D_Batch/` uses intermediate inputs prepared from the main workflow for HYDRUS-1D simulations under Windows 10;
- `R-code/` uses prepared inputs from the main workflow for SEM and related analyses in R.

Scripts in the main MATLAB workflow are generally organized in approximate numerical order within each stage. The numbering reflects the progression of the analysis, but the full repository should be understood as a cross-platform modular framework.

Representative stages in `MainCode-DataAnalysis/` include:
- `Proc11–Proc14`: vegetation anomaly calculations for LAI, SIF, LCC, and NDVI
- `Proc31–Proc33`: site-based covariate-adjusted analyses and dose-response data preparation
- `Proc60–Proc71`: ecosystem service deficit calculations and annual summaries
- `ProcS01–ProcS02`: supplementary or additional analyses

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
- Module 5: ecosystem service calculations and related remote-sensing processing — Google Earth Engine &  Linux

### Python dependencies
Python was used in parts of the data preprocessing workflow under the Linux environment. Only selected preprocessing scripts require Python and the corresponding packages specified in the relevant scripts.
  
### MATLAB dependencies
MATLAB was used for data processing, preprocessing, statistical analysis, and plotting. Some scripts may require standard MATLAB toolboxes used for matrix computation, statistics, and visualization.

### HYDRUS-1D
HYDRUS-1D is required for Module 3, which simulates arsenic transport and root water uptake under the Windows 10 environment.

### R packages
Please install the required R packages before running the R scripts. These include packages used for regression, structural equation modeling, statistical analysis, and visualization.

### Hardware requirements
Representative example workflows and selected site-scale modules can be inspected or partially executed on a standard desktop computer. However, the full global preprocessing workflow was conducted on a high-memory Linux server environment and may require substantial memory and computational resources.

## Installation guide
### Instructions
1. Clone or download this repository.
2.  Install the required software according to the module to be run:
   - MATLAB R2024a for the main MATLAB workflow
   - Python for selected preprocessing steps
   - R 4.4.1 for the R-based analyses
   - HYDRUS-1D Version 4.17 
3. Install the required R packages listed in the corresponding scripts.
4. For the GEE scripts, a valid Google Earth Engine account is required.
5. Update file paths in the scripts according to your local directory structure before running.

### Typical installation time
Installation of the required software environment typically takes for the required software environments of selected modules on a standard desktop computer, excluding external data download time.

