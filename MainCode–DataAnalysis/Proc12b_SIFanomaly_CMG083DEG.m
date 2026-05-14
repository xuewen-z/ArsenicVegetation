clear; clc;
addpath(genpath('./'));

Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_Anomaly_CMG1KM = '../output/12a_SIFanomaly_CMG1KM/';
Path_Anomaly_CMG083DEG = '../output/12b_SIFanomaly_CMG083DEG/';

system(['rm -rf ', Path_Anomaly_CMG083DEG]);
system(['mkdir -p ', Path_Anomaly_CMG083DEG]);

% 读取 LandCover 参考信息
File_LandCover = fullfile(Path_LandCover, 'LCTIGBP_USGS_MCD12Q1_Y10_CMG083DEG_20012010.tif');
[~, R] = readgeoraster(File_LandCover);

% 读取 SIF anomaly 数据
SIFanomaly = readgeoraster([Path_Anomaly_CMG1KM, 'SIFanomaly_CMG1KM.tif']);

% 统计窗口参数
WinSize = 100;
epsilon = 0.05;

% 计算网格尺寸
numRows = ceil(size(SIFanomaly, 1) / WinSize);
numCols = ceil(size(SIFanomaly, 2) / WinSize);

% 预分配结果矩阵
SignifiSIF = nan(numRows, numCols);
AnomalySIF = nan(numRows, numCols);

% 遍历整个影像
for row = 1:numRows
    for col = 1:numCols
        % 计算窗口边界
        StartRow = (row - 1) * WinSize + 1;
        StartCol = (col - 1) * WinSize + 1;
        EndRow = min(StartRow + WinSize - 1, size(SIFanomaly, 1));
        EndCol = min(StartCol + WinSize - 1, size(SIFanomaly, 2));

        % 提取窗口数据
        WinSIF = SIFanomaly(StartRow:EndRow, StartCol:EndCol);
        validData = WinSIF(~isnan(WinSIF));

        % 计算均值和 Wilcoxon 符号秩检验
        if numel(validData) >= 2
            AnomalySIF(row, col) = mean(validData, 'omitnan');
            SignifiSIF(row, col) = signrank(validData, epsilon);
        end
    end
end

% 保存 SIF Anomaly 结果
geotiffwrite(fullfile(Path_Anomaly_CMG083DEG, 'AnomalySIF_CMG083DEG.tif'), AnomalySIF, R, ...
    'TiffTags', struct('Compression', Tiff.Compression.LZW));

% 保存 Wilcoxon 符号秩检验结果
geotiffwrite(fullfile(Path_Anomaly_CMG083DEG, 'SignifiSIF_CMG083DEG.tif'), SignifiSIF, R, ...
    'TiffTags', struct('Compression', Tiff.Compression.LZW));

disp('Done with SIF anomaly');
