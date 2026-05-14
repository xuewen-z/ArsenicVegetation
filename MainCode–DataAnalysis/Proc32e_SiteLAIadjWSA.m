
clear; clc;

addpath(genpath('./'));

Path_SiteXCov = '../output/31e_SiteXcovWSA/';
Path_SiteData_LAI = '../output/22a_SiteData_LAI/';
Path_SiteLAIadj = '../output/32e_SiteLAIadjWSA/';


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



% AVG 删除含有 NaN 的行
NanMask95P = any(isnan(Xcov), 2) | isnan(SiteData_LAI95P_20012020);
X95Pclean = Xcov(~NanMask95P, :);  % 删除含有 NaN 的行
LAI95Pclean = SiteData_LAI95P_20012020(~NanMask95P);  % 删除响应变量的 NaN 行

% 如果数据清理后不为空，进行线性回归
if ~isempty(X95Pclean)
    % 增加偏置项
    X95Pclean = [ones(size(X95Pclean, 1), 1), X95Pclean];  % 增加常数项

    % 使用岭回归（可以避免共线性问题）
    lambda = 0.1;  % 正则化参数
    b = ridge(LAI95Pclean, X95Pclean(:, 2:end), lambda, 0);  % 忽略偏置项列

    % 计算预测值和残差
    ypred = X95Pclean * b;  % 预测 LAI
    LAI95Padj = LAI95Pclean - ypred;  % 计算残差
else
    error('没有足够的数据进行计算');
end

SiteLAI_95Padj = LAI95Padj; 


% 将调整后的 LAI 保存
save([Path_SiteLAIadj, 'SiteLAIadj20012020.mat'],'-regexp','^SiteLAI*','^NanMask*');  