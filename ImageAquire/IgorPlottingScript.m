% open all the igor data
%%
Igor = actxserver('IgorPro.Application');
pause(1) % crashes without a pause
Igor.Visible = 1; % show the Igor if not already
Igor.NewExperiment(0);
Igor.OpenFile(0, 12, '', 'C:\Users\lab\Documents\WaveMetrics\Igor Pro 6 User Files\User Procedures\NVAnalysis.ipfT3');
%%
igorDateFull = 'C:\Users\lab\Documents\Data\2015_Mar_11\';%get(handles.esrSavePath,'String');
igorDateTrunc = igorDateFull((end-6):(end-1));
latestIndex = num2str(11);%num2str(str2num(get(handles.numCompleted,'String'))-2);

% parameters to change with new data sets
numgraphs = 32;
prefix = 'autoZ_NVB';
suffix = '_cwesr';

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
    if i < -1
        igorFolderName = [prefix num2str(i) suffix '000' num2str(i+19)];
    else
        igorFolderName = [prefix num2str(i) suffix '00' num2str(i+19)];      
    end
    x1= num2str(xmat(i));
    x2= num2str(xmat(i)+width);
    y1= num2str(ymat(i));
    y2= num2str(ymat(i)+height);
    igorString = ['LoadCWESRsweepWinPos(' latestIndex ', "' igorDateTrunc '", "' igorFolderName '", ' x1 ',' y1 ',' x2 ',' y2 ')'];
    Igor.Execute(igorString);
end