clear; clc;
addpath(genpath('./'));

% 定义路径
Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_SiteData_As = '../output/21_SiteData_As/';
Path_DEM = '../input/';
Path_SiteData_DEM = '../output/23g_SiteData_DEM/';

% 确保输出目录存在
system(['rm -rf ', Path_SiteData_DEM]);
system(['mkdir -p ', Path_SiteData_DEM]);

% 加载站点数据
load([Path_SiteData_As, 'SiteData_As.mat']);

% 读取 DEM 数据
File_DEM = fullfile(Path_DEM, 'Globe_DEM_CMG1KM.tif');
[DEM,R] = readgeoraster(File_DEM);
File_Aspect = fullfile(Path_DEM, 'Globe_Aspect_CMG1KM.tif');
Aspect = readgeoraster(File_Aspect);

% 计算经纬度索引矩阵
MatrixLat = linspace(R.LatitudeLimits(2), R.LatitudeLimits(1), R.RasterSize(1))';
MatrixLon = linspace(R.LongitudeLimits(1), R.LongitudeLimits(2), R.RasterSize(2));

% 站点数据初始化
numSites = size(SiteData_As, 1);
SiteData_DEM = nan(numSites, 1);
SiteData_Aspect = nan(numSites, 1);

Data_Lat = SiteData_As(:, 1);
Data_Lon = SiteData_As(:, 2);

% 站点 DEM 赋值
for i = 1:numSites
    Lat = Data_Lat(i);
    Lon = Data_Lon(i);

    % 查找最接近的栅格索引
    [~, IndRow] = min(abs(MatrixLat - Lat));
    [~, IndCol] = min(abs(MatrixLon - Lon));

    % 赋值
    SiteData_DEM(i) = DEM(IndRow, IndCol);
    SiteData_Aspect(i) = Aspect(IndRow, IndCol);
end

% 保存站点 DEM 结果
File_SiteData_DEM = fullfile(Path_SiteData_DEM, 'SiteData_DEM.mat');
save(File_SiteData_DEM, '-regexp', '^Site*');

disp('Site DEM extraction completed.');
