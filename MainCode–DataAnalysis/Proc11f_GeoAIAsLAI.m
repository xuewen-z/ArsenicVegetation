

% 
clear; clc;

addpath(genpath('./'));

Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_AI = '../output/01e_AridIndex_Y00/';
Path_LAImean = '../output/11d_LAImean_CMG083/';
Path_GeoAIAsLAI = '../output/11f_GeoAIAsLAI/';



system(['rm -rf '  ,Path_GeoAIAsLAI]);
system(['mkdir -p ',Path_GeoAIAsLAI]);


AI = double(readgeoraster([Path_AI,'AridIndex_Y00_CMG083DEG.tif']));
AI = AI .*0.0001;


File_LandCover = fullfile(Path_LandCover, 'LCTIGBP_USGS_MCD12Q1_Y10_CMG083DEG_20012010.tif');
[LandCover, R] = readgeoraster(File_LandCover);

AI(LandCover == 0 | LandCover == 11 | LandCover == 13 | LandCover == 15 | LandCover == 16 | LandCover == 17) =nan;

WinLAsLAI = readgeoraster([Path_LAImean, 'LAI_LRAsMean_CMG083.tif']);
WinMAsLAI = readgeoraster([Path_LAImean, 'LAI_MRAsMean_CMG083.tif']);
WinHAsLAI = readgeoraster([Path_LAImean, 'LAI_HRAsMean_CMG083.tif']);
WinEAsLAI = readgeoraster([Path_LAImean, 'LAI_ERAsMean_CMG083.tif']);


% different AI areas 

IndexHA = find(AI<0.03);
IndexA = find(AI>=0.03 & AI<0.2 );
IndexSA = find(AI>=0.2 & AI<0.5);
IndexDsh = find(AI>=0.5 & AI<0.65); 
IndexH = find(AI>=0.65); 


BioList = {'HA','A','SA','Dsh','H'}; %


LAIEAsAI = [];
LAIHAsAI = [];
LAIMAsAI = [];
LAILAsAI = [];
BoxBioNum = [];
PHLAI = [];
PMLAI = [];
PELAI = [];

for I_Bio = 1 : numel(BioList)   
    BioName = BioList{I_Bio};
    Temp = (eval(['Index',BioName]));

    EAs= WinEAsLAI(Temp);
    HAs = WinHAsLAI(Temp);
    MAs = WinMAsLAI(Temp);
    LAs= WinLAsLAI(Temp);  %  eval([BioName,'LAs'])
 
    % 进行秩和检验
    if isnan(EAs)
       P = NaN;  
    else
    [P,~] = ranksum(EAs,LAs); 
    end
    PELAI(I_Bio,:) = P;

    [P,~] = ranksum(HAs,LAs); 
    PHLAI(I_Bio,:) = P;

    [P,~] = ranksum(MAs,LAs); 
    PMLAI(I_Bio,:) = P;

    LAIEAsAI = [LAIEAsAI;EAs];
    LAIHAsAI = [LAIHAsAI;HAs];
    LAIMAsAI = [LAIMAsAI;MAs];
    LAILAsAI = [LAILAsAI;LAs];

    Number = I_Bio * ones(size(HAs,1));
    BoxBioNum = [BoxBioNum; Number(:,1)];

   
end

save([Path_GeoAIAsLAI,'AIAsLAI.mat'],'-regexp','^LAI*','^BoxBio*','^P*');




