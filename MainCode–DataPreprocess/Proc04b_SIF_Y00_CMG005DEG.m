clear; clc;
addpath(genpath('./'));

% 设置路径
Path_YearSIF = '../input/GoSIF/Yearly/';
Path_MulSIF = '../output/04b_SIF_Y00_CMG005DEG/';

% 清理并创建输出文件夹
system(['rm -rf ', Path_MulSIF]);
system(['mkdir -p ', Path_MulSIF]);

% 设定处理年份范围
Years = 2001:2020;
NumYears = numel(Years);

% 读取第一年的数据，确定维度
RefeName = [Path_YearSIF, 'GOSIF_2001.tif'];  
[TempSIF, R] = readgeoraster(RefeName);
Proj = geotiffinfo(RefeName);
[Rows, Cols] = size(TempSIF);

% 预分配存储矩阵，提高计算效率
MulSIF = nan(Rows, Cols, NumYears);

% 逐年读取 SIF 数据
for i = 1:NumYears
    Year = Years(i);
    YearName = num2str(Year, '%d');
    
    % 读取 SIF 数据并进行预处理
    FilePath = [Path_YearSIF, 'GOSIF_', YearName, '.tif'];
    TempSIF = double(readgeoraster(FilePath));
    
    % 过滤异常值（32767: 水，32766: 冰雪）
    TempSIF(TempSIF == 32767 | TempSIF == 32766) = nan;
    
    % 进行单位转换并限制最小值
    TempSIF = TempSIF * 0.0001;
    TempSIF(TempSIF < 0) = 0.0001;
    
    % 存储数据
    MulSIF(:, :, i) = TempSIF;
    
    disp(['Done with ', YearName]);
end

% 计算多年平均值及标准差
MulSIF_Avg = mean(MulSIF, 3, 'omitnan');
MulSIF_Std = std(MulSIF, 0, 3, 'omitnan');

% 保存 GeoTIFF 结果
geotiffwrite([Path_MulSIF, 'SIFAVG_Y00_CMG005DEG_20012020.tif'], MulSIF_Avg, R, ...
    'TiffTags', struct('Compression', Tiff.Compression.LZW));

geotiffwrite([Path_MulSIF, 'SIFSTD_Y00_CMG005DEG_20012020.tif'], MulSIF_Std, R, ...
    'TiffTags', struct('Compression', Tiff.Compression.LZW));
