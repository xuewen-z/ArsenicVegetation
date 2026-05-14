clear; clc;
addpath(genpath('./'));

% 定义路径
Path_SiteData_As = '../output/21_SiteData_As/';
Path_MulLCC = '../output/07c_LCCmax_Y00_CMG1KM/';
Path_SiteData_LCC = '../output/22c_SiteData_LCC/';

% 确保输出目录存在
system(['rm -rf ', Path_SiteData_LCC]);
system(['mkdir -p ', Path_SiteData_LCC]);

% 加载站点数据
load([Path_SiteData_As, 'SiteData_As.mat']);

% 读取 LCC 数据
File_MulLCC95P = fullfile(Path_MulLCC, 'LCC95P_Y00_CMG1KM_20012020.tif');
[MulLCC95P,R] = readgeoraster(File_MulLCC95P);

% 计算经纬度索引矩阵
MatrixLat = linspace(R.LatitudeLimits(2), R.LatitudeLimits(1), R.RasterSize(1))';
MatrixLon = linspace(R.LongitudeLimits(1), R.LongitudeLimits(2), R.RasterSize(2));

% 站点数据初始化
numSites = size(SiteData_As, 1);
SiteData_LCC95P = nan(numSites, 1);

Data_Lat = SiteData_As(:, 1);
Data_Lon = SiteData_As(:, 2);

% 站点 LCC 赋值
for i = 1:numSites
    Lat = Data_Lat(i);
    Lon = Data_Lon(i);

    % 查找最接近的栅格索引
    [~, IndRow] = min(abs(MatrixLat - Lat));
    [~, IndCol] = min(abs(MatrixLon - Lon));

    % 赋值
    SiteData_LCC95P(i) = MulLCC95P(IndRow, IndCol);
end

% 保存站点 LCC 结果
File_SiteData_LCC = fullfile(Path_SiteData_LCC, 'SiteData_LCC.mat');
save(File_SiteData_LCC, '-regexp', '^Site*');

disp('Site LCC extraction completed.');
