%% ODS 批量转 XLSX 转换器 (适用于 Linux + LibreOffice)
clear; clc;

% --- 用户配置 ---
% 基础路径 (请根据你的实际路径修改)
baseDir = '../input/GGMNdata/FRA/';  % Sweden /Rwanda /Nigeria /Malaysia /Somalia
monitoringDir = fullfile(baseDir, 'monitoring');
wellsFileOds = fullfile(baseDir, 'wells.ods');

fprintf('开始 Linux 环境下的批量转换任务 (使用 LibreOffice)...\n');

% 检查 LibreOffice 是否安装
[status, ~] = system('command -v soffice');
if status ~= 0
    error('在系统中找不到 "soffice" 命令。请确保安装了 LibreOffice。');
end

%% 1. 转换主文件 wells.ods
fprintf('正在转换主文件: wells.ods ...\n');
convertFileLibre(wellsFileOds);

%% 2. 递归转换 monitoring 文件夹下的所有 ods
if exist(monitoringDir, 'dir')
    % 获取所有子文件夹
    subFolders = dir(monitoringDir);
    subFolders = subFolders([subFolders.isdir]);
    subFolders = subFolders(~ismember({subFolders.name}, {'.', '..'}));

    for i = 1:length(subFolders)
        currentSubFolder = fullfile(monitoringDir, subFolders(i).name);
        fprintf('正在处理目录: %s (%d/%d)\n', subFolders(i).name, i, length(subFolders));
        
        % 获取当前文件夹下所有的 .ods 文件
        odsFiles = dir(fullfile(currentSubFolder, '*.ods'));
        
        for j = 1:length(odsFiles)
            fullOdsPath = fullfile(currentSubFolder, odsFiles(j).name);
            convertFileLibre(fullOdsPath);
        end
    end
else
    fprintf('警告: 找不到目录 %s\n', monitoringDir);
end

fprintf('\n所有转换任务已完成！\n');

%% --- 辅助转换函数 (Linux/LibreOffice 版) ---
function convertFileLibre(odsPath)
    [fDir, fName, ~] = fileparts(odsPath);
    xlsxPath = fullfile(fDir, [fName '.xlsx']);
    
    % 如果文件不存在，直接返回
    if ~exist(odsPath, 'file')
        return;
    end
    
    % 如果已经存在对应的 xlsx，则跳过
    if exist(xlsxPath, 'file')
        return;
    end
    
    % 构建 LibreOffice 转换命令
    % --headless: 不启动图形界面
    % --convert-to xlsx: 转换为 xlsx 格式
    % --outdir: 指定输出目录
    cmd = sprintf('soffice --headless --convert-to xlsx "%s" --outdir "%s"', odsPath, fDir);
    
    try
        [status, cmdOut] = system(cmd);
        if status == 0
            fprintf('  成功转换: %s.xlsx\n', fName);
        else
            fprintf('  转换失败: %s. 错误信息: %s\n', fName, cmdOut);
        end
    catch ME
        fprintf('  发生异常: %s, 错误: %s\n', fName, ME.message);
    end
end