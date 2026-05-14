clear; clc;
addpath(genpath('./'));

% 设置路径
Path_Input = '../input/LAI_SYSU_MCD15A2H_M01_CMG1KM_20002021_XQC/';
Path_Output = '../output/04a_LAI_Y01_CMG1KM/';

% 确保输出目录存在
system(['rm -rf ', Path_Output]);
system(['mkdir -p ', Path_Output]);

Years = 2001:2021;
NumMonths = 12;

% 读取第一个影像以获取地理参考信息
SampleFile = fullfile(Path_Input, 'LAI_SYSU_MCD15A2H_M01_CMG1KM_200101.tif');
[~, R] = readgeoraster(SampleFile);
RasterSize = R.RasterSize;

% 并行处理每个年份
for YearIdx = 1:length(Years)
    Year = Years(YearIdx);

    % 预分配存储
    LAI_Stack = nan([RasterSize, NumMonths], 'double');

    % 逐月读取数据
    for Month = 1:NumMonths
        FileName = fullfile(Path_Input, sprintf('LAI_SYSU_MCD15A2H_M01_CMG1KM_%d%02d.tif', Year, Month));

        if isfile(FileName)
            TempData = double(readgeoraster(FileName));
            LAI_Stack(:, :, Month) = TempData;
            fprintf('Read file: %s\n', FileName);
        else
            fprintf('Missing file: %s\n', FileName);
        end
    end

    % 计算年平均值和 95% 分位数
    LAI_Annual_Avg = mean(LAI_Stack, 3, 'omitnan');
    LAI_Annual_95P = prctile(LAI_Stack, 95, 3);

    % 保存 GeoTIFF
    OutFile_Avg = fullfile(Path_Output, sprintf('LAIAVG_Y01_CMG1KM_%d.tif', Year));
    geotiffwrite(OutFile_Avg, LAI_Annual_Avg, R, 'TiffTags', struct('Compression', Tiff.Compression.LZW));
    
    OutFile_95P = fullfile(Path_Output, sprintf('LAI95P_Y01_CMG1KM_%d.tif', Year));
    geotiffwrite(OutFile_95P, LAI_Annual_95P, R, 'TiffTags', struct('Compression', Tiff.Compression.LZW));

    fprintf('Done with %d\n', Year);
end
