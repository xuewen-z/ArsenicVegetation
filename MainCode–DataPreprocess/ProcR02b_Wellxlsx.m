%% 设置路径和参数
clear; clc;
addpath(genpath('./'));

% --- 用户配置 ---
% 基础路径 (当前设置为索马里，可根据需要修改)
baseDir = '../input/GGMNdata/Sweden/';   % Sweden /Rwanda /Nigeria /Malaysia /Somalia
dataExt = '.xlsx'; 

% monitoring 目录 (扁平化结构，文件直接在此目录下)
monitoringDir = fullfile(baseDir, 'monitoring'); 
% wells 信息文件完整路径
wellsFile = fullfile(baseDir, ['wells' dataExt]);

% 定义需要提取的化学指标 (对应监测表中 Parameter 列的值)
targetParams = {'As', 'EC', 'pH', 'Fe', 'TDS', 'F'};

%% 第一步：读取主文件 (General Information)
fprintf('正在读取主文件: %s ...\n', wellsFile);

if ~exist(wellsFile, 'file')
    error('找不到文件：%s。请确认已完成 ODS 转 XLSX 转换。', wellsFile);
end

try
    % 读取 wells 信息 (跳过第二行单位行)
    masterData = readtable(wellsFile, 'FileType', 'spreadsheet', ...
        'Sheet', 'General Information', ...
        'VariableNamesRange', '1:1', ...  
        'DataRange', 'A3', ...             
        'TextType', 'string', ...
        'VariableNamingRule', 'preserve'); 
catch ME
    error('读取 wells 文件失败。错误信息：%s', ME.message);
end

% 识别列名
colNames = masterData.Properties.VariableNames;
idIdx = find(contains(colNames, 'ID', 'IgnoreCase', true), 1);
latIdx = find(contains(colNames, 'Lat', 'IgnoreCase', true), 1);
if isempty(latIdx), latIdx = find(contains(colNames, 'Y', 'IgnoreCase', true), 1); end
lonIdx = find(contains(colNames, 'Lon', 'IgnoreCase', true), 1);
if isempty(lonIdx), lonIdx = find(contains(colNames, 'X', 'IgnoreCase', true), 1); end

idColName = colNames{idIdx};
latColName = colNames{latIdx};
lonColName = colNames{lonIdx};

%% 第二步：准备结果容器
numWells = height(masterData);
results = table();
results.ID = masterData.(idColName);
results.Latitude = ifnumeric(masterData.(latColName));
results.Longitude = ifnumeric(masterData.(lonColName));

% 为化学指标预分配 NaN 列
for k = 1:length(targetParams)
    results.(targetParams{k}) = nan(numWells, 1);
end

%% 第三步：循环处理每个站点 (扁平化文件读取)
fprintf('开始处理 %d 个站点文件...\n', numWells);
missingFilesCount = 0;

for i = 1:numWells
    fullID = results.ID(i); 
    if ismissing(fullID) || fullID == "", continue; end
    
    % --- 扁平化处理逻辑 ---
    % 如果 ID 是 "00025X0198/PZ2"，我们取斜杠后的 "PZ2" 作为文件名
    % 如果 ID 没斜杠，就直接用 ID 作为文件名
    if contains(fullID, '/')
        parts = split(fullID, '/');
        fileName = parts(end); 
    else
        fileName = fullID;
    end
    
    % 直接在 monitoring 目录下寻找文件，不再进入子文件夹
    monitorFilePath = fullfile(monitoringDir, strcat(fileName, dataExt));
    
    if exist(monitorFilePath, 'file')
        try
            warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');
            
            % 读取监测数据 (忽略第二行单位)
            chemData = readtable(monitorFilePath, 'FileType', 'spreadsheet', ...
                'Sheet', 'Groundwater Quality', 'Basic', true, ...
                'VariableNamesRange', '1:1', ... 
                'DataRange', 'A3', ...            
                'TextType', 'string', 'VariableNamingRule', 'preserve');
            
            chemVars = chemData.Properties.VariableNames;
            
            % 寻找 "Parameter" 和 "Value" 所在的列
            paramColIdx = find(strcmpi(chemVars, 'Parameter'), 1);
            valueColIdx = find(contains(chemVars, 'Value', 'IgnoreCase', true), 1);
            
            if isempty(paramColIdx) || isempty(valueColIdx)
                % 备选方案：尝试第1列和第2列
                paramColIdx = 1; valueColIdx = 2;
            end
            
            % 获取该文件所有的参数名和数值
            fileParams = chemData{:, paramColIdx};
            fileValues = ifnumeric(chemData{:, valueColIdx});
            
            for k = 1:length(targetParams)
                targetP = targetParams{k};
                
                % 在 Parameter 列中寻找匹配项 (忽略大小写)
                rowIdx = find(strcmpi(fileParams, targetP));
                
                % 模糊匹配备选 (如 "As (mg/l)")
                if isempty(rowIdx)
                    rowIdx = find(contains(fileParams, targetP, 'IgnoreCase', true));
                end
                
                if ~isempty(rowIdx)
                    % 提取数值，计算均值（针对多日期数据）
                    matchedVals = fileValues(rowIdx);
                    results.(targetP)(i) = mean(matchedVals, 'omitnan');
                end
            end
        catch
            % 忽略个别损坏文件的读取错误
        end
    else
        missingFilesCount = missingFilesCount + 1;
    end
    
    if mod(i, 50) == 0
        fprintf('进度: %d / %d (未找到文件: %d)\n', i, numWells, missingFilesCount);
    end
end

%% 第四步：保存结果
outputFile = fullfile(baseDir, 'Processed_Results.xlsx');
writetable(results, outputFile);

fprintf('\n处理完成！共提取 %d 个化学指标。\n', length(targetParams));
fprintf('最终汇总表已保存至: %s\n', outputFile);
head(results)

%% --- 辅助函数：安全转换数值 ---
function out = ifnumeric(in)
    if isnumeric(in)
        out = double(in);
    else
        % 尝试将字符串转换为双精度数值
        out = str2double(in);
    end
end