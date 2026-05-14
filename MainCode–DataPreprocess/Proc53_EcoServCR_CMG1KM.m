% unit kW·h/m2/year
clear;clc;

addpath(genpath('./'));

Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_EcoServe = '../input/EcoServe/CR/';
Path_MulYCR = '../output/53_EcoServCR_CMG1KM/';

system(['rm -rf ',Path_MulYCR]);
system(['mkdir -p ',Path_MulYCR]);

RefeName = [Path_LandCover,'LCTIGBP_USGS_MCD12Q1_Y10_CMG1KM_20012010.tif'];  %Landcover坐标
[~,R]= readgeoraster(RefeName);
Proj = geotiffinfo(RefeName);

MulYCR = nan([R.RasterSize,19]) ;

for Year = 2002:2019
    YearName = num2str(Year,'%d');
    
         
        FileList = dir([Path_EcoServe,'CR_',YearName,'*.tif']);
        FilePath1 = fullfile(FileList(1).folder, FileList(1).name);
        GlobeCR1 = readgeoraster(FilePath1);

        FilePath2 = fullfile(FileList(2).folder, FileList(2).name);
        GlobeCR2 = readgeoraster(FilePath2);

        GlobeCR = [GlobeCR1,GlobeCR2];
        GlobeCR(18001:21600,:)=[];

        MulYCR(:,:,Year-2000) = GlobeCR;
  
          FileName=[Path_MulYCR,'EcoServ_CR.Y',YearName,'_CMG1KM.tif'];
             geotiffwrite(FileName,GlobeCR,R,'GeoKeyDirectoryTag',...
             Proj.GeoTIFFTags.GeoKeyDirectoryTag,'TiffTags',struct('Compression',Tiff.Compression.LZW));


    disp(['Done with ',YearName])
   
end

        MulYCRavg = mean(MulYCR,3,'omitnan');

        FileName=[Path_MulYCR,'EcoServ_AVGCR_CMG1KM_B2001E2019.tif'];
             geotiffwrite(FileName,MulYCRavg,R,'GeoKeyDirectoryTag',...
             Proj.GeoTIFFTags.GeoKeyDirectoryTag,'TiffTags',struct('Compression',Tiff.Compression.LZW));

