
clear; clc;

addpath(genpath('./'));


Path_SiteXCov = '../output/25_SiteXcov/';
Path_SiteData_LCC = '../output/22c_SiteData_LCC/';
Path_SiteLCCadj = '../output/26c_SiteLCCadj/';

system(['rm -rf '  ,Path_SiteLCCadj]);
system(['mkdir -p ',Path_SiteLCCadj]);


load([Path_SiteData_LCC, 'SiteData_LCC.mat']);
load([Path_SiteXCov, 'SiteXcov.mat']);



% 删除含有 NaN 的行
NanMask95P = any(isnan(Xcov), 2) | isnan(SiteData_LCC95P);
X95Pclean = Xcov(~NanMask95P, :);  % 删除含有 NaN 的行
LCC95Pclean = SiteData_LCC95P(~NanMask95P);  % 删除响应变量的 NaN 行

% 如果数据清理后不为空，进行线性回归
if ~isempty(X95Pclean)
    % 增加偏置项
    X95Pclean = [ones(size(X95Pclean, 1), 1), X95Pclean];  % 增加常数项

    % 使用岭回归（可以避免共线性问题）
    lambda = 0.1;  % 正则化参数
    b = ridge(LCC95Pclean, X95Pclean(:, 2:end), lambda, 0);  % 忽略偏置项列

    % 计算预测值和残差
    ypred = X95Pclean * b;  % 预测 LCC
    LCC95Padj = LCC95Pclean - ypred;  % 计算残差
else
    error('没有足够的数据进行计算');
end

 SiteLCC_95Padj = LCC95Padj; 

% 将调整后的 LCC 保存
save([Path_SiteLCCadj, 'SiteLCCadj.mat'],'-regexp','^SiteLCC*','^NanMask*');  