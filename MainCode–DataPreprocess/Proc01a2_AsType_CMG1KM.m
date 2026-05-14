clear; clc;
addpath(genpath('./'));

% 设置输入和输出路径
Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_GeoMaskAs = '../output/01a_AsProb_CMG1KM/';
Path_GeoTypeAs = '../output/01a_AsProb_CMG1KM/';

% 读取参考地理信息
RefeName = fullfile(Path_LandCover, 'LCTIGBP_USGS_MCD12Q1_Y10_CMG1KM_20012010.tif');
[~, R] = readgeoraster(RefeName);

% 读取砷概率数据
Pb5AsFile = fullfile(Path_GeoMaskAs, 'AsProb_GT5ppb_CMG1KM.tif');
Pb10AsFile = fullfile(Path_GeoMaskAs, 'AsProb_GT10ppb_CMG1KM.tif');
Pb50AsFile = fullfile(Path_GeoMaskAs, 'AsProb_GT50ppb_CMG1KM.tif');
Pb5As = readgeoraster(Pb5AsFile);
Pb10As = readgeoraster(Pb10AsFile);
Pb50As = readgeoraster(Pb50AsFile);
Pb5As(Pb5As < 0) = nan;
Pb10As(Pb10As < 0) = nan;
Pb50As(Pb50As < 0) = nan;

% 计算风险区域
ERAs = Pb50As >= 0.5; % 极高风险区（ERAs）
HRAs = Pb10As >= 0.5 & Pb50As < 0.5; % 高风险区（HRAs）: 10 µg/L 的概率 ≥ 50%
MRAs = Pb5As >= 0.5 & Pb10As < 0.5;  % 中风险区（MRAs）: 5 µg/L ≥ 50% 且 10 µg/L < 50%
LRAs = Pb5As < 0.5;  % 低风险区（LRAs）: 5 µg/L 的概率 < 50%

% 解决重叠区域
LRAs(ERAs| HRAs | MRAs) = 0;
MRAs(HRAs| ERAs) = 0;
HRAs(ERAs) = 0;

% 生成 TypeAs 并设置值：
% ERAs = 4, HRAs = 3, MRAs = 2, LRAs = 1
TypeAs = nan(size(HRAs));
TypeAs(ERAs) = 4;
TypeAs(HRAs) = 3;
TypeAs(MRAs) = 2;
TypeAs(LRAs) = 1;

% 转换为 uint8（NaN 会变成 0）
TypeAs = uint8(TypeAs);

% 写入 GeoTIFF
FileName = fullfile(Path_GeoTypeAs, 'AsType.TargetPixel.ControlPixel.CMG1KM.tif');
geotiffwrite(FileName, TypeAs, R, 'TiffTags', struct('Compression', Tiff.Compression.LZW));

