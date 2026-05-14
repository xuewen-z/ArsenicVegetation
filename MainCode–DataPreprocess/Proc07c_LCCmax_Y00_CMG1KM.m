
addpath(genpath('./'));
clear; clc; 

Path_LCCTIF = '../output/06c_LCCmax_Y01_CMG1KM/';
Path_Output = '../output/07c_LCCmax_Y00_CMG1KM/';

system(['rm -rf ',Path_Output]);
system(['mkdir -p ',Path_Output]);

% 读取示例 GeoTIFF 获取参考信息
Example_File = fullfile(Path_LCCTIF, 'LCC95P_Y01_CMG1KM_2001.tif');
[~, R] = readgeoraster(Example_File, 'OutputType', 'double');
 
MultYLCC = nan([R.RasterSize,20]);


 for I_Year = 2001 : 2020
     YearName = num2str(I_Year,'%d');
         
     
             RefeName = [Path_LCCTIF,'LCC95P_Y01_CMG1KM_',YearName,'.tif'];
             YLCCmax= readgeoraster(RefeName);
             Proj = geotiffinfo(RefeName);


             MultYLCC(:,:,I_Year-2000) = YLCCmax;

     
      disp(['Done with ',YearName])
 end

      AVGLCC95p =  mean(MultYLCC,3,'omitnan');

      OutputFile = fullfile([Path_Output, 'LCC95P_Y00_CMG1KM_20012020.tif']);
      geotiffwrite(OutputFile, AVGLCC95p, R, 'TiffTags', struct('Compression', Tiff.Compression.LZW));
