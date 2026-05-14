
clear; clc;

addpath(genpath('./'));


Path_SiteXCov = '../output/25_SiteXcov/';
Path_SiteData_SIF = '../output/22b_SiteData_SIF/';
Path_SiteSIFadj = '../output/26b_SiteSIFadj/';

system(['rm -rf '  ,Path_SiteSIFadj]);
system(['mkdir -p ',Path_SiteSIFadj]);


load([Path_SiteData_SIF, 'SiteData_SIF.mat']);
load([Path_SiteXCov, 'SiteXcov.mat']);



% AVG 删除含有 NaN 的行
NanMaskAVG = any(isnan(Xcov), 2) | isnan(SiteData_SIFAVG);
XAVGclean = Xcov(~NanMaskAVG, :);  % 删除含有 NaN 的行
SIFAVGclean = SiteData_SIFAVG(~NanMaskAVG);  % 删除响应变量的 NaN 行

% 如果数据清理后不为空，进行线性回归
if ~isempty(XAVGclean)
    % 增加偏置项
    XAVGclean = [ones(size(XAVGclean, 1), 1), XAVGclean];  % 增加常数项

    % 使用岭回归（可以避免共线性问题）
    lambda = 0.1;  % 正则化参数
    b = ridge(SIFAVGclean, XAVGclean(:, 2:end), lambda, 0);  % 忽略偏置项列

    % 计算预测值和残差
    ypred = XAVGclean * b;  % 预测 SIF
    SIFAVGadj = SIFAVGclean - ypred;  % 计算残差
else
    error('没有足够的数据进行计算');
end

 SiteSIF_AVGadj = SIFAVGadj; 


% 将调整后的 SIF 保存
save([Path_SiteSIFadj, 'SiteSIFadj.mat'],'-regexp','^SiteSIF*','^NanMask*');  