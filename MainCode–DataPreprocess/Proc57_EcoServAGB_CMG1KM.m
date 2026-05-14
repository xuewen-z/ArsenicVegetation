clear;clc;

addpath(genpath('./'));

Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_GlobeYAGB = '../output/56_GlobeYAGB_CMG1KM/';
Path_MulYAGB = '../output/57_EcoServAGB_CMG1KM/';

system(['rm -rf ',Path_MulYAGB]);
system(['mkdir -p ',Path_MulYAGB]);

RefeName = [Path_LandCover,'LCTIGBP_USGS_MCD12Q1_Y10_CMG1KM_20012010.tif'];  %Landcover坐标
[~,R]= readgeoraster(RefeName);
Proj = geotiffinfo(RefeName);


MulYAGB = nan([R.RasterSize,19]) ;

for Year = 2002:2019

    YearName = num2str(Year,'%d');
       
        FileName = dir([Path_GlobeYAGB,'GlobeAGB_CarbonDensity_A',YearName,'_CMG1KM.tif']);
        GlobeAGB = readgeoraster(fullfile(FileName.folder,FileName.name));
        % 生物量 (MgC/ha)÷10,000=生物量 (MgC/m²) 
         GlobeAGB = GlobeAGB ./ 10000;
              
        FileName=[Path_MulYAGB,'EcoServ_AGB.Y',YearName,'_CMG1KM.tif'];
             geotiffwrite(FileName,GlobeAGB,R,'GeoKeyDirectoryTag',...
             Proj.GeoTIFFTags.GeoKeyDirectoryTag,'TiffTags',struct('Compression',Tiff.Compression.LZW));

                
        
        MulYAGB(:,:,Year-2000) = GlobeAGB;
  

    disp(['Done with ',YearName])
   
 end
        MulYAGB = mean(MulYAGB,3,'omitnan');

        FileName=[Path_MulYAGB,'EcoServ_AVGAGB_CMG1KM_B2001E2019.tif'];
             geotiffwrite(FileName,MulYAGB,R,'GeoKeyDirectoryTag',...
             Proj.GeoTIFFTags.GeoKeyDirectoryTag,'TiffTags',struct('Compression',Tiff.Compression.LZW));

