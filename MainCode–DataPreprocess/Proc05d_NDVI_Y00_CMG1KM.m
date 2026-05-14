clear; clc;
addpath(genpath('./'));

% 定义输入和输出路径
Path_MOD13NDVI = '/public/data/xuewen/MOD13A3NDVI/04_MOD13NDVIYavg/';
Path_Output = '../output/05d_NDVI_Y00_CMG1KM/';

% 确保输出目录存在
system(['rm -rf ', Path_Output]);
system(['mkdir -p ', Path_Output]);

% 读取示例 GeoTIFF 获取参考信息
RefeName = [Path_MOD13NDVI,'MOD13NDVIavg.A2001.061.CMG1KM.tif'];
[~,R] = readgeoraster(RefeName);


MulYNDVI = [];
           
            for  Year= 2001 : 2020
                 YearName = num2str(Year,'%d');
    
              RefeName = [Path_MOD13NDVI,'MOD13NDVIavg.A',YearName,'.061.CMG1KM.tif'];
              [MOD13NDVI,R] = readgeoraster(RefeName);

             MulYNDVI(:,:,Year-2000) = MOD13NDVI;

             disp(['Done with Year', num2str(Year)])

            end

           
      MulAvgNDVI = mean(MulYNDVI,3,'omitnan'); 
       

%    geotiff write
    
    FileName =[Path_Output,'NDVIAVG_Y00_CMG1KM_20012020.tif'];
    geotiffwrite(FileName,MulAvgNDVI,R,'TiffTags',struct('Compression',Tiff.Compression.LZW));
    

    

