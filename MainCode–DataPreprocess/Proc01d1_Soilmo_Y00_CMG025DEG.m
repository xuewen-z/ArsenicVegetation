clc; clear;
addpath(genpath('./'));

Path_Input = '../input/GLDAS/';
Path_Output = '../output/01d_Soilmo_Y00/';

system(['rm -rf ', Path_Output]);
system(['mkdir -p ', Path_Output]);

YearStart = 2001;
YearEnd = 2017;
NumYears = YearEnd - YearStart + 1;
NumDays = 365;

% 读取第一个数据，确定数据维度
FirstFile = dir([Path_Input, '*Soilmo*2001001*']);
FirstData = readgeoraster(fullfile(FirstFile.folder, FirstFile.name));
DataSize = size(FirstData);

% 预分配数组
MulDay = nan([DataSize(1), DataSize(2), NumDays]);
MulYr = nan([DataSize(1), DataSize(2), NumYears]);

for Year = YearStart:YearEnd
    YearName = num2str(Year, '%d');

    for Date = 1:NumDays
        DateName = [YearName, sprintf('%03d', Date)];
        FileList = dir([Path_Input, '*Soilmo*', DateName, '*']);

        Tempor = readgeoraster(fullfile(FileList.folder, FileList.name));
        MulDay(:, :, Date) = double(Tempor);
    end

    MulYr(:, :, Year - YearStart + 1) = mean(MulDay, 3, 'omitnan');
    disp(['Done with ', YearName]);
end

MulAvg = mean(MulYr, 3, 'omitnan');

% 获取参考地理信息
[~, R] = readgeoraster(fullfile(FirstFile.folder, FirstFile.name));


% 保存为 GeoTIFF
GeoTIFF_File = [Path_Output, 'Soilmo_Y00_CMG025DEG.tif'];
geotiffwrite(GeoTIFF_File, MulAvg, R, 'TiffTags', struct('Compression', Tiff.Compression.LZW));
