function [results] = extract_hydrus_outputs(folder_path)
    % =============================================================
    % 纯“物理复制”版提取器：直接定位列号，不进行复杂识别
    % =============================================================

    %% 1. 提取 Nod_Inf.out (Depth: 2, Conc1: 12)
    nod_content = fileread(fullfile(folder_path, 'Nod_Inf.out'));
    time_idx = strfind(nod_content, 'Time:');
    last_block = nod_content(time_idx(end):end); % 只要最后一段
    lines = strsplit(last_block, {'\n', '\r'});
    
    data = [];
    for k = 1:length(lines)
        row = str2num(lines{k}); 
        % 只要这一行数字足够多，我就强行取第 2 和 第 12 个
        if length(row) >= 12 
            data = [data; row(2), row(12)]; 
        end
    end
    results.Depth = data(:, 1);
    results.Conc1 = data(:, 2);

    %% 2. 提取 solute1.out (cRoot: 9, cvRoot: 11)
    sol_content = fileread(fullfile(folder_path, 'solute1.out'));
    lines = strsplit(sol_content, {'\n', '\r'});
    
    data = [];
    for k = 1:length(lines)
        row = str2num(lines{k});
        % 只要这一行数字够多，直接硬取第 9 和 12 个
        if length(row) >= 12
            data = [data; row(9), row(12)];
        end
    end
    results.cRoot_series = data(:, 1);
    results.cvRoot_final  = data(end, 2);

    %% 3. 提取 T_Level.out (vRoot: 5)
    t_content = fileread(fullfile(folder_path, 'T_Level.out'));
    lines = strsplit(t_content, {'\n', '\r'});
    
    data = [];
    for k = 1:length(lines)
        row = str2num(lines{k});
        % 直接硬取第 5 个数字
        if length(row) >= 5
            data = [data; row(5)];
        end
    end
    results.vRoot_final = data(end);
end