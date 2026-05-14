clear; clc;

addpath(genpath('./'));

Path_SiteData_As = '../output/21_SiteData_As/';
Path_SiteData_LAI = '../output/22a_SiteData_LAI/';
Path_SiteData_CO2 = '../output/23b_SiteData_CO2/';
Path_SiteData_Ozone = '../output/23c_SiteData_Ozone/';
Path_SiteData_Soilmo = '../output/23d_SiteData_Soilmo/';
Path_SiteData_AridIndex = '../output/23e_SiteData_AridIndex/';
Path_SiteData_DEM = '../output/23g_SiteData_DEM/';
Path_SiteData_Climate = '../output/23h_SiteData_Climate/';
Path_SiteXCov = '../output/31j_SiteXcovENF/';

system(['rm -rf '  ,Path_SiteXCov]);
system(['mkdir -p ',Path_SiteXCov]);

load([Path_SiteData_LAI, 'SiteData_LAI.mat']);
load([Path_SiteData_As, 'SiteData_As.mat']);
load([Path_SiteData_Climate, 'SiteData_Climate.mat']);
load([Path_SiteData_DEM, 'SiteData_DEM.mat']);
load([Path_SiteData_Soilmo, 'SiteData_Soilmo.mat']);
load([Path_SiteData_Ozone, 'SiteData_Ozone.mat']);
load([Path_SiteData_CO2, 'SiteData_CO2.mat']);
load([Path_SiteData_AridIndex, 'SiteData_AridIndex.mat']);



SiteAs = SiteData_As(:,3); 
SiteCEC = SiteData_As(:,11); 
SitePH = SiteData_As(:,15); 
SiteSOC = SiteData_As(:,14); 
SiteAlpha = SiteData_As(:,9); 
SiteAI = SiteData_AridIndex;
SiteSWC = SiteData_As(:,20);
SitePre = SiteData_As(:,5);


% 数据清理，去除无效值
% Tall vegetation
Invalid =~(SiteData_PFT == 1); 
SiteData_Ta(Invalid) = nan;
SiteData_Rg(Invalid) = nan;
SitePre(Invalid) = nan;
SiteData_VPD(Invalid) = nan;
SiteData_Aspect(Invalid) = nan;
SiteData_DEM(Invalid) = nan;
SiteData_Ozone(Invalid) = nan;
SiteData_Soilmo(Invalid) = nan;
SiteData_CO2(Invalid) = nan;
SiteCEC(Invalid) = nan;
SitePH(Invalid) = nan;
SiteSOC(Invalid) = nan;
SiteSWC(Invalid) = nan;
SiteAlpha(Invalid) = nan;
SiteAI(Invalid) = nan;

Xcov = [SiteData_Ta,SiteCEC,SiteData_VPD,SiteData_Rg,SitePH,SitePre,SiteSOC,SiteData_Aspect,SiteData_DEM,SiteData_Soilmo,...
    SiteData_Ozone,SiteData_CO2,SiteAI,SiteAlpha,SiteSWC];

save([Path_SiteXCov, 'SiteXcov.mat'],'-regexp','^Xcov*');  
