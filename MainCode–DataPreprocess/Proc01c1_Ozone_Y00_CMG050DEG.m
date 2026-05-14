clc; clear;
addpath(genpath('./'));

Path_Input = '../input/Ozone-MSR/';
Path_Output = '../output/01c_Ozone_Y00/';

system(['rm -rf ', Path_Output]);
system(['mkdir -p ', Path_Output]);

YearStart = 2001;
YearEnd = 2018;
NumYears = YearEnd - YearStart + 1;
NumMonths = 12;

% 读取第一个数据，确定数据维度
FirstFile = [Path_Input, num2str(YearStart), '01-C3S-L4_OZONE-O3_PRODUCTS-MSR-ASSIM-ALG-MONTHLY-v0023.nc'];
ncinf = ncinfo(FirstFile);
FirstData = ncread(FirstFile, ncinf.Variables(4).Name);
DataSize = size(FirstData);

% 预分配数组
MulMon = nan(DataSize(2), DataSize(1), NumMonths);
MulYr = nan(DataSize(2), DataSize(1), NumYears);

for Year = YearStart:YearEnd
    YearName = num2str(Year, '%d');

    for Mon = 1:NumMonths
        MonName = num2str(Mon, '%02d');
        FileName = [Path_Input, YearName, MonName, '-C3S-L4_OZONE-O3_PRODUCTS-MSR-ASSIM-ALG-MONTHLY-v0023.nc'];

        Tempor = ncread(FileName, ncinf.Variables(4).Name);
        MulMon(:, :, Mon) = double(rot90(Tempor));
    end

    MulYr(:, :, Year - YearStart + 1) = mean(MulMon, 3, 'omitnan');
    disp(['Done with ', YearName]);
end

MulAvg = mean(MulYr, 3, 'omitnan');

% 获取参考地理信息
Lon = double(ncread(FileName, ncinf.Variables(1).Name));
Lat = double(ncread(FileName, ncinf.Variables(2).Name));

R = georasterref('RasterSize', size(MulAvg), 'Latlim', [min(Lat), max(Lat)], 'Lonlim', [min(Lon), max(Lon)]);
R.ColumnsStartFrom = 'north';

% 保存为 GeoTIFF
GeoTIFF_File = [Path_Output, 'Ozone_Y00_CMG050DEG.tif'];
geotiffwrite(GeoTIFF_File, MulAvg, R, 'TiffTags', struct('Compression', Tiff.Compression.LZW));
