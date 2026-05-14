
addpath(genpath('./'));
clear; clc; 

Path_LCCTIF = '../input/LCC/';
Path_GlobeLCC = '../output/04c_LCC_8Day_CMG500M/';

% system(['rm -rf ',Path_GlobeLCC]);
% system(['mkdir -p ',Path_GlobeLCC]);


    for  I_Year = 2001:2020
         YearName = num2str(I_Year,'%d');
    
     
      for I_Date = 1 : 8 : 365
          DateName = num2str(I_Date,'%03d');

             RefeName = [Path_LCCTIF,YearName,'/MODISLCCInterp.A',YearName,DateName,'.Sinusoidal.NH.tif'];
             [LCCNH,RNH]= readgeoraster(RefeName);
             Proj = geotiffinfo(RefeName);

             RefeName = [Path_LCCTIF,YearName,'/MODISLCCInterp.A',YearName,DateName,'.Sinusoidal.SH.tif'];
             [LCCSH,RSH] = readgeoraster(RefeName);
           

             LCC = double([LCCNH;LCCSH]);
             LCC(LCC<2 | LCC>200) = nan;
             LCC = double(LCC) .* 0.5;


             RGlobal = RNH; % 以北半球的 R 作为基础
             RGlobal.YWorldLimits = [RSH.YWorldLimits(1), RNH.YWorldLimits(2)];
             RGlobal.RasterSize = [size(LCC,1), size(LCC,2)]; % 适配拼接后的数据大小

       
             FileName=[Path_GlobeLCC,'MODISLCC.Y',YearName,DateName,'_500M.tif'];
             geotiffwrite(FileName,LCC,RGlobal,'GeoKeyDirectoryTag',...
             Proj.GeoTIFFTags.GeoKeyDirectoryTag,'TiffTags',struct('Compression',Tiff.Compression.LZW));
     
  

      end
          disp(['Done with ',YearName])
    end

