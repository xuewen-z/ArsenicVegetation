clear; clc;
addpath(genpath('./'));

% Step 1: 路径设置
Path_GEM = '../input/';
Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_CO2EcoServ = '../output/64_DominEcoServMean/';
Path_EcoServPFT = '../output/65_DominEcoPFTMean/';

system(['rm -rf '  ,Path_EcoServPFT]);
system(['mkdir -p ',Path_EcoServPFT]);

% Step 2: 读取数据
[DominEco, ~] = readgeoraster([Path_CO2EcoServ,'DominEcoServ.AsLoss.tif']);  
[GeoPFT_raw, ~] = readgeoraster([Path_LandCover,'LCTIGBP_USGS_MCD12Q1_Y10_CMG083DEG_20012010.tif']);  
GeoPFT_raw = double(GeoPFT_raw);

% Step 3: 植被类型重编码（生成新的植被类型编号）

GeoPFT = nan(size(GeoPFT_raw));
GeoPFT(GeoPFT_raw == 12 | GeoPFT_raw == 14) = 10;  % CRO
GeoPFT(GeoPFT_raw == 6  | GeoPFT_raw == 7 ) = 6;  % SH

% 其余保留原编号（以便逐一统计），并重新编号为3起
veg_codes = [1 2 3 4 5];  % Tall tree
for i = 1:length(veg_codes)
    GeoPFT(GeoPFT_raw == veg_codes(i)) = i;  % 编号从1开始
end

veg_codes = [8 9 10];
for i = 1:length(veg_codes)  % short tree
    GeoPFT(GeoPFT_raw == veg_codes(i)) = i+6;  % 编号从7开始
end

% Step 4: 屏蔽 DominEco 中无效区域
GeoPFT(isnan(DominEco)) = nan;

% Step 5: 统计每个PFT下生态服务的占比
PFTtypes = 1:10;    % 现在共有10个功能类型
Ecoserv = 1:5;      % 生态系统服务类型（CS, CR, WC, SR, AGB）
Percent = zeros(length(PFTtypes), length(Ecoserv));
for vt = PFTtypes
    Vegemask = GeoPFT == vt;
    for ES = Ecoserv
        Servmask = DominEco == ES;
        Overlapmask = Servmask & Vegemask;

        if vt == 10 && ES == 1  % CRO下CS服务
            Percent(vt, ES) = 0;
        elseif vt == 10  % CRO下其余服务，分母要特殊处理
            % 只统计非CS的CRO像元
            NonCSmask = Vegemask & (DominEco ~= 1) & ~isnan(DominEco);
            Percent(vt, ES) = nnz(Overlapmask) / nnz(NonCSmask) * 100;
        else  % 其它PFT按总像元数为分母
            Percent(vt, ES) = nnz(Overlapmask) / nnz(Vegemask) * 100;
        end
    end
end


save([Path_EcoServPFT,'DominEcoPFT.mat'],'-regexp','^Percent*');
