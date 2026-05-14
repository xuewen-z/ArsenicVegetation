clear; clc;
addpath(genpath('./'));

% 1. Path Configuration
baseDir = '../input/GGMNdata/';
mergedExcel = fullfile(baseDir, 'GGMN_Global_Merged_As_Data.xlsx');
Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';

% 植被指数路径配置
Path_LAI = '../output/S01a_GlobeLAIadj_CMG1KM/';
Path_SIF = '../output/S01b_GlobeSIFadj_CMG1KM/';
Path_LCC = '../output/S01c_GlobeLCCadj_CMG1KM/';
Path_NDVI = '../output/S01d_GlobeNDVIadj_CMG1KM/';

savePath = fullfile(baseDir, 'GGMN_Global_Merged_With_All_FullyAdj.xlsx');

% 2. Load Data
T = readtable(mergedExcel);
numSites = height(T);
Data_Lat = T.Latitude;
Data_Lon = T.Longitude;

% 3. Read Rasters (LandCover & 4 Vegetation Indices)
[LandCover, R] = readgeoraster(fullfile(Path_LandCover, 'LCTIGBP_USGS_MCD12Q1_Y10_CMG1KM_20012010.tif'));

% 读取四个指标的栅格数据
GeoLAIadj  = readgeoraster(fullfile(Path_LAI,  'LAIadj_B2001E2020_CMG1KM.tif'));
GeoSIFadj  = readgeoraster(fullfile(Path_SIF,  'SIFadj_B2001E2020_CMG1KM.tif'));
GeoLCCadj  = readgeoraster(fullfile(Path_LCC,  'LCCadj_B2001E2020_CMG1KM.tif'));
GeoNDVIadj = readgeoraster(fullfile(Path_NDVI, 'NDVIadj_B2001E2020_CMG1KM.tif'));

% Geo-indexing
MatrixLat = linspace(R.LatitudeLimits(2), R.LatitudeLimits(1), R.RasterSize(1))';
MatrixLon = linspace(R.LongitudeLimits(1), R.LongitudeLimits(2), R.RasterSize(2));

% 4. Initialize Columns (为四个指标各准备两列)
T.PFT = nan(numSites, 1);
vNames = {'LAI', 'SIF', 'LCC', 'NDVI'};
for i = 1:length(vNames)
    T.([vNames{i}, 'adj']) = nan(numSites, 1);
    T.([vNames{i}, '_fully_adj']) = nan(numSites, 1);
end

% 5. Extraction Logic
disp('Starting extraction of PFT and all Vegetation Indices from rasters...');
for j = 1:numSites
    [~, IndRow] = min(abs(MatrixLat - Data_Lat(j)));
    [~, IndCol] = min(abs(MatrixLon - Data_Lon(j)));
    
    T.PFT(j) = LandCover(IndRow, IndCol);
    
    % 提取栅格值
    T.LAIadj(j)  = GeoLAIadj(IndRow, IndCol);
    T.SIFadj(j)  = GeoSIFadj(IndRow, IndCol);
    T.LCCadj(j)  = GeoLCCadj(IndRow, IndCol);
    T.NDVIadj(j) = GeoNDVIadj(IndRow, IndCol);
end

% 6. Second-Stage Adjustment (Subsurface Hydrochemistry) for all indices
% 统一处理 pH, EC, F, Fe 的剥离计算
disp('Calculating fully-adjusted residuals for all indices...');

hydroVars = {'EC', 'pH', 'F', 'Fe'};

for i = 1:length(vNames)
    adjName = [vNames{i}, 'adj'];
    fullyAdjName = [vNames{i}, '_fully_adj'];
    
    % 筛选该指标有效且地下水成分完整的站点
    valid_idx = ~any(isnan(T{:, hydroVars}), 2) & ~isnan(T.(adjName));
    
    if any(valid_idx)
        fprintf('Processing %s...\n', vNames{i});
        % 执行稳健线性回归，剔除地下水背景
        mdl = fitlm(T(valid_idx, :), [adjName, ' ~ EC + pH + F + Fe'], 'RobustOpts', 'on');
        
        % 保存残差 (Anomaly)
        T.(fullyAdjName)(valid_idx) = T.(adjName)(valid_idx) - mdl.Fitted;
    else
        warning('No valid sites for %s adjustment.', vNames{i});
    end
end

7. Save the Table
disp(['Saving updated table to: ', savePath]);
writetable(T, savePath);

disp('Extraction and Adjustment for all 4 indices completed successfully!');