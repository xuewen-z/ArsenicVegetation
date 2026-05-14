%% ODS 批量转 XLSX 转换器 (适用于 Linux + LibreOffice - 扁平化结构)
clear; clc;

% --- 用户配置 ---
% 基础路径 (当前设置为索马里，可根据需要修改国家名称)
baseDir = '../input/GGMNdata/Sweden/';  % Sweden /Rwanda /Nigeria /Malaysia /Somalia
monitoringDir = fullfile(baseDir, 'monitoring');
wellsFileOds = fullfile(baseDir, 'wells.ods');

fprintf('开始 Linux 环境下的批量转换任务 (使用 LibreOffice)...\n');

% 检查 LibreOffice 是否安装
[status, ~] = system('command -v soffice');
if status ~= 0
    error('在系统中找不到 "soffice" 命令。请确保安装了 LibreOffice。');
end

%% 1. 转换主文件 wells.ods
if exist(wellsFileOds, 'file')
    fprintf('正在转换主文件: wells.ods ...\n');
    convertFileLibre(wellsFileOds);
else
    fprintf('警告: 找不到主文件 %s\n', wellsFileOds);
end

%% 2. 转换监测文件夹下的所有 ods (扁平化处理)
if exist(monitoringDir, 'dir')
    fprintf('正在处理监测目录: %s ...\n', monitoringDir);
    
    % 获取 monitoring 目录下所有的 .ods 文件 (不进入子文件夹)
    odsFiles = dir(fullfile(monitoringDir, '*.ods'));
    
    if ~isempty(odsFiles)
        numFiles = length(odsFiles);
        fprintf('  检测到 %d 个监测文件，开始转换...\n', numFiles);
        
        for k = 1:numFiles
            fullOdsPath = fullfile(monitoringDir, odsFiles(k).name);
            convertFileLibre(fullOdsPath);
            
            % 每处理 10% 显示一次进度
            if mod(k, max(1, round(numFiles/10))) == 0
                fprintf('  转换进度: %d/%d\n', k, numFiles);
            end
        end
    else
        fprintf('  提示: monitoring 目录下未发现 .ods 文件。\n');
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
    
    % 如果已经存在对应的 xlsx，则跳过以提高效率
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
        if status ~= 0
            fprintf('  转换失败: %s. 错误信息: %s\n', fName, cmdOut);
        end
    catch ME
        fprintf('  发生异常: %s, 错误: %s\n', fName, ME.message);
    end
end