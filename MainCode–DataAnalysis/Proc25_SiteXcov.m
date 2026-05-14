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
% Path_SiteData_WTD = '../output/23i_SiteData_WTD/';
Path_SiteXCov = '../output/25_SiteXcov/';

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
% load([Path_SiteData_WTD, 'SiteData_WTD.mat']);



SiteAs = SiteData_As(:,3); 
SiteCEC = SiteData_As(:,11); 
SitePH = SiteData_As(:,15); 
SiteSOC = SiteData_As(:,14); 
SiteAlpha = SiteData_As(:,9); 
SiteAI = SiteData_AridIndex;
SiteSWC = SiteData_As(:,20);
SitePre = SiteData_As(:,5);



% 数据清理，去除无效值

Invalid = (SiteData_PFT == 0| SiteData_PFT == 17| SiteData_PFT == 15 | SiteData_PFT == 13  | SiteData_PFT == 16 | SiteData_PFT == 11); 
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
% SiteData_WTD(Invalid) = nan;

% SiteData_PFT重新编码
SiteData_PFT(SiteData_PFT == 7) = 6;
SiteData_PFT(SiteData_PFT == 14 | SiteData_PFT == 12) = 7;
SiteData_PFT(Invalid)=12;


% 哑变量编码 PFT , dummyvar() 不能处理 0 或负数or NaN
PFTdum = dummyvar(SiteData_PFT);
PFTdum(:,12) = []; %  去掉与编码为12（无效类别）对应的那一列
PFTdum(:,10) = []; % 选择有效的参照类别 GRA


% 构建回归自变量矩阵 X，包含所有环境变量和 PFT 哑变量
Xcov = [SiteData_Ta,SiteCEC,SiteData_VPD,SiteData_Rg,SitePH,SitePre,SiteSOC,SiteData_Aspect,SiteData_DEM,SiteData_Soilmo,...
    SiteData_Ozone,SiteData_CO2,SiteAI,SiteAlpha,SiteSWC,PFTdum];

save([Path_SiteXCov, 'SiteXcov.mat'],'-regexp','^Xcov*');  
