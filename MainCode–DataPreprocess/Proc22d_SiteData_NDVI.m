clear; clc;
addpath(genpath('./'));

% 定义路径
Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_SiteData_As = '../output/21_SiteData_As/';
Path_MulNDVI = '../output/05d_NDVI_Y00_CMG1KM/';
Path_SiteData_NDVI = '../output/22d_SiteData_NDVI/';

% 确保输出目录存在
system(['rm -rf ', Path_SiteData_NDVI]);
system(['mkdir -p ', Path_SiteData_NDVI]);

% 加载站点数据
load([Path_SiteData_As, 'SiteData_As.mat']);

% 读取 LandCover 数据
File_LandCover = fullfile(Path_LandCover, 'LCTIGBP_USGS_MCD12Q1_Y10_CMG1KM_20012010.tif');
[~, R] = readgeoraster(File_LandCover);

% 时间段
Periods = {'20012020'};

% 计算经纬度索引矩阵
MatrixLat = linspace(R.LatitudeLimits(2), R.LatitudeLimits(1), R.RasterSize(1))';
MatrixLon = linspace(R.LongitudeLimits(1), R.LongitudeLimits(2), R.RasterSize(2));

% 站点经纬度
numSites = size(SiteData_As, 1);
Data_Lat = SiteData_As(:, 1);
Data_Lon = SiteData_As(:, 2);

% 初始化存储变量
for i = 1:length(Periods)
    Period = Periods{i};
    eval(['SiteData_NDVIAVG_', Period, ' = nan(numSites, 1);']);
    
end

% 站点赋值
for i = 1:length(Periods)
    Period = Periods{i};
    NDVIAVG_File = fullfile(Path_MulNDVI, ['NDVIAVG_Y00_CMG1KM_', Period, '.tif']);
   
    % 读取 NDVI 数据
    [MulNDVIAVG, ~] = readgeoraster(NDVIAVG_File);
 

    for j = 1:numSites
        Lat = Data_Lat(j);
        Lon = Data_Lon(j);

        % 查找最接近的栅格索引
        [~, IndRow] = min(abs(MatrixLat - Lat));
        [~, IndCol] = min(abs(MatrixLon - Lon));

        % 赋值
        eval(['SiteData_NDVIAVG_', Period, '(j) = MulNDVIAVG(IndRow, IndCol);']);
       
    end
end

% 保存站点 NDVI 结果
File_SiteData_NDVI = fullfile(Path_SiteData_NDVI, 'SiteData_NDVI.mat');
save(File_SiteData_NDVI, '-regexp', '^Site');

fprintf('All NDVI periods processing completed!\n');
