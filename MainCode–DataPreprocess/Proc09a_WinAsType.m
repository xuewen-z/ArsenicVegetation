clear; clc;
addpath(genpath('./'));

% 定义路径
Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_AsType = '../output/01a_AsProb_CMG1KM/';
Path_ExampleWin = '../output/09_ExampleWin/';

system(['rm -rf '  ,Path_ExampleWin]);
system(['mkdir -p ',Path_ExampleWin]);

[LandCover, R] = readgeoraster([Path_LandCover, 'LCTIGBP_USGS_MCD12Q1_Y10_CMG1KM_20012010.tif']);

% 读取风险区掩码
File_AsType = fullfile(Path_AsType, 'AsType.TargetPixel.ControlPixel.CMG1KM.tif');
AsType = double(readgeoraster(File_AsType));
AsType(LandCover == 0 | LandCover == 11| LandCover == 13| LandCover == 15 | LandCover == 16 | LandCover == 17 | LandCover == 255) = nan;



% 统计窗口大小
WinSize = 100;

[row_count, col_count] = size(AsType);

% 存储包含所有四个风险区的窗口行列号
valid_windows = [];

% 逐步滑动窗口
for row = 1:WinSize:row_count-WinSize+1
    for col = 1:WinSize:col_count-WinSize+1
        % 提取当前窗口
        current_window = AsType(row:row+WinSize-1, col:col+WinSize-1);

        % 计算各风险区占比
        total_pixels = numel(current_window) - sum(isnan(current_window), 'all');  % 非nan的有效像素总数
        if total_pixels == 0
            continue;
        end

        % 计算每个风险区的占比
        lra_ratio = sum(current_window == 1, 'all') / total_pixels;
        mra_ratio = sum(current_window == 2, 'all') / total_pixels;
        hra_ratio = sum(current_window == 3, 'all') / total_pixels;
        era_ratio = sum(current_window == 4, 'all') / total_pixels;

        % 检查是否包含四个风险区且每个占比都大于20%
        if lra_ratio > 0.05 && mra_ratio > 0.05 && hra_ratio > 0.05 && era_ratio > 0.05
            valid_windows = [valid_windows; row, col, lra_ratio, mra_ratio, hra_ratio, era_ratio];
        end
    end
end

% 指定测试样本索引

I = 6001; 
J = 35101; 

% 确保索引不超出边界
StartRow = I:min(I + WinSize - 1, size(AsType, 1));
StartCol = J:min(J + WinSize - 1, size(AsType, 2));

% 提取窗口数据
ExampleWin = double(AsType(StartRow, StartCol));


% 保存窗口数据
save(fullfile(Path_ExampleWin, 'ExampleWin.mat'), 'ExampleWin');

disp('Done');
