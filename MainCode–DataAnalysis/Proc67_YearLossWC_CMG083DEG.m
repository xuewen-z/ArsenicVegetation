

% 
clear; clc;

addpath(genpath('./'));

Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_MulYWC = '../output/52_EcoServWC_CMG1KM/';
Path_GeoAsType = '../output/01a_AsProb_CMG1KM/';
Path_YearLossWC = '../output/67_YearLossWC_CMG083DEG/';

system(['rm -rf '  ,Path_YearLossWC]);
system(['mkdir -p ',Path_YearLossWC]);

% 读取风险区掩码
GeoAsType = readgeoraster([Path_GeoAsType,'AsType.TargetPixel.ControlPixel.CMG1KM.tif']);


LandCover = readgeoraster([Path_LandCover,'LCTIGBP_USGS_MCD12Q1_Y10_CMG1KM_20012010.tif']);

[~,R] = readgeoraster([Path_LandCover,'LCTIGBP_USGS_MCD12Q1_Y10_CMG083DEG_20012010.tif']);  % LandCover坐标




for Year = 2002 : 2019
    YearName = num2str(Year,'%d');
    WC = readgeoraster([Path_MulYWC,'EcoServ_WC.Y',YearName,'_CMG1KM.tif']);
    WC(LandCover==0 | LandCover==11 | LandCover==13 | LandCover==15 | LandCover==16 | LandCover==17 | LandCover==255)=nan;

    WinSize = 100;  % 100*100 统计窗口 sample
    NumRow = 0;
    AsThreshold = 0.05; % 5% 阈值

       
LossWC = nan(R.RasterSize);
TotalWC = nan(R.RasterSize);


% 6400,34000
for Index = 1 : WinSize : size(GeoAsType,1)
    NumRow = NumRow + 1 ;
    NumCol = 0;
    
        for j =  1 : WinSize : size(GeoAsType,2)   
            NumCol = NumCol + 1; 
         
                       StartRow = Index:min(WinSize + Index -1, size(GeoAsType,1));
                       StartCol = j:min(WinSize + j -1, size(GeoAsType,2));
                        
                        WinAs = GeoAsType(StartRow,StartCol);
                        WinWC = WC(StartRow, StartCol);
                        
                      % 统计不同风险区的像元数量
        TotalPixels = numel(WinAs(~isnan(WinAs)));
        CountENum = nnz(WinAs(:) == 4); % ERAs
        CountHNum = nnz(WinAs(:) == 3); % HRAs
        CountMNum = nnz(WinAs(:) == 2); % MRAs
        CountLNum = nnz(WinAs(:) == 1); % LRAs
        
        RatioE = CountENum / TotalPixels;
        RatioH = CountHNum / TotalPixels; 
        RatioM = CountMNum / TotalPixels; 
        RatioL = CountLNum / TotalPixels;  
        
        
        % % 如果窗口内没有效像元直接跳过
        if TotalPixels == 0 ||  (CountENum+ CountHNum + CountMNum) == 0 || CountLNum == 0
            continue; % 直接跳过该窗口
        end

        % 筛选条件：HRAs + MRAs ≥ 5% 且 LRAs ≥ 5%
            if (RatioE + RatioH + RatioM) >= AsThreshold && RatioL >= AsThreshold
                % 计算 LRAs (低风险区) 的 LAI 均值
                WCcontrol = WinWC(WinAs == 1); 
                WCtarget = WinWC(WinAs == 2 | WinAs == 3| WinAs == 4); 
                   
              % 检查是否有足够的有效数据
            if nnz(~isnan(WCtarget)) < 2 || nnz(~isnan(WCcontrol)) < 2
                continue; 
            end
    
                MeanWCHM = mean(WCtarget,'omitnan') ;
                MeanWCL = mean(WCcontrol,'omitnan') ;
                                                                                     
                LossWC(NumRow,NumCol) = (MeanWCHM - MeanWCL).*(RatioE+RatioM+RatioH);
                TotalWC(NumRow,NumCol) = mean(WinWC(:),'omitnan');
         
            else
                       
                LossWC(NumRow, NumCol) = nan;
                TotalWC(NumRow,NumCol) = nan;
           
            end

      end  
 end

FileName =[Path_YearLossWC,'WinWCLoss.Y',YearName,'_CMG083DEG.tif'];
geotiffwrite(FileName,LossWC,R,'TiffTags',struct('Compression',Tiff.Compression.LZW));

FileName =[Path_YearLossWC,'WinWCTotal.Y',YearName,'_CMG083DEG.tif'];
geotiffwrite(FileName,TotalWC,R,'TiffTags',struct('Compression',Tiff.Compression.LZW));

LossWC(LossWC>0) = nan;
LossWCsum = sum(LossWC(:),'omitnan'); 
CO2LossWC(:,Year-2001) = LossWCsum;



disp(['Done with ', YearName])

end
save([Path_YearLossWC, 'CO2LossWC.mat'], 'CO2LossWC');  
