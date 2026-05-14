clear; clc;

addpath(genpath('./'));


Path_SiteXCov = '../output/31b_SiteXcovCrop/';
Path_SiteLAIadj = '../output/32b_SiteLAIadjCrop/';
Path_SiteData_As = '../output/21_SiteData_As/';
Path_SiteData_AridIndex = '../output/23e_SiteData_AridIndex/';
Path_SiteData_Climate = '../output/23h_SiteData_Climate/';
Path_SiteData_Irrigation = '../output/23f_SiteData_Irrigation/';
Path_SiteDose = '../output/33b_DoseDataCrop/';

% 确保输出目录存在
system(['rm -rf ', Path_SiteDose]);
system(['mkdir -p ', Path_SiteDose]);

load([Path_SiteLAIadj, 'SiteLAIadj20012020.mat']);
load([Path_SiteXCov, 'SiteXcov.mat']);
load([Path_SiteData_As, 'SiteData_As.mat']);
load([Path_SiteData_AridIndex, 'SiteData_AridIndex.mat']);
load([Path_SiteData_Climate, 'SiteData_Climate.mat']);
load([Path_SiteData_Irrigation, 'SiteData_Irrigation.mat']);

SiteAs = SiteData_As(:,3); 
SiteAsAVG = SiteAs(~NanMaskAVG);
SiteAs95P = SiteAs(~NanMask95P);

% Dose data
SitePre = SiteData_As(:,5); 
SiteAI = SiteData_AridIndex;
SiteTa = SiteData_Ta;
SiteCEC = SiteData_As(:,11); 
SiteSOC = SiteData_As(:,14); 
SitePH = SiteData_As(:,15); 
SiteIrri = SiteData_Irrigation;
SiteIrri(SiteIrri<=0)=0.001;

% 删除响应变量的 NaN 行
SitePre = SitePre(~NanMaskAVG);
SiteTa = SiteTa(~NanMaskAVG);
SiteAI = SiteAI(~NanMaskAVG);
SiteCEC = SiteCEC(~NanMaskAVG);
SiteSOC = SiteSOC(~NanMaskAVG);
SitePH = SitePH(~NanMaskAVG);
SiteIrri = SiteIrri(~NanMaskAVG);

% 再次检查有效行
ValidIdx = ~isnan(SiteAsAVG) & ~isnan(SiteLAI_AVGadj) & ~isnan(SiteIrri);  


SiteAsAVG = SiteAsAVG(ValidIdx);
SiteAs95P = SiteAs95P(ValidIdx);
SiteLAI_AVGadj = SiteLAI_AVGadj(ValidIdx);
SiteLAI_95Padj = SiteLAI_95Padj(ValidIdx);
SitePre = SitePre(ValidIdx);
SiteTa = SiteTa(ValidIdx);
SiteAI = SiteAI(ValidIdx);
SiteSOC = SiteSOC(ValidIdx);
SiteCEC = SiteCEC(ValidIdx);
SitePH = SitePH(ValidIdx);
SiteIrri = SiteIrri(ValidIdx);

% 添加到表格
DoseSiteData = table(SiteAsAVG,SiteAs95P,SitePre,SiteTa,SiteAI,SitePH,SiteCEC,SiteSOC,SiteIrri,...
    SiteLAI_AVGadj,SiteLAI_95Padj);

DoseSiteData.SiteAsAVG2 = DoseSiteData.SiteAsAVG.^2; 
DoseSiteData.SiteAs95P2 = DoseSiteData.SiteAs95P.^2; 


% 保存站点 SIF 结果
File_SiteDose = fullfile(Path_SiteDose, 'DoseSiteData.mat');
save(File_SiteDose, '-regexp', '^Dose*');



