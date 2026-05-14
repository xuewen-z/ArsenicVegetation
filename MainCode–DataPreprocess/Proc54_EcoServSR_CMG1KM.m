clear;clc;

addpath(genpath('./'));

Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_EcoServe = '../input/EcoServe/SR/';
Path_MulYSR = '../output/54_EcoServSR_CMG1KM/';

system(['rm -rf ',Path_MulYSR]);
system(['mkdir -p ',Path_MulYSR]);

RefeName = [Path_LandCover,'LCTIGBP_USGS_MCD12Q1_Y10_CMG1KM_20012010.tif'];  %Landcover坐标
[~,R]= readgeoraster(RefeName);
Proj = geotiffinfo(RefeName);

MulYSR = nan([R.RasterSize,19]) ;

for Year = 2002:2019
    YearName = num2str(Year,'%d');
    
         
        FileList = dir([Path_EcoServe,'SR',YearName,'*.tif']);
        FilePath1 = fullfile(FileList(1).folder, FileList(1).name);
        GlobeSR1 = readgeoraster(FilePath1);

        FilePath2 = fullfile(FileList(2).folder, FileList(2).name);
        GlobeSR2 = readgeoraster(FilePath2);

        GlobeSR = [GlobeSR1,GlobeSR2];
        GlobeSR(18001:21600,:)=[];

        MulYSR(:,:,Year-2000) = GlobeSR;
  
          FileName=[Path_MulYSR,'EcoServ_SR.Y',YearName,'_CMG1KM.tif'];
             geotiffwrite(FileName,GlobeSR,R,'GeoKeyDirectoryTag',...
             Proj.GeoTIFFTags.GeoKeyDirectoryTag,'TiffTags',struct('Compression',Tiff.Compression.LZW));


    disp(['Done with ',YearName])
   
end

        MulYSRavg = mean(MulYSR,3,'omitnan');

        FileName=[Path_MulYSR,'EcoServ_AVGSR_CMG1KM_B2001E2019.tif'];
             geotiffwrite(FileName,MulYSRavg,R,'GeoKeyDirectoryTag',...
             Proj.GeoTIFFTags.GeoKeyDirectoryTag,'TiffTags',struct('Compression',Tiff.Compression.LZW));

