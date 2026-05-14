clear; clc;
addpath(genpath('./')); % 确保 extract_hydrus_outputs.m 在路径中
tic

%% ========================================================================
% 1. 路径与基础设置
% =========================================================================
base_dir    = 'H:\Hydrus1D_Batch\'; 
engine_path = fullfile(base_dir, 'H1D_Engine');
% 确认输入路径：根据你的描述改为 09_SiteH1DRunFile
input_root  = fullfile(base_dir, 'output', '09_SiteH1DRunFile');
% 结果保存路径
output_root = fullfile(base_dir, 'output', '10_ActualObs1');
h1d_exec    = fullfile(engine_path, 'H1D_Calc.exe'); 

if ~exist(output_root, 'dir'), mkdir(output_root); end

% 获取站点文件夹
site_dirs = dir(fullfile(input_root, 'Site_*'));
site_dirs = site_dirs([site_dirs.isdir]);
num_sites = length(site_dirs);

fprintf('🚀 发现 %d 个待计算站点（已预筛选），开始执行 As=0 和 实测浓度模拟...\n', num_sites);

%% ========================================================================
% 2. 外层循环：遍历每个站点
% =========================================================================
for s = 1:num_sites
    site_name = site_dirs(s).name;
    site_path = fullfile(input_root, site_name);
    save_filename = fullfile(output_root, [site_name, '_Actual.mat']);
    
    % --- A. 断点续传逻辑 ---
    if exist(save_filename, 'file')
        continue;
    end
    
    % --- B. 从 DESCRIPT.TXT 中提取真实 As 浓度 ---
    desc_file = fullfile(site_path, 'DESCRIPT.TXT');
    if ~exist(desc_file, 'file')
        warning('站点 %s 缺失 DESCRIPT.TXT', site_name); continue;
    end
    
    desc_text = fileread(desc_file);
    matches = regexp(desc_text, 'Groundwater As-\s*([\d\.]+)', 'tokens');
    if ~isempty(matches)
        obs_val = str2double(matches{1}{1});
    else
        warning('站点 %s 无法从 DESCRIPT.TXT 提取浓度', site_name); continue;
    end
    
    % --- C. 设置计算目标 (0 和 实测值) ---
    as_targets = [0, obs_val]; 
    final_data = struct();
      
    fprintf('\n========== [%d/%d] %s (实测浓度: %.2f) ==========\n', ...
            s, num_sites, site_name, obs_val);
    
    %% ====================================================================
    % 3. 内层循环：运行 2 次 (0 和 obs_val)
    % =====================================================================
    for i = 1:length(as_targets)
        c_as = as_targets(i);
        
        % 1. 修改 ATMOSPH.in
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
                
                % 格式化输出
                line_format = '%11.0f%12.3f%12.3f%12.3f%12d%12d%12d%12d%12d%12d%12d%12d%12.2f';
                lines{target_row} = sprintf(line_format, vals);
                break;
            end
        end
        
        fid = fopen(atmos_file, 'w');
        fprintf(fid, '%s\n', lines{:});
        fclose(fid);
        
        % 2. 运行计算引擎
        old_pwd = pwd; cd(site_path);
        fid_dir = fopen('LEVEL_01.DIR', 'w');
        fprintf(fid_dir, '.\n.\n'); fclose(fid_dir);
        
        [~, ~] = system(['echo. | "', h1d_exec, '"']);
        cd(old_pwd);
        
        % 3. 提取结果
        try
            pause(0.1); % 短暂缓冲确保文件写入完成
            res = extract_hydrus_outputs(site_path);
            
            % 动态命名：As_0 或 As_78_5
            safe_name = ['As_', strrep(num2str(c_as), '.', '_')];
            final_data.(safe_name) = res;
        catch ME
            fprintf('   - 浓度 %.1f 提取异常: %s\n', c_as, ME.message);
        end
    end
    
    % --- 4. 保存站点合并结果 ---
    save(save_filename, 'final_data', 'obs_val');
    clear final_data; % 释放内存
    
end

toc
disp('✨ 1751个有效站点模拟全部完成！结果已存至 10_ActualObs。');