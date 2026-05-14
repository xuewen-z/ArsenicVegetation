clear; clc;
addpath(genpath('./'));

% 定义输入和输出路径
Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_GeoAsType = '../output/01a_AsProb_CMG1KM/';
Path_MulYLCC = '../output/07c_LCCmax_Y00_CMG1KM/';
Path_LCCanomaly = '../output/13a_LCCanomaly_CMG1KM/';

% 确保输出目录存在
system(['rm -rf ', Path_LCCanomaly]);
system(['mkdir -p ', Path_LCCanomaly]);

% 读取风险区掩码
File_GeoAsType = fullfile(Path_GeoAsType, 'AsType.TargetPixel.ControlPixel.CMG1KM.tif');
GeoAsType = readgeoraster(File_GeoAsType);

% 读取 LCC 数据
File_LCC = fullfile(Path_MulYLCC, 'LCC95P_Y00_CMG1KM_20012020.tif');
GeoMulLCC = double(readgeoraster(File_LCC));
GeoMulLCC(GeoMulLCC==0) =nan;


File_LandCover = fullfile(Path_LandCover, 'LCTIGBP_USGS_MCD12Q1_Y10_CMG1KM_20012010.tif');
[~, R] = readgeoraster(File_LandCover);

WinSize = 100;  % 100*100 统计窗口 sample

AsThreshold = 0.05; % 5% 阈值

GeoLCCanomaly = nan(R.RasterSize);
GeoLCCcontAvg = nan(R.RasterSize);  % 存储 LRAs 平均 LCC
GeoLCCcontStd = nan(R.RasterSize);  % 存储 LRAs 标准差

% 遍历图像窗口 % test : 6400,34000
for Index = 1 : WinSize : size(GeoAsType,1)
    for j =  1 : WinSize : size(GeoAsType,2)   
     
        StartRow = Index:min(WinSize + Index -1, size(GeoAsType,1));
        StartCol = j:min(WinSize + j -1, size(GeoAsType,2));

        WinAs = GeoAsType(StartRow, StartCol);
        WinLCC = GeoMulLCC(StartRow, StartCol);

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
                % 计算 LRAs (低风险区) 的 LCC 均值和标准差
                LCCcontrol = WinLCC(WinAs == 1); 
                LCCcontAvg = mean(LCCcontrol,'omitnan'); 
                LCCcontStd = std(LCCcontrol,'omitnan'); 
    
                  % 如果 LCCcontAvg 或 LCCcontStd 是 NaN，跳过
                if isnan(LCCcontAvg) || isnan(LCCcontStd)
                    continue; 
                end
    
               
                % 避免除零错误（如果标准差过小，设为 NaN）
                LCCcontStd(LCCcontStd < 1e-3) = 0.01;
                
                   
                TargetAs = WinLCC(WinAs == 2 | WinAs == 3 | WinAs == 4); % 极高+高+中风险区
                
                % 检查是否有足够的有效数据  % 存储结果（仅对 HRAs 和 MRAs 位置赋值）
                if  nnz(~isnan(TargetAs)) < 2                
                   continue;
                end
                    
                                  
                    % 赋值 LCCcontAvg 和 LCCcontStd 给 LRAs 位置
                    WinLCCcontAvg = nan(size(WinLCC));
                    WinLCCcontStd = nan(size(WinLCC));
                    WinLCCcontAvg(WinAs == 4 |WinAs == 3 | WinAs == 2 |WinAs == 1) = LCCcontAvg;
                    WinLCCcontStd(WinAs == 4 |WinAs == 3 | WinAs == 2 |WinAs == 1) = LCCcontStd;
    
            
                     % 计算 LCC anomaly
                    WinLCCanomaly = nan(size(WinLCC)); 
                    WinLCCanomaly(WinAs == 4 |WinAs == 2 | WinAs == 3) = ...
                        (WinLCC(WinAs == 4 |WinAs == 2 | WinAs == 3) - LCCcontAvg) / LCCcontStd;

                    GeoLCCanomaly(StartRow, StartCol) = WinLCCanomaly;
                    GeoLCCcontAvg(StartRow, StartCol) = WinLCCcontAvg;
                    GeoLCCcontStd(StartRow, StartCol) = WinLCCcontStd;
         
            else

                    GeoLCCanomaly(StartRow, StartCol) = nan;
                    GeoLCCcontAvg(StartRow, StartCol) = nan;
                    GeoLCCcontStd(StartRow, StartCol) = nan;
            end

      end  
 end



% 保存 GeoTIFF 结果
geotiffwrite(fullfile(Path_LCCanomaly, 'LCCanomaly_CMG1KM.tif'), GeoLCCanomaly, R, ...
             'TiffTags', struct('Compression', Tiff.Compression.LZW));
geotiffwrite(fullfile(Path_LCCanomaly, 'LCCcontAvg_CMG1KM.tif'), GeoLCCcontAvg, R, ...
             'TiffTags', struct('Compression', Tiff.Compression.LZW));
geotiffwrite(fullfile(Path_LCCanomaly, 'LCCcontStd_CMG1KM.tif'), GeoLCCcontStd, R, ...
             'TiffTags', struct('Compression', Tiff.Compression.LZW));

disp('Done with LCC anomaly');
