function [ scand ] = GetScanData( scanNum,npc,ncc )
%GETSCANDATA
% this loads all the parameters of AFM scans from a file and saves into an
% output structure


    scand.strFile = ['C:\AFM\scans\', num2str(scanNum),'\', sprintf('%06d',scanNum)];
    scand.scanFile = [scand.strFile,'.scan'];
    scand.infoFile = [scand.strFile,'.info'];
    scand.scanDat = importdata(scand.scanFile);
    scand.scanInfo = importdata(scand.infoFile,'\t');
chanLabels = scand.scanInfo{end};
    scand.chanLabelsArray = strsplit(chanLabels,'/');

% get resolution
numPointsLine = strsplit(scand.scanInfo{4},':');
numPointsDims = strsplit(numPointsLine{2},'x');
    scand.numPointsX = str2double(numPointsDims{1}); % integer number of points in X
    scand.numPointsY = str2double(numPointsDims{2}); % integer number of points in Y

% get center
centerLine = strsplit(scand.scanInfo{3},':'); 
Vpos = regexp(centerLine{2},'V'); % find positions of units in string
cpos = regexp(centerLine{2},','); % find dividing comma in string
    scand.centerX_V = str2double(centerLine{2}(2:Vpos(1)-1)); % extract X value
    scand.centerY_V = str2double(centerLine{2}(cpos+1:Vpos(2)-1)); % extract Y value
    scand.centerX_um = scand.centerX_V*10;
    scand.centerY_um = scand.centerY_V*10;

% get size
sizeLine = strsplit(scand.scanInfo{2},':');
Vpos = regexp(sizeLine{2},'V'); % find positions of units in string
cpos = regexp(sizeLine{2},'x'); % find dividing x in string
    scand.sizeX_V = str2double(sizeLine{2}(1:Vpos(1)-1));
    scand.sizeY_V = str2double(sizeLine{2}(cpos+1:Vpos(2)-1));
    scand.sizeX_um = scand.sizeX_V*10;
    scand.sizeY_um = scand.sizeY_V*10;

% limits
    scand.xmin_um=scand.centerX_um-scand.sizeX_um/2;
    scand.xmax_um =scand.centerX_um+scand.sizeX_um/2;
    scand.ymin_um = scand.centerY_um-scand.sizeY_um/2;
    scand.ymax_um = scand.centerY_um+scand.sizeY_um/2;
    
    % reshape the channel data into array
    scand.chanImages = cell(2,npc);
    scand.extraImages = cell(2,ncc);
    scand.zImages = cell(2,2);
    scand.plImages = cell(2,1);
    
    scand.xpixels=linspace(scand.centerX_um-scand.sizeX_um/2,scand.centerX_um+scand.sizeX_um/2,scand.numPointsX);
    scand.ypixels=linspace(scand.centerY_um-scand.sizeY_um/2,scand.centerY_um+scand.sizeY_um/2,scand.numPointsY);
    
    if ncc==0 && npc ==0
       % just assume then that ch0 - z and ch7 - Counter are active 
       zChanCounter=3; %3=for-unfilter, 4=for-filtered, 5=rev-unfilter, 6=rev-filtered
    
            scand.zImages{1,1}=reshape(scand.scanDat(:,zChanCounter),scand.numPointsY,scand.numPointsX); 
            scand.zImages{1,2}=reshape(scand.scanDat(:,zChanCounter+1),scand.numPointsY,scand.numPointsX); 
            scand.zImages{2,1}=reshape(scand.scanDat(:,zChanCounter+2),scand.numPointsY,scand.numPointsX); 
            scand.zImages{2,2}=reshape(scand.scanDat(:,zChanCounter+3),scand.numPointsY,scand.numPointsX);
    else
        % this is a scan with several PL channels and no ch0 - z image.
        pulseChanCounter=7;
        for iChan=1:npc
            scand.chanImages{1,iChan}=reshape(scand.scanDat(:,pulseChanCounter),scand.numPointsY,scand.numPointsX);
            pulseChanCounter=pulseChanCounter+1;
            scand.chanImages{2,iChan}=reshape(scand.scanDat(:,pulseChanCounter),scand.numPointsY,scand.numPointsX);
            pulseChanCounter=pulseChanCounter+1;
        end
        
        for kChan = 1:ncc
            scand.extraImages{1,kChan} = 100*scand.chanImages{1,kChan}./scand.chanImages{1,1};
            scand.extraImages{2,kChan} = 100*scand.chanImages{2,kChan}./scand.chanImages{2,1};
        end
    end
end

