function profile_matrix = profiledat(WTD, RD, numNodes)
% 输入: WTD(水位), RD(根深), numNodes(节点数)
% 输出: 11列矩阵 [n, x, h, Mat, Lay, Beta, Axz, Bxz, Dxz, Temp, Conc]

% WTD = 200; % 地下水深度
% RD = 100;  % 根深
% numNodes = 101; % 节点数

    % 1. 生成网格 (x)
    x = linspace(0, -WTD, numNodes)'; 

    % 2. 初始水头 (h)
    h = -abs(x - (-WTD)); 

    % 3. 根分布系数 (Beta)
    actual_root_limit_z = max(-RD, -WTD);
    Beta = zeros(numNodes, 1);
    
    % 向量化计算提升速度
    is_root_zone = (x >= actual_root_limit_z);
    Beta(is_root_zone) = 1.2 * (1 - abs(x(is_root_zone)) / abs(actual_root_limit_z));

    % 4. 材料和子区域 (Mat & Lay)
    % 规则：前30行(i=1~30)为1，之后为2
    Mat = ones(numNodes, 1);
    Lay = ones(numNodes, 1);
    if numNodes > 30
        Mat(31:end) = 2;
        Lay(31:end) = 2;
    end

    % 5. 填充常数列
    n = (1:numNodes)';         % 节点序号
    Axz = ones(numNodes, 1);   % 比例因子 Axz
    Bxz = ones(numNodes, 1);   % 比例因子 Bxz
    Dxz = ones(numNodes, 1);   % 比例因子 Dxz
    Temp = zeros(numNodes, 1); % 初始温度
    Conc = zeros(numNodes, 1); % 初始浓度

    % 6. 合并为 11 列输出
    profile_matrix = [n, x, h, Mat, Lay, Beta, Axz, Bxz, Dxz, Temp, Conc];
end