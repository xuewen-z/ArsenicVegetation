clear; clc;
addpath(genpath('./'));

%% ===============================
% 路径
% ===============================
PathAs   = '../output/21_SiteData_As/';
PathLAI  = '../output/22a_SiteData_LAIH1D/';
PathRD   = '../output/23j_SiteData_RD/';
PathOut  = '../output/05_SiteHydrus/';

system(['rm -rf ', PathOut]);
system(['mkdir -p ', PathOut]);

%% ===============================
% 读取数据
% ===============================
load([PathLAI,'SiteData_LAIH1D.mat']);
load([PathRD, 'SiteData_RD.mat']);
load([PathAs, 'SiteData_AsH1D.mat']);

Data = [ ...
    SiteData_As(:,[1:6,11:14,15,16:19,21]), ... % 含 AI / WTD
    abs(SiteData_RD), ...                       % RD
    SiteData_PFT, ...                           % PFT
    SiteData_LAIAVG_20012020];                  % LAI

Name = [ ...
    SiteName_As(:,[1:6,11:14,15,16:19,21]), ...
    'RD','PFT','LAI'];

%% ===============================
% 接触类型：Direct / Indirect
% ===============================
WTD = Data(:,end-3);
RD  = Data(:,end-2);

Ok = ~isnan(WTD) & ~isnan(RD);

Direct   = (WTD - RD) <= 0 & Ok;
Indirect = (WTD - RD) > 0 & (WTD - RD) < 3 & Ok;

%% ===============================
% 植被类型：Forest / ShortVeg / Crop
% ===============================
PFT = Data(:,end-1);

Forest   = ismember(PFT,[1 2 3 4 5]);
ShortVeg = ismember(PFT,[6 7 8 9 10]);
Crop     = ismember(PFT,[12 14]);

PFTforest  = Data(Forest,:);
PFTherb = Data(ShortVeg,:);

% 保存站点结果
File_SiteHydrus= fullfile(PathOut, 'SiteHydrus.mat');
save(File_SiteHydrus,'PFTforest','PFTherb','Name');


