%% 设置路径和参数
clear; clc;
addpath(genpath('./'));


% --- 用户配置 ---
dataExt = '.xlsx'; 

% monitoring 总目录
monitoringDir = '../input/GGMNdata/FRA/monitoring/'; 
% wells 信息文件完整路径
wellsFile = ['../input/GGMNdata/FRA/wells' dataExt];

% 定义需要提取的化学指标 (对应 Parameter 列中的值)
targetParams = {'As', 'EC', 'pH', 'Fe', 'TDS', 'F'};

%% 第一步：读取主文件 (General Information)
fprintf('正在读取主文件: %s ...\n', wellsFile);

if ~exist(wellsFile, 'file')
    error('找不到文件：%s。', wellsFile);
end

try
    % 读取 wells 信息
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

%% 第三步：循环处理每个站点
fprintf('开始处理 %d 个站点文件...\n', numWells);
missingFilesCount = 0;

for i = 1:numWells
    fullID = results.ID(i); 
    if ismissing(fullID) || fullID == "", continue; end
    
    % ID 拆分逻辑: "00025X0198/PZ2" -> 文件夹: "00025X0198", 文件: "PZ2.xlsx"
    parts = split(fullID, '/');
    if length(parts) < 2, continue; end
    
    folderPart = parts(1);
    filePart = parts(2);
    monitorFilePath = fullfile(monitoringDir, folderPart, strcat(filePart, dataExt));
    
    if exist(monitorFilePath, 'file')
        try
            warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');
            
            % 读取监测数据 (忽略第二行单位)
            chemData = readtable(monitorFilePath, 'FileType', 'spreadsheet', ...
                'Sheet', 'Groundwater Quality', 'Basic', true, ...
                'VariableNamesRange', '1:1', ... 
                'DataRange', 'A3', ...            
                'TextType', 'string', 'VariableNamingRule', 'preserve');
            
            % --- 核心逻辑修改：按行匹配参数 ---
            chemVars = chemData.Properties.VariableNames;
            
            % 寻找 "Parameter" 和 "Value" 所在的列
            paramColIdx = find(strcmpi(chemVars, 'Parameter'), 1);
            valueColIdx = find(contains(chemVars, 'Value', 'IgnoreCase', true), 1);
            
            if isempty(paramColIdx) || isempty(valueColIdx)
                % 如果没找到标准列名，尝试第1列和第2列
                paramColIdx = 1; valueColIdx = 2;
            end
            
            % 获取该文件所有的参数名和数值
            fileParams = chemData{:, paramColIdx};
            fileValues = ifnumeric(chemData{:, valueColIdx});
            
            for k = 1:length(targetParams)
                targetP = targetParams{k};
                
                % 在 Parameter 列中寻找所有匹配该指标的行
                % 使用 strcmpi 进行不区分大小写的匹配
                rowIdx = find(strcmpi(fileParams, targetP));
                
                % 如果直接匹配不到，尝试模糊匹配 (如 "As (mg/l)")
                if isempty(rowIdx)
                    rowIdx = find(contains(fileParams, targetP, 'IgnoreCase', true));
                end
                
                if ~isempty(rowIdx)
                    % 提取这些行对应的数值，计算均值并存入结果
                    matchedVals = fileValues(rowIdx);
                    results.(targetP)(i) = mean(matchedVals, 'omitnan');
                end
            end
        catch
            % 忽略读取错误
        end
    else
        missingFilesCount = missingFilesCount + 1;
    end
    
    if mod(i, 50) == 0
        fprintf('进度: %d / %d (未找到: %d)\n', i, numWells, missingFilesCount);
    end
end

%% 第四步：保存结果
outputFile = fullfile('../input/GGMNdata/FRA - GGMN/', 'Processed_Results.xlsx');
writetable(results, outputFile);

fprintf('\n处理完成！共提取 %d 个指标。\n', length(targetParams));
fprintf('结果已保存至: %s\n', outputFile);
head(results)

%% --- 辅助函数 ---
function out = ifnumeric(in)
    if isnumeric(in)
        out = double(in);
    else
        % 处理含非数字字符的情况，只保留数字部分
        out = str2double(in);
    end
end