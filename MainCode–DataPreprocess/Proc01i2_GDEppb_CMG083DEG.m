clear; clc;
addpath(genpath('./'));

Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_GDE1KM = '../input/GDEppb/gde_merged_output/';
Path_GDE083 = '../input/GDEppb/gde_merged_output/';


% 读取 LandCover 参考信息
File_LandCover = fullfile(Path_LandCover, 'LCTIGBP_USGS_MCD12Q1_Y10_CMG083DEG_20012010.tif');
[~, R] = readgeoraster(File_LandCover);

% 读取 LAI anomaly 数据
GDE = double(readgeoraster([Path_GDE1KM,'global_GDE_1km_band2.tif']));  
GDE(GDE>100) =nan;

WinSize = 100;
NumRow = 0;

GDE083 = nan(round(size(GDE,1)/WinSize),round(size(GDE,2)/WinSize));

% test : 6400,34000
for Index = 1 : WinSize : size(GDE,1)
    NumRow = NumRow + 1 ;
    NumCol = 0;
    
        for j = 1 : WinSize : size(GDE,2)   
            NumCol = NumCol + 1; 
         
                       StartRow = Index:min(WinSize + Index -1, size(GDE,1));
                       StartCol = j:min(WinSize + j -1, size(GDE,2));
                        
                      
                       GDEkm = GDE(StartRow,StartCol);
                       
                       if   numel(GDEkm(~isnan(GDEkm))) >= 2
                                                                          
                            MeanGDE083 = mean(GDEkm(:),'omitnan');
                            GDE083(NumRow, NumCol) = MeanGDE083;  
                        else
                            % 如果没有有效数据，跳过该窗口                           
                            GDE083(NumRow, NumCol) = nan;
                        end
                                         
    end
end

% 保存 LAI Anomaly 结果
geotiffwrite(fullfile(Path_GDE083, 'GDEppb_CMG083DEG.tif'), GDE083, R, ...
    'TiffTags', struct('Compression', Tiff.Compression.LZW));

