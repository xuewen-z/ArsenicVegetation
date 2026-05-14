%% HYDRUS-1D 分层蒙特卡洛剖面敏感性分析 
clear; clc;
tic
% --- 1. 基础配置 ---
base_dir    = 'H:\Hydrus1D_Batch\';
engine_path = fullfile(base_dir, 'H1D_Engine');
h1d_exec    = fullfile(engine_path, 'H1D_Calc.exe');

% 定义 4 个干湿分区的阈值范围 [下限, 上限]
ai_zones = [0.03, 0.20;   % Zone 1: < 0.2 (Hyper/Arid)
            0.20, 0.50;   % Zone 2: 0.2 - 0.5 (Semi-arid)
            0.50, 0.65;   % Zone 3: 0.5 - 0.65 (Dry sub-humid)
            0.65, 1.5];  % Zone 4: > 0.65 (Humid)

num_per_zone = 1000;       % 每个区间抽样的数量 1000
num_mc = num_per_zone * size(ai_zones, 1); % 自动计算总模拟次数 (100 * 4 = 400次)

% 目标站点配置
target_sites = {'Site_0001', 'Site_0020'}; 
input_root   = fullfile(base_dir, 'siteInputs');
output_root  = fullfile(base_dir, 'output', '12_AsDepthMC');
if ~exist(output_root, 'dir'), mkdir(output_root); end

% --- 2. 站点循环 ---
for s = 1:length(target_sites)
    site_name = target_sites{s};
    site_path = fullfile(input_root, site_name);
    fprintf('🚀 正在处理站点: %s\n', site_name);
    
    mc_profiles = []; 
    mc_ai_factors = nan(num_mc, 1); % 预分配内存
    mc_cRoot_all = nan(num_mc, 760); 
    
    rng(166, 'twister'); % 设定随机种子，保证每次跑生成的随机数一致
    
    %预先生成分层抽样的目标 AI 列表
    target_ai_list = zeros(num_mc, 1);
    current_idx = 1;
    for z = 1:size(ai_zones, 1)
        lower_bound = ai_zones(z, 1);
        upper_bound = ai_zones(z, 2);
        % 在当前区间内均匀随机生成 num_per_zone 个样本
        zone_samples = lower_bound + (upper_bound - lower_bound) * rand(num_per_zone, 1);
        target_ai_list(current_idx : current_idx + num_per_zone - 1) = zone_samples;
        current_idx = current_idx + num_per_zone;
    end
    
   
    % --- 3. 蒙特卡洛循环 ---
    for m = 1:num_mc
        % 1. 提取实测浓度 (obs_val)
        desc_file = fullfile(site_path, 'DESCRIPT.TXT');
        desc_text = fileread(desc_file);
        matches = regexp(desc_text, 'Groundwater As-\s*([\d\.]+)', 'tokens');
        obs_val = str2double(matches{1}{1});
    
    

        % 2. 直接从预先生成的列表中读取目标 AI，不再直接使用 rand()
        target_ai = target_ai_list(m);
        mc_ai_factors(m, 1) = target_ai;
        
        % 3. 修改 ATMOSPH.in
        atmos_file = fullfile(site_path, 'ATMOSPH.in');
        fid = fopen(atmos_file, 'r');
        content = textscan(fid, '%s', 'Delimiter', '\n', 'Whitespace', '');
        lines = content{1}; fclose(fid);
        
        for row = 1:length(lines)
            if contains(lines{row}, 'tAtm')
                target_row = row + 1;
                vals = str2num(lines{target_row});
                
                % --- ATMOSPH.IN 核心修正逻辑 ---
                % vals(2) 是 Prec (降水), vals(3) 是 rsoil (蒸散)
                % 我们保持蒸腾 vals(3) 不变，通过目标 AI 计算需要的降水
                orig_pet = abs(vals(3));           % 获取原始蒸腾绝对值
                new_prec = orig_pet * target_ai;   % 计算达到目标 AI 所需的降水量
                
                vals(13) = obs_val;                % 砷浓度
                vals(2)  = new_prec;               % 直接赋予新的降水量
                % vals(3) 不变，维持原始蒸散
                % -----------------
                
                line_format = '%10.0f%10.4f%10.4f%10.4f%10.0f%10.0f%10.0f%10.0f%10.0f%10.0f%10.0f%10.0f%10.2f%10.2f';
                lines{target_row} = sprintf(line_format, vals);
                break;
            end
        end
        
        fid = fopen(atmos_file, 'w'); fprintf(fid, '%s\n', lines{:}); fclose(fid);
        
        % C. 运行 HYDRUS
        old_pwd = pwd; cd(site_path);
        [status, ~] = system(['echo. | "', h1d_exec, '"']);
        cd(old_pwd);
        
        % D. 提取结果
        pause(0.5); % 适当减小 pause 提高效率
        res = extract_hydrus_outputs(site_path); 
        
        if m == 1
            depth_axis = res.Depth; 
        end
        mc_profiles = [mc_profiles; res.Conc1']; 
        cols = length(res.cRoot_series);
        mc_cRoot_all(m, 1:cols) = res.cRoot_series'; 
        
        % 控制台输出也帮你加了这是第几个区间的提示（由于是顺序执行的）
        current_zone = ceil(m / num_per_zone); 
        fprintf('   - MC Run %d/%d (Zone %d, AI: %.4f, New Prec: %.4f) 完成\n', ...
                m, num_mc, current_zone, target_ai, new_prec);
    end
    
    % --- 4. 保存站点 MC 结果 ---
    save_name = fullfile(output_root, [site_name, 'MC.mat']);
    save(save_name, 'mc_profiles', 'depth_axis', 'mc_ai_factors', 'mc_cRoot_all');
end
toc
disp('✨ 分层蒙特卡洛模拟全部结束。mc_ai_factors 包含 4 个干湿区间的均匀分布样本。');