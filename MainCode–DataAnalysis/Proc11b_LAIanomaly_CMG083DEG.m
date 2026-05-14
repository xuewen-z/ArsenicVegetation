clear; clc;
addpath(genpath('./'));

Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_GeoAsType = '../output/01a_AsProb_CMG1KM/';
Path_Anomaly_CMG1KM = '../output/11a_LAIanomaly_CMG1KM/';
Path_Anomaly_CMG083DEG = '../output/11b_LAIanomaly_CMG083DEG/';

system(['rm -rf ', Path_Anomaly_CMG083DEG]);
system(['mkdir -p ', Path_Anomaly_CMG083DEG]);

% 读取风险区掩码
File_GeoAsType = fullfile(Path_GeoAsType, 'AsType.TargetPixel.ControlPixel.CMG1KM.tif');
GeoAsType = readgeoraster(File_GeoAsType);

% 读取 LandCover 参考信息
File_LandCover = fullfile(Path_LandCover, 'LCTIGBP_USGS_MCD12Q1_Y10_CMG083DEG_20012010.tif');
[~, R] = readgeoraster(File_LandCover);

% 读取 LAI anomaly 数据
LAIanomaly = readgeoraster([Path_Anomaly_CMG1KM, 'LAIanomaly_CMG1KM.tif']);

WinSize = 100;
NumRow = 0;
epsilon = 0.05;

% LAIa __ for Globe
SignifiLAI = nan(round(size(LAIanomaly,1)/WinSize),round(size(LAIanomaly,2)/WinSize));
AnomalyLAI = nan(round(size(LAIanomaly,1)/WinSize),round(size(LAIanomaly,2)/WinSize));

% test : 6400,34000
for Index = 1 : WinSize : size(LAIanomaly,1)
    NumRow = NumRow + 1 ;
    NumCol = 0;
    
        for j = 1 : WinSize : size(LAIanomaly,2)   
            NumCol = NumCol + 1; 
         
                       StartRow = Index:min(WinSize + Index -1, size(LAIanomaly,1));
                       StartCol = j:min(WinSize + j -1, size(LAIanomaly,2));
                        
                      
                       LAIkm = LAIanomaly(StartRow,StartCol);
                       
                       if   numel(LAIkm(~isnan(LAIkm))) >= 2
                                                                          
                            MeanLAI083 = mean(LAIkm(:),'omitnan');
                                        
                            % 是否显著
                            p = signrank(LAIkm(~isnan(LAIkm)), epsilon);

                            SignifiLAI(NumRow, NumCol) = p;
                            AnomalyLAI(NumRow, NumCol) = MeanLAI083;  
                        else
                            % 如果没有有效数据，跳过该窗口
                            SignifiLAI(NumRow, NumCol) = nan;
                            AnomalyLAI(NumRow, NumCol) = nan;
                        end
                                         
    end
end

% 保存 LAI Anomaly 结果
geotiffwrite(fullfile(Path_Anomaly_CMG083DEG, 'AnomalyLAI_CMG083DEG.tif'), AnomalyLAI, R, ...
    'TiffTags', struct('Compression', Tiff.Compression.LZW));

% 保存 Wilcoxon 符号秩检验结果
geotiffwrite(fullfile(Path_Anomaly_CMG083DEG, 'SignifiLAI_CMG083DEG.tif'), SignifiLAI, R, ...
    'TiffTags', struct('Compression', Tiff.Compression.LZW));
