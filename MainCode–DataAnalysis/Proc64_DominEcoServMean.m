clear;clc;

addpath(genpath('./'));

Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_MulDiffCS = '../output/58_MeanDiffCS_CMG083DEG/';
Path_MulDiffWC = '../output/59_MeanDiffWC_CMG083DEG/';
Path_MulDiffCR = '../output/60_MeanDiffCR_CMG083DEG/';
Path_MulDiffSR = '../output/61_MeanDiffSR_CMG083DEG/';
Path_MulDiffAGB = '../output/62_MeanDiffAGB_CMG083DEG/';
Path_CO2EcoServ = '../output/64_DominEcoServMean/';

system(['rm -rf '  ,Path_CO2EcoServ]);
system(['mkdir -p ',Path_CO2EcoServ]);


WorldShape=shaperead('../misc/WorldCountry/world_country_boundary.shp','UseGeoCoords', true);

[LandCover,R] = readgeoraster([Path_LandCover,'LCTIGBP_USGS_MCD12Q1_Y10_CMG083DEG_20012010.tif']);  % LandCover坐标


LossCS = readgeoraster([Path_MulDiffCS,'WinCSLoss.CMG083DEG.tif']);
LossCR = readgeoraster([Path_MulDiffCR,'WinCRLoss.CMG083DEG.tif']);
LossWC = readgeoraster([Path_MulDiffWC,'WinWCLoss.CMG083DEG.tif']);
LossSR = readgeoraster([Path_MulDiffSR,'WinSRLoss.CMG083DEG.tif']);
LossAGB = readgeoraster([Path_MulDiffAGB,'WinAGBLoss.CMG083DEG.tif']);

LossCS((LandCover == 12 | LandCover == 14) & ~isnan(LossCS)) = 0;



% Step 1: 创建一个掩码，用于记录哪些地方是 NaN（非植被区域或海洋）
NaNmask = isnan(LossCS) | isnan(LossCR) | isnan(LossWC) | isnan(LossSR) | isnan(LossAGB);

LossCS(LossCS>0 | LossCS ==0 ) = nan;
LossCR(LossCR>0 | LossCS ==0 ) = nan;
LossWC(LossWC>0 | LossCS ==0 ) = nan;
LossSR(LossSR>0 | LossCS ==0 ) = nan;
LossAGB(LossAGB>0 | LossCS ==0 ) = nan;

% 单位转换（根据需要，调整不同生态系统服务的转换系数）
LossCSCO2 = abs(LossCS.*10^-6);  % g·CO2/m2 to t·CO2/m2 to tCo2-eq/m2
LossSRCO2 = abs(LossSR .*3.67 .*10^-3);  % kg/m2 to t/m2 to tCo2-eq/m2
LossAGBCO2 = abs(LossAGB .*3.67); % MgC/m2 (1Mg=1t) to tCo2-eq/m2
LossWCCO2 = abs(LossWC.* 0.8 .*0.52 .*10^-3);  % (m3/m2)*(KWh/m3) to kgCO2eq/KWh/m2 to tCo2-eq/m2
LossCRCO2 = abs(LossCR .*0.52 .*10^-3);  % kgCO2eq/KWh/m2 to tCo2-eq/m2


% Step 3: 找出每个网格点主导因素（损失最大的服务），并忽略 NaN 区域

LossCSCO2(NaNmask) = -Inf;
LossCRCO2(NaNmask) = -Inf;
LossWCCO2(NaNmask) = -Inf;
LossSRCO2(NaNmask) = -Inf;
LossAGBCO2(NaNmask) = -Inf;


% Step 2: 找出每个网格点主导因素
[~, DominEco] = nanmax(cat(3, LossCSCO2, LossCRCO2, LossWCCO2, LossSRCO2, LossAGBCO2), [], 3);

DominEco(NaNmask) = NaN;

% 主导因素的类型：1 = 固碳, 2 = 气候调节, 3 = 水源涵养, 4 = 土壤保持, 5 = 地上生物量

FileName =[Path_CO2EcoServ,'DominEcoServ.AsLoss.tif'];
geotiffwrite(FileName,DominEco,R,'TiffTags',struct('Compression',Tiff.Compression.LZW));

