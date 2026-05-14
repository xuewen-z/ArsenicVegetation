clear; clc;
addpath(genpath('./')); % 确保 extract_hydrus_outputs.m 在路径中
tic

%% ========================================================================
% 1. 路径与基础设置
% =========================================================================
base_dir    = 'H:\Hydrus1D_Batch\'; 
engine_path = fullfile(base_dir, 'H1D_Engine');
input_root  = fullfile(base_dir, 'output', '09_SiteH1DRunFile');
output_root = fullfile(base_dir, 'output', '11_AsGradient');
h1d_exec    = fullfile(engine_path, 'H1D_Calc.exe'); % 请确保此路径下有计算引擎

if ~exist(output_root, 'dir'), mkdir(output_root); end

% --- 梯度设置 (推荐的 11 个关键点，覆盖 0-200) ---
% 采用前密后疏原则，捕捉低浓度非线性特征
base_gradients = [0, 10, 20, 30, 40, 60, 80, 100, 130, 160, 200];

% --- 获取站点文件夹 ---
site_dirs = dir(fullfile(input_root, 'Site_*'));
site_dirs = site_dirs([site_dirs.isdir]);
num_sites = length(site_dirs);

fprintf('🚀 发现 %d 个站点，准备开始全量梯度模拟...\n', num_sites);

%% ========================================================================
% 2. 外层循环：遍历每个站点
% =========================================================================
for s = 1:num_sites
% for s= 1 
    site_name = site_dirs(s).name;
    site_path = fullfile(input_root, site_name);
    save_filename = fullfile(output_root, [site_name, '.mat']);
    
    % --- 断点续传逻辑 ---
    if exist(save_filename, 'file')
        fprintf('⏩ [%d/%d] 站点 %s 已有结果，跳过。\n', s, num_sites, site_name);
        continue;
    end
    
    % --- 关键修改：从 DESCRIPT.TXT 中提取真实 As 浓度 ---
    desc_file = fullfile(site_path, 'DESCRIPT.TXT');
    if ~exist(desc_file, 'file')
        warning('站点 %s 缺失 DESCRIPT.TXT，跳过。', site_name); continue;
    end
    
    % 读取文件内容并提取数字
    desc_text = fileread(desc_file);
    % 使用正则表达式匹配数字（支持整数和小数）
    matches = regexp(desc_text, 'Groundwater As-\s*([\d\.]+)', 'tokens');
    if ~isempty(matches)
        obs_val = str2double(matches{1}{1});
    else
        warning('站点 %s 的 DESCRIPT.TXT 格式不正确，无法提取浓度。', site_name);
        continue;
    end
    
    % 准备当前的浓度序列（合并梯度与提取到的实测值）
    as_gradients = unique(sort([base_gradients, obs_val]));
    final_data = struct();
    
    fprintf('\n========== [%d/%d] 站点: %s (从文件提取实测值: %.2f) ==========\n', ...
            s, num_sites, site_name, obs_val);
    
    %% ====================================================================
    % 3. 内层循环：遍历浓度梯度
    % =====================================================================
    for i = 1:length(as_gradients)
        c_as = as_gradients(i);
        
        % A. 修改 ATMOSPH.in
        atmos_file = fullfile(site_path, 'ATMOSPH.in');
        fid = fopen(atmos_file, 'r');
        file_content = textscan(fid, '%s', 'Delimiter', '\n', 'Whitespace', '');
        lines = file_content{1};
        fclose(fid);
        
        for row = 1:length(lines)
            if contains(lines{row}, 'tAtm')
                target_row = row + 1; 
                vals = str2num(lines{target_row});
                
                % 修改 cBot (第 13 列)
                vals(13) = c_as; 
                
                % 格式化输出 (保持 12 位宽)
                line_format = '%11.0f%12.3f%12.3f%12.3f%12d%12d%12d%12d%12d%12d%12d%12d%12.2f';
                lines{target_row} = sprintf(line_format, vals);
                break;
            end
        end
        
        fid = fopen(atmos_file, 'w');
        fprintf(fid, '%s\n', lines{:});
        fclose(fid);
        
        % B. 运行引擎
        old_pwd = pwd; cd(site_path);
        fid_dir = fopen('LEVEL_01.DIR', 'w');
        fprintf(fid_dir, '.\n.\n'); fclose(fid_dir);
        
        [status, ~] = system(['echo. | "', h1d_exec, '"']);
        cd(old_pwd);
        
        % C. 提取结果
        try
            pause(0.2); 
            res = extract_hydrus_outputs(site_path);
            
            % 转换浓度为合法字段名 (Site_78_7)
            safe_name = ['As_', strrep(num2str(c_as), '.', '_')];
            final_data.(safe_name) = res;
            
            % fprintf('   - 进度: %d/%d (浓度 %.1f) ✅\n', i, length(as_gradients), c_as);
        catch ME
            fprintf('   - 进度: %d/%d (浓度 %.1f) ❌ 失败\n', i, length(as_gradients), c_as);
        end
    end
    
    % --- 4. 保存站点结果 ---
    save(save_filename, 'final_data', 'as_gradients', 'obs_val');
    clear final_data; % 释放内存
    
end

toc
disp('✨ 全部模拟任务已根据 DESCRIPT.TXT 提取的实测值完成！');