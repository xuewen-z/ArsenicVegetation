clear; clc;
addpath(genpath('./'));

Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_GeoAsType = '../output/01a_AsProb_CMG1KM/';
Path_SIFanomaly = '../output/12c1_SIFanoAsType_CMG1KM/';
Path_Anomaly_CMG083DEG = '../output/12c2_SIFanoAsType_CMG083DEG/';

system(['rm -rf ', Path_Anomaly_CMG083DEG]);
system(['mkdir -p ', Path_Anomaly_CMG083DEG]);

% 读取风险区掩码
File_GeoAsType = fullfile(Path_GeoAsType, 'AsType.TargetPixel.ControlPixel.CMG1KM.tif');
GeoAsType = readgeoraster(File_GeoAsType);

% 读取 LandCover 参考信息
File_LandCover = fullfile(Path_LandCover, 'LCTIGBP_USGS_MCD12Q1_Y10_CMG083DEG_20012010.tif');
[~, R] = readgeoraster(File_LandCover);

% 读取 SIF anomaly 数据
SIFanomaly = readgeoraster([Path_SIFanomaly, 'SIFanoAsType_CMG1KM.tif']);

% 统计窗口参数
WinSize = 100;
epsilon = 0.05;
AsThreshold = 0.05;

% 计算网格尺寸
numRows = ceil(size(SIFanomaly, 1) / WinSize);
numCols = ceil(size(SIFanomaly, 2) / WinSize);

% 预分配结果矩阵

LRAsMean = nan(numRows, numCols);
MRAsMean = nan(numRows, numCols);
HRAsMean = nan(numRows, numCols);
ERAsMean = nan(numRows, numCols);

LRAsSTD = nan(numRows, numCols);
MRAsSTD = nan(numRows, numCols);
HRAsSTD = nan(numRows, numCols);
ERAsSTD = nan(numRows, numCols); 

LRAsCounts = nan(numRows, numCols);
MRAsCounts = nan(numRows, numCols);
HRAsCounts = nan(numRows, numCols);
ERAsCounts = nan(numRows, numCols);

% 遍历整个影像
% test : 6400,34000
for row = 1:numRows
    for col = 1:numCols
        % 计算窗口边界
        StartRow = (row - 1) * WinSize + 1;
        StartCol = (col - 1) * WinSize + 1;
        EndRow = min(StartRow + WinSize - 1, size(SIFanomaly, 1));
        EndCol = min(StartCol + WinSize - 1, size(SIFanomaly, 2));

     
        % 提取窗口数据
        WinSIF = SIFanomaly(StartRow:EndRow, StartCol:EndCol);
        WinAsT = GeoAsType(StartRow:EndRow, StartCol:EndCol);

     
        % 计算ERAs, HRAs, MRAs, LRAs各自的均值（过滤 NaN）
        LRAsMean(row, col) = mean(WinSIF(WinAsT == 1),'omitnan');
        MRAsMean(row, col) = mean(WinSIF(WinAsT == 2),'omitnan');
        HRAsMean(row, col) = mean(WinSIF(WinAsT == 3),'omitnan');
        ERAsMean(row, col) = mean(WinSIF(WinAsT == 4),'omitnan'); 

        % 计算ERAs,HRAs, MRAs, LRAs各自的标准差（过滤 NaN）
        LRAsSTD(row, col) = std(WinSIF(WinAsT == 1),'omitnan');
        MRAsSTD(row, col) = std(WinSIF(WinAsT == 2),'omitnan');
        HRAsSTD(row, col) = std(WinSIF(WinAsT == 3),'omitnan');
        ERAsSTD(row, col) = std(WinSIF(WinAsT == 4),'omitnan'); 

        % 统计不同风险区的像元数量
        PixelTotal = numel(WinAsT(~isnan(WinAsT)));
        PixelERAs = nnz(WinAsT == 4); % ERAs
        PixelHRAs = nnz(WinAsT == 3); % HRAs
        PixelMRAs = nnz(WinAsT == 2); % MRAs
        PixelLRAs = nnz(WinAsT == 1); % LRAs

        RatioERAs = PixelERAs / PixelTotal;
        RatioHRAs = PixelHRAs / PixelTotal;
        RatioMRAs = PixelMRAs / PixelTotal;
        RatioLRAs = PixelLRAs / PixelTotal;

        % 筛选窗口: HRAs+MRAs ≥ 5% 且 LRAs ≥ 5%
        if (RatioERAs + RatioHRAs + RatioMRAs) < AsThreshold || RatioLRAs < AsThreshold
            continue;
        end

        % 计算LRAs有效像元个数
        LRAsCounts(row, col) = nnz(WinAsT == 1); % LRAs
        MRAsCounts(row, col) = nnz(WinAsT == 2); % MRAs
        HRAsCounts(row, col) = nnz(WinAsT == 3); % HRAs
        ERAsCounts(row, col) = nnz(WinAsT == 4); % ERAs
    end
end

% 保存 HRAs, MRAs, LRAs 的 SIF anomaly 均值
geotiffwrite(fullfile(Path_Anomaly_CMG083DEG, 'AnomalySIF_LRAsMean_CMG083DEG.tif'), LRAsMean, R, 'TiffTags', struct('Compression', Tiff.Compression.LZW));
geotiffwrite(fullfile(Path_Anomaly_CMG083DEG, 'AnomalySIF_MRAsMean_CMG083DEG.tif'), MRAsMean, R, 'TiffTags', struct('Compression', Tiff.Compression.LZW));
geotiffwrite(fullfile(Path_Anomaly_CMG083DEG, 'AnomalySIF_HRAsMean_CMG083DEG.tif'), HRAsMean, R, 'TiffTags', struct('Compression', Tiff.Compression.LZW));
geotiffwrite(fullfile(Path_Anomaly_CMG083DEG, 'AnomalySIF_ERAsMean_CMG083DEG.tif'), ERAsMean, R, 'TiffTags', struct('Compression', Tiff.Compression.LZW));

% 保存 HRAs, MRAs, LRAs 的 SIF anomaly 标准差
geotiffwrite(fullfile(Path_Anomaly_CMG083DEG, 'AnomalySIF_LRAsSTD_CMG083DEG.tif'), LRAsSTD, R, 'TiffTags', struct('Compression', Tiff.Compression.LZW));
geotiffwrite(fullfile(Path_Anomaly_CMG083DEG, 'AnomalySIF_MRAsSTD_CMG083DEG.tif'), MRAsSTD, R, 'TiffTags', struct('Compression', Tiff.Compression.LZW));
geotiffwrite(fullfile(Path_Anomaly_CMG083DEG, 'AnomalySIF_HRAsSTD_CMG083DEG.tif'), HRAsSTD, R, 'TiffTags', struct('Compression', Tiff.Compression.LZW));
geotiffwrite(fullfile(Path_Anomaly_CMG083DEG, 'AnomalySIF_ERAsSTD_CMG083DEG.tif'), ERAsSTD, R, 'TiffTags', struct('Compression', Tiff.Compression.LZW));

% 保存 LRAs 的像元个数
geotiffwrite(fullfile(Path_Anomaly_CMG083DEG, 'LRAsCounts_CMG083DEG.tif'), LRAsCounts, R, 'TiffTags', struct('Compression', Tiff.Compression.LZW));
geotiffwrite(fullfile(Path_Anomaly_CMG083DEG, 'MRAsCounts_CMG083DEG.tif'), MRAsCounts, R, 'TiffTags', struct('Compression', Tiff.Compression.LZW));
geotiffwrite(fullfile(Path_Anomaly_CMG083DEG, 'HRAsCounts_CMG083DEG.tif'), HRAsCounts, R, 'TiffTags', struct('Compression', Tiff.Compression.LZW));
geotiffwrite(fullfile(Path_Anomaly_CMG083DEG, 'ERAsCounts_CMG083DEG.tif'), ERAsCounts, R, 'TiffTags', struct('Compression', Tiff.Compression.LZW));

disp('Done with SIF anomaly');
