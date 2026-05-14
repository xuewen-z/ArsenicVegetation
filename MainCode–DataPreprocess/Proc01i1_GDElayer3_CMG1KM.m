clear; clc;
addpath(genpath('./'));

% 设置文件路径
Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_GDE = '../input/';


[GDE,R] = readgeoraster([Path_GDE,'GDE_CMG1KM.tif']);
GDElayer3 = double(GDE(:,:,3));
GDElayer3 = GDElayer3 ./10^8;

% 保存坡向结果为 GeoTIFF 文件
geotiffwrite(fullfile(Path_GDE, 'Globe_GDElayer3_CMG1KM.tif'), GDElayer3, R, ...
    'TiffTags', struct('Compression', Tiff.Compression.LZW));

disp('计算完成，结果已保存。');
