clear; clc;
addpath(genpath('./'));

%% ===============================
% 路径设置
% ===============================
PathIn = '../output/08_SiteHydrus2input/';
PathOut = '../output/09_SiteH1DRunFile/';

if ~exist(PathOut, 'dir'), mkdir(PathOut); end

load([PathIn,'HydrusInput.mat']);

   
numNodes = 101;

for i = 1: numel(Alpha_sub)
% for i = 1:5
    % ---------------------------------------------------------
    % 1. 计算并生成 PROFILE.DAT
    % ---------------------------------------------------------

    WTD = round(filtered_data(i,16).*100);
    RD = round(filtered_data(i,17).*100);
    
    profile_matrix = profiledat(WTD, RD, numNodes);

    % 创建该站点的专用文件夹 (例如 Site_0001)
    folderName = fullfile(PathOut, sprintf('Site_%04d', i));
    if ~exist(folderName, 'dir'), mkdir(folderName); end
    
    % 指定生成的 PROFILE.DAT 路径
    profilePath = fullfile(folderName, 'PROFILE.DAT');
    fid = fopen(profilePath, 'w');
    
   
    % 写入文件头信息
    fprintf(fid, 'Pcp_File_Version=4\n');
    fprintf(fid, '%6d\n', 2); % 2个观测点
    % 观测点1：地表
    fprintf(fid, ' %5d %14.6e %14.6e %14.6e\n', 1, 0, 1, 1);
    % 观测点2：对应WTD (注意这里 -WTD 要转为浮点科学计数法)
    fprintf(fid, ' %5d %14.6e %14.6e %14.6e\n', 2, -double(WTD), 1, 1);
    
  
    % 写入 11 列数据标题行
    fprintf(fid, '  %d   1   1   1       x          h       Mat  Lay      Beta         Axz          Bxz          Dxz        Temp        Conc\n', numNodes);


    % 逐行写入 11 列矩阵数据
    % profile_matrix 顺序: [n, x, h, Mat, Lay, Beta, Axz, Bxz, Dxz, Temp, Conc]
    % 格式说明：%5d(整数) %14.6e(科学计数) %5d(Mat/Lay)
    formatSpec = '%5d %14.6e %14.6e %5d %5d %14.6e %14.6e %14.6e %14.6e %14.6e %14.6e\n';
    fprintf(fid, formatSpec, profile_matrix');
    
    % 写入文件末尾标志 (通常是一个 0)
    fprintf(fid, '0\n');
    
    % 关闭当前文件句柄
    fclose(fid);
    

    %---------------------------------------------------------
    % 2. 替换并生成 HYDRUS1D.DAT
    % ---------------------------------------------------------
    % 读取模板文件内容
    TemplatePathH1D = 'H:\Hydrus1D_Batch\siteinputs\Template\HYDRUS1D.DAT';
    h1d_content = fileread(TemplatePathH1D);
    
    % 将 WTD 转换为 Hydrus 标准科学计数法 (例如 50 变为 5.E+01)
    % %5.1E 会生成 5.0E+01，我们手动把 0 删掉匹配模板样式 (或者直接用 %.1E)
    wtd_formatted = sprintf('%.1E', double(WTD)); 
    % 转换 E+01 为 E+01 (Matlab默认如此)，如果是单数字指数可能需要微调，但通常通用
    
    % 执行替换
    % 注意：要确保模板里的原始值确实是 ProfileDepth=5.E+01
    new_h1d_content = strrep(h1d_content, 'ProfileDepth=5.E+01', ['ProfileDepth=', wtd_formatted]);
    
    % 写入到当前站点文件夹
    h1dPath = fullfile(folderName, 'HYDRUS1D.DAT');
    fidH1D = fopen(h1dPath, 'w');
    fprintf(fidH1D, '%s', new_h1d_content);
    fclose(fidH1D);

    % ---------------------------------------------------------
    % 3. 替换并生成 SELECTOR.IN
    % ---------------------------------------------------------
    TemplatePathSel = 'H:\Hydrus1D_Batch\siteinputs\Template\Selector.in';
    sel_content = fileread(TemplatePathSel);
    
    % --- 构造 BLOCK B 的数据行 (Water Flow) ---
    % 格式：thr(7.3) ths(8.3) Alfa(8.3) n(8.2) Ks(10.2) l(8.1)
    % 注意：l 保持 0.5 不变
    lineB1 = sprintf('%7.3f %8.3f %8.4f %8.3f %10.2f %8.1f', ...
        ThetaR_top(i), ThetaS_top(i), Alpha_top(i), n_top(i), Ks_top(i), 0.5);
    lineB2 = sprintf('%7.3f %8.3f %8.4f %8.3f %10.2f %8.1f', ...
        ThetaR_sub(i), ThetaS_sub(i), Alpha_sub(i), n_sub(i), Ks_sub(i), 0.5);
    
    % --- 构造 BLOCK F 的数据行 (Solute Ks/Kd) ---
    % 只需要替换第一个数 Ks (即 Kd)，后面全是 0 或 1
    lineKd1 = sprintf('%11.2f%11d%11d%11d%11d%11d%11d%11d%11d%11d%11d%11d%11d%11d', ...
        Kd_top(i), 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        
    lineKd2 = sprintf('%11.2f%11d%11d%11d%11d%11d%11d%11d%11d%11d%11d%11d%11d%11d', ...
        Kd_sub(i), 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

    % --- 执行字符串替换 ---
    sel_content = strrep(sel_content, 'BLOCK_B_MAT1', lineB1);
    sel_content = strrep(sel_content, 'BLOCK_B_MAT2', lineB2);
    
    % 替换弥散度 (DisperL)
    sel_content = strrep(sel_content, 'BLOCK_F_DISP', sprintf('%12.2f', DisperL(i)));
    
    % 替换吸附系数 (Kd)
    sel_content = strrep(sel_content, 'BLOCK_F_KD1', lineKd1);
    sel_content = strrep(sel_content, 'BLOCK_F_KD2', lineKd2);
    
    % 写入文件
    selPath = fullfile(folderName, 'Selector.in');
    fidSel = fopen(selPath, 'w');
    fprintf(fidSel, '%s', sel_content);
    fclose(fidSel);


    % ---------------------------------------------------------
    % 4. 替换并生成 ATMOSPH.IN
    % ---------------------------------------------------------
    TemplatePathAtm = 'H:\Hydrus1D_Batch\siteinputs\Template\ATMOSPH.IN';
    atm_content = fileread(TemplatePathAtm);
    
    % 获取当前站点的气象和浓度参数 (确保你已经准备好了这些变量名)

    curr_Prec  = filtered_data(i, 5)./3650; %Pre  mm/year 转为cm/day
    curr_rSoil = filtered_data(i, 4)./3650; % PET  mm/year 转为cm/day
    curr_rRoot = filtered_data(i, 19); % LAI
    curr_cBot  = filtered_data(i, 3); % As
    
    % 构造数据行
    % 对应列顺序: Prec rSoil rRoot hCritA rB hB ht tTop tBot Ampl cTop cBot RootDepth
    % 模板中固定值: hCritA=10000, 其余rB~Ampl=0, cTop=0
    % 如果需要保留模板末尾的空位，请严格匹配空格。
    
    lineAtm = sprintf('%12.3f%12.3f%12.3f%12d%12d%12d%12d%12d%12d%12d%12d%12.1f', ...
        curr_Prec, curr_rSoil, curr_rRoot, 10000, 0, 0, 0, 0, 0, 0, 0, curr_cBot);

    % 执行替换
    atm_content = strrep(atm_content, 'BLOCK_ATM_DATA', lineAtm);
    
    % 写入文件
    atmPath = fullfile(folderName, 'ATMOSPH.IN');
    fidAtm = fopen(atmPath, 'w');
    fprintf(fidAtm, '%s', atm_content);
    fclose(fidAtm);


    % ---------------------------------------------------------
    % 5. 动态生成 DESCRIPT.TXT
    % ---------------------------------------------------------
    % 按照你的要求：修改第二行为 Site_0001 这种格式
    descPath = fullfile(folderName, 'DESCRIPT.TXT');
    fidDesc = fopen(descPath, 'w');
    fprintf(fidDesc, 'Pcp_File_Version=1\n');
    % 使用 %.2f 确保浓度显示两位小数
    fprintf(fidDesc, 'Groundwater As- %.1f\n', curr_cBot);
    % fprintf(fidDesc, 'Groundwater As- %s\n', sprintf('Site_%04d', i));
    fclose(fidDesc);



end % 循环结束
