

clear; clc;

addpath(genpath('./'));

Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_SiteData_As = '../output/21_SiteData_As/';
Path_BESSecoAVG = '../output/45_BESSEco_CMG1KM/';
Path_SiteData_BESSEco = '../output/46_SiteData_BESSEco/';

system(['rm -rf '  ,Path_SiteData_BESSEco]);
system(['mkdir -p ',Path_SiteData_BESSEco]);

load([Path_SiteData_As, 'SiteData_As.mat']);

File_LandCover = fullfile(Path_LandCover, 'LCTIGBP_USGS_MCD12Q1_Y10_CMG1KM_20012010.tif');
[~, R] = readgeoraster(File_LandCover);
AvgGPPmax = readgeoraster([Path_BESSecoAVG,'BESS_AvgGPPmax_CMG1KM_B2001E2020.tif']);
AvgWUE = readgeoraster([Path_BESSecoAVG,'BESS_AvgWUE_CMG1KM_B2001E2020.tif']);
AvgCUE = readgeoraster([Path_BESSecoAVG,'BESS_AvgCUE_CMG1KM_B2001E2020.tif']);


% 计算经纬度索引矩阵
MatrixLat = linspace(R.LatitudeLimits(2), R.LatitudeLimits(1), R.RasterSize(1))';
MatrixLon = linspace(R.LongitudeLimits(1), R.LongitudeLimits(2), R.RasterSize(2));

% 站点数据初始化
numSites = size(SiteData_As, 1);
SiteData_GPPmax = nan(numSites, 1);
SiteData_WUE = nan(numSites, 1);
SiteData_CUE = nan(numSites, 1);


Data_Lat = SiteData_As(:, 1);
Data_Lon = SiteData_As(:, 2);

% 站点 CO2 赋值
for i = 1:numSites
    Lat = Data_Lat(i);
    Lon = Data_Lon(i);

    % 查找最接近的栅格索引
    [~, IndRow] = min(abs(MatrixLat - Lat));
    [~, IndCol] = min(abs(MatrixLon - Lon));

    % 赋值
    SiteData_GPPmax(i) = AvgGPPmax(IndRow, IndCol);
    SiteData_WUE(i) = AvgWUE(IndRow, IndCol);
    SiteData_CUE(i) = AvgCUE(IndRow, IndCol);

end

% 保存站点 CO2 结果
File_SiteData_BESS = fullfile(Path_SiteData_BESSEco, 'SiteData_BESSEco.mat');
save(File_SiteData_BESS, '-regexp', '^Site*');

disp('Site BESSEco extraction completed.');


