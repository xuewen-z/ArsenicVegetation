clear; clc;
addpath(genpath('./'));

% 定义输入和输出路径
Path_Input = '../output/04a_LAI_Y01_CMG1KM/';
Path_Output = '../output/05a_LAI_Y00_CMG1KM/';

% 确保输出目录存在
system(['rm -rf ', Path_Output]);
system(['mkdir -p ', Path_Output]);

% 读取示例 GeoTIFF 获取参考信息
Example_File = fullfile(Path_Input, 'LAIAVG_Y01_CMG1KM_2001.tif');
[~, R] = readgeoraster(Example_File, 'OutputType', 'double');

% 定义十年期，避免字段名以数字开头
Decadal_Periods = containers.Map(...
    {'Period_20012010', 'Period_20012020', 'Period_20112020'}, ...
    {2001:2010, 2001:2020, 2011:2020});

% 计算不同时间段的 LAI 平均值和 95% 分位数
Keys = keys(Decadal_Periods);
for i = 1:length(Keys)
    Period = Keys{i};
    Years = Decadal_Periods(Period);
    Period_Name = erase(Period, "Period_"); % 移除前缀用于文件命名

    fprintf('Processing time period: %s\n', Period_Name);

    % 读取所有年份的 LAI 数据
    LAIAVG_Data = [];
    LAI95P_Data = [];
    
    for Year = Years
        File_LAIAVG = fullfile(Path_Input, sprintf('LAIAVG_Y01_CMG1KM_%d.tif', Year));
        File_LAI95P = fullfile(Path_Input, sprintf('LAI95P_Y01_CMG1KM_%d.tif', Year));
        
        if isfile(File_LAIAVG) && isfile(File_LAI95P)
            LAIAVG_Year = readgeoraster(File_LAIAVG, 'OutputType', 'double');
            LAI95P_Year = readgeoraster(File_LAI95P, 'OutputType', 'double');
            
            LAIAVG_Data = cat(3, LAIAVG_Data, LAIAVG_Year);
            LAI95P_Data = cat(3, LAI95P_Data, LAI95P_Year);
            
            fprintf('Loaded: %s and %s\n', File_LAIAVG, File_LAI95P);
        else
            fprintf('Missing files for year: %d\n', Year);
        end
    end

    % 计算十年期的 LAI 平均值和 95% 分位数
    LAIAVG_Decadal = mean(LAIAVG_Data, 3, 'omitnan');
    LAI95P_Decadal = mean(LAI95P_Data, 3, 'omitnan');

    Output_File_LAIAVG = fullfile(Path_Output, sprintf('LAIAVG_Y00_CMG1KM_%s.tif', Period_Name));
    geotiffwrite(Output_File_LAIAVG, LAIAVG_Decadal, R, 'TiffTags', struct('Compression', Tiff.Compression.LZW));
    fprintf('Saved: %s\n', Output_File_LAIAVG);

    Output_File_LAI95P = fullfile(Path_Output, sprintf('LAI95P_Y00_CMG1KM_%s.tif', Period_Name));
    geotiffwrite(Output_File_LAI95P, LAI95P_Decadal, R, 'TiffTags', struct('Compression', Tiff.Compression.LZW));
    fprintf('Saved: %s\n', Output_File_LAI95P);
end
