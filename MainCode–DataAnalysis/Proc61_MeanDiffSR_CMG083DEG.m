% 
clear; clc;

addpath(genpath('./'));

Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_MulYSR = '../output/54_EcoServSR_CMG1KM/';
Path_GeoAsType = '../output/01a_AsProb_CMG1KM/';
Path_MulDiffSR = '../output/61_MeanDiffSR_CMG083DEG/';


system(['rm -rf '  ,Path_MulDiffSR]);
system(['mkdir -p ',Path_MulDiffSR]);


% 读取风险区掩码
GeoAsType = readgeoraster([Path_GeoAsType,'AsType.TargetPixel.ControlPixel.CMG1KM.tif']);

SR = readgeoraster([Path_MulYSR,'EcoServ_AVGSR_CMG1KM_B2001E2019.tif']);
LandCover = readgeoraster([Path_LandCover,'LCTIGBP_USGS_MCD12Q1_Y10_CMG1KM_20012010.tif']);
SR(LandCover==0 | LandCover==11 | LandCover==13 |LandCover==15 | LandCover==16 | LandCover==17 | LandCover==255)=nan;

[~,R] = readgeoraster([Path_LandCover,'LCTIGBP_USGS_MCD12Q1_Y10_CMG083DEG_20012010.tif']);  % LandCover坐标

WinSize = 100;  % 100*100 统计窗口 sample
NumRow = 0;
AsThreshold = 0.05; % 5% 阈值

LossSR = nan(R.RasterSize);
TotalSR = nan(R.RasterSize);


% 遍历图像窗口 % test : 6400,34000
for Index = 1 : WinSize : size(GeoAsType,1)
    NumRow = NumRow + 1 ;
    NumCol = 0;

    for j =  1 : WinSize : size(GeoAsType,2)   
        NumCol = NumCol + 1; 
         
        StartRow = Index:min(WinSize + Index -1, size(GeoAsType,1));
        StartCol = j:min(WinSize + j -1, size(GeoAsType,2));

        WinAs = GeoAsType(StartRow, StartCol);
        WinSR = SR(StartRow, StartCol);

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
                % 计算 LRAs (低风险区) 的 LAI 均值
                SRcontrol = WinSR(WinAs == 1); 
                SRtarget = WinSR(WinAs == 2 | WinAs == 3| WinAs == 4); 
               
               
              % 检查是否有足够的有效数据
            if nnz(~isnan(SRtarget)) < 2 || nnz(~isnan(SRcontrol)) < 2
                continue; 
            end
    
                MeanSRHM = mean(SRtarget,'omitnan') ;
                MeanSRL = mean(SRcontrol,'omitnan') ;
                                                                                     
                LossSR(NumRow,NumCol) = (MeanSRHM - MeanSRL).*(RatioE+RatioM+RatioH);;
                TotalSR(NumRow,NumCol) = mean(WinSR(:),'omitnan');
         
            else
                       
                LossSR(NumRow, NumCol) = nan;
                TotalSR(NumRow,NumCol) = nan;

            end

      end  
 end


FileName =[Path_MulDiffSR,'WinSRLoss.CMG083DEG.tif'];
geotiffwrite(FileName,LossSR,R,'TiffTags',struct('Compression',Tiff.Compression.LZW));

FileName =[Path_MulDiffSR,'WinSRTotal.CMG083DEG.tif'];
geotiffwrite(FileName,TotalSR,R,'TiffTags',struct('Compression',Tiff.Compression.LZW));
