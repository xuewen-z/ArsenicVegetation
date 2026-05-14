clear; clc;
addpath(genpath('./'));

% 定义输入和输出路径
Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_GeoAsType = '../output/01a_AsProb_CMG1KM/';
Path_GeoSIFadj = '../output/S01b_GlobeSIFadj_CMG1KM/';
Path_SIFanomaly = '../output/S03a_SIFadj_anomaly_CMG1KM/';

% 确保输出目录存在
system(['rm -rf ', Path_SIFanomaly]);
system(['mkdir -p ', Path_SIFanomaly]);

% 读取风险区掩码
File_GeoAsType = fullfile(Path_GeoAsType, 'AsType.TargetPixel.ControlPixel.CMG1KM.tif');
GeoAsType = readgeoraster(File_GeoAsType);

% 读取 SIF 数据
File_SIF = fullfile(Path_GeoSIFadj,'SIFadj_B2001E2020_CMG1KM.tif');
GeoSIFadj = double(readgeoraster(File_SIF));


File_LandCover = fullfile(Path_LandCover, 'LCTIGBP_USGS_MCD12Q1_Y10_CMG1KM_20012010.tif');
[~, R] = readgeoraster(File_LandCover);

WinSize = 100;  % 100*100 统计窗口 sample

AsThreshold = 0.05; % 5% 阈值

GeoSIFanomaly = nan(R.RasterSize);
GeoSIFcontAvg = nan(R.RasterSize);  % 存储 LRAs 平均 SIF
GeoSIFcontStd = nan(R.RasterSize);  % 存储 LRAs 标准差

% 遍历图像窗口 % test : 6400,34000
for Index = 1 : WinSize : size(GeoAsType,1)
    for j =  1 : WinSize : size(GeoAsType,2)   
     
        StartRow = Index:min(WinSize + Index -1, size(GeoAsType,1));
        StartCol = j:min(WinSize + j -1, size(GeoAsType,2));

        WinAs = GeoAsType(StartRow, StartCol);
        WinSIF = GeoSIFadj(StartRow, StartCol);

        % 统计不同风险区的像元数量
        TotalPixels = numel(WinAs(~isnan(WinAs)));               
        CountHNum = nnz(WinAs(:) == 3); % HRAs
        CountMNum = nnz(WinAs(:) == 2); % MRAs
        CountLNum = nnz(WinAs(:) == 1); % LRAs
        
        RatioH = CountHNum / TotalPixels; 
        RatioM = CountMNum / TotalPixels; 
        RatioL = CountLNum / TotalPixels;  
        
        
        % % 如果窗口内没有效像元直接跳过
        if TotalPixels == 0 || CountHNum + CountMNum == 0 || CountLNum == 0
            continue; % 直接跳过该窗口
        end

        % 筛选条件：HRAs + MRAs ≥ 5% 且 LRAs ≥ 5%
            if (RatioH + RatioM) >= AsThreshold && RatioL >= AsThreshold
                % 计算 LRAs (低风险区) 的 SIF 均值和标准差
                SIFcontrol = WinSIF(WinAs == 1); 
                SIFcontAvg = nanmean(SIFcontrol); 
                SIFcontStd = nanstd(SIFcontrol);
    
                  % 如果 SIFcontAvg 或 SIFcontStd 是 NaN，跳过
                if isnan(SIFcontAvg) || isnan(SIFcontStd)
                    continue; 
                end
    
               
                % 避免除零错误（如果标准差过小，设为 NaN）
                SIFcontStd(SIFcontStd < 1e-3) = 0.01;
                
               
    
                TargetAs = WinSIF(WinAs == 2 | WinAs == 3); % 高+中风险区
                % 检查是否有足够的有效数据  % 存储结果（仅对 HRAs 和 MRAs 位置赋值）
                if  nnz(~isnan(TargetAs)) < 2                
                   continue;
                end
                    
                                  
                    % 赋值 SIFcontAvg 和 SIFcontStd 给 LRAs 位置
                    WinSIFcontAvg = nan(size(WinSIF));
                    WinSIFcontStd = nan(size(WinSIF));
                    WinSIFcontAvg(WinAs == 3 | WinAs == 2 |WinAs == 1) = SIFcontAvg;
                    WinSIFcontStd(WinAs == 3 | WinAs == 2 |WinAs == 1) = SIFcontStd;
    
            
                     % 计算 SIF anomaly
                    WinSIFanomaly = nan(size(WinSIF)); 
                    WinSIFanomaly(WinAs == 2 | WinAs == 3) = ...
                        (WinSIF(WinAs == 2 | WinAs == 3) - SIFcontAvg) / SIFcontStd;

                    GeoSIFanomaly(StartRow, StartCol) = WinSIFanomaly;
                    GeoSIFcontAvg(StartRow, StartCol) = WinSIFcontAvg;
                    GeoSIFcontStd(StartRow, StartCol) = WinSIFcontStd;
         
            else

                    GeoSIFanomaly(StartRow, StartCol) = nan;
                    GeoSIFcontAvg(StartRow, StartCol) = nan;
                    GeoSIFcontStd(StartRow, StartCol) = nan;
            end

      end  
 end



% 保存 GeoTIFF 结果
geotiffwrite(fullfile(Path_SIFanomaly, 'SIFadj_anomaly_CMG1KM.tif'), GeoSIFanomaly, R, ...
             'TiffTags', struct('Compression', Tiff.Compression.LZW));
geotiffwrite(fullfile(Path_SIFanomaly, 'SIFcontAvg_CMG1KM.tif'), GeoSIFcontAvg, R, ...
             'TiffTags', struct('Compression', Tiff.Compression.LZW));
geotiffwrite(fullfile(Path_SIFanomaly, 'SIFcontStd_CMG1KM.tif'), GeoSIFcontStd, R, ...
             'TiffTags', struct('Compression', Tiff.Compression.LZW));

disp('Done with SIF anomaly');
 