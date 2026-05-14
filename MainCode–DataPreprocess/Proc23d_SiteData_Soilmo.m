clear; clc;
addpath(genpath('./'));

% 定义路径
Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_SiteData_As = '../output/21_SiteData_As/';
Path_Soilmo = '../output/01d_Soilmo_Y00/';
Path_SiteData_Soilmo = '../output/23d_SiteData_Soilmo/';

% 确保输出目录存在
system(['rm -rf ', Path_SiteData_Soilmo]);
system(['mkdir -p ', Path_SiteData_Soilmo]);

% 加载站点数据
load([Path_SiteData_As, 'SiteData_As.mat']);

% 读取 Soilmo 数据
File_Soilmo = fullfile(Path_Soilmo, 'Soilmo_Y00_CMG1KM.tif');
[Soilmo,R] = readgeoraster(File_Soilmo);

% 计算经纬度索引矩阵
MatrixLat = linspace(R.LatitudeLimits(2), R.LatitudeLimits(1), R.RasterSize(1))';
MatrixLon = linspace(R.LongitudeLimits(1), R.LongitudeLimits(2), R.RasterSize(2));

% 站点数据初始化
numSites = size(SiteData_As, 1);
SiteData_Soilmo = nan(numSites, 1);

Data_Lat = SiteData_As(:, 1);
Data_Lon = SiteData_As(:, 2);

% 站点 Soilmo 赋值
for i = 1:numSites
    Lat = Data_Lat(i);
    Lon = Data_Lon(i);

    % 查找最接近的栅格索引
    [~, IndRow] = min(abs(MatrixLat - Lat));
    [~, IndCol] = min(abs(MatrixLon - Lon));

    % 赋值
    SiteData_Soilmo(i) = Soilmo(IndRow, IndCol);
end

% 保存站点 Soilmo 结果
File_SiteData_Soilmo = fullfile(Path_SiteData_Soilmo, 'SiteData_Soilmo.mat');
save(File_SiteData_Soilmo, '-regexp', '^Site*');

disp('Site Soilmo extraction completed.');
