clear; clc;
addpath(genpath('./'));

% 定义路径
Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_SiteData_As = '../output/21_SiteData_As/';
Path_WaterTD = '../input/Water-TableDepth/';
Path_SiteData_RD = '../output/23j_SiteData_RD/';

% 确保输出目录存在
system(['rm -rf ', Path_SiteData_RD]);
system(['mkdir -p ', Path_SiteData_RD]);

% 加载站点数据
load([Path_SiteData_As,'SiteData_As.mat']);

% 读取数据
[PRD,R] = readgeoraster([Path_WaterTD,'PRD_Y00_CMG1KM.tif']);
PRD = double(PRD);

% 计算经纬度索引矩阵
MatrixLat = linspace(R.LatitudeLimits(2), R.LatitudeLimits(1), R.RasterSize(1))';
MatrixLon = linspace(R.LongitudeLimits(1), R.LongitudeLimits(2), R.RasterSize(2));

% 站点数据初始化
numSites = size(SiteData_As, 1);
SiteData_RD = nan(numSites, 1);

Data_Lat = SiteData_As(:, 1);
Data_Lon = SiteData_As(:, 2);

% 站点 Irrigation 赋值
for i = 1:numSites
    Lat = Data_Lat(i);
    Lon = Data_Lon(i);

    % 查找最接近的栅格索引
    [~, IndRow] = min(abs(MatrixLat - Lat));
    [~, IndCol] = min(abs(MatrixLon - Lon));

    % 赋值
    SiteData_RD(i) = PRD(IndRow, IndCol);
end

% 保存站点 Irrigation 结果
File_SiteData_RD = fullfile(Path_SiteData_RD, 'SiteData_RD.mat');
save(File_SiteData_RD, '-regexp', '^Site*');

disp('Site RD extraction completed.');
