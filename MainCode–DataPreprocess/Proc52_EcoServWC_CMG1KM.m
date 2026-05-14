clear;clc;

addpath(genpath('./'));

Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_EcoServe = '../input/EcoServe/WC/';
Path_MulYWC = '../output/52_EcoServWC_CMG1KM/';

system(['rm -rf ',Path_MulYWC]);
system(['mkdir -p ',Path_MulYWC]);

RefeName = [Path_LandCover,'LCTIGBP_USGS_MCD12Q1_Y10_CMG1KM_20012010.tif'];  %Landcover坐标
[~,R]= readgeoraster(RefeName);
Proj = geotiffinfo(RefeName);

MulYWC = nan([R.RasterSize,19]) ;
 
for Year = 2002:2019
    YearName = num2str(Year,'%d');
    
         
        FileList = dir([Path_EcoServe,'WC',YearName,'*.tif']);
        FilePath1 = fullfile(FileList(1).folder, FileList(1).name);
        GlobeWC1 = readgeoraster(FilePath1);

        FilePath2 = fullfile(FileList(2).folder, FileList(2).name);
        GlobeWC2 = readgeoraster(FilePath2);

        GlobeWC = [GlobeWC1,GlobeWC2];
        GlobeWC(18001:21600,:)=[];

        MulYWC(:,:,Year-2000) = GlobeWC;
  
          FileName=[Path_MulYWC,'EcoServ_WC.Y',YearName,'_CMG1KM.tif'];
             geotiffwrite(FileName,GlobeWC,R,'GeoKeyDirectoryTag',...
             Proj.GeoTIFFTags.GeoKeyDirectoryTag,'TiffTags',struct('Compression',Tiff.Compression.LZW));


    disp(['Done with ',YearName])
   
end

        MulYWCavg = nanmean(MulYWC,3);

        FileName=[Path_MulYWC,'EcoServ_AVGWC_CMG1KM_B2001E2019.tif'];
             geotiffwrite(FileName,MulYWCavg,R,'GeoKeyDirectoryTag',...
             Proj.GeoTIFFTags.GeoKeyDirectoryTag,'TiffTags',struct('Compression',Tiff.Compression.LZW));

