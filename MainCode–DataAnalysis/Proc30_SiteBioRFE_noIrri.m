
clear; clc;

addpath(genpath('./'));

Path_SiteData_As = '../output/21_SiteData_As/';
Path_SiteData_LAI = '../output/22a_SiteData_LAI/';
Path_SiteData_CO2 = '../output/23b_SiteData_CO2/';
Path_SiteData_Ozone = '../output/23c_SiteData_Ozone/';
Path_SiteData_Soilmo = '../output/23d_SiteData_Soilmo/';
Path_SiteData_AridIndex = '../output/23e_SiteData_AridIndex/';
Path_SiteData_Irrigation = '../output/23f_SiteData_Irrigation/';
Path_SiteData_DEM = '../output/23g_SiteData_DEM/';
Path_SiteData_Climate = '../output/23h_SiteData_Climate/';
Path_SiteRFE = '../output/30_SiteBioRFEno/';

system(['rm -rf '  ,Path_SiteRFE]);
system(['mkdir -p ',Path_SiteRFE]);

load([Path_SiteData_LAI, 'SiteData_LAI.mat']);
load([Path_SiteData_Climate, 'SiteData_Climate.mat']);
load([Path_SiteData_DEM, 'SiteData_DEM.mat']);
load([Path_SiteData_Soilmo, 'SiteData_Soilmo.mat']);
load([Path_SiteData_Ozone, 'SiteData_Ozone.mat']);
load([Path_SiteData_CO2, 'SiteData_CO2.mat']);
load([Path_SiteData_AridIndex, 'SiteData_AridIndex.mat']);
load([Path_SiteData_Irrigation, 'SiteData_Irrigation.mat']);
load([Path_SiteData_As, 'SiteData_As.mat']);


%% REF---- LAI select best variables
Y = SiteData_LAIAVG_20012020;
SiteData_As(:,7) = SiteData_Ta;
SiteData_As(:,6) = SiteData_AridIndex;
X = [SiteData_As(:,3:20),SiteData_Rg,SiteData_VPD,SiteData_DEM,SiteData_Aspect,SiteData_Ozone,SiteData_CO2,SiteData_Soilmo];
BestHeadInt = [SiteName_As(:,3:20),'Rg','VPD','Elev','Aspect','O3','CO2','SM'];

Xnone = any(isnan(X),2);
Ynone = any(isnan(Y),2);
Bothnone = Xnone | Ynone;
Y = Y(~Bothnone,:);
X = X(~Bothnone,:);


%% Step 1: VIF 筛选
VIF = zeros(1, size(X, 2)); % 初始化 VIF 矩阵

for i = 1:size(X, 2)
    X_temp = X(:, [1:i-1, i+1:end]); % 去掉当前列
    mdl = fitlm(X_temp, X(:, i));    % 回归当前列对其他列
    R2 = mdl.Rsquared.Ordinary;         % 获取 R^2
    VIF(i) = 1 / (1 - R2);              % 计算 VIF
end

%% **Step 2: 剔除 VIF 过高的变量**
remove_vars = {'AET','PET','SWC','Clay_{top}','Clay_{sub}', 'silt_{top}', 'silt_{sub}', ...
               'sand_{top}', 'sand_{sub}'};  % 剔除的变量  'SWC','O3'
keep_idx = ~ismember(BestHeadInt, remove_vars);  % 保留变量的索引
X = X(:, keep_idx);
BestHeadInt = BestHeadInt(keep_idx);


%% Step 2: Sequential Feature Selection (RFE)
rng(2024,'twister')

% MustInclude = 1; % 保留的特征索引

Opts = statset('UseParallel',false,'display','iter');
Cv = cvpartition(length(Y),"KFold",5);

[FsLAI,~] = sequentialfs(@myfun,X,Y,'cv',Cv,...
    'direction','backward','options',Opts); %,'Keepin',MustInclude

LAIXset = X(:,FsLAI);
LAIHeadInt = BestHeadInt;
LAIHeadInt(FsLAI==0) = [];

%% **Step 3: 重新计算 VIF**
numVars = size(LAIXset, 2);
VIF = zeros(1, numVars);
for i = 1:numVars
    X_temp = LAIXset(:, [1:i-1, i+1:end]); 
    mdl = fitlm(X_temp, LAIXset(:, i)); 
    R2 = mdl.Rsquared.Ordinary;
    VIF(i) = 1 / (1 - R2);
end

%% Step 3: Feature Importance using Random Forest
RFmodel = TreeBagger(100, LAIXset, Y, 'Method', 'R', ...
    MinLeafSize = 5, OOBPredictorImportance = "On");
LAIImport = RFmodel.OOBPermutedPredictorDeltaError;

[~,SortIndx] = sort(LAIImport,'descend');
TopInd = SortIndx;
TopVar = LAIHeadInt(TopInd');
TopImp = LAIImport(TopInd');
TopSet = LAIXset(:,TopInd');

save([Path_SiteRFE,'SiteRFEPFT.mat'],'-regexp','^Top*');

save([Path_SiteRFE,'RFmodel.mat'], 'RFmodel'); % 保存随机森林模型
save([Path_SiteRFE,'TopSet.mat'], 'TopSet'); % 保存特征数据
save([Path_SiteRFE,'Y.mat'], 'Y'); % 保存目标变量

SHAPInData = [TopSet,Y];

 FilePath = fullfile(Path_SiteRFE, 'TopSet.csv');
 writematrix(TopSet,FilePath);

 FilePath = fullfile(Path_SiteRFE, 'Y.csv');
 writematrix(Y,FilePath);

