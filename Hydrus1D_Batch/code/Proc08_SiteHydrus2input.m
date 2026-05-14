clear; clc;
addpath(genpath('./'));

%% ===============================
% 路径设置
% ===============================
PathIn  = '../output/05_SiteHydrus/';
PathPy  = '../output/06_Site2PyRosetta/';
PathOut = '../output/08_SiteHydrus2input/';
if ~exist(PathOut, 'dir'), mkdir(PathOut); end

%% ===============================
% 读取数据
% ===============================
load([PathIn,'SiteHydrus.mat']);
all_data = [PFTforest; PFTherb]; % 纵向合并森林和草本数据

% 读取 TOP 层结果
opts = detectImportOptions(fullfile(PathPy, 'input2rosettaTOP_results.csv'));
resTOP = readtable(fullfile(PathPy, 'input2rosettaTOP_results.csv'), opts);

% 读取 SUB 层结果
opts = detectImportOptions(fullfile(PathPy, 'input2rosettaSUB_results.csv'));
resSUB = readtable(fullfile(PathPy, 'input2rosettaSUB_results.csv'), opts);

%% ===============================
% 1. 自动定位关键变量列号
% ===============================
idx_clay_top = find(strcmp(Name, 'Clay_{top}'));
idx_clay_sub = find(strcmp(Name, 'Clay_{sub}'));
idx_WTD      = find(strcmp(Name, 'WTD'));
idx_RD       = find(strcmp(Name, 'RD')); 
idx_pH       = find(strcmp(Name, 'PH'));
idx_SOC       = find(strcmp(Name, 'SOC'));
idx_As       = find(strcmp(Name, 'As')); 

% 提取用于筛选的基础向量 (Unit: m)
WTD_raw = all_data(:, idx_WTD);
RD_raw  = all_data(:, idx_RD);
As_raw  = all_data(:, idx_As);

%% ===============================
% 2. 数据筛选 (关键步骤 - 已加入浓度过滤)
% ===============================

% 1. WTD_raw > 0: 水位不能在地表
% 2. (WTD_raw - RD_raw) <= 5: 水位与根深的差值在 5m 以内
% 3. As_raw > 5: ✅ 只保留砷浓度大于 5 的站点，<=5 的直接剔除
valid_idx = find(WTD_raw > 0 & (WTD_raw - RD_raw) <= 5 & As_raw > 5);

% 根据筛选后的索引提取水力参数子集
resTOP_f = resTOP(valid_idx, :);
resSUB_f = resSUB(valid_idx, :);

% 提取具体水力参数
Ks_top = resTOP_f.Ks;
Ks_sub = resSUB_f.Ks;
Alpha_top = resTOP_f.Alpha;
Alpha_sub = resSUB_f.Alpha;
n_top = resTOP_f.n;
n_sub = resSUB_f.n;
ThetaS_top = resTOP_f.Ths;
ThetaS_sub = resSUB_f.Ths;
ThetaR_top = resTOP_f.Thr;
ThetaR_sub = resSUB_f.Thr;

% 根据索引提取筛选后的基础数据子集
filtered_data = all_data(valid_idx, :);

%% ===============================
% 3. 修正后的 Kd 计算 (针对总溶解态砷 As-tot)
% ===============================

% 提取筛选后的列数据
pH_vals  = filtered_data(:, idx_pH);
Clay_top = filtered_data(:, idx_clay_top);
Clay_sub = filtered_data(:, idx_clay_sub);
WTD_vals = filtered_data(:, idx_WTD);
RD_vals  = filtered_data(:, idx_RD);
SOC_vals  = filtered_data(:, idx_SOC);
As_vals  = filtered_data(:, idx_As); 

% 科学逻辑说明：
% 1. 缺乏形态信息时，取 As(III) 和 As(V) 吸附特征的权重平滑值。
% 2. 变量协同：pH 决定电荷环境，Clay 提供物理位点，SOC 提供化学络合位点。
% 3. 响应系数：SOC 的系数设为 +0.15 (对数尺度)，反映有机质对砷的固定作用。
% 4. 稳健性：使用 log10(SOC + 1) 防止在高有机质区域（如湿地/泥炭土）出现极端的 Kd 飙升。

SOC_top = SOC_vals;          % 表层直接使用原始数据
SOC_sub = SOC_vals * 0.4;    % 底层按 40% 比例进行物理衰减修正

calc_kd_tot = @(ph, clay, soc, is_top) ...
    10.^( ...
        1.15 ...                  % 基础常数
        - 0.12 * ph ...          % pH 响应 (砷的阴离子特征)
        + 0.22 * log10(clay + 1) ... % 粘土贡献 (物理位点)
        + 0.15 * log10(soc + 1) ...  % SOC 贡献 (化学络合)
        + 0.05 * is_top ...      % 层位修正 (Topsoil 额外氧化增量)
    );

%% --- 3. 执行分层计算 ---
% 分别带入对应的层位数据
Kd_top = calc_kd_tot(pH_vals, Clay_top, SOC_top, 1);
Kd_sub = calc_kd_tot(pH_vals, Clay_sub, SOC_sub, 0);


% 计算弥散度 (Dispersion Length) 
DisperL = WTD_vals .* 10;  % cm*1/10 or m*10 ：通常设为路径长度的 1/10


%% ===============================
% 4. 保存结果
% ===============================
save_filename = fullfile(PathOut, 'HydrusInput.mat');

% 保存时加入了 valid_idx (原始索引) 和 As_vals (当前站点实际浓度)
save(save_filename, ...
    'Name','filtered_data','valid_idx','As_vals',...
    'Kd_top', 'Kd_sub', 'DisperL', ...
    'Ks_top','Ks_sub','Alpha_top','Alpha_sub',...
    'n_top','n_sub','ThetaR_sub','ThetaR_top',...
    'ThetaS_top','ThetaS_sub');

% % --- 验证输出 ---
% fprintf('📊 数据筛选完成！\n');
% fprintf('原始总站点数: %d\n', size(all_data, 1));
% fprintf('筛选后站点数 (WTD条件+As>5): %d\n', length(valid_idx));
fprintf('筛选后 Kd_top 均值: %.2f\n', mean(Kd_top));
fprintf('筛选后 Kd_sub 均值: %.2f\n', mean(Kd_sub));