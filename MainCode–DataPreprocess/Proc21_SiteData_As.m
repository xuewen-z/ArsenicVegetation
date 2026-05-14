clear; clc;
addpath(genpath('./'));

% 定义路径
Path_AsData = '../input/AsData/';
Path_SiteData_As = '../output/21_SiteData_As/';

% 确保输出目录存在
system(['rm -rf ', Path_SiteData_As]);
system(['mkdir -p ', Path_SiteData_As]);

% 读取数据，保持原始列名
File_AsData = fullfile(Path_AsData, 'arsenic_concentrations_predictor_data');
DataTable = readtable(File_AsData, 'VariableNamingRule', 'preserve');

% 提取前 20 列
Head = DataTable.Properties.VariableNames(1:20);
Data = table2array(DataTable(:, 1:20));
Data(Data == -9999) = nan;
Data(Data(:, 14) > 9000, 14) = NaN;
Data(Data(:, 3) > 500, 3) = NaN;

% 数据清理
DataClean = Data(~any(isnan(Data), 2), :); % 删除含 NaN 的行

% 变量命名一致
SiteData_As = DataClean;
SiteName_As = Head;

% 保存结果
save(fullfile(Path_SiteData_As, 'SiteData_As.mat'), '-regexp', '^Site*');

disp('Site data processing completed.');
