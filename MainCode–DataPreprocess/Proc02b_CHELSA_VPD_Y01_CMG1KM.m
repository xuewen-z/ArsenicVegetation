clear; clc;
addpath(genpath('./'));

Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_EcoServe = '../input/CHELSA/Monthly/VPD/';
Path_GeoClimate = '../output/02b_CHELSA_VPD_Y01_CMG1KM/';

system(['rm -rf ',Path_GeoClimate]);
system(['mkdir -p ',Path_GeoClimate]);

RefeName = [Path_LandCover, 'LCTIGBP_USGS_MCD12Q1_Y10_CMG1KM_20012010.tif'];
[LandCover, R] = readgeoraster(RefeName);
Proj = geotiffinfo(RefeName);

InvalidMask = (LandCover == 0 | LandCover == 15 | LandCover == 16 | LandCover == 17 | LandCover == 255);
NumYears = 2018 - 2001 + 1;
NumMonths = 12;
MultMonVPD = nan([R.RasterSize, NumMonths]);

for Year = 2001:2018
    YearName = num2str(Year);
    for mon = 1:NumMonths
        MonName = sprintf('%02d', mon);
        FileList = dir([Path_EcoServe, 'CHELSA_vpd_', MonName, '_', YearName, '*.tif']);

        if isempty(FileList)
            warning(['Missing file for ', YearName, ' Month: ', MonName]);
            continue;
        end

        FilePath = fullfile(FileList(1).folder, FileList(1).name);
        MonthVPD = double(readgeoraster(FilePath));

        MonthVPD(18001:end, :) = [];
        MonthVPD(InvalidMask) = nan;
        MonthVPD = MonthVPD * 0.1 * 0.001; % 转换为 KPa

        MultMonVPD(:, :, mon) = MonthVPD;
    end

    YVPD = nanmean(MultMonVPD, 3);

    FileName = fullfile(Path_GeoClimate, ['CHELSA_VPD_Y01_CMG1KM_', YearName, '.tif']);
    geotiffwrite(FileName, YVPD, R, 'GeoKeyDirectoryTag', ...
        Proj.GeoTIFFTags.GeoKeyDirectoryTag, 'TiffTags', struct('Compression', Tiff.Compression.LZW));

    disp(['Done with ', YearName])
end
