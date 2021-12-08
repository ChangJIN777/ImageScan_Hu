function scan_ps_pillar_xy_z_cwesr_T_Fast( )
%scan_ps_pillar_xy scanning pulse sequence on 2D xy plane
% on 10/09/15 added for loop to do a z scan
% mostly to do feedback then lift height comparison at each x,y point

global Img_handles;
global esr_handles;

global laser_x_handle;
global laser_y_handle;
 global is_center;
 is_center = 0;
%Generate a list of points to measure

x_size_nm = 300; %Dimensions of scan in nm, POSITIVE VALUED
y_size_nm = 200;
if x_size_nm<0
    x_size_nm=-x_size_nm; % safety
end
if y_size_nm<0
    y_size_nm=-y_size_nm; % safety
end
x_size_V = x_size_nm*0.0001;
y_size_V = y_size_nm*0.0001;

% bCheckPID
bCheckPID=0; % don't need to do this check if you're careful. see below

nx = 50; %Number of points along x axis
ny = 50; %y axis
nz=1;
xpts_nm = linspace(-x_size_nm/2, x_size_nm/2,nx);
xpts_V = xpts_nm*0.0001; % 10 µm/V
ypts_nm = linspace(-y_size_nm/2, y_size_nm/2,ny);
ypts_V = ypts_nm*0.0001; % 10 µm/V
current_xy = [0,0];
safeLiftZ_endPixel_V = 0.05; % in Volts where 1 um = 1 Volt
safeLiftZ_endLine_V = 0.05; % in Volts where 1 um = 1 Volt

% each height in nm to visit
% DON"T MAKE z=0 THE LAST POINT IN THE ARRAY OR IT WILL MOVE XY IN FEEDBACK
% WE CAN EASILY CHANGE THIS BY TURNING OFF PID AFTER MEASUREMENT BUT THAT
% JUST TAKES MORE TIME AWAY FROM EMASURING
zrange_nm = [0];%linspace(2,1000,nz);%[0];%linspace(5,200,nz);%[5,10,20,30,40,50,75,100,200]; %[6,10,20,30,40,50,75,100,125,150,200,300];
yrange_ns = [200010,200010];%[500,600,600,600,600,600,600,700,700,800,800,800]*10^3;%[500,500,600,600,700,700,800,800,1000,1000,1000,1200]*10^3;
numzRange = length(zrange_nm);
numyRange = length(yrange_ns);
ycounter = 1;
if (numyRange~=numzRange)
   'Aborted z scan. The length of zrange must match length of end Tau time range' 
end
% make a list of the z values concatenated nz number of times
zpts_nm = zrange_nm;%repmat(zrange_nm,1,nz); %linspace(z_min_nm,z_max_nm,nz);
nz = length(zpts_nm);
ypts_ns = repmat(yrange_ns,1,nz);
nz_all = length(zpts_nm); % don't use nz_all for xyz scan, only z scan
zpts_V = zpts_nm*0.001; % 300 nm on zpts means 0.3 V PId output 

setptFrac = 0.92; % fraction of the free R that the setpoint should be
Pgain = -0.3; % V/Vrms
% do a slow approach with low Igain and then increase it
IgainApproach = -45; %V/Vrms/s
IgainEngaged = -45; % 
currentDefaultOut = 0.000; % V, NOTE THAT here 1 V is 1 micron, not 10.
outCenter = 0.5; %V, 500 mV
outRange = 10; % 5V = 5 microns on [center-range,center+range]
errTol = 0.001; % 0.1 mV is the error tolerance to first know when in contact
errCurrent = 1; % just set to some large value
outTotalBefore = 0; % current PID output
outTotalAfter = 0;
outTotal = 0;
outShift = 0; % current PID shift
outTotal_runningMean = 0;
outTotal_previous = 0;
outTotal_tolerance = 0.1; % don't be off more than 50 nm (0.1V Zurich) before starting engage (may be false engage)
outTotal_changeSpeed = 0.005; % 5 nanometers in say 1 second

% for x,y, scans the range is [-x_size/2,x_size/2]
% however, for z scans you start at the surface so [0, z_size]

numTauPoints = 4; % same as in ESR GUI
numc=1;
numFreqPoints = 20;

% how to trat the tau data----------
% for a T1 use:
firstTauCmd = 'divideBy2';
secondTauCmd = 'yMinusFirst';

%-----------------

%Get original image for tracking
global ESR_pulsed_handles;
%ESR_pulsed_handles.PerformImageRegistration(0,1);
bTipTrackXY = false;
galvoTrackPeriod = 5;

%-------temperature readout setup-------
%lake = gpib('ni',0,12);
%fopen(lake);

%---------------------------------------

%------ziDAQ setup------------
clear ziDAQ
ziDAQ('connect', 'localhost', 8005);
% get device name (e.g. 'dev236')
zdevice = ziAutoDetect();
%-------------------------------

% first make sure the PID is disabled other wise quit measurement
if bCheckPID==1
    sampEnable = ziDAQ('get',['/',zdevice,'/PIDS/0/ENABLE']);
    eval(['isEnabled = sampEnable.',zdevice,'.pids.enable']);
    if (isEnabled)
        'Turn off the HF2LI PID1 (/PIDS/0/ENABLE) before starting a z scan. Start assumption is that the tip is approached within 500 nm, but not engaged. Aborted.'
        return
    end
end
%---------------

firstNum = '';

sweep=0;

ijkCounterFirst=true;
set(esr_handles.writeDataFreq,'UserData',0); % default value
for j=1:ny
    for i=1:nx
        
        if (bTipTrackXY)
                % this will be the same procedure as for the false case
                % except when I lift up to safe height I don't go to the
                % next XY point, rather I move to the 0,0 center point and
                % do a scan_line_smooth line scan to check the drift. then
                % do an algorithm to compare the scan line.
        else
            % don't track tip-NV/pillar separation in XY
            % assumed starting conditions
                % 1) user sets tip position to desired center of scan
                % window. All x,y points will be relative to this because
                % they are negative
                %2) scan size/2 must not be larger than the tip position in
                %the Figure3 AFM gui.
                %3) feedback is turned off and tip is at least 500 nm up.
                %4) the XY center position should typically be on a pillar
                %such that moving in XY 500 nm up has no chance of damage.
                
            % procedure:
                % 0) optical NV tracking
                % 1) move tip from current position to the next X,Y point
                % 2) compute the percentage setpoint
                % 3) turn on feedback
                % 4) wait until feedback settles
                % 5) average N times the PID OUTPUT to get surface position
                % 6) Start the Pulse Sequence
                % 7) compute a new default out from drifted surface position
                %8) Get a new default out to lift before going to next point
                % and feedback turned off
                % 9) retrieve data from pulse sequence into 00xxxx.scan
                % file
                % repeat from steps 2-9
                
            % 0) optical NV tracking
            if (mod(i,galvoTrackPeriod)==0)
                ESR_pulsed_handles.gesr.RunSingleTrackPulsedESR(ESR_pulsed_handles.imageScanHandles);
            end
            
            % 1) move tip from 0,0 position to the first X,Y point, laser
            % doesn't matter. Function takes nanometer relative inputs
            dx = xpts_nm(i) - current_xy(1);
            dy = ypts_nm(j) - current_xy(2);
            mDAC('move_tip_laser',dx,dy,0,0);
            current_xy = [xpts_nm(i),ypts_nm(j)];
            pause(5) ;
            
            % 2) compute the percentage setpoint
            % sample the current free amplitude to compute a setpoint
            sampStart = ziDAQ('get',['/',zdevice,'/DEMODS/0/SAMPLE']);
            eval(['samp_x = sampStart.',zdevice,'.demods.sample.x']);
            eval(['samp_y = sampStart.',zdevice,'.demods.sample.y']);
            R = sqrt(samp_x^2 + samp_y^2);
            Rstpt = R*setptFrac;
            
            % in this "FAST" version only engage once per X,Y point not for
            % every Z point, since for CWESR we assume it is fast enough
            % that we don't have to go back and check the surface until
            % going to a new X,Y point
            
            % set this setpoint and other parameters in the Zurich
            ziDAQ('setDouble',['/',zdevice,'/PIDS/0/SETPOINT'],Rstpt);
            ziDAQ('setDouble',['/',zdevice,'/PIDS/0/P'],Pgain);
            ziDAQ('setDouble',['/',zdevice,'/PIDS/0/I'],IgainApproach);
            ziDAQ('setDouble',['/',zdevice,'/PIDS/0/D'],0.000);
            ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],currentDefaultOut);
            ziDAQ('setInt',['/',zdevice,'/PIDS/0/OUTPUTDEFAULTENABLE'],1);
            ziDAQ('setDouble',['/',zdevice,'/PIDS/0/CENTER'],outCenter);
            ziDAQ('setDouble',['/',zdevice,'/PIDS/0/RANGE'],outRange);

            % 3) turn on feedback
            % start PID0 with gradual engage speed
            ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],1);
            'enable PID 1'

            % 4) wait until feedback settles
            % get PID error signal and loop until it is small (engaged)
            sampPID = ziDAQ('get',['/',zdevice,'/PIDS/0/ERROR']);
            eval(['samp_err = sampPID.',zdevice,'.pids.error;']);
            errCurrent = samp_err;
            % usually error < 0 because setpoint is lower, but once engaged
            % sometimes it will become positive, so this is when to stop
            while(errCurrent < 0)
                sampPID = ziDAQ('get',['/',zdevice,'/PIDS/0/ERROR']);
                eval(['samp_err = sampPID.',zdevice,'.pids.error;']);
                errCurrent = samp_err;
            end
            pause(2.0);
            'sampled error until broke while loop 1'

            % do it again to be sure it is really engaged!
            % added on 11/04/15
            sampPID = ziDAQ('get',['/',zdevice,'/PIDS/0/ERROR']);
            eval(['samp_err = sampPID.',zdevice,'.pids.error;']);
            errCurrent = samp_err;
            while(errCurrent < 0)
                sampPID = ziDAQ('get',['/',zdevice,'/PIDS/0/ERROR']);
                eval(['samp_err = sampPID.',zdevice,'.pids.error;']);
                errCurrent = samp_err;
            end
            pause(0.8);
            'sampled error until broke while loop 2'

            %--------------get surface position--------------
            numSurfAverages = 100;
            outSamples = zeros(1,numSurfAverages);
            for s=1:numSurfAverages
                sampPID =  ziDAQ('get',['/',zdevice,'/PIDS/0/SHIFT']);
                eval(['samp_shift = sampPID.',zdevice,'.pids.shift;']);
                outShift = samp_shift;
                outSamples(s) = outCenter + outShift;
            end
            outTotal = mean(outSamples);
            pause(0.5);
            'averaged to find the surface'

            
            skipSpeedCheck=0;
            if skipSpeedCheck==0
                % as a last defense against early engage flag make sure
                % the presetn DAC output value makes sense based on
                % previous ones
                outTotal_previous = outTotal;
                outTotal = -100;
                while(abs(outTotal-outTotal_previous)>outTotal_changeSpeed)
                    %'entered while loop for changeSpeed engage check'
                    outTotal_previous=outTotal;
                    for s=1:numSurfAverages
                        sampPID =  ziDAQ('get',['/',zdevice,'/PIDS/0/SHIFT']);
                        eval(['samp_shift = sampPID.',zdevice,'.pids.shift;']);
                        outShift = samp_shift;
                        outSamples(s) = outCenter + outShift;
                    end
                    outTotal = mean(outSamples);
                    pause(1.0);
                end
                'finished condition of averaging at surface'
            end

            % once qualified, allow it
            %outTotal_previous = outTotal;
           % outTotal_runningMean = (outTotal_runningMean+outTotal)/2;
           %--------------------------------------------------------
            % for ehatever reason outTotal didn't change from huge
            % initialization value of -100 make sure it is not large
            % when it is accidentally used physically. This would only
            % happen if the above while loop somehow didn't execute
            if outTotal<=-100
               outTotal=0.1; 
            end


            %8) Get a lift height to the first z point
            %and feedback turned off
            kFirst =1;
            currentDefaultOut = outTotal-zpts_V(kFirst);
            ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],currentDefaultOut);
            if zpts_nm(kFirst) > 1
                ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],0);
                'disabled PID'
            else
                % do not disable PID if the Z value is too small!! use feedback
                % but since this default out value won't be used set it higher
                % for safety in case the pid enable stops
                currentDefaultOut = outTotal-zpts_V(kFirst)-0.01;
                'dont disable PID for in contact'
            end 
            
            for k=1:nz   

                % for this FAST version we must retract the tip by a
                % relative amount between current position and new
                % position, but not for k==1 since that is done just before
                % the for loop
                % also "disable PID" in any case because it doesn't hurt in
                % case the first Z point is a PID on one
                if k>1
                    outRelative = zpts_V(k)-zpts_V(k-1); % should always be positive
                    currentDefaultOut = currentDefaultOut-outRelative; % such that here tip retracts
                    ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],currentDefaultOut);
                end

                % record the temperature at this same time as surface reading
                %fprintf(lake,'KRDG?A');
                %response = fscanf(lake);
                %tempA = str2double(response);
                %fprintf(lake,'KRDG?B');
                %response = fscanf(lake);
                %tempB = str2double(response);
                tempA=0;
                tempB=0;

                % 6) Start the Pulse Sequence
                'about to start sequence'
                % add some dummy variable that is switched true here and
                % switched false only if pulsed sweep is done.
                % just some free UserData variable on gui..
                set(esr_handles.writeDataFreq,'UserData',1);
                
                %ESRControl('buttonStartSequence_Callback',0,0,esr_handles); %Start current ESR sequence
                ESRControl('buttonStartCWESR_Callback',0,0,esr_handles); %Start current ESR sequence
                'passed start sequence'
                
                % make sure it doesn't skip through this before finished:
                % it will only be set back to 0 by the ESRpulseSweep being
                % completed.
                %while ( strcmp(get(esr_handles.buttonStartSequence,'Enable'),'off')==1)
                while ( get(esr_handles.writeDataFreq,'UserData') == 1)
                    'while loop for not skipping esrcontrol'
                   pause(1); 
                end
                'ended past ESRControl and while loop enable'

                % 7) compute a new default out from drifted surface position
%                 numSurfAverages = 100;
%                 outSamples = zeros(1,numSurfAverages);
%                 for s=1:numSurfAverages
%                     sampPID =  ziDAQ('get',['/',zdevice,'/PIDS/0/SHIFT']);
%                     eval(['samp_shift = sampPID.',zdevice,'.pids.shift;']);
%                     outShift = samp_shift;
%                     outSamples(s) = outCenter + outShift;
%                 end
%                 outTotalAfter = mean(outSamples);
                
%               only do this safe lift after LAST z point, don't need to
%               waste time between Z points at same x,y
                if (k==nz)
                    % before going to the next point:
                    % if the pid is off. Lift up even more
                    % if pid is on DON'T MAKE PID ON THE LASER Z POINT GO FROM 
                    
                    if (i==nx) % end of line
                        % not end of line, just a pixel
                        currentDefaultOut = currentDefaultOut-safeLiftZ_endLine_V;   
                    else
                        % not end of line as i<nx, just a pixel
                        currentDefaultOut = currentDefaultOut-safeLiftZ_endPixel_V;
                    end
                    ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],currentDefaultOut);
                    ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],0);
                end

                % 9) retrieve data from pulse sequence into 00xxxx.scan
                path1 = get(esr_handles.esrSavePath,'String');
                path2 = get(esr_handles.esrSaveFilePrefix,'String');
                path3 = get(esr_handles.esrSaveFileNum,'String');
                if (i==1 && j==1 && k==1)
                   firstNum = path3; 
                end
                % for every signal channel of the sequence, there is 1 file to read in
                % containing a sig and ref.
                % '_a_b.txt' where a=1,2 for channel and b=0,1,2... for tau points
                pathPrefix = [path1 path2 path3 '\' path2 path3]; 
                filepath1 = [pathPrefix ,'_1.txt'];
                %filepath2 = [pathPrefix '_2_','.txt'];
                d1 = importdata(filepath1);
                %d2 = importdata(filepath2);
                celld = {d1};
                signalArray = zeros(numc,numFreqPoints*2);
                for c=1:numc 
                    for nf=1:numFreqPoints
                        signalArray(c,2*nf-1) = celld{c}.data(nf,1); % gets frequency value
                        signalArray(c,2*nf) = celld{c}.data(nf,2); % gets current count rate
                    end
                end
                % how to handle 2tau data, which is column index 1,4,7,10,...

                % put all data for single Z point into a matrix with 1 row
                % transpose first to take all of row 1, then all row 2, ...
                scanTauPLTuples = reshape(signalArray',1,numFreqPoints*2*numc);
                % concatenate the x,y,z,z,z,z data into this array
                 zs = zpts_V(k)/10;% convert 1 um/V to 10 um/V for using same plotting script
                 zpid = zpts_V(k);
                 znmSet = zpts_nm(k);
                 znmSurf = outTotal*1000;
                scanSaveArray = [xpts_V(i),ypts_V(j),zs,zpid,znmSet,znmSurf,scanTauPLTuples,tempA,tempB];
                %----------------------------------------------

                % format: make it the same as *.scan and *.info data for easy analysis
                % .scan format, but make Z stuff redundant here for Zscan
                % X | Y | Zfor | ZforFilt |Zrev |ZrevFilt | tau1 | sig1 | ref1 | tau2 | sig2| ref2 | ....
                scanFilename   = [path1,'\',path2,firstNum,'.scan'];         
                dlmwrite(scanFilename,scanSaveArray,'-append','delimiter','\t');


                if (i==1 && j==1 && k==1)
                     % ---------write a .info file first----------------
                    infoFilename   = [path1,'\',path2,firstNum,'.info'];
                    dlmwrite(infoFilename, datestr(date),'-append','delimiter','');
                    dlmwrite(infoFilename, ['Size: ',num2str(x_size_V),' V x ',num2str(y_size_V),' V'],'-append','delimiter','');
                    dlmwrite(infoFilename, 'Center: (0.0 V, 0.0 V)','-append','delimiter','');
                    dlmwrite(infoFilename, ['Resolution: ',num2str(nx),' x ',num2str(ny),' x ',num2str(nz)],'-append','delimiter','');
                    dlmwrite(infoFilename, 'Scan Speed: 0 Hz','-append','delimiter','');
                    dlmwrite(infoFilename, 'Rotation: 0 deg','-append','delimiter','');
                    dlmwrite(infoFilename, ' ','-append','delimiter','');
                    dlmwrite(infoFilename, 'Column Headings:','-append','delimiter','');
                    chanPosLabels = 'X / Y / Z - V / Z - PID / Z - surf1 nm / Z - surf2 nm';
                    chanMeasLabels = ' / freq / sig';
                    chanTempLabels = ' / tempA / tempB';
                    chanMeasLabels = repmat(chanMeasLabels,1,(numFreqPoints*numc));
                    dlmwrite(infoFilename, [chanPosLabels,chanMeasLabels,chanTempLabels],'-append','delimiter','');
                    %------------------------------------------------ 
                end
            end
        end
    end
end

% a the end the high default out is again set and I want to bring the tip
% back to the original position
ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],currentDefaultOut);
ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],0);
dx = 0 - current_xy(1);
dy = 0 - current_xy(2);
mDAC('move_tip_laser',dx,dy,0,0);

% to clean up, set default out = 0 again, and leave in feedback mode to
% protect tip from long term drift if user doesn't take control at end
% immediately
%ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],0.000);
%ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],1);

end




