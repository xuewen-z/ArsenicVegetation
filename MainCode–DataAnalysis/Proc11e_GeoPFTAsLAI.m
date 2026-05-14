
clear; clc;
addpath(genpath('./'));

Path_LandCover = '../input/LCTIGBP_USGS_MCD12Q1_Y10_CMG00_20012020_XQC/';
Path_LAImean = '../output/11d_LAImean_CMG083/';
Path_GeoPFTAsLAI = '../output/11e_GeoPFTAsLAI/';


system(['rm -rf '  ,Path_GeoPFTAsLAI]);
system(['mkdir -p ',Path_GeoPFTAsLAI]);


File_LandCover = fullfile(Path_LandCover, 'LCTIGBP_USGS_MCD12Q1_Y10_CMG083DEG_20012010.tif');
[LandCover, R] = readgeoraster(File_LandCover);

WinLAsLAI = readgeoraster([Path_LAImean, 'LAI_LRAsMean_CMG083.tif']);
WinMAsLAI = readgeoraster([Path_LAImean, 'LAI_MRAsMean_CMG083.tif']);
WinHAsLAI = readgeoraster([Path_LAImean, 'LAI_HRAsMean_CMG083.tif']);
WinEAsLAI = readgeoraster([Path_LAImean, 'LAI_ERAsMean_CMG083.tif']);


IndexENF = find(LandCover == 1);  
IndexEBF = find(LandCover == 2);
IndexDNF = find(LandCover == 3);
IndexDBF = find(LandCover == 4);
IndexMIF = find(LandCover == 5);
IndexOSH = find(LandCover == 6 | LandCover == 7);
IndexWSA = find(LandCover == 8);
IndexSAV = find(LandCover == 9);
IndexGRA = find(LandCover == 10);   
IndexCRO = find(LandCover == 12 | LandCover == 14);   


BioList = {'ENF','EBF','DNF','DBF','MIF','OSH','WSA','SAV','GRA','CRO'}; %,'CSH','WET'


LAIHAsPFT = [];
LAIMAsPFT = [];
LAILAsPFT = [];
LAIEAsPFT = [];
BoxBioNum = [];
PHLAI = [];
PMLAI = [];
PELAI = [];

for I_Bio = 1 : numel(BioList)   
    BioName = BioList{I_Bio};
    Temp = (eval(['Index',BioName]));

    EAs = WinEAsLAI(Temp);
    HAs = WinHAsLAI(Temp);
    MAs = WinMAsLAI(Temp);
    LAs= WinLAsLAI(Temp);  %  eval([BioName,'LAs'])
 
    % 进行秩和检验
    [P,~] = ranksum(HAs,LAs); 
    PHLAI(I_Bio,:) = P;

    [P,~] = ranksum(MAs,LAs); 
    PMLAI(I_Bio,:) = P;

    if isnan(EAs)
       P = NaN;
       
    else
    [P,~] = ranksum(EAs,LAs); 
    end

    PELAI(I_Bio,:) = P;

    LAIEAsPFT = [LAIEAsPFT;EAs];
    LAIHAsPFT = [LAIHAsPFT;HAs];
    LAIMAsPFT = [LAIMAsPFT;MAs];
    LAILAsPFT = [LAILAsPFT;LAs];

    Number = I_Bio * ones(size(HAs,1));
    BoxBioNum = [BoxBioNum; Number(:,1)];

   
end

save([Path_GeoPFTAsLAI,'GeoPFTAsLAI.mat'],'-regexp','^LAI*','^BoxBio*','^P*');


