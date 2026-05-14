clear; clc;
addpath(genpath('./'));

%% ===============================
% 路径
% ===============================
PathIn  = '../output/05_SiteHydrus/';
PathOut  = '../output/06_Site2PyRosetta/';

if ~exist(PathOut, 'dir'), mkdir(PathOut); end

%% ===============================
% 读取数据
% ===============================
load([PathIn,'SiteHydrus.mat']);


%% TOP
% 自动寻找列号
idx_sand = find(strcmp(Name, 'sand_{top}'));
idx_silt = find(strcmp(Name, 'silt_{top}'));
idx_clay = find(strcmp(Name, 'Clay_{top}'));

fprintf('列号确认：Sand=%d, Silt=%d, Clay=%d\n', idx_sand, idx_silt, idx_clay);

% --- 1. 纵向合并两个矩阵 ---
all_data = [PFTforest; PFTherb]; 

% --- 2. 提取目标三列 (Sand, Silt, Clay) ---
% 假设通过上面的步骤查到是 13, 11, 8 列（请以实际查到的为准）
subset_data = all_data(:, [idx_sand, idx_silt, idx_clay]);

% --- 3. 转换为 Table 并导出 ---
% 给列起好名字，方便 Python 识别
T = array2table(subset_data, 'VariableNames', {'Sand', 'Silt', 'Clay'});

% 导出为 CSV
save_name = fullfile(PathOut, 'input2rosettaTOP.csv');
writetable(T, save_name);
disp('导出成功！已生成 input2rosettaTOP.csv，包含约 1.88 万条数据。');

%% SUB

% 自动寻找列号
idx_sand = find(strcmp(Name, 'sand_{sub}'));
idx_silt = find(strcmp(Name, 'silt_{sub}'));
idx_clay = find(strcmp(Name, 'Clay_{sub}'));

fprintf('列号确认：Sand=%d, Silt=%d, Clay=%d\n', idx_sand, idx_silt, idx_clay);


% --- 2. 提取目标三列 (Sand, Silt, Clay) ---
% 假设通过上面的步骤查到是 13, 11, 8 列（请以实际查到的为准）
subset_data = all_data(:, [idx_sand, idx_silt, idx_clay]);

% --- 3. 转换为 Table 并导出 ---
% 给列起好名字，方便 Python 识别
T = array2table(subset_data, 'VariableNames', {'Sand', 'Silt', 'Clay'});

% 导出为 CSV
save_name = fullfile(PathOut, 'input2rosettaSUB.csv');
writetable(T, save_name);
disp('导出成功！已生成 input2rosettaSUB.csv，包含约 1.88 万条数据。');



% %% ===============================
% % 质量检查：Sand + Silt + Clay 总和校验
% % ===============================
% 
% % 计算每一行的总和
% sum_texture = sum(subset_data, 2);
% 
% % 设定容差范围 (99% - 101%)
% is_outlier = (sum_texture < 99 | sum_texture > 101);
% 
% % 提取异常值
% outlier_indices = find(is_outlier);
% outlier_values = subset_data(is_outlier, :);
% outlier_sums = sum_texture(is_outlier);
