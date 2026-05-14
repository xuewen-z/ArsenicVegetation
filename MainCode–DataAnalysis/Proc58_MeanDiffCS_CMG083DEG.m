% 
clear; clc;

addpath(genpath('./'));

Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_MulYCS = '../output/51_EcoServCS_CMG1KM/';
Path_GeoAsType = '../output/01a_AsProb_CMG1KM/';
Path_MulDiffCS = '../output/58_MeanDiffCS_CMG083DEG/';


system(['rm -rf '  ,Path_MulDiffCS]);
system(['mkdir -p ',Path_MulDiffCS]);


% 读取风险区掩码
GeoAsType = readgeoraster([Path_GeoAsType,'AsType.TargetPixel.ControlPixel.CMG1KM.tif']);


CS = readgeoraster([Path_MulYCS,'EcoServ_AVGCS_CMG1KM_B2001E2019.tif']);
LandCover = readgeoraster([Path_LandCover,'LCTIGBP_USGS_MCD12Q1_Y10_CMG1KM_20012010.tif']);
CS(LandCover==0 | LandCover==12 |LandCover==14 | LandCover==11 | LandCover==13 |LandCover==15 | LandCover==16 | LandCover==17 | LandCover==255)=nan;

[~,R] = readgeoraster([Path_LandCover,'LCTIGBP_USGS_MCD12Q1_Y10_CMG083DEG_20012010.tif']);  % LandCover坐标

% 统计窗口参数
WinSize = 100;  
NumRow = 0;
AsThreshold = 0.05; % 5% 阈值

LossCS = nan(R.RasterSize);
TotalCS = nan(R.RasterSize);


% 遍历图像窗口 % test : 6400,34000
for Index = 1 : WinSize : size(GeoAsType,1)
    NumRow = NumRow + 1 ;
    NumCol = 0;

    for j =  1 : WinSize : size(GeoAsType,2)   
        NumCol = NumCol + 1; 
         
        StartRow = Index:min(WinSize + Index -1, size(GeoAsType,1));
        StartCol = j:min(WinSize + j -1, size(GeoAsType,2));

        WinAs = GeoAsType(StartRow, StartCol);
        WinCS = CS(StartRow, StartCol);

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
                % 计算 LRAs (低风险区) 的 LAI 值
                CScontrol = WinCS(WinAs == 1); 
                CStarget = WinCS(WinAs == 2 | WinAs == 3| WinAs == 4); 
               
               
              % 检查是否有足够的有效数据
            if nnz(~isnan(CStarget)) < 2 || nnz(~isnan(CScontrol)) < 2
                continue; 
            end
    
                MeanCSHM = mean(CStarget,'omitnan') ;
                MeanCSL = mean(CScontrol,'omitnan') ;
                                                                                     
                LossCS(NumRow,NumCol) = (MeanCSHM - MeanCSL).*(RatioE+RatioM+RatioH);
                TotalCS(NumRow,NumCol) = mean(WinCS(:),'omitnan');

            else
                       
                LossCS(NumRow, NumCol) = nan;
                TotalCS(NumRow,NumCol) = nan;
            end

      end  
 end


FileName =[Path_MulDiffCS,'WinCSLoss.CMG083DEG.tif'];
geotiffwrite(FileName,LossCS,R,'TiffTags',struct('Compression',Tiff.Compression.LZW));

FileName =[Path_MulDiffCS,'WinCSTotal.CMG083DEG.tif'];
geotiffwrite(FileName,TotalCS,R,'TiffTags',struct('Compression',Tiff.Compression.LZW));
