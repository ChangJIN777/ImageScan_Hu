function scan_ps_pillar_z( )
%scan_ps_pillar_z scanning pulse sequence at a range of Z heights
%   

global Img_handles;
global esr_handles;

global laser_x_handle;
global laser_y_handle;
 global is_center;
 is_center = 0;
%Generate a list of points to measure

z_size_nm = 0.01; %Dimensions of scan in nm, POSITIVE VALUED
if z_size_nm<0
    z_size_nm=-z_size_nm; % safety
end
z_min_nm = 20;
z_max_nm = z_min_nm+z_size_nm;
nz = 40; %Number of points along z axis
setptFrac = 0.9; % fraction of the free R that the setpoint should be
Pgain = -0.3; % V/Vrms
% do a slow approach with low Igain and then increase it
IgainApproach = -15; %V/Vrms/s
IgainEngaged = -25; % 
currentDefaultOut = 0.000; % V, NOTE THAT here 1 V is 1 micron, not 10.
outCenter = 0.5; %V, 500 mV
outRange = 5; % 5V = 5 microns on [center-range,center+range]
errTol = 0.001; % 0.1 mV is the error tolerance to first know when in contact
errCurrent = 1; % just set to some large value
outTotal = 0; % current PID output
outShift = 0; % current PID shift

% for x,y, scans the range is [-x_size/2,x_size/2]
% however, for z scans you start at the surface so [0, z_size]

zpts_nm = linspace(z_min_nm,z_max_nm,nz);
zpts_V = zpts_nm*0.001; % 300 nm on zpts means 0.3 V PId output 
numTauPoints = 21; % same as in ESR GUI
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
for k=1:nz
    if (bTipTrackXY)
            % ...
    else
        % don't track tip-NV/pillar separation in XY
        % assumed starting conditions
            % 1) the user sets desired tip position for x,y
            % 2) The tip is approached, but Zurich PID0 ("1") is off
            % 3) All pulse sequence settings are set in ESRControl GUI
            
     if (mod(k,galvoTrackPeriod)==0)
        ESR_pulsed_handles.gesr.RunSingleTrackPulsedESR(ESR_pulsed_handles.imageScanHandles);
     end
     
        % first reset the default out back to 0 so that the engage can be
        % smooth and robust if drift occurs
        currentDefaultOut=0;
        ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],currentDefaultOut);
        
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
        
        % start PID0 with gradual engage speed
        ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],1);
        
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
        pause(0.2); % not necessary to pause but could be useful
        
        % once engaged, compute the next desired height
        % this takes into account the preset PID output sample as well as
        % the height value (where surface is defined at zero)
        numSurfAverages = 100;
        outSamples = zeros(1,numSurfAverages);
        for s=1:numSurfAverages
            sampPID =  ziDAQ('get',['/',zdevice,'/PIDS/0/SHIFT']);
            eval(['samp_shift = sampPID.',zdevice,'.pids.shift;']);
            outShift = samp_shift;
            outSamples(s) = outCenter + outShift;
        end
        outTotal = mean(outSamples);
        
        % so outTotal is now the voltage value (where 1 V=1 micron) of the
        % PID output going to MCL. for example
        % outTotal = 0.5 + 0.031  corresponds to MCL raised 531 nm
        % so to back off some 60 nm requires default out to be changed from
        % 0 to 531 - 60
        currentDefaultOut = outTotal-zpts_V(k);
        
        % set this default out and turn off the feedback
        ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],currentDefaultOut);
        ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],0);
        
        % start the pulse sequence at this set height
        ['pulse sequence ', num2str(k), ' started']
        ESRControl('buttonStartSequence_Callback',0,0,esr_handles); %Start current ESR sequence
        
        % extract the pulse sequence data at this height
        path1 = get(esr_handles.esrSavePath,'String');
        path2 = get(esr_handles.esrSaveFilePrefix,'String');
        path3 = get(esr_handles.esrSaveFileNum,'String');
        if (k==1)
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
        zs = zpts_V(k)/10;% convert 1 um/V to 10 um/V for using same plotting script
        zpid = zpts_V(k);
        znmSet = zpts_nm(k);
        znmSurf = outTotal*1000;
        scanSaveArray = [0,0,zs,zpid,znmSet,znmSurf,scanTauPLTriplets];
        %----------------------------------------------
        
        % format: make it the same as *.scan and *.info data for easy analysis
        % .scan format, but make Z stuff redundant here for Zscan
        % X | Y | Zfor | ZforFilt |Zrev |ZrevFilt | tau1 | sig1 | ref1 | tau2 | sig2| ref2 | ....
        scanFilename   = [path1,'\',path2,firstNum,'.scan'];         
        dlmwrite(scanFilename,scanSaveArray,'-append','delimiter','\t');
        
        
        
    end
    
end

% ---------write a .info file----------------
    infoFilename   = [path1,'\',path2,firstNum,'.info'];
    dlmwrite(infoFilename, datestr(date),'-append','delimiter','');
    dlmwrite(infoFilename, 'Size: 0.0 V x 0.0 V','-append','delimiter','');
    dlmwrite(infoFilename, 'Center: (0.0 V, 0.0 V)','-append','delimiter','');
    dlmwrite(infoFilename, ['Resolution: 0 x 0 x ',num2str(nz)],'-append','delimiter','');
    dlmwrite(infoFilename, 'Scan Speed: 0 Hz','-append','delimiter','');
    dlmwrite(infoFilename, 'Rotation: 0 deg','-append','delimiter','');
    dlmwrite(infoFilename, ' ','-append','delimiter','');
    dlmwrite(infoFilename, 'Column Headings:','-append','delimiter','');
    chanPosLabels = 'X / Y / Z - V / Z - PID / Z - set nm / Z - surf nm';
    chanMeasLabels = ' / tau / sig / ref';
    chanMeasLabels = repmat(chanMeasLabels,1,(numTauPoints*numc));
    dlmwrite(infoFilename, [chanPosLabels,chanMeasLabels],'-append','delimiter','');
%------------------------------------------------

% to clean up, set default out = 0 again, and leave in feedback mode to
% protect tip from long term drift if user doesn't take control at end
% immediately
ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],0.000);
ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],1);

end

