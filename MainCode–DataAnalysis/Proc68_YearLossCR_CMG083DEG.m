

% 
clear; clc;

addpath(genpath('./'));

Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_MulYCR = '../output/53_EcoServCR_CMG1KM/';
Path_GeoAsType = '../output/01a_AsProb_CMG1KM/';
Path_YearLossCR = '../output/68_YearLossCR_CMG083DEG/';

system(['rm -rf '  ,Path_YearLossCR]);
system(['mkdir -p ',Path_YearLossCR]);

% 读取风险区掩码
GeoAsType = readgeoraster([Path_GeoAsType,'AsType.TargetPixel.ControlPixel.CMG1KM.tif']);


LandCover = readgeoraster([Path_LandCover,'LCTIGBP_USGS_MCD12Q1_Y10_CMG1KM_20012010.tif']);

[~,R] = readgeoraster([Path_LandCover,'LCTIGBP_USGS_MCD12Q1_Y10_CMG083DEG_20012010.tif']);  % LandCover坐标




for Year = 2002 : 2019
    YearName = num2str(Year,'%d');
    CR = readgeoraster([Path_MulYCR,'EcoServ_CR.Y',YearName,'_CMG1KM.tif']);
    CR(LandCover==0 | LandCover==11 | LandCover==13 | LandCover==15 | LandCover==16 | LandCover==17 | LandCover==255)=nan;

    WinSize = 100;  % 100*100 统计窗口 sample
    NumRow = 0;
    AsThreshold = 0.05; % 5% 阈值

       
LossCR = nan(R.RasterSize);
TotalCR = nan(R.RasterSize);


% 6400,34000
for Index = 1 : WinSize : size(GeoAsType,1)
    NumRow = NumRow + 1 ;
    NumCol = 0;
    
        for j =  1 : WinSize : size(GeoAsType,2)   
            NumCol = NumCol + 1; 
         
                       StartRow = Index:min(WinSize + Index -1, size(GeoAsType,1));
                       StartCol = j:min(WinSize + j -1, size(GeoAsType,2));
                        
                        WinAs = GeoAsType(StartRow,StartCol);
                        WinCR = CR(StartRow, StartCol);
                        
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
                CRcontrol = WinCR(WinAs == 1); 
                CRtarget = WinCR(WinAs == 2 | WinAs == 3| WinAs == 4);
                   
              % 检查是否有足够的有效数据
            if nnz(~isnan(CRtarget)) < 2 || nnz(~isnan(CRcontrol)) < 2
                continue; 
            end
    
                MeanCRHM = mean(CRtarget,'omitnan') ;
                MeanCRL = mean(CRcontrol,'omitnan') ;
                                                                                     
                LossCR(NumRow,NumCol) = (MeanCRHM - MeanCRL).*(RatioE+RatioM+RatioH);
                TotalCR(NumRow,NumCol) = mean(WinCR(:),'omitnan');
  
            else
                       
                LossCR(NumRow, NumCol) = nan;
                TotalCR(NumRow,NumCol) = nan;

            end

      end  
 end

FileName =[Path_YearLossCR,'WinCRLoss.Y',YearName,'_CMG083DEG.tif'];
geotiffwrite(FileName,LossCR,R,'TiffTags',struct('Compression',Tiff.Compression.LZW));

FileName =[Path_YearLossCR,'WinCRTotal.Y',YearName,'_CMG083DEG.tif'];
geotiffwrite(FileName,TotalCR,R,'TiffTags',struct('Compression',Tiff.Compression.LZW));

LossCR(LossCR>0) = nan;
LossCRsum = sum(LossCR(:),'omitnan'); 
CO2LossCR(:,Year-2001) = LossCRsum;



disp(['Done with ', YearName])

end
save([Path_YearLossCR, 'CO2LossCR.mat'], 'CO2LossCR');  
