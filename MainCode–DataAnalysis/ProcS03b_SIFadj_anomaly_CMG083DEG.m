clear; clc;
addpath(genpath('./'));

Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_GeoAsType = '../output/01a_AsProb_CMG1KM/';
Path_Anomaly_CMG1KM = '../output/S03a_SIFadj_anomaly_CMG1KM/';
Path_Anomaly_CMG083DEG = '../output/S03b_SIFadj_anomaly_CMG083DEG/';

system(['rm -rf ', Path_Anomaly_CMG083DEG]);
system(['mkdir -p ', Path_Anomaly_CMG083DEG]);

% 读取风险区掩码
File_GeoAsType = fullfile(Path_GeoAsType, 'AsType.TargetPixel.ControlPixel.CMG1KM.tif');
GeoAsType = readgeoraster(File_GeoAsType);

% 读取 LandCover 参考信息
File_LandCover = fullfile(Path_LandCover, 'LCTIGBP_USGS_MCD12Q1_Y10_CMG083DEG_20012010.tif');
[~, R] = readgeoraster(File_LandCover);

% 读取 SIF anomaly 数据
SIFanomaly = readgeoraster([Path_Anomaly_CMG1KM, 'SIFadj_anomaly_CMG1KM.tif']);

WinSize = 100;
NumRow = 0;
epsilon = 0.05;

% SIFa __ for Globe
SignifiSIF = nan(round(size(SIFanomaly,1)/WinSize),round(size(SIFanomaly,2)/WinSize));
AnomalySIF = nan(round(size(SIFanomaly,1)/WinSize),round(size(SIFanomaly,2)/WinSize));

% test : 6400,34000
for Index = 1 : WinSize : size(SIFanomaly,1)
    NumRow = NumRow + 1 ;
    NumCol = 0;
    
        for j = 1 : WinSize : size(SIFanomaly,2)   
            NumCol = NumCol + 1; 
         
                       StartRow = Index:min(WinSize + Index -1, size(SIFanomaly,1));
                       StartCol = j:min(WinSize + j -1, size(SIFanomaly,2));
                        
                      
                       SIFkm = SIFanomaly(StartRow,StartCol);
                       
                       if   numel(SIFkm(~isnan(SIFkm))) >= 2
                                                                          
                            MeanSIF083 = mean(SIFkm(:),'omitnan');
                                        
                            % Wilcoxon 符号秩检验（检验 HRAs 和 MRAs 的 SIF anomaly 是否显著 ≠ 0）
                            p = signrank(SIFkm(~isnan(SIFkm)), epsilon);

                            SignifiSIF(NumRow, NumCol) = p;
                            AnomalySIF(NumRow, NumCol) = MeanSIF083;  
                        else
                            % 如果没有有效数据，跳过该窗口
                            SignifiSIF(NumRow, NumCol) = nan;
                            AnomalySIF(NumRow, NumCol) = nan;
                        end
                                         
    end
end

% 保存 SIF Anomaly 结果
geotiffwrite(fullfile(Path_Anomaly_CMG083DEG, 'AnomalySIFadj_CMG083DEG.tif'), AnomalySIF, R, ...
    'TiffTags', struct('Compression', Tiff.Compression.LZW));

% 保存 Wilcoxon 符号秩检验结果
geotiffwrite(fullfile(Path_Anomaly_CMG083DEG, 'SignifiSIFadj_CMG083DEG.tif'), SignifiSIF, R, ...
    'TiffTags', struct('Compression', Tiff.Compression.LZW));
