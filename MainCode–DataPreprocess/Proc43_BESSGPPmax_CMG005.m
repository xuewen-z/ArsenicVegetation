addpath(genpath('./'));
clear; clc; 

Path_BESS2TIF = '../input/BESSV2/GPP/Daily/';
Path_BESSGPPx = '../output/43_BESSGPPmax_CMG005/';

system(['rm -rf ',Path_BESSGPPx]);
system(['mkdir -p ',Path_BESSGPPx]);

DGPP = nan([3600,7200,365]);
MulGPPmax = nan([3600,7200,20]);

   for I_Year = 2001 : 2020
   YearName = num2str(I_Year,'%d');
     
     for I_Date = 1 : 365
         DateName = num2str(I_Date,'%.3d');
             FileName = [Path_BESS2TIF,'/',YearName,'/BESS_GPP_Daily.A',YearName,DateName,'.tif'];
             [Temper,R] = readgeoraster(FileName);

             DGPP(:,:,I_Date) = Temper;

     end
      
         YrGPPmax = prctile(DGPP,95,3);
    
         MulGPPmax(:,:,I_Year-2000) = YrGPPmax;

         FileName = [Path_BESSGPPx,'BESS_GPPmax_Yearly_CMG005DEG.A',YearName,'.tif'];
         geotiffwrite(FileName,YrGPPmax,R,'TiffTags',struct('Compression',Tiff.Compression.Deflate));
     
         disp(['Done with ',YearName]); 

   end
    
         MulGPPmax = nanmean(MulGPPmax,3);

         FileName = [Path_BESSGPPx,'BESS_AvgGPPmax_CMG005DEG_B2001E2020.tif'];
         geotiffwrite(FileName,MulGPPmax,R,'TiffTags',struct('Compression',Tiff.Compression.Deflate));
     
