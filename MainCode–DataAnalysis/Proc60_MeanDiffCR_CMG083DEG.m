% 
clear; clc;

addpath(genpath('./'));

Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_MulYCR = '../output/53_EcoServCR_CMG1KM/';
Path_GeoAsType = '../output/01a_AsProb_CMG1KM/';
Path_MulDiffCR = '../output/60_MeanDiffCR_CMG083DEG/';


system(['rm -rf '  ,Path_MulDiffCR]);
system(['mkdir -p ',Path_MulDiffCR]);


% 读取风险区掩码
GeoAsType = readgeoraster([Path_GeoAsType,'AsType.TargetPixel.ControlPixel.CMG1KM.tif']);

CR = readgeoraster([Path_MulYCR,'EcoServ_AVGCR_CMG1KM_B2001E2019.tif']);
LandCover = readgeoraster([Path_LandCover,'LCTIGBP_USGS_MCD12Q1_Y10_CMG1KM_20012010.tif']);
CR(LandCover==0 | LandCover==11 | LandCover==13 |LandCover==15 | LandCover==16 | LandCover==17 | LandCover==255)=nan;

[~,R] = readgeoraster([Path_LandCover,'LCTIGBP_USGS_MCD12Q1_Y10_CMG083DEG_20012010.tif']);  % LandCover坐标

% 统计窗口参数
WinSize = 100;  
NumRow = 0;
AsThreshold = 0.05; % 5% 阈值

LossCR = nan(R.RasterSize);
TotalCR = nan(R.RasterSize);


% 遍历图像窗口 % test : 6400,34000
for Index = 1 : WinSize : size(GeoAsType,1)
    NumRow = NumRow + 1 ;
    NumCol = 0;

    for j =  1 : WinSize : size(GeoAsType,2)   
        NumCol = NumCol + 1; 
         
        StartRow = Index:min(WinSize + Index -1, size(GeoAsType,1));
        StartCol = j:min(WinSize + j -1, size(GeoAsType,2));

        WinAs = GeoAsType(StartRow, StartCol);
        WinCR = CR(StartRow, StartCol);

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

        % 筛选条件
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
                                                                                     
                LossCR(NumRow,NumCol) = (MeanCRHM - MeanCRL).*(RatioE+RatioM+RatioH);;
                TotalCR(NumRow,NumCol) = mean(WinCR(:),'omitnan');
         
            else
                       
                LossCR(NumRow, NumCol) = nan;
                TotalCR(NumRow,NumCol) = nan;
            end

      end  
 end


FileName =[Path_MulDiffCR,'WinCRLoss.CMG083DEG.tif'];
geotiffwrite(FileName,LossCR,R,'TiffTags',struct('Compression',Tiff.Compression.LZW));

FileName =[Path_MulDiffCR,'WinCRTotal.CMG083DEG.tif'];
geotiffwrite(FileName,TotalCR,R,'TiffTags',struct('Compression',Tiff.Compression.LZW));
