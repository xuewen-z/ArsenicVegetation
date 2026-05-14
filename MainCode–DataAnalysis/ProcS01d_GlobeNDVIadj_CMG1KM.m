clear;clc;

addpath(genpath('./'));

Path_DEM = '../input/';
Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_MulYNDVI = '../output/05d_NDVI_Y00_CMG1KM/';
Path_Ozone = '../output/01c_Ozone_Y00/';
Path_Soilmo = '../output/01d_Soilmo_Y00/';
Path_Climate_Ta = '../output/03a_CHELSA_Ta_Y00_CMG1KM/';
Path_Climate_Rg = '../output/03c_CHELSA_Rg_Y00_CMG1KM/';
Path_Climate_VPD = '../output/03b_CHELSA_VPD_Y00_CMG1KM/';
Path_Climate_Pre = '../output/03d_CHELSA_Pre_Y00_CMG1KM/';
Path_CO2 = '../output/01b_CO2_Y00/';
Path_AridIndex = '../output/01e_AridIndex_Y00/';
% Path_WaterTD = '../input/Water-TableDepth/';
Path_GeoNDVIadj = '../output/S01d_GlobeNDVIadj_CMG1KM/';

system(['rm -rf ',Path_GeoNDVIadj]);
system(['mkdir -p ',Path_GeoNDVIadj]);


% 读取 LandCover 数据
File_LandCover = fullfile(Path_LandCover, 'LCTIGBP_USGS_MCD12Q1_Y10_CMG1KM_20012010.tif');
[LandCover, R] = readgeoraster(File_LandCover);
LandCover = double(LandCover);

% 读取 Climate 数据
File_Climate = fullfile(Path_Climate_Ta, 'CHELSA_Ta_Y00_CMG1KM_20012018.tif');
Ta = readgeoraster(File_Climate);
File_Climate = fullfile(Path_Climate_Rg, 'CHELSA_Rg_Y00_CMG1KM_20012018.tif');
Rg = readgeoraster(File_Climate);
File_Climate = fullfile(Path_Climate_VPD, 'CHELSA_VPD_Y00_CMG1KM_20012018.tif');
VPD = readgeoraster(File_Climate);
File_Climate = fullfile(Path_Climate_Pre, 'CHELSA_Pre_Y00_CMG1KM_20012018.tif');
Pre = readgeoraster(File_Climate);

% DEM & Aspect
File_DEM = fullfile(Path_DEM, 'Globe_DEM_CMG1KM.tif');
DEM = readgeoraster(File_DEM);
File_Aspect = fullfile(Path_DEM, 'Globe_Aspect_CMG1KM.tif');
Aspect = readgeoraster(File_Aspect);

% 读取 Soilmo 数据
File_Soilmo = fullfile(Path_Soilmo, 'Soilmo_Y00_CMG1KM.tif');
Soilmo = readgeoraster(File_Soilmo);

% 读取 Ozone 数据
File_Ozone = fullfile(Path_Ozone, 'Ozone_Y00_CMG1KM.tif');
Ozone = readgeoraster(File_Ozone);

% 读取 CO2 数据
File_CO2 = fullfile(Path_CO2, 'CO2_Y00_CMG1KM.tif');
CO2= readgeoraster(File_CO2);

% 读取 AridIndex 数据
File_AridIndex = fullfile(Path_AridIndex, 'AridIndex_Y00_CMG1KM.tif');
AridIndex = readgeoraster(File_AridIndex);
AridIndex = double(AridIndex) * 0.0001;

% 读取 NDVI 数据
File_NDVI = fullfile(Path_MulYNDVI, 'NDVIAVG_Y00_CMG1KM_20012020.tif');
GeoMulNDVI = double(readgeoraster(File_NDVI));
GeoMulNDVI(GeoMulNDVI==0) =nan;

% % 读取 WTD 数据
% File_WaterTD = fullfile(Path_WaterTD, 'WaterTD_Y00_CMG1KM.tif');
% WTD = readgeoraster(File_WaterTD);
% WTD(WTD == -Inf) = nan;

% 数据清理，去除无效值
Invalid = (LandCover == 0  | LandCover == 11 | LandCover == 13 | LandCover == 15 | LandCover == 16 | LandCover == 17 | LandCover == 255);
Elev(Invalid) = nan;
Aspect(Invalid) = nan;
GeoMulNDVI(Invalid) = nan;

Ta(Invalid) = nan;
Rg(Invalid) = nan;
Pre(Invalid) = nan;
VPD(Invalid) = nan;

Ozone(Invalid) = nan;
Soilmo(Invalid) = nan;
CO2(Invalid) = nan;

AridIndex(Invalid) = nan;
% WTD(Invalid) = nan;

% LandCover重新编码
LandCover(LandCover == 7) = 6;
LandCover(LandCover == 14 | LandCover == 12) = 7;
LandCover(Invalid)=12;

% 哑变量编码 PFT , dummyvar() 不能处理 0 或负数or NaN
PFTdum = dummyvar(LandCover(:));
PFTdum(:,12) = []; %  去掉与编码为12（无效类别）对应的那一列
PFTdum(:,10) = []; % 选择有效的参照类别 GRA
PFTdum = reshape(PFTdum,[R.RasterSize,size(PFTdum,2)]);
PFTdum = reshape(PFTdum,[],10);
clear LandCover 

% 构建回归自变量矩阵 X，包含所有环境变量和 PFT 哑变量
X = [Ta(:),Rg(:),Pre(:),VPD(:),Ozone(:),Soilmo(:),CO2(:),AridIndex(:),Aspect(:),Elev(:),PFTdum];
GeoMulNDVI = GeoMulNDVI(:);
GeoMulNDVI(Invalid) = nan;

% 删除含有 NaN 的行
NanMask = any(isnan(X), 2) | isnan(GeoMulNDVI);
Xclean = X(~NanMask, :);  % 删除含有 NaN 的行
NDVIclean = GeoMulNDVI(~NanMask);  % 删除响应变量的 NaN 行

% 如果数据清理后不为空，进行线性回归
if ~isempty(Xclean)
    % 增加偏置项
    Xclean = [ones(size(Xclean, 1), 1), Xclean];  % 增加常数项

    % 使用岭回归（可以避免共线性问题）
    lambda = 0.1;  % 正则化参数
    b = ridge(NDVIclean, Xclean(:, 2:end), lambda, 0);  % 忽略偏置项列

    % 计算预测值和残差
    ypred = Xclean * b;  % 预测 NDVI
    residuals = NDVIclean - ypred;  % 计算残差

    % 初始化为 NaN
        AdjustValue = nan(size(GeoMulNDVI));
        AdjustValue(~NanMask) = residuals;  % 填充计算的残差
else
        AdjustValue = nan(size(GeoMulNDVI));
end


GeoNDVIadj = reshape(AdjustValue, [18000, 43200]);

% 将调整后的 NDVI 保存
geotiffwrite(fullfile(Path_GeoNDVIadj,'NDVIadj_B2001E2020_CMG1KM.tif'), GeoNDVIadj, R, ...
             'TiffTags', struct('Compression', Tiff.Compression.LZW));