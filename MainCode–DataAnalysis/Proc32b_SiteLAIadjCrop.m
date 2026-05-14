
clear; clc;

addpath(genpath('./'));


Path_SiteXCov = '../output/31b_SiteXcovCrop/';
Path_SiteData_LAI = '../output/22a_SiteData_LAI/';
Path_SiteLAIadj = '../output/32b_SiteLAIadjCrop/';


system(['rm -rf '  ,Path_SiteLAIadj]);
system(['mkdir -p ',Path_SiteLAIadj]);


load([Path_SiteData_LAI, 'SiteData_LAI.mat']);
load([Path_SiteXCov, 'SiteXcov.mat']);



% AVG 删除含有 NaN 的行
NanMaskAVG = any(isnan(Xcov), 2) | isnan(SiteData_LAIAVG_20012020);
XAVGclean = Xcov(~NanMaskAVG, :);  % 删除含有 NaN 的行
LAIAVGclean = SiteData_LAIAVG_20012020(~NanMaskAVG);  % 删除响应变量的 NaN 行

% 如果数据清理后不为空，进行线性回归
if ~isempty(XAVGclean)
    % 增加偏置项
    XAVGclean = [ones(size(XAVGclean, 1), 1), XAVGclean];  % 增加常数项

    % 使用岭回归（可以避免共线性问题）
    lambda = 0.1;  % 正则化参数
    b = ridge(LAIAVGclean, XAVGclean(:, 2:end), lambda, 0);  % 忽略偏置项列

    % 计算预测值和残差
    ypred = XAVGclean * b;  % 预测 LAI
    LAIAVGadj = LAIAVGclean - ypred;  % 计算残差
else
    error('没有足够的数据进行计算');
end

SiteLAI_AVGadj = LAIAVGadj; 



% 将调整后的 LAI 保存
save([Path_SiteLAIadj, 'SiteLAIadjCROP.mat'],'-regexp','^SiteLAI*','^NanMask*');  