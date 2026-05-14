addpath(genpath('./'));
clear; clc; 

Path_BESSGPP = '../input/BESSV2/GPP/Yearly/';
Path_BESSRECO = '../input/BESSV2/Reco/Yearly/';
Path_BESSET = '../input/BESSV2/ET/';
Path_BESSWCUE = '../output/44_BESSWUE_CUE_CMG005/';

system(['rm -rf ',Path_BESSWCUE]);
system(['mkdir -p ',Path_BESSWCUE]);

YrWUE = nan([3600,7200,20]);
YrCUE = nan([3600,7200,20]);


   for I_Year = 2001 : 2020
   YearName = num2str(I_Year,'%d');
       
   FileName = [Path_BESSGPP,'BESS_GPP_Yearly.A',YearName,'.tif'];
             [GPP,R] = readgeoraster(FileName);


   FileName = [Path_BESSRECO,'BESS_RECO_Yearly.A',YearName,'.tif'];
             RECO = readgeoraster(FileName);
  
   FileName = [Path_BESSET,'BESS_ET_Yearly_0.05C.A',YearName,'.tif'];
             ET = readgeoraster(FileName);

             WUE = GPP./ET;
             CUE = (GPP-RECO)./GPP;
             

         FileName = [Path_BESSWCUE,'BESS_WUE_Yearly_CMG005DEG.A',YearName,'.tif'];
         geotiffwrite(FileName,WUE,R,'TiffTags',struct('Compression',Tiff.Compression.Deflate));
     
 
         FileName = [Path_BESSWCUE,'BESS_CUE_Yearly_CMG005DEG.A',YearName,'.tif'];
         geotiffwrite(FileName,CUE,R,'TiffTags',struct('Compression',Tiff.Compression.Deflate));
     

         disp(['Done with ',YearName]); 


         YrWUE(:,:,I_Year-2000) = WUE;
         YrCUE(:,:,I_Year-2000) = CUE;

   end

        MulWUE = nanmean(YrWUE,3);
        MulCUE = nanmean(YrCUE,3);
    
         FileName = [Path_BESSWCUE,'BESS_AvgWUE_CMG005DEG_B2001E2020.tif'];
         geotiffwrite(FileName,MulWUE,R,'TiffTags',struct('Compression',Tiff.Compression.Deflate));
     
 
         FileName = [Path_BESSWCUE,'BESS_AvgCUE_CMG005DEG_B2001E2020.tif'];
         geotiffwrite(FileName,MulCUE,R,'TiffTags',struct('Compression',Tiff.Compression.Deflate));
     