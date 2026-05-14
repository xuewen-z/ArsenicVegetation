
clear; clc;

addpath(genpath('./'));


Path_SiteXCov = '../output/25_SiteXcov/';
Path_SiteData_NDVI = '../output/22d_SiteData_NDVI/';
Path_SiteNDVIadj = '../output/26d_SiteNDVIadj/';

system(['rm -rf '  ,Path_SiteNDVIadj]);
system(['mkdir -p ',Path_SiteNDVIadj]);


load([Path_SiteData_NDVI, 'SiteData_NDVI.mat']);
load([Path_SiteXCov, 'SiteXcov.mat']);


% AVG 删除含有 NaN 的行
NanMaskAVG = any(isnan(Xcov), 2) | isnan(SiteData_NDVIAVG_20012020);
XAVGclean = Xcov(~NanMaskAVG, :);  % 删除含有 NaN 的行
NDVIAVGclean = SiteData_NDVIAVG_20012020(~NanMaskAVG);  % 删除响应变量的 NaN 行

% 如果数据清理后不为空，进行线性回归
if ~isempty(XAVGclean)
    % 增加偏置项
    XAVGclean = [ones(size(XAVGclean, 1), 1), XAVGclean];  % 增加常数项

    % 使用岭回归（可以避免共线性问题）
    lambda = 0.1;  % 正则化参数
    b = ridge(NDVIAVGclean, XAVGclean(:, 2:end), lambda, 0);  % 忽略偏置项列

    % 计算预测值和残差
    ypred = XAVGclean * b;  % 预测 NDVI
    NDVIAVGadj = NDVIAVGclean - ypred;  % 计算残差
else
    error('没有足够的数据进行计算');
end

 SiteNDVI_AVGadj = NDVIAVGadj; 



% 
% % AVG 删除含有 NaN 的行
% NanMask95P = any(isnan(Xcov), 2) | isnan(SiteData_NDVI95P_20012020);
% X95Pclean = Xcov(~NanMask95P, :);  % 删除含有 NaN 的行
% NDVI95Pclean = SiteData_NDVI95P_20012020(~NanMask95P);  % 删除响应变量的 NaN 行
% 
% % 如果数据清理后不为空，进行线性回归
% if ~isempty(X95Pclean)
%     % 增加偏置项
%     X95Pclean = [ones(size(X95Pclean, 1), 1), X95Pclean];  % 增加常数项
% 
%     % 使用岭回归（可以避免共线性问题）
%     lambda = 0.1;  % 正则化参数
%     b = ridge(NDVI95Pclean, X95Pclean(:, 2:end), lambda, 0);  % 忽略偏置项列
% 
%     % 计算预测值和残差
%     ypred = X95Pclean * b;  % 预测 NDVI
%     NDVI95Padj = NDVI95Pclean - ypred;  % 计算残差
% else
%     error('没有足够的数据进行计算');
% end
% 
%  SiteNDVI_95Padj = NDVI95Padj; 

% 将调整后的 NDVI 保存
save([Path_SiteNDVIadj, 'SiteNDVIadj.mat'],'-regexp','^SiteNDVI*','^NanMask*');  