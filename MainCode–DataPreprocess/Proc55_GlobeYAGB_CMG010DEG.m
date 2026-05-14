clear;clc;

addpath(genpath('./'));

Path_GlobeAGB = '../input/';
Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_GlobeYAGB = '../output/55_GlobeYAGB_CMG010DEG/';

system(['rm -rf ',Path_GlobeYAGB]);
system(['mkdir -p ',Path_GlobeYAGB]);

RefeName = [Path_LandCover,'LCTIGBP_USGS_MCD12Q1_Y10_CMG010DEG_20012010.tif'];  %Landcover坐标
[a,R]= readgeoraster(RefeName);
Proj = geotiffinfo(RefeName);

GlobeAGB =readgeoraster([Path_GlobeAGB,'GlobeAGB_cd_ab_pred_corr_2000_2019_v2.tif']);

for Year = 2000:2019

    YearName = num2str(Year,'%d');
       
    GlobeYAGB = GlobeAGB(:,:,Year-1999);
    GlobeYAGB(1501:1800,:) = [];

    FileName=[Path_GlobeYAGB,'GlobeAGB_CarbonDensity_A',YearName,'_CMG010.tif'];
         geotiffwrite(FileName,GlobeYAGB,R,'GeoKeyDirectoryTag',...
         Proj.GeoTIFFTags.GeoKeyDirectoryTag,'TiffTags',struct('Compression',Tiff.Compression.LZW));

    disp(['Done with ',YearName])
   
 end

