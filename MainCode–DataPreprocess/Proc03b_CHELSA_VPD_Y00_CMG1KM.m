clear; clc;
addpath(genpath('./'));

Path_Input = '../output/02b_CHELSA_VPD_Y01_CMG1KM/';
Path_Output = '../output/03b_CHELSA_VPD_Y00_CMG1KM/';

system(['rm -rf ',Path_Output]);
system(['mkdir -p ',Path_Output]);

% 目标年份范围
StartYear = 2001;
EndYear = 2018;
NumYears = EndYear - StartYear + 1;

% 确保文件完整，按年份逐个检查
SumVPD = [];
for Year = StartYear:EndYear
    FileName = sprintf('CHELSA_VPD_Y01_CMG1KM_%d.tif', Year);
    FilePath = fullfile(Path_Input, FileName);

    if ~isfile(FilePath)
        error('Missing file: %s', FilePath);
    end

    YearVPD = double(readgeoraster(FilePath));

    if isempty(SumVPD)
        [~, R] = readgeoraster(FilePath);
        Proj = geotiffinfo(FilePath);
        SumVPD = zeros(R.RasterSize);
    end

    SumVPD = SumVPD + YearVPD;
    disp(['Processed: ', FileName]);
end

% 计算多年均值
MultiYearMean = SumVPD / NumYears;

% 保存多年均值
FileName = fullfile(Path_Output, 'CHELSA_VPD_Y00_CMG1KM_20012018.tif');
geotiffwrite(FileName, MultiYearMean, R, 'GeoKeyDirectoryTag', ...
    Proj.GeoTIFFTags.GeoKeyDirectoryTag, 'TiffTags', struct('Compression', Tiff.Compression.LZW));

disp('Multi-Year Mean VPD Calculation Completed.');
