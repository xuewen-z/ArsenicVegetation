% 

% function criterion = myfun(xTrain,yTrain,xTest,yTest)
% 
%   mdl = fitrensemble(xTrain,yTrain,'Method','Bag','NumLearningCycles',50);
%   precdicyTest = predict(mdl,xTest);
%   e = yTest - precdicyTest;
%   criterion = mean(e.^2);
% end


function criterion = myfun(xTrain,yTrain,xTest,yTest)

  mdl = fitrensemble(xTrain,yTrain);
  precdicyTest = predict(mdl,xTest);
  e = yTest - precdicyTest;
  criterion = mean(e.^2);
end
