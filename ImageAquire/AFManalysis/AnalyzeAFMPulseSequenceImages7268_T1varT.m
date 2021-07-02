%% analyze AFM pulse sequence imaging data
% loads .scan and .info files in the automatically saved afm scan folder
% for further visualization and post-processing
% 03/27/15
doLinePlots=0; % whether to plot T1 line scans
doHeightSurfAndContours=0; % whether to plot height map
doLimNormTo_01=0; % whether to limit colorscale on iChan=1 (usually norm) to [0,1] interval
fixColorScale=1; countLow=-10; countHigh=0; fracLow=100*-0.10; fracHigh=0;
%-------------- inputs---------
scanNum = 7268; % scan number in scans directory
npc  = 7;%5 % number of pulse channels, e.g. = 5 for norm,sig1,ref1,sig2,ref2
ncc = 7;%1 % number of custom channels to add, post-processing of existing channels into new visualization
customNorm = []; % expression 
fac = 1; %resize factor
%------------------------------
strFile = ['C:\AFM\scans\', num2str(scanNum),'\', sprintf('%06d',scanNum)];
scanFile = [strFile,'.scan'];
infoFile = [strFile,'.info'];
scanDat = importdata(scanFile);
scanInfo = importdata(infoFile,'\t');
chanLabels = scanInfo{end};
chanLabelsArray = strsplit(chanLabels,'/');

% get resolution
numPointsLine = strsplit(scanInfo{4},':');
numPointsDims = strsplit(numPointsLine{2},'x');
numPointsX = str2double(numPointsDims{1}); % integer number of points in X
numPointsY = str2double(numPointsDims{2}); % integer number of points in Y

% get center
centerLine = strsplit(scanInfo{3},':'); 
Vpos = regexp(centerLine{2},'V'); % find positions of units in string
cpos = regexp(centerLine{2},','); % find dividing comma in string
centerX_V = str2double(centerLine{2}(2:Vpos(1)-1)); % extract X value
centerY_V = str2double(centerLine{2}(cpos+1:Vpos(2)-1)); % extract Y value
centerX_um = centerX_V*10;
centerY_um = centerY_V*10;

% get size
sizeLine = strsplit(scanInfo{2},':');
Vpos = regexp(sizeLine{2},'V'); % find positions of units in string
cpos = regexp(sizeLine{2},'x'); % find dividing x in string
sizeX_V = str2double(sizeLine{2}(1:Vpos(1)-1));
sizeY_V = str2double(sizeLine{2}(cpos+1:Vpos(2)-1));
sizeX_um = sizeX_V*10;
sizeY_um = sizeY_V*10;

% limits
xmin_um=centerX_um-sizeX_um/2;
xmax_um =centerX_um+sizeX_um/2;
ymin_um = centerY_um-sizeY_um/2;
ymax_um = centerY_um+sizeY_um/2;

% reshape the channel data into array
chanImages = cell(2,npc);
extraImages = cell(2,ncc);

if (ncc+npc >0)
figure('Position',[400,700,200*(npc),400]);
pulseChanCounter=7; % #7 should always be the first non-Z channel
colormap('pink');
end

numPointsX
numPointsY
size(scanDat(:,7))
sizeX_um

% reshape into image format and plot each channel forward and reverse
for iChan=1:npc
    
    %forward
    %chanImages{1,iChan}=wiener2(reshape(scanDat(:,pulseChanCounter),numPointsX,numPointsY)); 
    chanImages{1,iChan}=reshape(scanDat(:,pulseChanCounter),numPointsY,numPointsX); 
    plottedImage = imresize(chanImages{1,iChan},fac);
    subplot(2,npc,iChan);
    if iChan==1 && doLimNormTo_01
        clims = [0 1];
        imagesc([xmin_um,xmax_um],...
            [ymin_um,ymax_um],...
            plottedImage,clims);
    elseif fixColorScale && iChan>1
        clims = [countLow,countHigh];
        imagesc([xmin_um,xmax_um],...
            [ymin_um,ymax_um],...
            plottedImage,clims);
    else
        imagesc([xmin_um,xmax_um],...
            [ymin_um,ymax_um],...
            plottedImage);
    end
    title(['(',num2str(1),',',num2str(iChan),') ',chanLabelsArray{pulseChanCounter}]);
    pulseChanCounter = pulseChanCounter+1;
    
    %reverse
    %chanImages{2,iChan}=wiener2(reshape(scanDat(:,pulseChanCounter),numPointsX,numPointsY));
    chanImages{2,iChan}=reshape(scanDat(:,pulseChanCounter),numPointsY,numPointsX);
    plottedImage = imresize(chanImages{2,iChan},fac);
    subplot(2,npc,iChan+npc);
    if iChan==1 && doLimNormTo_01
        clims = [0 1];
        imagesc([xmin_um,xmax_um],...
            [ymin_um,ymax_um],...
            plottedImage,clims);
    elseif fixColorScale && iChan>1
        clims = [countLow,countHigh];
        imagesc([xmin_um,xmax_um],...
            [ymin_um,ymax_um],...
            plottedImage,clims);
    else
        imagesc([xmin_um,xmax_um],...
            [ymin_um,ymax_um],...
            plottedImage);
    end
    title(['(',num2str(2),',',num2str(iChan),') ',chanLabelsArray{pulseChanCounter}]);
    pulseChanCounter = pulseChanCounter+1;
end

% if there are any custom channels
if ncc ~=0
    figure('Position',[400,500,200*(ncc),400]);
    colormap('pink');
end
pulseChanCounter=7;
for kChan = 1:ncc
    %extraImages{1,kChan} = (chanImages{1,3}./chanImages{1,2})+(chanImages{1,5}./chanImages{1,4});
    %extraImages{1,kChan} = abs(chanImages{1,5}-chanImages{1,4})./abs(chanImages{1,3}-chanImages{1,2});
    extraImages{1,kChan} = 100*chanImages{1,kChan}./chanImages{1,1};
    %extraImages{1,kChan} = (chanImages{1,5}-chanImages{1,4});
    plottedImage = imresize(extraImages{1,kChan},fac);
    
    subplot(2,ncc,kChan);
    if doLimNormTo_01
        clims=[0 1];
        imagesc([centerX_um-sizeX_um/2,centerX_um+sizeX_um/2],...
            [centerY_um-sizeY_um/2,centerY_um+sizeY_um/2],...
            plottedImage,clims);
    elseif fixColorScale
        clims = [fracLow,fracHigh];
        imagesc([centerX_um-sizeX_um/2,centerX_um+sizeX_um/2],...
            [centerY_um-sizeY_um/2,centerY_um+sizeY_um/2],...
            plottedImage, clims);
    else
        imagesc([centerX_um-sizeX_um/2,centerX_um+sizeX_um/2],...
            [centerY_um-sizeY_um/2,centerY_um+sizeY_um/2],...
            plottedImage);
    end
    title(['(',num2str(1),',',num2str(kChan),') ',chanLabelsArray{pulseChanCounter}]);
     pulseChanCounter = pulseChanCounter+1;
    %extraImages{2,kChan} = abs(chanImages{2,5}-chanImages{2,4})./abs(chanImages{2,3}-chanImages{2,2});
    extraImages{2,kChan} = 100*chanImages{2,kChan}./chanImages{2,1};
    %extraImages{1,kChan} = (chanImages{2,5}-chanImages{2,4});
    plottedImage = imresize(extraImages{2,kChan},fac);
    
    subplot(2,ncc,kChan+ncc);
    if doLimNormTo_01
        clims=[0 1]; 
        imagesc([centerX_um-sizeX_um/2,centerX_um+sizeX_um/2],...
            [centerY_um-sizeY_um/2,centerY_um+sizeY_um/2],...
            plottedImage,clims);
    elseif fixColorScale
        clims = [fracLow,fracHigh];
        imagesc([centerX_um-sizeX_um/2,centerX_um+sizeX_um/2],...
            [centerY_um-sizeY_um/2,centerY_um+sizeY_um/2],...
            plottedImage, clims);
    else
        imagesc([centerX_um-sizeX_um/2,centerX_um+sizeX_um/2],...
            [centerY_um-sizeY_um/2,centerY_um+sizeY_um/2],...
            plottedImage);
    end
    title(['(',num2str(2),',',num2str(kChan),') ',chanLabelsArray{pulseChanCounter}]);
    pulseChanCounter = pulseChanCounter+1;
end
colorbar;
%global f7214;
%global f7209;
%f7214 = chanImages{1,iChan};
%f7209 = chanImages{1,iChan};

if doLinePlots
    hp = figure;
    ypix = linspace(centerY_um-sizeY_um/2,centerY_um+sizeY_um/2,numPointsY*fac);
    plot1 = imresize(chanImages{1,1}(:,1),fac);
    plot2 = imresize(chanImages{1,1}(:,2),fac);
    plot3 = imresize(chanImages{2,1}(:,1),fac);
    plot4 = imresize(chanImages{2,1}(:,2),fac);
    meanScan = 0.25*(plot1 + plot2 + plot3+ plot4);
    plot(ypix,plot1,'k-');
    hold on;
    plot(ypix,plot2,'k-');
    plot(ypix,plot3,'b-');
    plot(ypix,plot4,'b-');
    plot(ypix,meanScan,'r-','LineWidth',2);
    xlabel('Y scan position [um]');
    ylabel('Normalized relaxation contrast');
    hold off;
end

if doHeightSurfAndContours
    zChanCounter=2; %3=for-unfilter, 4=for-filtered, 5=rev-unfilter, 6=rev-filtered
    zImages = cell(2,2);
    zImages{1,1}=reshape(scanDat(:,zChanCounter),numPointsY,numPointsX); 
    zImages{1,2}=reshape(scanDat(:,zChanCounter+1),numPointsY,numPointsX); 
    zImages{2,1}=reshape(scanDat(:,zChanCounter+2),numPointsY,numPointsX); 
    zImages{2,2}=reshape(scanDat(:,zChanCounter+3),numPointsY,numPointsX); 
    %zImages{1,2}(find(~zImages{1,2}))=6.2
    h2 = figure;
    %subplot(1,2,1)
    xpixels=linspace(centerX_um-sizeX_um/2,centerX_um+sizeX_um/2,numPointsX);
    ypixels=linspace(centerY_um-sizeY_um/2,centerY_um+sizeY_um/2,numPointsY);
    surf(xpixels,ypixels,-zImages{2,2},'EdgeColor','None');

    h3=figure;
    subplot(1,2,1)
    for kL=1:numPointsX
        hold on;
        plot(ypixels,-zImages{1,2}(:,kL));
        %plot3(xpixels(kL)*ones(1,numPointsY),ypixels,-zImages{1,2}(:,kL));
        xlabel('Y scan position [micron]');
    end
    hold off;
    subplot(1,2,2)
    for kL=1:numPointsY
        hold on;
        plot(xpixels,-zImages{1,2}(kL,:));
        %plot3(xpixels,ypixels(kL)*ones(1,numPointsX),-zImages{1,2}(kL,:));
        xlabel('X scan position [micron]');
    end
    hold off;
end
%%
% fit data at each point to an exponential
% e.g.: s1 = tau50 us, s2 = tau 600 us, r1,r2=tau 0 us
fitT1Image = zeros(numPointsY,numPointsX);
startPoints = [65, 3, 200];
for ix=1:numPointsX
    for iy=1:numPointsY
        tau = [0, 50, 600]; % microseconds fixed tau
        PL = [chanImages{1,2}(iy,ix),chanImages{1,5}(iy,ix),chanImages{1,3}(iy,ix)];
        expEqn = 'a+b*exp(-x/c)'; % a = offset PL, b=contrast, c=T1
        
        f1 = fit(tau',PL',expEqn,'Start', startPoints);
        fitT1Image(iy,ix) = f1.c;
        startPoints = [f1.a,f1.b,f1.c];
    end
end
h4 = figure;
imagesc([centerX_um-sizeX_um/2,centerX_um+sizeX_um/2],...
        [centerY_um-sizeY_um/2,centerY_um+sizeY_um/2],...
        fitT1Image,[0,200]);
