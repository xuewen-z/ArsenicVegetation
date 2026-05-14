
addpath(genpath('./'));
clear; clc; 


Path_GlobeLCC = '../output/05c_LCC_8Day_CMG1KM/';
Path_LCCTIF = '../output/06c_LCCmax_Y01_CMG1KM/';

system(['rm -rf ',Path_LCCTIF]);
system(['mkdir -p ',Path_LCCTIF]);

% 读取示例 GeoTIFF 获取参考信息
Example_File = fullfile(Path_GlobeLCC, 'MODISLCC.Y2001001_500M.tif');
[~, R] = readgeoraster(Example_File, 'OutputType', 'double');
 
YrLCC = nan([R.RasterSize,46]);


 for I_Year = 2001 : 2020
     YearName = num2str(I_Year,'%d');
    
     k= 0;
     
      for I_Date = 1 : 8 : 365
          DateName = num2str(I_Date,'%03d');
             k = k + 1;

             RefeName = [Path_GlobeLCC,'/MODISLCC.Y',YearName,DateName,'_500M.tif'];
             D8LCC= readgeoraster(RefeName);
             

             YrLCC(:,:,k) = D8LCC;

      end

      MulLCC95p =  prctile(YrLCC,95,3);

      OutputFile = fullfile([Path_LCCTIF, 'LCC95P_Y01_CMG1KM_',YearName,'.tif']);
      geotiffwrite(OutputFile, MulLCC95p, R, 'TiffTags', struct('Compression', Tiff.Compression.LZW));

      disp(['Done with ',YearName])
 end

