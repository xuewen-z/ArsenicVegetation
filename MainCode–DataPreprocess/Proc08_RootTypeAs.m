clear; clc;
addpath(genpath('./'));

% 设置文件路径
Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_WTD = '../input/Water-TableDepth/';
Path_GeoAsType = '../output/01a_AsProb_CMG1KM/';
Path_LAIAnomaly = '../output/11a_LAIanomaly_CMG1KM/';
Path_output = '../output/08_RootTypeAs/';
Path_Figure    = '../figure/';

% 确保输出目录存在
system(['rm -rf ', Path_output]);
system(['mkdir -p ', Path_output]);

% 读取风险区掩码
File_GeoAsType = fullfile(Path_GeoAsType, 'AsType.TargetPixel.ControlPixel.CMG1KM.tif');
GeoAsType = readgeoraster(File_GeoAsType);

% 读取 LandCover 影像数据及其地理信息
[LandCover, R] = readgeoraster([Path_LandCover,'LCTIGBP_USGS_MCD12Q1_Y10_CMG1KM_20012010.tif']);
LandCover = double(LandCover);

PRD = double(readgeoraster([Path_WTD,'PRD_Y00_CMG1KM.tif']));
PRD(LandCover==15 | LandCover ==16 | LandCover==11 |LandCover==13 | LandCover ==17 | LandCover ==0) =nan;

WTD = readgeoraster([Path_WTD,'WaterTD_Y00_CMG1KM.tif']);  
WTD(LandCover==15 | LandCover ==16 | LandCover==11 |LandCover==13 | LandCover ==17 | LandCover ==0) =nan;
WTD = double(WTD);
WTD(WTD<-100) =nan;


AsType = readgeoraster([Path_GeoAsType, 'AsType.TargetPixel.ControlPixel.CMG1KM.tif']);
AsType(LandCover==15 | LandCover ==16 | LandCover==11 |LandCover==13 | LandCover ==17 | LandCover ==0) =nan;
AsType =double(AsType);
AsType(AsType==0)=nan;

LAIanom = readgeoraster([Path_LAIAnomaly, 'LAIanomaly_CMG1KM.tif']);
LAIanom(LandCover==15 | LandCover ==16 | LandCover==11 |LandCover==13 | LandCover ==17 | LandCover ==0) =nan;


% DiffPRD < 0 : 直接接触
% DiffPRD > 0 : 间接接触
DiffPRD = abs(WTD) - abs(PRD);


% 构建有效陆地掩膜
MaskMRA = ~isnan(DiffPRD) & (AsType==2);
MaskHRA = ~isnan(DiffPRD) & (AsType==3);
MaskERA = ~isnan(DiffPRD) & (AsType==4);

RDelevat = nan(size(DiffPRD));
RDelevat(MaskMRA) = DiffPRD(MaskMRA);  
RDelevat(MaskHRA) = DiffPRD(MaskHRA);   
RDelevat(MaskERA) = DiffPRD(MaskERA); 


FileName =[Path_output,'PRD_EelevatedAsType.CMG1KM.tif'];
geotiffwrite(FileName,RDelevat,R,'TiffTags',struct('Compression',Tiff.Compression.LZW));



% 直接接触区
DirectMRA = (DiffPRD <= 0) & MaskMRA;
DirectHRA = (DiffPRD <= 0) & MaskHRA;
DirectERA = (DiffPRD <= 0) & MaskERA;


% 间接接触区
IndirectMRA = (DiffPRD > 0) & MaskMRA;
IndirectHRA = (DiffPRD > 0) & MaskHRA;
IndirectERA = (DiffPRD > 0) & MaskERA;

% 总陆地像元
NumTotalMRA = sum(MaskMRA(:));
NumTotalHRA = sum(MaskHRA(:));
NumTotalERA = sum(MaskERA(:));

% 直接接触区像元
NumDirectMRA = sum(DirectMRA(:));
NumDirectHRA = sum(DirectHRA(:));
NumDirectERA = sum(DirectERA(:));

% 直接接触区百分比（相对于全球陆地）
PercentDMRA = NumDirectMRA / NumTotalMRA * 100;
PercentDHRA = NumDirectHRA / NumTotalHRA * 100;
PercentDERA = NumDirectERA / NumTotalERA * 100;


% 取出各风险等级下的DiffPRD数据
DiffPRDMRA = DiffPRD(MaskMRA);
DiffPRDHRA = DiffPRD(MaskHRA);
DiffPRDERA = DiffPRD(MaskERA);

% DiffPRDMRA(DiffPRDMRA<=0) = -1;
% DiffPRDHRA(DiffPRDHRA<=0) = -1;
% DiffPRDERA(DiffPRDERA<=0) = -1;


% Step 9: 绘图
Fig=figure;
set(gcf,'position',[100 100 500 420],'defaultAxesFontSize',26);  
set(gca,'Units','Pixels','Position',[80 105 400 300]);box on;hold on;


edges = -6:1:60;  % 横轴范围与分箱间距，可根据实际DiffPRD调整


H1 = histogram(DiffPRDMRA, edges, 'Normalization','probability', 'FaceColor',[1 0.85 0.2], 'EdgeColor','none', 'FaceAlpha', 0.6);
H2 = histogram(DiffPRDHRA, edges, 'Normalization','probability', 'FaceColor',[1 0.6 0.2], 'EdgeColor','none', 'FaceAlpha', 0.6);
H3 = histogram(DiffPRDERA, edges, 'Normalization','probability', 'FaceColor',[1 0 0], 'EdgeColor','none', 'FaceAlpha', 0.5);

set(gca,'ylim',[0 0.25],'ytick',0:0.1:0.3, ...
    'xlim',[-6 35],'xtick',0:10:40,'fontsize',22,... 
    'TickDir','out', 'LineWidth',1.5, 'Box', 'off');
set(gca, 'YTickLabel', get(gca,'YTick')*100);

xlabel('|WTD| - |PRD| (m)','fontsize',20);
ylabel('area fraction (%)','fontsize',20);
set(H1, 'DisplayStyle', 'bar');
set(H2, 'DisplayStyle', 'bar');
set(H3, 'DisplayStyle', 'bar');

hold on;
hFake1 = bar(nan, nan, 'FaceColor', [1 0.85 0.2], 'EdgeColor', 'none');
hFake2 = bar(nan, nan, 'FaceColor', [1 0.6 0.2], 'EdgeColor', 'none');
hFake3 = bar(nan, nan, 'FaceColor', [1 0 0], 'EdgeColor', 'none');
L = legend([hFake1 hFake2 hFake3], {'MRA','HRA','ERA'});
set(L,'Box','off','FontSize', 16,'Units','Normalized',...
    'Position',[0.65 0.8 0.1 0.1],'Orientation','horizon','ItemTokenSize', [16, 6]);

pause(5); set(gcf,'position',[100 100 500 420],'defaultAxesFontSize',26);  
print(Fig,'-dtiff','-r300',[Path_Figure,'RD-FractionAsType','.tif']);close(Fig);





% 提取每类像元的 LAI anomaly 值
% MRA
LAIMRADirect   = LAIanom( MaskMRA & (DiffPRD <= 0) );
LAIMRAIndirect = LAIanom( MaskMRA & (DiffPRD > 10) );

% HRA
LAIHRADirect   = LAIanom( MaskHRA & (DiffPRD <= 0) );
LAIHRAIndirect = LAIanom( MaskHRA & (DiffPRD > 10) );

% ERA
LAIERADirect   = LAIanom( MaskERA & (DiffPRD <= 0) );
LAIERAIndirect = LAIanom( MaskERA & (DiffPRD > 10) );


% 均值
meanMRADirect   = mean(LAIMRADirect, 'omitnan');
meanMRAIndirect = mean(LAIMRAIndirect, 'omitnan');
meanHRADirect   = mean(LAIHRADirect, 'omitnan');
meanHRAIndirect = mean(LAIHRAIndirect, 'omitnan');
meanERADirect   = mean(LAIERADirect, 'omitnan');
meanERAIndirect = mean(LAIERAIndirect, 'omitnan');

% 显著性检验（非参数，比如 ranksum/Wilcoxon）
p_MRA = ranksum(LAIMRADirect, LAIMRAIndirect);
p_HRA = ranksum(LAIHRADirect, LAIHRAIndirect);
p_ERA = ranksum(LAIERADirect, LAIERAIndirect);

% Fig
Fig = figure;
set(gcf, 'position', [100 100 540 420], 'defaultAxesFontSize', 26);
set(gca, 'Units', 'Pixels', 'Position', [80 105 400 300]);
box on; hold on;

% 组装数据：每组两个（Direct, Indirect）
All_LAI = [LAIMRADirect(:); LAIMRAIndirect(:); ...
           LAIHRADirect(:); LAIHRAIndirect(:); ...
           LAIERADirect(:); LAIERAIndirect(:)];

% 按顺序为6组
Group_ID = [ones(length(LAIMRADirect),1)*1; ones(length(LAIMRAIndirect),1)*2; ...
            ones(length(LAIHRADirect),1)*3; ones(length(LAIHRAIndirect),1)*4; ...
            ones(length(LAIERADirect),1)*5; ones(length(LAIERAIndirect),1)*6];

% x位置设置：让Direct/Indirect靠近，组间远
xpos = [1, 1.4, 3, 3.4, 5, 5.4];

% 两种颜色
color_direct = [236 99 67]/255;   % 橙红
color_indirect   = [38 120 178]/255;  % 蓝
colormap_map = {color_direct, color_indirect, color_direct, color_indirect, color_direct, color_indirect};

% 画箱型图
hold on
h = boxchart(xpos(1)*ones(size(LAIMRADirect)), LAIMRADirect,   'BoxFaceColor', color_direct,   'MarkerStyle','none','BoxWidth',0.3);
h = boxchart(xpos(2)*ones(size(LAIMRAIndirect)), LAIMRAIndirect, 'BoxFaceColor', color_indirect, 'MarkerStyle','none','BoxWidth',0.3);
h = boxchart(xpos(3)*ones(size(LAIHRADirect)),   LAIHRADirect,   'BoxFaceColor', color_direct,   'MarkerStyle','none','BoxWidth',0.3);
h = boxchart(xpos(4)*ones(size(LAIHRAIndirect)), LAIHRAIndirect, 'BoxFaceColor', color_indirect, 'MarkerStyle','none','BoxWidth',0.3);
h = boxchart(xpos(5)*ones(size(LAIERADirect)),   LAIERADirect,   'BoxFaceColor', color_direct,   'MarkerStyle','none','BoxWidth',0.3);
h = boxchart(xpos(6)*ones(size(LAIERAIndirect)), LAIERAIndirect, 'BoxFaceColor', color_indirect, 'MarkerStyle','none','BoxWidth',0.3);

% X轴主标签
set(gca,'XTick',[1.2 3.2 5.2],'XTickLabel',{'MRA','HRA','ERA'},'Fontsize',20);

set(gca,'ylim',[-5 8],'ytick',-10:5:10,'fontsize',20,...
    'TickDir','out', 'LineWidth',1.5, 'Box', 'off');

ylabel('LAI anomaly','Fontsize',20,'Color','k');
set(gca,'Units','Pixels','Position',[80 105 400 300]);

% 0线
plot([0.4 5.9],[0 0],':','Color',[0.5 0.5 0.5],'LineWidth',0.8);


% 图例
hold on
plot(nan, nan, 's', 'MarkerFaceColor', color_direct, 'MarkerEdgeColor', color_direct, 'MarkerSize', 13);
plot(nan, nan, 's', 'MarkerFaceColor', color_indirect, 'MarkerEdgeColor', color_indirect, 'MarkerSize', 13);
L = legend({'|PRD| \geq |WTD|','|PRD| < |WTD|'},'Box','off');
     
set(L,'Box','off','FontSize', 16,'Units','Normalized',...
    'Position',[0.5 0.8 0.1 0.1],'ItemTokenSize', [16, 6]);


pause(5); set(gcf,'position',[100 100 500 420],'defaultAxesFontSize',26);  
print(Fig,'-dtiff','-r300',[Path_Figure,'RD-BoxAsType','.tif']);close(Fig);



