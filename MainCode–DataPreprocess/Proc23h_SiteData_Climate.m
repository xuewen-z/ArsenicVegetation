clear; clc;
addpath(genpath('./'));

% 定义路径
Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_SiteData_As = '../output/21_SiteData_As/';
Path_Climate_Ta = '../output/03a_CHELSA_Ta_Y00_CMG1KM/';
Path_Climate_Rg = '../output/03c_CHELSA_Rg_Y00_CMG1KM/';
Path_Climate_VPD = '../output/03b_CHELSA_VPD_Y00_CMG1KM/';
Path_Climate_Pre = '../output/03d_CHELSA_Pre_Y00_CMG1KM/';
Path_SiteData_Climate = '../output/23h_SiteData_Climate/';

% 确保输出目录存在
system(['rm -rf ', Path_SiteData_Climate]);
system(['mkdir -p ', Path_SiteData_Climate]);

% 加载站点数据
load([Path_SiteData_As, 'SiteData_As.mat']);

% 读取 Climate 数据
File_Climate = fullfile(Path_Climate_Ta, 'CHELSA_Ta_Y00_CMG1KM_20012018.tif');
[Climate_Ta,R] = readgeoraster(File_Climate);
File_Climate = fullfile(Path_Climate_Rg, 'CHELSA_Rg_Y00_CMG1KM_20012018.tif');
Climate_Rg = readgeoraster(File_Climate);
File_Climate = fullfile(Path_Climate_VPD, 'CHELSA_VPD_Y00_CMG1KM_20012018.tif');
Climate_VPD = readgeoraster(File_Climate);
File_Climate = fullfile(Path_Climate_Pre, 'CHELSA_Pre_Y00_CMG1KM_20012018.tif');
Climate_Pre = readgeoraster(File_Climate);

% 计算经纬度索引矩阵
MatrixLat = linspace(R.LatitudeLimits(2), R.LatitudeLimits(1), R.RasterSize(1))';
MatrixLon = linspace(R.LongitudeLimits(1), R.LongitudeLimits(2), R.RasterSize(2));

% 站点数据初始化
numSites = size(SiteData_As, 1);
SiteData_Ta = nan(numSites, 1);
SiteData_Rg = nan(numSites, 1);
SiteData_VPD = nan(numSites, 1);
SiteData_Pre = nan(numSites, 1);

Data_Lat = SiteData_As(:, 1);
Data_Lon = SiteData_As(:, 2);

% 站点 Climate 赋值
for i = 1:numSites
    Lat = Data_Lat(i);
    Lon = Data_Lon(i);

    % 查找最接近的栅格索引
    [~, IndRow] = min(abs(MatrixLat - Lat));
    [~, IndCol] = min(abs(MatrixLon - Lon));

    % 赋值
    SiteData_Ta(i) = Climate_Ta(IndRow, IndCol);
    SiteData_Rg(i) = Climate_Rg(IndRow, IndCol);
    SiteData_VPD(i) = Climate_VPD(IndRow, IndCol);
    SiteData_Pre(i) = Climate_Pre(IndRow, IndCol);
end

% 保存站点 Climate 结果
File_SiteData_Climate = fullfile(Path_SiteData_Climate, 'SiteData_Climate.mat');
save(File_SiteData_Climate, '-regexp', '^Site*');

disp('Site Climate extraction completed.');
