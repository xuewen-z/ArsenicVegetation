clear; clc;

addpath(genpath('./'));
Path_GEM = '../input/';

% 读取高程数据（GeoTIFF 格式）
[Z, R] = readgeoraster(fullfile(Path_GEM, 'Globe_DEM_CMG1KM.tif'));

% 确保数据为双精度浮点数，避免计算误差
Z = double(Z);

% 计算栅格的空间分辨率
cellsize_x = abs(R.CellExtentInLongitude);
cellsize_y = abs(R.CellExtentInLatitude);

% 计算高程变化率（梯度）
[dy, dx] = gradient(Z, cellsize_y, cellsize_x);

% 计算坡向（Aspect），并转换到 [0, 360] 范围
aspect = mod(atan2(dy, -dx) * (180 / pi) + 360, 360);

% 保存坡向结果为 GeoTIFF 文件
geotiffwrite(fullfile(Path_GEM, 'Globe_Aspect_CMG1KM.tif'), aspect, R, ...
    'TiffTags', struct('Compression', Tiff.Compression.LZW));

disp('坡向计算完成，结果已保存。');
