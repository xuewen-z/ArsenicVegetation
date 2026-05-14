clear; clc;
addpath(genpath('./'));

% 定义输入和输出路径
Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_GeoAsType = '../output/01a_AsProb_CMG1KM/';
Path_MulYLAI = '../output/05a_LAI_Y00_CMG1KM/';
Path_LAImean = '../output/11d_LAImean_CMG083/';

% 创建输出目录
system(['rm -rf ', Path_LAImean]);
system(['mkdir -p ', Path_LAImean]);

% 读取风险区掩码
File_GeoAsType = fullfile(Path_GeoAsType, 'AsType.TargetPixel.ControlPixel.CMG1KM.tif');
GeoAsType = readgeoraster(File_GeoAsType);

% 读取 LAI 数据
File_LAI = fullfile(Path_MulYLAI, 'LAIAVG_Y00_CMG1KM_20012020.tif');
GeoMulLAI = double(readgeoraster(File_LAI));
GeoMulLAI(GeoMulLAI==0) =nan;

% 读取 LandCover 参考信息
File_LandCover = fullfile(Path_LandCover, 'LCTIGBP_USGS_MCD12Q1_Y10_CMG083DEG_20012010.tif');
[~, R] = readgeoraster(File_LandCover);


WinSize = 100;  % 100*100 统计窗口
AsThreshold = 0.05;
NumRow =0;



LRAsMean = nan(R.RasterSize);
MRAsMean = nan(R.RasterSize);
HRAsMean = nan(R.RasterSize);
ERAsMean = nan(R.RasterSize);

for Index = 1 : WinSize : size(GeoAsType,1)
    NumRow = NumRow + 1 ;
    NumCol = 0;
    
        for j = 1 : WinSize : size(GeoAsType,2)   
            NumCol = NumCol + 1; 
         
                       StartRow = Index:min(WinSize + Index -1, size(GeoAsType,1));
                       StartCol = j:min(WinSize + j -1, size(GeoAsType,2));
                        
                        WinAs = GeoAsType(StartRow, StartCol);
                        WinLAI = GeoMulLAI(StartRow, StartCol);



        % 有效像元总数
        TotalPixels = nnz(~isnan(WinAs));
        if TotalPixels == 0
            continue;
        end

        % 风险等级像元数量
        CountLNum = nnz(WinAs == 1);
        CountMNum = nnz(WinAs == 2);
        CountHNum = nnz(WinAs == 3);
        CountENum = nnz(WinAs == 4);

        RatioL = CountLNum / TotalPixels;
        RatioM = CountMNum / TotalPixels;
        RatioH = CountHNum / TotalPixels;
        RatioE = CountENum / TotalPixels;

        % 筛选条件
        if (RatioL < AsThreshold || RatioE +RatioM + RatioH < AsThreshold)
            continue;
        end

        % 分别计算三类区域 LAI 均值
        Mean_LRAs = mean(WinLAI(WinAs == 1),'omitnan');
        Mean_MRAs = mean(WinLAI(WinAs == 2),'omitnan');
        Mean_HRAs = mean(WinLAI(WinAs == 3),'omitnan');
        Mean_ERAs = mean(WinLAI(WinAs == 4),'omitnan');

        % 写入对应像元区域
        LRAsMean(NumRow, NumCol) = Mean_LRAs;
        MRAsMean(NumRow, NumCol) = Mean_MRAs;
        HRAsMean(NumRow, NumCol) = Mean_HRAs;
        ERAsMean(NumRow, NumCol) = Mean_ERAs;
    end
end

% 保存结果
geotiffwrite(fullfile(Path_LAImean, 'LAI_LRAsMean_CMG083.tif'), LRAsMean, R, ...
             'TiffTags', struct('Compression', Tiff.Compression.LZW));
geotiffwrite(fullfile(Path_LAImean, 'LAI_MRAsMean_CMG083.tif'), MRAsMean, R, ...
             'TiffTags', struct('Compression', Tiff.Compression.LZW));
geotiffwrite(fullfile(Path_LAImean, 'LAI_HRAsMean_CMG083.tif'), HRAsMean, R, ...
             'TiffTags', struct('Compression', Tiff.Compression.LZW));
geotiffwrite(fullfile(Path_LAImean, 'LAI_ERAsMean_CMG083.tif'), ERAsMean, R, ...
             'TiffTags', struct('Compression', Tiff.Compression.LZW));

disp('Done. LAI mean values for LRAs, MRAs, and HRAs ERAs saved at 0.83° resolution.');
