%% GGMN Duo Guo Shu Ju Zi Dong Hui Zong Jiao Biao (Pure Text Version)
clear; clc;

% 1. Pei Zhi Lu Jing Yu Mu Biao Bian Liang
baseDir = '../input/GGMNdata/'; 
countries = {'FRA','Sweden', 'Rwanda', 'Nigeria', 'Malaysia', 'Somalia'};
% Mu biao lie ming (Qing bi dui Excel biao tou)
targetCols = {'ID', 'Latitude', 'Longitude', 'As', 'EC', 'pH', 'Fe', 'TDS', 'F'};

All_Summary = table();
disp('Start processing and unifying data types...');

% 2. Xun Huan Chu Li
for i = 1:length(countries)
    countryName = countries{i};
    filePath = fullfile(baseDir, countryName, 'Processed_Results.xlsx');
    
    if ~exist(filePath, 'file')
        fprintf('Skip: File not found for %s\n', countryName);
        continue; 
    end
    
    try
        opts = detectImportOptions(filePath);
        opts.VariableNamingRule = 'preserve';
        T = readtable(filePath, opts);
        
        % --- Core Fix: Unify numeric types ---
        varsInFile = T.Properties.VariableNames;
        numericVars = intersect(targetCols, varsInFile, 'stable');
        % Exclude ID and coordinates from forced double conversion if they are strings
        numericVars = setdiff(numericVars, {'ID', 'Latitude', 'Longitude'});
        
        for v = 1:length(numericVars)
            colName = numericVars{v};
            colData = T.(colName);
            
            if iscell(colData)
                % Convert cell to string then to double (Handles Mixed '12' and NaN)
                tempStr = string(colData);
                T.(colName) = str2double(tempStr);
            elseif iscategorical(colData) || isstring(colData) || ischar(colData)
                T.(colName) = str2double(string(colData));
            else
                % Already numeric, ensure it is double
                T.(colName) = double(colData);
            end
        end
        % ---------------------------------------

        existingCols = T.Properties.VariableNames;
        coreVars = intersect({'As', 'EC', 'pH', 'Fe', 'TDS', 'F'}, existingCols);
        
        if ~isempty(coreVars)
            % Extract rows that have at least one numeric value in core columns
            dataMatrix = table2array(T(:, coreVars));
            hasData = any(~isnan(dataMatrix), 2);
            subT = T(hasData, :);
            
            % Select only target columns present in this file
            finalCols = intersect(targetCols, subT.Properties.VariableNames, 'stable');
            subT = subT(:, finalCols);
            
            % Add source country label
            subT.Country = repmat({countryName}, height(subT), 1);
            
            % Horizontal alignment and vertical concatenation
            if isempty(All_Summary)
                All_Summary = subT;
            else
                % Fill missing columns in All_Summary
                missingInSummary = setdiff(subT.Properties.VariableNames, All_Summary.Properties.VariableNames);
                for col = missingInSummary
                    All_Summary.(col{1}) = nan(height(All_Summary), 1);
                end
                
                % Fill missing columns in subT
                missingInSub = setdiff(All_Summary.Properties.VariableNames, subT.Properties.VariableNames);
                for col = missingInSub
                    subT.(col{1}) = nan(height(subT), 1);
                end
                
                % Ensure same column order before appending
                subT = subT(:, All_Summary.Properties.VariableNames);
                All_Summary = [All_Summary; subT];
            end
            fprintf('Success: %s - Extracted %d records.\n', countryName, height(subT));
        end
        
    catch ME
        fprintf('Error: Processing %s failed: %s\n', countryName, ME.message);
    end
end

% 3. Final Output
if ~isempty(All_Summary)
    % Reorder: Country to the first column
    All_Summary = movevars(All_Summary, 'Country', 'Before', 1);
    
    savePath = fullfile(baseDir, 'GGMN_Global_Merged_As_Data.xlsx');
    writetable(All_Summary, savePath);
    fprintf('\nSummary complete! Total samples: %d\n', height(All_Summary));
    fprintf('File saved to: %s\n', savePath);
else
    disp('No valid data extracted. Check your column names.');
end