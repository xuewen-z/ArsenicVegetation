clear; clc;
addpath(genpath('./'));

% 定义输入和输出路径
Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_GeoAsType = '../output/01a_AsProb_CMG1KM/';
Path_MulYNDVI = '../output/05d_NDVI_Y00_CMG1KM/';
Path_NDVIanomaly = '../output/14c1_NDVIanoAsType_CMG1KM/';

% 确保输出目录存在
system(['rm -rf ', Path_NDVIanomaly]);
system(['mkdir -p ', Path_NDVIanomaly]);

% 读取风险区掩码
File_GeoAsType = fullfile(Path_GeoAsType, 'AsType.TargetPixel.ControlPixel.CMG1KM.tif');
GeoAsType = readgeoraster(File_GeoAsType);

% 读取 NDVI 数据
File_NDVI = fullfile(Path_MulYNDVI, 'NDVIAVG_Y00_CMG1KM_20012020.tif');
GeoMulNDVI = double(readgeoraster(File_NDVI));
GeoMulNDVI(GeoMulNDVI==0) =nan;


File_LandCover = fullfile(Path_LandCover, 'LCTIGBP_USGS_MCD12Q1_Y10_CMG1KM_20012010.tif');
[~, R] = readgeoraster(File_LandCover);

WinSize = 100;  % 100*100 统计窗口 sample

AsThreshold = 0.05; % 5% 阈值

GeoNDVIanomaly = nan(R.RasterSize);
GeoNDVIcontAvg = nan(R.RasterSize);  % 存储 LRAs 平均 NDVI
GeoNDVIcontStd = nan(R.RasterSize);  % 存储 LRAs 标准差

% 遍历图像窗口 % test : 6400,34000
for Index = 1 : WinSize : size(GeoAsType,1)
    for j =  1 : WinSize : size(GeoAsType,2)   
     
        StartRow = Index:min(WinSize + Index -1, size(GeoAsType,1));
        StartCol = j:min(WinSize + j -1, size(GeoAsType,2));

        WinAs = GeoAsType(StartRow, StartCol);
        WinNDVI = GeoMulNDVI(StartRow, StartCol);

        % 统计不同风险区的像元数量
        TotalPixels = numel(WinAs(~isnan(WinAs)));
        CountENum = nnz(WinAs(:) == 4); % ERAs (极高风险区)
        CountHNum = nnz(WinAs(:) == 3); % HRAs
        CountMNum = nnz(WinAs(:) == 2); % MRAs
        CountLNum = nnz(WinAs(:) == 1); % LRAs
        
        RatioE = CountENum / TotalPixels;
        RatioH = CountHNum / TotalPixels; 
        RatioM = CountMNum / TotalPixels; 
        RatioL = CountLNum / TotalPixels;  
        
        
        % % 如果窗口内没有效像元直接跳过
        if TotalPixels == 0 || (CountENum+ CountHNum + CountMNum) == 0 || CountLNum == 0
            continue; % 直接跳过该窗口
        end

        % 筛选条件：HRAs + MRAs ≥ 5% 且 LRAs ≥ 5%
            if (RatioE + RatioH + RatioM) >= AsThreshold && RatioL >= AsThreshold
                % 计算 LRAs (低风险区) 的 NDVI 均值和标准差
                NDVIcontrol = WinNDVI(WinAs == 1); 
                NDVIcontAvg = mean(NDVIcontrol,'omitnan'); 
                NDVIcontStd = std(NDVIcontrol,'omitnan');
    
                  % 如果 NDVIcontAvg 或 NDVIcontStd 是 NaN，跳过
                if isnan(NDVIcontAvg) || isnan(NDVIcontStd)
                    continue; 
                end
    
               
                % 避免除零错误（如果标准差过小，设为 NaN）
                NDVIcontStd(NDVIcontStd < 1e-3) = 0.01;
                
               
                                                  
                    % 赋值 NDVIcontAvg 和 NDVIcontStd 给 LRAs 位置
                    WinNDVIcontAvg = nan(size(WinNDVI));
                    WinNDVIcontStd = nan(size(WinNDVI));
                    WinNDVIcontAvg(WinAs == 4 | WinAs == 3 | WinAs == 2 |WinAs == 1) = NDVIcontAvg;
                    WinNDVIcontStd(WinAs == 4 | WinAs == 3 | WinAs == 2 |WinAs == 1) = NDVIcontStd;
    
            
                     % 计算 NDVI anomaly
                    WinNDVIanomaly = nan(size(WinNDVI)); 
                    WinNDVIanomaly(WinAs == 4 | WinAs == 3 | WinAs == 2| WinAs == 1) = ...
                        (WinNDVI(WinAs == 4 | WinAs == 3 | WinAs == 2| WinAs == 1) - NDVIcontAvg) / NDVIcontStd;

                    GeoNDVIanomaly(StartRow, StartCol) = WinNDVIanomaly;
                    GeoNDVIcontAvg(StartRow, StartCol) = WinNDVIcontAvg;
                    GeoNDVIcontStd(StartRow, StartCol) = WinNDVIcontStd;
         
            else

                    GeoNDVIanomaly(StartRow, StartCol) = nan;
                    GeoNDVIcontAvg(StartRow, StartCol) = nan;
                    GeoNDVIcontStd(StartRow, StartCol) = nan;
            end

      end  
 end



% 保存 GeoTIFF 结果
geotiffwrite(fullfile(Path_NDVIanomaly, 'NDVIanoAsType_CMG1KM.tif'), GeoNDVIanomaly, R, ...
             'TiffTags', struct('Compression', Tiff.Compression.LZW));

disp('Done with NDVI anomaly');
 