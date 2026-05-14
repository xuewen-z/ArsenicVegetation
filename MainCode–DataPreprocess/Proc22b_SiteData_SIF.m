clear; clc;
addpath(genpath('./'));

% 定义路径
Path_SiteData_As = '../output/21_SiteData_As/';
Path_MulSIF = '../output/05b_SIF_Y00_CMG1KM/';
Path_SiteData_SIF = '../output/22b_SiteData_SIF/';

% 确保输出目录存在
system(['rm -rf ', Path_SiteData_SIF]);
system(['mkdir -p ', Path_SiteData_SIF]);

% 加载站点数据
load([Path_SiteData_As, 'SiteData_As.mat']);

% 读取 SIF 数据
File_MulSIFAVG = fullfile(Path_MulSIF, 'SIFAVG_Y00_CMG1KM_20012020.tif');
[MulSIFAVG, R] = readgeoraster(File_MulSIFAVG);

% 计算经纬度索引矩阵
MatrixLat = linspace(R.LatitudeLimits(2), R.LatitudeLimits(1), R.RasterSize(1))';
MatrixLon = linspace(R.LongitudeLimits(1), R.LongitudeLimits(2), R.RasterSize(2));

% 站点数据初始化
numSites = size(SiteData_As, 1);
SiteData_SIFAVG = nan(numSites, 1);
SiteData_PFT = nan(numSites, 1);

Data_Lat = SiteData_As(:, 1);
Data_Lon = SiteData_As(:, 2);

% 站点 SIF 赋值
for i = 1:numSites
    Lat = Data_Lat(i);
    Lon = Data_Lon(i);

    % 查找最接近的栅格索引
    [~, IndRow] = min(abs(MatrixLat - Lat));
    [~, IndCol] = min(abs(MatrixLon - Lon));

    % 赋值
    SiteData_SIFAVG(i) = MulSIFAVG(IndRow, IndCol);
end

% 保存站点 SIF 结果
File_SiteData_SIF = fullfile(Path_SiteData_SIF, 'SiteData_SIF.mat');
save(File_SiteData_SIF, '-regexp', '^Site*');

disp('Site SIF extraction completed.');
