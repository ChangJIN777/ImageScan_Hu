% open all the igor data
%%
Igor = actxserver('IgorPro.Application');
pause(1) % crashes without a pause
Igor.Visible = 1; % show the Igor if not already
Igor.NewExperiment(0);
Igor.OpenFile(0, 12, '', 'C:\Users\lab\Documents\WaveMetrics\Igor Pro 6 User Files\User Procedures\NVAnalysis.ipfT4');
Igor.OpenFile(0, 12, '', 'C:\Users\lab\Documents\WaveMetrics\Igor Pro 6 User Files\User Procedures\NVFitFunctions.ipf');
%%
igorDateFull = 'C:\Users\lab\Documents\Data\2015_May_08\';%get(handles.esrSavePath,'String');
igorDateTrunc = igorDateFull((end-6):(end-1));
latestIndex = num2str(13);%num2str(str2num(get(handles.numCompleted,'String'))-2);

% parameters to change with new data sets
numgraphs = 30;
prefix = 't_NVE';%'autoZ_NVB';
suffix = '_T1';
repsPerTau = 10000;
pi_time = 100;


% plotting windows parameters--------
% make a grid of windows of specified position height, width
width=230;
height=115;
numhorz=6;
numvert=5;
firstx=0;
firsty=0;
xvals = firstx:width:(firstx+width*(numhorz-1));
yvals = firsty:height:(firsty+height*(numvert-1));
[xmat, ymat] = meshgrid(xvals,yvals);
xmat = xmat';
ymat = ymat';
%-------------------------------
irow=1;
icol=1;

for i=1:numgraphs
    if i < 9
        igorFolderName = [prefix num2str(i) suffix '0000' num2str(i+1)];
    else
        igorFolderName = [prefix num2str(i) suffix '000' num2str(i+1)];      
    end
    x1= num2str(xmat(i));
    x2= num2str(xmat(i)+width);
    y1= num2str(ymat(i));
    y2= num2str(ymat(i)+height);
    repsStr = num2str(repsPerTau);
    piStr = num2str(pi_time);
    %LoadT1DiffWinPos(13, "Apr_24", "p_NVB36_T100049",10000,1,100,0,0,230,115)
    igorString = ['LoadT1DiffWinPos(' latestIndex ', "' igorDateTrunc '", "' igorFolderName '", ' repsStr ',1,' piStr ',' x1 ',' y1 ',' x2 ',' y2 ')'];
    Igor.Execute(igorString);
end

%%
% results of T1 of NVs
numNV = 36;
NVBnames = linspace(1,numNV,numNV);
NVBnames = NVBnames';
T1a = [152.65; 0; 109.03; 54.652; 107.78; 206.63; 108.75; 0; 242.25; 15.888; 212.84; 31.936; 0; 95.418; 0; 195.25; 42.447;...
    166.11; 0; 412.66; 0; 46.665; 175.49; 68.974; 0; 210.57; 59.667; 73.193; 0; 148.06; 126.91; 224; 66.059; 101.99;...
    119.66; 179.31];
T1aStd = [47; 0; 12.9; 13.5; 34; 21.9; 13; 1e4; 101; 2.01; 25.7; 15.7; 1e4; 35.9; 1e4; 34.8; 33.2; 40.3; 0; 200; 0; 23.6; 29.9;...
    15.8; 0; 36.2; 17.6; 15.3; 0; 28; 67.6; 33.4; 15.4; 13; 40.9; 16.3];
refCounts = [138;104;164;58;146;558;108;55;144;117;131;58;103;33;108;236;67;109;8.5;132;8.5;126;475;136;8.5;365;123;116;106;202;...
    29.5;236;240;308;232;204];

h = figure;
hist(T1a(find(T1a)),20)

h2=figure;
plot(refCounts,T1a,'r*');
