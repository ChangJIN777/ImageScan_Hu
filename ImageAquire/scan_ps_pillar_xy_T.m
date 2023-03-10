function scan_ps_pillar_xy_T( )
%scan_ps_pillar_xy scanning pulse sequence on 2D xy plane

global Img_handles;
global esr_handles;

global laser_x_handle;
global laser_y_handle;
 global is_center;
 is_center = 0;
%Generate a list of points to measure

x_size_nm = 200; %Dimensions of scan in nm, POSITIVE VALUED
y_size_nm = 1;
if x_size_nm<0
    x_size_nm=-x_size_nm; % safety
end
if y_size_nm<0
    y_size_nm=-y_size_nm; % safety
end
x_size_V = x_size_nm*0.0001;
y_size_V = y_size_nm*0.0001;

nx = 20; %Number of points along x axis
ny = 1; %y axis
xpts_nm = linspace(-x_size_nm/2, x_size_nm/2,nx);
xpts_V = xpts_nm*0.0001; % 10 ?m/V
ypts_nm = linspace(-y_size_nm/2, y_size_nm/2,ny);
ypts_V = ypts_nm*0.0001; % 10 ?m/V
current_xy = [0,0];
safeLiftZ_V = 1.0; % in Volts where 1 um = 1 Volt

setptFrac = 0.9; % fraction of the free R that the setpoint should be
Pgain = -0.3; % V/Vrms
% do a slow approach with low Igain and then increase it
IgainApproach = -20; %V/Vrms/s
IgainEngaged = -25; % 
currentDefaultOut = 0.000; % V, NOTE THAT here 1 V is 1 micron, not 10.
outCenter = 0.5; %V, 500 mV
outRange = 10; % 5V = 5 microns on [center-range,center+range]
errTol = 0.001; % 0.1 mV is the error tolerance to first know when in contact
errCurrent = 1; % just set to some large value
outTotalBefore = 0; % current PID output
outTotalAfter = 0;
outShift = 0; % current PID shift

% for x,y, scans the range is [-x_size/2,x_size/2]
% however, for z scans you start at the surface so [0, z_size]

numTauPoints = 4; % same as in ESR GUI
numc=2;

% how to trat the tau data----------
% for a T1 use:
firstTauCmd = 'divideBy2';
secondTauCmd = 'yMinusFirst';

%-----------------

%Get original image for tracking
global ESR_pulsed_handles;
%ESR_pulsed_handles.PerformImageRegistration(0,1);
bTipTrackXY = false;
galvoTrackPeriod = 2;

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
sampEnable = ziDAQ('get',['/',zdevice,'/PIDS/0/ENABLE']);
eval(['isEnabled = sampEnable.',zdevice,'.pids.enable']);
if (isEnabled)
    'Turn off the HF2LI PID1 (/PIDS/0/ENABLE) before starting a z scan. Start assumption is that the tip is approached within 500 nm, but not engaged. Aborted.'
    return
end
%---------------

firstNum = '';

sweep=0;


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

            % 2) compute the percentage setpoint
            % sample the current free amplitude to compute a setpoint
            sampStart = ziDAQ('get',['/',zdevice,'/DEMODS/0/SAMPLE']);
            eval(['samp_x = sampStart.',zdevice,'.demods.sample.x']);
            eval(['samp_y = sampStart.',zdevice,'.demods.sample.y']);
            R = sqrt(samp_x^2 + samp_y^2);
            Rstpt = R*setptFrac;

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
            pause(0.8);

            % 5) average N times the PID OUTPUT to get surface position
            numSurfAverages = 100;
            outSamples = zeros(1,numSurfAverages);
            for s=1:numSurfAverages
                sampPID =  ziDAQ('get',['/',zdevice,'/PIDS/0/SHIFT']);
                eval(['samp_shift = sampPID.',zdevice,'.pids.shift;']);
                outShift = samp_shift;
                outSamples(s) = outCenter + outShift;
            end
            outTotalBefore = mean(outSamples);
            pause(0.5);
            
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
            ESRControl('buttonStartSequence_Callback',0,0,esr_handles); %Start current ESR sequence
            
            pause(0.5);
            % 7) compute a new default out from drifted surface position
            numSurfAverages = 100;
            outSamples = zeros(1,numSurfAverages);
            for s=1:numSurfAverages
                sampPID =  ziDAQ('get',['/',zdevice,'/PIDS/0/SHIFT']);
                eval(['samp_shift = sampPID.',zdevice,'.pids.shift;']);
                outShift = samp_shift;
                outSamples(s) = outCenter + outShift;
            end
            outTotalAfter = mean(outSamples);
            
            %8) Get a new default out to lift before going to next point
            %and feedback turned off
            currentDefaultOut = outTotalAfter-safeLiftZ_V;
        
            ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],currentDefaultOut);
            ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],0);

            % 9) retrieve data from pulse sequence into 00xxxx.scan
            path1 = get(esr_handles.esrSavePath,'String');
            path2 = get(esr_handles.esrSaveFilePrefix,'String');
            path3 = get(esr_handles.esrSaveFileNum,'String');
            if (i==1 && j==1)
               firstNum = path3; 
            end
            % for every signal channel of the sequence, there is 1 file to read in
            % containing a sig and ref.
            % '_a_b.txt' where a=1,2 for channel and b=0,1,2... for tau points
            pathPrefix = [path1 path2 path3 '\' path2 path3]; 
            filepath1 = [pathPrefix '_1_',num2str(sweep),'.txt'];
            filepath2 = [pathPrefix '_2_',num2str(sweep),'.txt'];
            d1 = importdata(filepath1);
            d2 = importdata(filepath2);
            celld = {d1,d2};
            signalArray = zeros(numc,numTauPoints*3);
            for c=1:numc 
                for nt=1:numTauPoints
                    signalArray(c,3*nt-2) = celld{c}.data(nt,1); % gets 2 tau
                    signalArray(c,3*nt-1) = celld{c}.data(nt,2); % gets signal
                    signalArray(c,3*nt) = celld{c}.data(nt,3);  % gets reference
                end
            end
            % how to handle 2tau data, which is column index 1,4,7,10,...
            switch(firstTauCmd)
                case 'divideBy2'
                    % for getting tau
                    signalArray(1,1:3:end) = signalArray(1,1:3:end)./2; % get tau
            end
            switch(secondTauCmd)
                case 'yMinusFirst'
                    % for getting y-tau,or y-2tau, etc...
                    tauEndVal = str2double(get(esr_handles.tauEnd,'String'));
                    signalArray(2,1:3:end) = tauEndVal - signalArray(1,1:3:end); % get tau
            end

            % put all data for single Z point into a matrix with 1 row
            % transpose first to take all of row 1, then all row 2, ...
            scanTauPLTriplets = reshape(signalArray',1,numTauPoints*3*numc);
            % concatenate the x,y,z,z,z,z data into this array
            zs = 0;% convert 1 um/V to 10 um/V for using same plotting script
            zpid = 0;
            znmSurf1 = outTotalBefore*1000;
            znmSurf2 = outTotalAfter*1000;
            scanSaveArray = [xpts_V(i),ypts_V(j),zs,zpid,znmSurf1,znmSurf2,scanTauPLTriplets,tempA,tempB];
            %----------------------------------------------

            % format: make it the same as *.scan and *.info data for easy analysis
            % .scan format, but make Z stuff redundant here for Zscan
            % X | Y | Zfor | ZforFilt |Zrev |ZrevFilt | tau1 | sig1 | ref1 | tau2 | sig2| ref2 | ....
            scanFilename   = [path1,'\',path2,firstNum,'.scan'];         
            dlmwrite(scanFilename,scanSaveArray,'-append','delimiter','\t');
            
            
            if (i==1 && j==1)
                 % ---------write a .info file first----------------
                infoFilename   = [path1,'\',path2,firstNum,'.info'];
                dlmwrite(infoFilename, datestr(date),'-append','delimiter','');
                dlmwrite(infoFilename, ['Size: ',num2str(x_size_V),' V x ',num2str(y_size_V),' V'],'-append','delimiter','');
                dlmwrite(infoFilename, 'Center: (0.0 V, 0.0 V)','-append','delimiter','');
                dlmwrite(infoFilename, ['Resolution: ',num2str(nx),' x ',num2str(ny),' x ',num2str(0)],'-append','delimiter','');
                dlmwrite(infoFilename, 'Scan Speed: 0 Hz','-append','delimiter','');
                dlmwrite(infoFilename, 'Rotation: 0 deg','-append','delimiter','');
                dlmwrite(infoFilename, ' ','-append','delimiter','');
                dlmwrite(infoFilename, 'Column Headings:','-append','delimiter','');
                chanPosLabels = 'X / Y / Z - V / Z - PID / Z - surf1 nm / Z - surf2 nm';
                chanMeasLabels = ' / tau / sig / ref';
                chanTempLabels = ' / tempA / tempB';
                chanMeasLabels = repmat(chanMeasLabels,1,(numTauPoints*numc));
                dlmwrite(infoFilename, [chanPosLabels,chanMeasLabels,chanTempLabels],'-append','delimiter','');
                %------------------------------------------------ 
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



