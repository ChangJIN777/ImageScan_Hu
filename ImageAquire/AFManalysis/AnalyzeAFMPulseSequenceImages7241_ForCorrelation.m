%% analyze AFM pulse sequence imaging data
% loads .scan and .info files in the automatically saved afm scan folder
% for further visualization and post-processing
% 03/27/15
doLinePlots=0; % whether to plot T1 line scans
doHeightSurfAndContours=1; % whether to plot height map
doLimNormTo_01=0; % whether to limit colorscale on iChan=1 (usually norm) to [0,1] interval
fixColorScale=0; countLow=-18; countHigh=0; fracLow=100*-0.04; fracHigh=100*0.01;
%-------------- inputs---------
scanNum = 7241; % scan number in scans directory
scanNum2 = 7242;
npc  = 0;%5 % number of pulse channels, e.g. = 5 for norm,sig1,ref1,sig2,ref2
ncc = 0;%1 % number of custom channels to add, post-processing of existing channels into new visualization
customNorm = []; % expression 
fac = 1; %resize factor
%------------------------------

% call function to load all data and metadat in structure sd
sd1 = GetScanData( scanNum,npc,ncc );
sd2 = GetScanData( scanNum2,npc,ncc );

if (ncc+npc >0)
figure('Position',[400,700,200*(npc),400]);
pulseChanCounter=7; % #7 should always be the first non-Z channel
colormap('pink');
end


% reshape into image format and plot each channel forward and reverse
for iChan=1:npc
    
    %forward
    %sd1.chanImages{1,iChan}=reshape(sd1.scanDat(:,pulseChanCounter),sd1.numPointsY,sd1.numPointsX); 
    plottedImage = imresize(sd1.chanImages{1,iChan},fac);
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
    title(['(',num2str(1),',',num2str(iChan),') ',sd1.chanLabelsArray{pulseChanCounter}]);
    pulseChanCounter = pulseChanCounter+1;
    
    %reverse
    %sd1.chanImages{2,iChan}=reshape(sd1.scanDat(:,pulseChanCounter),sd1.numPointsY,sd1.numPointsX);
    plottedImage = imresize(sd1.chanImages{2,iChan},fac);
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
    title(['(',num2str(2),',',num2str(iChan),') ',sd1.chanLabelsArray{pulseChanCounter}]);
    pulseChanCounter = pulseChanCounter+1;
end

% if there are any custom channels
if ncc ~=0
    figure('Position',[400,400,200*(ncc),400]);
    colormap('pink');
end
pulseChanCounter=7;
for kChan = 1:ncc
    
    plottedImage = imresize(sd1.extraImages{1,kChan},fac);
    
    subplot(2,ncc,kChan);
    if doLimNormTo_01
        clims=[0 1];
        imagesc([sd1.centerX_um-sd1.sizeX_um/2,sd1.centerX_um+sd1.sizeX_um/2],...
            [sd1.centerY_um-sd1.sizeY_um/2,sd1.centerY_um+sd1.sizeY_um/2],...
            plottedImage,clims);
    elseif fixColorScale
        clims = [fracLow,fracHigh];
        imagesc([sd1.centerX_um-sd1.sizeX_um/2,sd1.centerX_um+sd1.sizeX_um/2],...
            [sd1.centerY_um-sd1.sizeY_um/2,sd1.centerY_um+sd1.sizeY_um/2],...
            plottedImage, clims);
    else
        imagesc([centerX_um-sizeX_um/2,centerX_um+sizeX_um/2],...
            [centerY_um-sizeY_um/2,centerY_um+sizeY_um/2],...
            plottedImage);
    end
    title(['(',num2str(1),',',num2str(kChan),') ',sd1.chanLabelsArray{pulseChanCounter}]);
     pulseChanCounter = pulseChanCounter+1;
    %extraImages{2,kChan} = abs(chanImages{2,5}-chanImages{2,4})./abs(chanImages{2,3}-chanImages{2,2});
    %sd1.extraImages{2,kChan} = 100*sd1.chanImages{2,kChan}./sd1.chanImages{2,1};
    %extraImages{1,kChan} = (chanImages{2,5}-chanImages{2,4});
    plottedImage = imresize(sd1.extraImages{2,kChan},fac);
    
    subplot(2,ncc,kChan+ncc);
    if doLimNormTo_01
        clims=[0 1]; 
        imagesc([sd1.centerX_um-sd1.sizeX_um/2,sd1.centerX_um+sd1.sizeX_um/2],...
            [sd1.centerY_um-sd1.sizeY_um/2,sd1.centerY_um+sd1.sizeY_um/2],...
            plottedImage,clims);
    elseif fixColorScale
        clims = [fracLow,fracHigh];
        imagesc([sd1.centerX_um-sd1.sizeX_um/2,sd1.centerX_um+sd1.sizeX_um/2],...
            [sd1.centerY_um-sd1.sizeY_um/2,sd1.centerY_um+sd1.sizeY_um/2],...
            plottedImage, clims);
    else
        imagesc([sd1.centerX_um-sd1.sizeX_um/2,sd1.centerX_um+sd1.sizeX_um/2],...
            [sd1.centerY_um-sd1.sizeY_um/2,sd1.centerY_um+sd1.sizeY_um/2],...
            plottedImage);
    end
    title(['(',num2str(2),',',num2str(kChan),') ',sd1.chanLabelsArray{pulseChanCounter}]);
    pulseChanCounter = pulseChanCounter+1;
end
colorbar;
%global f7214;
%global f7209;
%f7214 = chanImages{1,iChan};
%f7209 = chanImages{1,iChan};

if doLinePlots
    hp = figure;
    ypix = linspace(sd1.centerY_um-sd1.sizeY_um/2,sd1.centerY_um+sd1.sizeY_um/2,sd1.numPointsY*fac);
    plot1 = imresize(sd1.chanImages{1,1}(:,1),fac);
    plot2 = imresize(sd1.chanImages{1,1}(:,2),fac);
    plot3 = imresize(sd1.chanImages{2,1}(:,1),fac);
    plot4 = imresize(sd1.chanImages{2,1}(:,2),fac);
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
    zChanCounter=3; %3=for-unfilter, 4=for-filtered, 5=rev-unfilter, 6=rev-filtered
    
    sd1.zImages{1,1}=reshape(sd1.scanDat(:,zChanCounter),sd1.numPointsY,sd1.numPointsX); 
    sd1.zImages{1,2}=reshape(sd1.scanDat(:,zChanCounter+1),sd1.numPointsY,sd1.numPointsX); 
    sd1.zImages{2,1}=reshape(sd1.scanDat(:,zChanCounter+2),sd1.numPointsY,sd1.numPointsX); 
    sd1.zImages{2,2}=reshape(sd1.scanDat(:,zChanCounter+3),sd1.numPointsY,sd1.numPointsX); 
    %zImages{1,2}(find(~zImages{1,2}))=6.2
    h2 = figure;
    %subplot(1,2,1)
    xpixels=linspace(sd1.centerX_um-sd1.sizeX_um/2,sd1.centerX_um+sd1.sizeX_um/2,sd1.numPointsX);
    ypixels=linspace(sd1.centerY_um-sd1.sizeY_um/2,sd1.centerY_um+sd1.sizeY_um/2,sd1.numPointsY);
    surf(xpixels,ypixels,-sd1.zImages{1,1},'EdgeColor','None');

    h3=figure;
    subplot(1,2,1)
    for kL=1:sd1.numPointsX
        hold on;
        plot(ypixels,-sd1.zImages{1,2}(:,kL));
        %plot3(xpixels(kL)*ones(1,numPointsY),ypixels,-zImages{1,2}(:,kL));
        xlabel('Y scan position [micron]');
    end
    hold off;
    subplot(1,2,2)
    for kL=1:sd1.numPointsY
        hold on;
        plot(xpixels,-sd1.zImages{1,2}(kL,:));
        %plot3(xpixels,ypixels(kL)*ones(1,numPointsX),-zImages{1,2}(kL,:));
        xlabel('X scan position [micron]');
    end
    hold off;
    
    % last in array 'end' is the counter channel for typical topographic
    % scans
    
    sd1.plImages{1,1} = reshape(sd1.scanDat(:,end-1),sd1.numPointsY,sd1.numPointsX); %forward
    sd1.plImages{2,1} = reshape(sd1.scanDat(:,end),sd1.numPointsY,sd1.numPointsX); %reverse
    h4 = figure;
    %subplot(1,2,1)
    surf(xpixels,ypixels,sd1.plImages{1,1},'EdgeColor','None');
    
    % on this plot for drift do the first and last lines
    hFirstLast=figure;
    subplot(1,2,1)
    for kL=[1,length(ypixels)]
        hold on;
        plot(ypixels,-sd1.zImages{1,2}(kL,:));
        %plot3(xpixels(kL)*ones(1,numPointsY),ypixels,-zImages{1,2}(:,kL));
        xlabel('Y scan position [micron]');
        title('Height plots drift over time');
    end
    hold off;
    subplot(1,2,2)
    for kL=[1,length(ypixels)]
        hold on;
        plot(ypixels,sd1.plImages{1,1}(kL,:));
        %plot3(xpixels,ypixels(kL)*ones(1,numPointsX),-zImages{1,2}(kL,:));
        xlabel('Y scan position [micron]');
        title('PL plots drift over time');
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
