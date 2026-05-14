% unit g·CO2/m2/year
clear;clc;

addpath(genpath('./'));

Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_EcoServe = '../input/EcoServe/CS/';
Path_MulYCS = '../output/51_EcoServCS_CMG1KM/';

system(['rm -rf ',Path_MulYCS]);
system(['mkdir -p ',Path_MulYCS]);

RefeName = [Path_LandCover,'LCTIGBP_USGS_MCD12Q1_Y10_CMG1KM_20012010.tif'];  %Landcover坐标
[~,R]= readgeoraster(RefeName);
Proj = geotiffinfo(RefeName);

MulYCS = nan([R.RasterSize,19]) ;

for Year = 2002:2019
    YearName = num2str(Year,'%d');
    
         
        FileList = dir([Path_EcoServe,'CS',YearName,'*.tif']);
        FilePath1 = fullfile(FileList(1).folder, FileList(1).name);
        GlobeCS1 = readgeoraster(FilePath1);

        FilePath2 = fullfile(FileList(2).folder, FileList(2).name);
        GlobeCS2 = readgeoraster(FilePath2);

        GlobeCS = [GlobeCS1,GlobeCS2];
        GlobeCS(18001:21600,:)=[];

        MulYCS(:,:,Year-2000) = GlobeCS;
  
        FileName=[Path_MulYCS,'EcoServ_CS.Y',YearName,'_CMG1KM.tif'];
             geotiffwrite(FileName,GlobeCS,R,'GeoKeyDirectoryTag',...
             Proj.GeoTIFFTags.GeoKeyDirectoryTag,'TiffTags',struct('Compression',Tiff.Compression.LZW));


        disp(['Done with ',YearName])
   
end

        AVGYCS = nanmean(MulYCS,3);  

        FileName=[Path_MulYCS,'EcoServ_AVGCS_CMG1KM_B2001E2019.tif'];
             geotiffwrite(FileName,AVGYCS,R,'GeoKeyDirectoryTag',...
             Proj.GeoTIFFTags.GeoKeyDirectoryTag,'TiffTags',struct('Compression',Tiff.Compression.LZW));

