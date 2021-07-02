% very rough specific script for loading data saved with a file per shot

%signal1
%signal2
%ref1
%ref2
prefix = 'R6_Ozone3hrLP650_00009';
filePath = ['C:\Users\lab\Documents\Data\2015_Dec_04\',prefix,'\'];
repsPerTau=10000;
numTauPoints = 11;
numFiles=90;


ref1Histogram = zeros(numTauPoints,repsPerTau*numFiles);
%ref2Histogram = zeros(numTauPoints,repsPerTau*numFiles);
for i=1:numFiles
    %[filePath, prefix,'_Scnt_1_', num2str(i-1),'.txt']
   %dataFileS1 = importdata([filePath, prefix,'_Scnt_1_', num2str(i-1),'.txt']);
   %dataFileS2 = importdata([filePath, prefix,'_Scnt_2_', num2str(i-1),'.txt']);
   dataFileR1 = importdata([filePath, prefix,'_Rcnt_1_', num2str(i-1),'.txt']);
   %dataFileR2 = importdata([filePath, prefix,'_Rcnt_2_', num2str(i-1),'.txt']);
   
   ref1Histogram(:,((i-1)*repsPerTau+1):(i*repsPerTau)) = dataFileR1;
end

%%
figure
histogram(ref1Histogram(1,:), 'BinMethod','integers');