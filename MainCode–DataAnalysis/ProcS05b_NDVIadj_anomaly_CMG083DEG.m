clear; clc;
addpath(genpath('./'));

Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_GeoAsType = '../output/01a_AsProb_CMG1KM/';
Path_Anomaly_CMG1KM = '../output/S05a_NDVIadj_anomaly_CMG1KM/';
Path_Anomaly_CMG083DEG = '../output/S05b_NDVIadj_anomaly_CMG083DEG/';

system(['rm -rf ', Path_Anomaly_CMG083DEG]);
system(['mkdir -p ', Path_Anomaly_CMG083DEG]);

% 读取风险区掩码
File_GeoAsType = fullfile(Path_GeoAsType, 'AsType.TargetPixel.ControlPixel.CMG1KM.tif');
GeoAsType = readgeoraster(File_GeoAsType);

% 读取 LandCover 参考信息
File_LandCover = fullfile(Path_LandCover, 'LCTIGBP_USGS_MCD12Q1_Y10_CMG083DEG_20012010.tif');
[~, R] = readgeoraster(File_LandCover);

% 读取 NDVI anomaly 数据
NDVIanomaly = readgeoraster([Path_Anomaly_CMG1KM, 'NDVIadj_anomaly_CMG1KM.tif']);

WinSize = 100;
NumRow = 0;
epsilon = 0.05;

% NDVIa __ for Globe
SignifiNDVI = nan(round(size(NDVIanomaly,1)/WinSize),round(size(NDVIanomaly,2)/WinSize));
AnomalyNDVI = nan(round(size(NDVIanomaly,1)/WinSize),round(size(NDVIanomaly,2)/WinSize));

% test : 6400,34000
for Index = 1 : WinSize : size(NDVIanomaly,1)
    NumRow = NumRow + 1 ;
    NumCol = 0;
    
        for j = 1 : WinSize : size(NDVIanomaly,2)   
            NumCol = NumCol + 1; 
         
                       StartRow = Index:min(WinSize + Index -1, size(NDVIanomaly,1));
                       StartCol = j:min(WinSize + j -1, size(NDVIanomaly,2));
                        
                      
                       NDVIkm = NDVIanomaly(StartRow,StartCol);
                       
                       if   numel(NDVIkm(~isnan(NDVIkm))) >= 2
                                                                          
                            MeanNDVI083 = mean(NDVIkm(:),'omitnan');
                                        
                            % Wilcoxon 符号秩检验（检验 HRAs 和 MRAs 的 NDVI anomaly 是否显著 ≠ 0）
                            p = signrank(NDVIkm(~isnan(NDVIkm)), epsilon);

                            SignifiNDVI(NumRow, NumCol) = p;
                            AnomalyNDVI(NumRow, NumCol) = MeanNDVI083;  
                        else
                            % 如果没有有效数据，跳过该窗口
                            SignifiNDVI(NumRow, NumCol) = nan;
                            AnomalyNDVI(NumRow, NumCol) = nan;
                        end
                                         
    end
end

% 保存 NDVI Anomaly 结果
geotiffwrite(fullfile(Path_Anomaly_CMG083DEG, 'AnomalyNDVIadj_CMG083DEG.tif'), AnomalyNDVI, R, ...
    'TiffTags', struct('Compression', Tiff.Compression.LZW));

% 保存 Wilcoxon 符号秩检验结果
geotiffwrite(fullfile(Path_Anomaly_CMG083DEG, 'SignifiNDVIadj_CMG083DEG.tif'), SignifiNDVI, R, ...
    'TiffTags', struct('Compression', Tiff.Compression.LZW));


