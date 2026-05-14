clear; clc;
addpath(genpath('./'));

% 定义路径
Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_SiteData_As = '../output/21_SiteData_As/';
Path_MulLAI = '../output/05a_LAI_Y00_CMG1KM/';
Path_SiteData_LAI = '../output/22a_SiteData_LAI/';

% 确保输出目录存在
system(['rm -rf ', Path_SiteData_LAI]);
system(['mkdir -p ', Path_SiteData_LAI]);

% 加载站点数据
load([Path_SiteData_As, 'SiteData_As.mat']);

% 读取 LandCover 数据
File_LandCover = fullfile(Path_LandCover, 'LCTIGBP_USGS_MCD12Q1_Y10_CMG1KM_20012010.tif');
[LandCover, R] = readgeoraster(File_LandCover);

% 时间段
Periods = {'20012010', '20112020', '20012020'};
% Periods = {'20012020'};

% 计算经纬度索引矩阵
MatrixLat = linspace(R.LatitudeLimits(2), R.LatitudeLimits(1), R.RasterSize(1))';
MatrixLon = linspace(R.LongitudeLimits(1), R.LongitudeLimits(2), R.RasterSize(2));

% 站点经纬度
numSites = size(SiteData_As, 1);
Data_Lat = SiteData_As(:, 1);
Data_Lon = SiteData_As(:, 2);

% 初始化存储变量
SiteData_PFT = nan(numSites, 1);
for i = 1:length(Periods)
    Period = Periods{i};
    eval(['SiteData_LAIAVG_', Period, ' = nan(numSites, 1);']);
    eval(['SiteData_LAI95P_', Period, ' = nan(numSites, 1);']);
end

% 站点赋值
for i = 1:length(Periods)
    Period = Periods{i};
    LAIAVG_File = fullfile(Path_MulLAI, ['LAIAVG_Y00_CMG1KM_', Period, '.tif']);
    LAI95P_File = fullfile(Path_MulLAI, ['LAI95P_Y00_CMG1KM_', Period, '.tif']);

    % 读取 LAI 数据
    [MulLAIAVG, ~] = readgeoraster(LAIAVG_File);
    [MulLAI95P, ~] = readgeoraster(LAI95P_File);

    for j = 1:numSites
        Lat = Data_Lat(j);
        Lon = Data_Lon(j);

        % 查找最接近的栅格索引
        [~, IndRow] = min(abs(MatrixLat - Lat));
        [~, IndCol] = min(abs(MatrixLon - Lon));

        % 赋值
        eval(['SiteData_LAIAVG_', Period, '(j) = MulLAIAVG(IndRow, IndCol);']);
        eval(['SiteData_LAI95P_', Period, '(j) = MulLAI95P(IndRow, IndCol);']);
    end
end

% PFT 只计算一次
for j = 1:numSites
    Lat = Data_Lat(j);
    Lon = Data_Lon(j);

    [~, IndRow] = min(abs(MatrixLat - Lat));
    [~, IndCol] = min(abs(MatrixLon - Lon));

    SiteData_PFT(j) = LandCover(IndRow, IndCol);
end

% 保存站点 LAI 结果
File_SiteData_LAI = fullfile(Path_SiteData_LAI, 'SiteData_LAI.mat');
save(File_SiteData_LAI, '-regexp', '^Site');

fprintf('All LAI periods processing completed!\n');
