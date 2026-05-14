clear; clc;

addpath(genpath('./'));


Path_SiteXCov = '../output/31_SiteXcov/';
Path_SiteLAIadj = '../output/32g_SiteLAIadjDBF/';
Path_SiteData_As = '../output/21_SiteData_As/';
Path_SiteData_AridIndex = '../output/23e_SiteData_AridIndex/';
Path_SiteData_Climate = '../output/23h_SiteData_Climate/';
Path_SiteDose = '../output/33g_DoseDataDBF/';

% 确保输出目录存在
system(['rm -rf ', Path_SiteDose]);
system(['mkdir -p ', Path_SiteDose]);

load([Path_SiteLAIadj, 'SiteLAIadj20012020.mat']);
load([Path_SiteXCov, 'SiteXcov.mat']);
load([Path_SiteData_As, 'SiteData_As.mat']);
load([Path_SiteData_AridIndex, 'SiteData_AridIndex.mat']);
load([Path_SiteData_Climate, 'SiteData_Climate.mat']);


SiteAs = SiteData_As(:,3); 
SiteAsAVG = SiteAs(~NanMaskAVG);


% Dose data
SitePre = SiteData_As(:,5); 
SiteAI = SiteData_AridIndex;
SiteTa = SiteData_Ta;
SiteCEC = SiteData_As(:,11); 
SiteSOC = SiteData_As(:,14); 
SitePH = SiteData_As(:,15); 


% 删除响应变量的 NaN 行
SitePre = SitePre(~NanMaskAVG);
SiteTa = SiteTa(~NanMaskAVG);
SiteAI = SiteAI(~NanMaskAVG);
SiteCEC = SiteCEC(~NanMaskAVG);
SiteSOC = SiteSOC(~NanMaskAVG);
SitePH = SitePH(~NanMaskAVG);

% 再次检查有效行
ValidIdx = ~isnan(SiteAsAVG) & ~isnan(SiteLAI_AVGadj);  


SiteAsAVG = SiteAsAVG(ValidIdx);
SiteLAI_AVGadj = SiteLAI_AVGadj(ValidIdx);
SitePre = SitePre(ValidIdx);
SiteTa = SiteTa(ValidIdx);
SiteAI = SiteAI(ValidIdx);
SiteSOC = SiteSOC(ValidIdx);
SiteCEC = SiteCEC(ValidIdx);
SitePH = SitePH(ValidIdx);

% 添加到表格
DoseSiteData = table(SiteAsAVG,SitePre,SiteTa,SiteAI,SitePH,SiteCEC,SiteSOC,...
    SiteLAI_AVGadj);

% 保存站点 SIF 结果
File_SiteDose = fullfile(Path_SiteDose, 'DoseSiteData.mat');
save(File_SiteDose, '-regexp', '^Dose*');



