clear;clc;

addpath(genpath('./'));

Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_MulDiffCS = '../output/58_MeanDiffCS_CMG083DEG/';
Path_MulDiffWC = '../output/59_MeanDiffWC_CMG083DEG/';
Path_MulDiffCR = '../output/60_MeanDiffCR_CMG083DEG/';
Path_MulDiffSR = '../output/61_MeanDiffSR_CMG083DEG/';
Path_MulDiffAGB = '../output/62_MeanDiffAGB_CMG083DEG/';
Path_CO2EcoServ = '../output/63_SpaceMeanLoss/';

system(['rm -rf '  ,Path_CO2EcoServ]);
system(['mkdir -p ',Path_CO2EcoServ]);


WorldShape=shaperead('../misc/WorldCountry/world_country_boundary.shp','UseGeoCoords', true);

[LandCover,R] = readgeoraster([Path_LandCover,'LCTIGBP_USGS_MCD12Q1_Y10_CMG083DEG_20012010.tif']);  % LandCover坐标

LossCS = readgeoraster([Path_MulDiffCS,'WinCSLoss.CMG083DEG.tif']);
LossCR = readgeoraster([Path_MulDiffCR,'WinCRLoss.CMG083DEG.tif']);
LossWC = readgeoraster([Path_MulDiffWC,'WinWCLoss.CMG083DEG.tif']);
LossSR = readgeoraster([Path_MulDiffSR,'WinSRLoss.CMG083DEG.tif']);
LossAGB = readgeoraster([Path_MulDiffAGB,'WinAGBLoss.CMG083DEG.tif']);


AllCS = readgeoraster([Path_MulDiffCS,'WinCSTotal.CMG083DEG.tif']);
AllCR = readgeoraster([Path_MulDiffCR,'WinCRTotal.CMG083DEG.tif']);
AllWC = readgeoraster([Path_MulDiffWC,'WinWCTotal.CMG083DEG.tif']);
AllSR = readgeoraster([Path_MulDiffSR,'WinSRTotal.CMG083DEG.tif']);
AllAGB = readgeoraster([Path_MulDiffAGB,'WinAGBTotal.CMG083DEG.tif']);



LossCS((LandCover == 12 | LandCover == 14) & ~isnan(LossCS)) = 0;
AllCS((LandCover == 12 | LandCover == 14) & ~isnan(AllCS)) = 0;


LossCS(LossCS > 0 | LossCS == 0) = nan;  
LossSR(LossSR > 0 | LossSR == 0) = nan;  
LossWC(LossWC > 0 | LossWC == 0) = nan;  
LossCR(LossCR > 0 | LossCR == 0) = nan;  
LossAGB(LossAGB > 0 | LossAGB == 0) = nan; 

% loss account for allsum
Total5sum = sum(AllCS(:),'omitnan')+ sum(AllCR(:),'omitnan') + sum(AllWC(:),'omitnan')+sum(AllSR(:),'omitnan')+sum(AllAGB(:),'omitnan');
Loss5sum = sum(LossCS(:),'omitnan')+ sum(LossCR(:),'omitnan') + sum(LossWC(:),'omitnan')+ sum(LossSR(:),'omitnan')+ sum(LossAGB(:),'omitnan');

PercentLoss = abs(Loss5sum) / Total5sum;
disp(PercentLoss)


% 单位转换（根据需要，调整不同生态系统服务的转换系数）
LossCSCO2 = LossCS.*10^-6;  % g·CO2/m2 to t·CO2/m2
LossSRCO2 = LossSR .*3.67 .*10^-3;  % kg/m2 to t/m2 to tCo2-eq
LossAGBCO2 = LossAGB .*3.67; % MgC/m²
LossWCCO2 = LossWC.* 0.8 .*0.52 .*10^-3;  % KWh/m3  kgCO2eq/KWh to tCo2-eq
LossCRCO2 = LossCR .*0.52 .*10^-3;  % kgCO2eq/KWh to tCo2-eq
 

AllLosses = cat(3, LossCSCO2, LossCRCO2, LossWCCO2, LossSRCO2, LossAGBCO2);
TotalLoss = sum(AllLosses, 3, 'omitnan'); 

TotalLoss(TotalLoss>=0 ) = nan;

FileName =[Path_CO2EcoServ,'LossEcoServ.AsSpace.tif'];
geotiffwrite(FileName,TotalLoss,R,'TiffTags',struct('Compression',Tiff.Compression.LZW));

