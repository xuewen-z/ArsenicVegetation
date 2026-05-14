clear; clc;
addpath(genpath('./'));

%% =========================================================
% 路径设置
%% =========================================================
Path_LandCover   = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_Root        = '../output/08_RootTypeAs/';
Path_GDEprob     = '../output/09_GDETypeAs/';
Path_AsType      = '../output/01a_AsProb_CMG1KM/';
Path_LAIAnomaly  = '../output/11a_LAIanomaly_CMG1KM/';
Path_Figure      = '../figure/';

%% =========================================================
% 读取基础数据
%% =========================================================
[LandCover, R] = readgeoraster( ...
    [Path_LandCover,'LCTIGBP_USGS_MCD12Q1_Y10_CMG1KM_20012010.tif']);
LandCover = double(LandCover);

% PRD - WTD（根深 - 地下水位）
PRD_WTD = readgeoraster( ...
    [Path_Root,'PRD_EelevatedAsType.CMG1KM.tif']);
PRD_WTD = double(PRD_WTD);

% GDE probability (%)
GDEprob = readgeoraster( ...
    [Path_GDEprob,'GDE_EelevatedAsType.CMG1KM.tif']);
GDEprob = double(GDEprob);

% 地下水砷风险等级
% 1=LRA, 2=MRA, 3=HRA, 4=ERA
AsType = readgeoraster( ...
    [Path_AsType,'AsType.TargetPixel.ControlPixel.CMG1KM.tif']);
AsType = double(AsType);

% LAI anomaly
LAIanom = readgeoraster( ...
    [Path_LAIAnomaly,'LAIanomaly_CMG1KM.tif']);
LAIanom = double(LAIanom);

%% =========================================================
% LandCover 过滤
%% =========================================================
InvalidLC = (LandCover==0 | LandCover==11 | LandCover==13 | ...
             LandCover==15 | LandCover==16 | LandCover==17);

PRD_WTD(InvalidLC)  = nan;
GDEprob(InvalidLC)  = nan;
AsType(InvalidLC)   = nan;
LAIanom(InvalidLC)  = nan;

AsType(AsType==0) = nan;

%% =========================================================
% 掩膜定义
%% =========================================================
% 间接地下水接触：PRD < WTD
MaskIndirect = (PRD_WTD > 0);

% 砷风险等级
MaskMRA = (AsType == 2);
MaskHRA = (AsType == 3);
MaskERA = (AsType == 4);

% GDE 分组
MaskGDEhi = (GDEprob >= 50);
MaskGDElo = (GDEprob < 50);

%% =========================================================
% 提取各组 LAI anomaly
% 含义：
% GDEhi = Indirect + GDE >= 50%
% GDElo = Indirect + GDE < 50%
%% =========================================================
% MRA
LAIMRA_GDEhi = LAIanom( MaskIndirect & MaskMRA & MaskGDEhi );
LAIMRA_GDElo = LAIanom( MaskIndirect & MaskMRA & MaskGDElo );

% HRA
LAIHRA_GDEhi = LAIanom( MaskIndirect & MaskHRA & MaskGDEhi );
LAIHRA_GDElo = LAIanom( MaskIndirect & MaskHRA & MaskGDElo );

% ERA
LAIERA_GDEhi = LAIanom( MaskIndirect & MaskERA & MaskGDEhi );
LAIERA_GDElo = LAIanom( MaskIndirect & MaskERA & MaskGDElo );

%% =========================================================
% 去极值
%% =========================================================
thr = 5;

LAIMRA_GDEhi = LAIMRA_GDEhi(abs(LAIMRA_GDEhi) < thr);
LAIMRA_GDElo = LAIMRA_GDElo(abs(LAIMRA_GDElo) < thr);

LAIHRA_GDEhi = LAIHRA_GDEhi(abs(LAIHRA_GDEhi) < thr);
LAIHRA_GDElo = LAIHRA_GDElo(abs(LAIHRA_GDElo) < thr);

LAIERA_GDEhi = LAIERA_GDEhi(abs(LAIERA_GDEhi) < thr);
LAIERA_GDElo = LAIERA_GDElo(abs(LAIERA_GDElo) < thr);

%% =========================================================
% 统计量
%% =========================================================
meanMRA_GDEhi = mean(LAIMRA_GDEhi, 'omitnan');
meanMRA_GDElo = mean(LAIMRA_GDElo, 'omitnan');
meanHRA_GDEhi = mean(LAIHRA_GDEhi, 'omitnan');
meanHRA_GDElo = mean(LAIHRA_GDElo, 'omitnan');
meanERA_GDEhi = mean(LAIERA_GDEhi, 'omitnan');
meanERA_GDElo = mean(LAIERA_GDElo, 'omitnan');

fprintf('Mean LAI anomaly:\n');
fprintf('MRA | Indirect+GDE>=50: %.3f ; Indirect+GDE<50: %.3f\n', meanMRA_GDEhi, meanMRA_GDElo);
fprintf('HRA | Indirect+GDE>=50: %.3f ; Indirect+GDE<50: %.3f\n', meanHRA_GDEhi, meanHRA_GDElo);
fprintf('ERA | Indirect+GDE>=50: %.3f ; Indirect+GDE<50: %.3f\n', meanERA_GDEhi, meanERA_GDElo);

% 显著性检验：同一风险等级下，两类 GDE 比较
p_MRA = ranksum(LAIMRA_GDEhi, LAIMRA_GDElo);
p_HRA = ranksum(LAIHRA_GDEhi, LAIHRA_GDElo);
p_ERA = ranksum(LAIERA_GDEhi, LAIERA_GDElo);

fprintf('\nWilcoxon rank-sum p-values:\n');
fprintf('MRA: %.3e\n', p_MRA);
fprintf('HRA: %.3e\n', p_HRA);
fprintf('ERA: %.3e\n', p_ERA);

%% =========================================================
% 画图
%% =========================================================
Fig = figure;
set(gcf, 'position', [100 100 540 420], 'defaultAxesFontSize', 26);
set(gca, 'Units', 'Pixels', 'Position', [80 105 400 300]);
box on; hold on;

% x位置：每个风险等级下两个箱子，组间稍拉开
xpos = [1, 1.4, 3, 3.4, 5, 5.4];

% 颜色
color_GDEhi = [205 160 70] / 255;   % 更偏黄的褐色
color_GDElo = [86 153 77]  / 255;   % 绿色：Indirect + GDE < 50%

% MRA
h1 = boxchart(xpos(1)*ones(size(LAIMRA_GDEhi)), LAIMRA_GDEhi, ...
    'BoxFaceColor', color_GDEhi, 'MarkerStyle','none','BoxWidth',0.3);
h2 = boxchart(xpos(2)*ones(size(LAIMRA_GDElo)), LAIMRA_GDElo, ...
    'BoxFaceColor', color_GDElo, 'MarkerStyle','none','BoxWidth',0.3);

% HRA
h3 = boxchart(xpos(3)*ones(size(LAIHRA_GDEhi)), LAIHRA_GDEhi, ...
    'BoxFaceColor', color_GDEhi, 'MarkerStyle','none','BoxWidth',0.3);
h4 = boxchart(xpos(4)*ones(size(LAIHRA_GDElo)), LAIHRA_GDElo, ...
    'BoxFaceColor', color_GDElo, 'MarkerStyle','none','BoxWidth',0.3);

% ERA
h5 = boxchart(xpos(5)*ones(size(LAIERA_GDEhi)), LAIERA_GDEhi, ...
    'BoxFaceColor', color_GDEhi, 'MarkerStyle','none','BoxWidth',0.3);
h6 = boxchart(xpos(6)*ones(size(LAIERA_GDElo)), LAIERA_GDElo, ...
    'BoxFaceColor', color_GDElo, 'MarkerStyle','none','BoxWidth',0.3);

% X轴主标签
set(gca,'XTick',[1.2 3.2 5.2], ...
        'XTickLabel',{'MRA','HRA','ERA'}, ...
        'Fontsize',20);

set(gca,'ylim',[-5 8], ...
        'ytick',-10:5:10, ...
        'fontsize',20, ...
        'TickDir','out', ...
        'LineWidth',1.5, ...
        'Box','off');

ylabel('LAI anomaly','Fontsize',20,'Color','k');
set(gca,'Units','Pixels','Position',[80 105 400 300]);

% 0线
plot([0.4 5.9],[0 0],':','Color',[0.5 0.5 0.5],'LineWidth',0.8);

% 图例
plot(nan, nan, 's', 'MarkerFaceColor', color_GDEhi, 'MarkerEdgeColor', color_GDEhi, 'MarkerSize', 13);
plot(nan, nan, 's', 'MarkerFaceColor', color_GDElo, 'MarkerEdgeColor', color_GDElo, 'MarkerSize', 13);

L = legend({'GDE \geq 50%','GDE < 50%'}, 'Box','off');
set(L,'Box','off', ...
      'FontSize',16, ...
      'Units','Normalized', ...
      'Position',[0.5 0.8 0.1 0.1], ...
      'ItemTokenSize',[16, 6]);
text(0.2,-4, '|PRD| < |WTD|', 'FontSize', 16,  'Color', 'k');

pause(5);
set(gcf,'position',[100 100 500 420],'defaultAxesFontSize',26);
print(Fig,'-dtiff','-r300',[Path_Figure,'GDE_IndirectGDE_BoxAsType','.tif']);
close(Fig);