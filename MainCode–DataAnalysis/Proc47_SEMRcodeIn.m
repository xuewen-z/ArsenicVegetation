
clear; clc;

addpath(genpath('./'));

Path_SiteData_As = '../output/21_SiteData_As/';
Path_SiteData_LAI = '../output/22a_SiteData_LAI/';
Path_SiteData_LCC = '../output/22c_SiteData_LCC/';
Path_SiteData_CO2 = '../output/23b_SiteData_CO2/';
Path_SiteData_Ozone = '../output/23c_SiteData_Ozone/';
Path_SiteData_Soilmo = '../output/23d_SiteData_Soilmo/';
Path_SiteData_AridIndex = '../output/23e_SiteData_AridIndex/';
Path_SiteData_DEM = '../output/23g_SiteData_DEM/';
Path_SiteData_BESSEco = '../output/46_SiteData_BESSEco/';
Path_SiteData_Climate = '../output/23h_SiteData_Climate/';
% Path_SiteData_WTD = '../output/23i_SiteData_WTD/';
Path_SiteRcode = '../output/47_SEMRcodeIn/';

system(['rm -rf '  ,Path_SiteRcode]);
system(['mkdir -p ',Path_SiteRcode]);


load([Path_SiteData_LAI, 'SiteData_LAI.mat']);
load([Path_SiteData_LCC, 'SiteData_LCC.mat']);
load([Path_SiteData_As, 'SiteData_As.mat']);
load([Path_SiteData_Climate, 'SiteData_Climate.mat']);
load([Path_SiteData_DEM, 'SiteData_DEM.mat']);
load([Path_SiteData_Soilmo, 'SiteData_Soilmo.mat']);
load([Path_SiteData_Ozone, 'SiteData_Ozone.mat']);
load([Path_SiteData_CO2, 'SiteData_CO2.mat']);
load([Path_SiteData_AridIndex, 'SiteData_AridIndex.mat']);
load([Path_SiteData_BESSEco, 'SiteData_BESSEco.mat']);
% load([Path_SiteData_WTD, 'SiteData_WTD.mat']);



SiteData_As(:,6) = SiteData_AridIndex;
SiteData_As(:,7) = SiteData_Ta;

 SEMInData = [SiteData_GPPmax,SiteData_WUE,SiteData_CUE,SiteData_LAIAVG_20012020,SiteData_PFT,SiteData_CO2,SiteData_Soilmo,SiteData_Rg,SiteData_VPD,SiteData_DEM,SiteData_Ozone,SiteData_As];
 SEMHeadName = ['GPPmax','WUE','CUE','LAI','PFT','CO2','SM','RSDS','VPD','Elev','O3',SiteName_As];

 NanMask = find(SiteData_PFT == 17 | SiteData_PFT == 11 | SiteData_PFT == 13 | SiteData_PFT == 15 | SiteData_PFT == 16);
 SEMInData(NanMask,:) = nan;

 Rownans = any(isnan(SEMInData),2); 
 SEMInData = SEMInData(~Rownans,:); 

 Rowinfs = any(isinf(SEMInData),2); 
 SEMInData = SEMInData(~Rowinfs,:); 


 FilePath = fullfile(Path_SiteRcode, 'SEMRInData.csv');
 writematrix(SEMInData,FilePath);