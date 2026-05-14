clear; clc;

addpath(genpath('./'));


Path_SiteXCov = '../output/31_SiteXcov/';
Path_SiteLAIadj = '../output/32b_SiteLAIadjCrop/';
Path_SiteData_As = '../output/21_SiteData_As/';
Path_SiteData_Irrigation = '../output/23f_SiteData_Irrigation/';
Path_SiteIrriPFT = '../output/39_SiteIrriPFT/';

system(['rm -rf ',Path_SiteIrriPFT]);
system(['mkdir -p ',Path_SiteIrriPFT]);

load([Path_SiteData_Irrigation, 'SiteData_Irrigation.mat']);
load([Path_SiteLAIadj, 'SiteLAIadjCROP.mat']);
load([Path_SiteData_As, 'SiteData_As.mat']);

SiteAs = SiteData_As(:,3);

%% LAI adjusted

SiteAs = SiteAs(~NanMaskAVG);
SiteIrriga = SiteData_Irrigation(~NanMaskAVG);


LAIAVGCRO= SiteLAI_AVGadj;
AsCRO = SiteAs;
IrriCRO= SiteIrriga;


save([Path_SiteIrriPFT,'SiteIrriPFT.mat'],'-regexp','^Irri*','^LAI*','^As*');



