clear; clc;
addpath(genpath('./'));

% 定义输入和输出路径
Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_GeoAsType = '../output/01a_AsProb_CMG1KM/';
Path_MulYLAI = '../output/05a_LAI_Y00_CMG1KM/';
Path_LAIanomaly = '../output/11c1_LAIanoAsType_CMG1KM/';

% 确保输出目录存在
system(['rm -rf ', Path_LAIanomaly]);
system(['mkdir -p ', Path_LAIanomaly]);

% 读取风险区掩码
File_GeoAsType = fullfile(Path_GeoAsType, 'AsType.TargetPixel.ControlPixel.CMG1KM.tif');
GeoAsType = readgeoraster(File_GeoAsType);

% 读取 LAI 数据
File_LAI = fullfile(Path_MulYLAI, 'LAIAVG_Y00_CMG1KM_20012020.tif');
GeoMulLAI = double(readgeoraster(File_LAI));
GeoMulLAI(GeoMulLAI==0) =nan;


File_LandCover = fullfile(Path_LandCover, 'LCTIGBP_USGS_MCD12Q1_Y10_CMG1KM_20012010.tif');
[~, R] = readgeoraster(File_LandCover);

WinSize = 100;  % 100*100 统计窗口 sample

AsThreshold = 0.05; % 5% 阈值

GeoLAIanomaly = nan(R.RasterSize);
GeoLAIcontAvg = nan(R.RasterSize);  % 存储 LRAs 平均 LAI
GeoLAIcontStd = nan(R.RasterSize);  % 存储 LRAs 标准差

% 遍历图像窗口 % test : 6400,34000
for Index = 1 : WinSize : size(GeoAsType,1)
    for j =  1 : WinSize : size(GeoAsType,2)   
     
        StartRow = Index:min(WinSize + Index -1, size(GeoAsType,1));
        StartCol = j:min(WinSize + j -1, size(GeoAsType,2));

        WinAs = GeoAsType(StartRow, StartCol);
        WinLAI = GeoMulLAI(StartRow, StartCol);

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
                % 计算 LRAs (低风险区) 的 LAI 均值和标准差
                LAIcontrol = WinLAI(WinAs == 1); 
                LAIcontAvg = mean(LAIcontrol,'omitnan'); 
                LAIcontStd = std(LAIcontrol,'omitnan');
    
                  % 如果 LAIcontAvg 或 LAIcontStd 是 NaN，跳过
                if isnan(LAIcontAvg) || isnan(LAIcontStd)
                    continue; 
                end
    
               
                % 避免除零错误（如果标准差过小，设为 NaN）
                LAIcontStd(LAIcontStd < 1e-3) = 0.01;
                
               
                                                  
                    % 赋值 LAIcontAvg 和 LAIcontStd 给 LRAs 位置
                    WinLAIcontAvg = nan(size(WinLAI));
                    WinLAIcontStd = nan(size(WinLAI));
                    WinLAIcontAvg(WinAs == 4 | WinAs == 3 | WinAs == 2 |WinAs == 1) = LAIcontAvg;
                    WinLAIcontStd(WinAs == 4 | WinAs == 3 | WinAs == 2 |WinAs == 1) = LAIcontStd;
    
            
                     % 计算 LAI anomaly
                    WinLAIanomaly = nan(size(WinLAI)); 
                    WinLAIanomaly(WinAs == 4 | WinAs == 3 | WinAs == 2| WinAs == 1) = ...
                        (WinLAI(WinAs == 4 | WinAs == 3 | WinAs == 2| WinAs == 1) - LAIcontAvg) / LAIcontStd;

                    GeoLAIanomaly(StartRow, StartCol) = WinLAIanomaly;
                    GeoLAIcontAvg(StartRow, StartCol) = WinLAIcontAvg;
                    GeoLAIcontStd(StartRow, StartCol) = WinLAIcontStd;
         
            else

                    GeoLAIanomaly(StartRow, StartCol) = nan;
                    GeoLAIcontAvg(StartRow, StartCol) = nan;
                    GeoLAIcontStd(StartRow, StartCol) = nan;
            end

      end  
 end



% 保存 GeoTIFF 结果
geotiffwrite(fullfile(Path_LAIanomaly, 'LAIanoAsType_CMG1KM.tif'), GeoLAIanomaly, R, ...
             'TiffTags', struct('Compression', Tiff.Compression.LZW));

disp('Done with LAI anomaly');
 