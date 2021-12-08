function scan_ps_pillar_z_range_cwesr_T( )
%scan_ps_pillar_z scanning pulse sequence at a range of Z heights
%   Added temperature sensing output on 08/13/15

global Img_handles;
global esr_handles;

global laser_x_handle;
global laser_y_handle;
 global is_center;
 is_center = 0;
%Generate a list of points to measure

z_size_nm = 200; %Dimensions of scan in nm, POSITIVE VALUED
if z_size_nm<0
    z_size_nm=-z_size_nm; % safety
end
z_min_nm = 5;
z_max_nm = z_min_nm+z_size_nm;
nz = 50; %Number of times to visit each height point
setptFrac = 0.94; % fraction of the free R that the setpoint should be
Pgain = -0.5; % V/Vrms
% do a slow approach with low Igain and then increase it
IgainApproach = -30; %V/Vrms/s
IgainEngaged = -25; % 
currentDefaultOut = 0.000; % V, NOTE THAT here 1 V is 1 micron, not 10.
outCenter = 0.5; %V, 500 mV
outRange = 10; % 5V = 5 microns on [center-range,center+range]
errTol = 0.001; % 0.1 mV is the error tolerance to first know when in contact
errCurrent = 1; % just set to some large value
outTotal = 0; % current PID output
outShift = 0; % current PID shift

% for x,y, scans the range is [-x_size/2,x_size/2]
% however, for z scans you start at the surface so [0, z_size]

% each height in nm to visit
zrange_nm = linspace(z_min_nm,z_max_nm,nz)%[0,100,200,300,400,500,800,1000,1500]; %[6,10,20,30,40,50,75,100,125,150,200,300];
yrange_ns = [2000010,2000010];%[500,600,600,600,600,600,600,700,700,800,800,800]*10^3;%[500,500,600,600,700,700,800,800,1000,1000,1000,1200]*10^3;
numzRange = length(zrange_nm);
numyRange = length(yrange_ns);
ycounter = 1;
if (numyRange~=numzRange)
   'Aborted z scan. The length of zrange must match length of end Tau time range' 
end
numFreqPoints = 300;

% make a list of the z values concatenated nz number of times
zpts_nm = zrange_nm;%repmat(zrange_nm,1,nz); %linspace(z_min_nm,z_max_nm,nz);
ypts_ns = repmat(yrange_ns,1,nz);
nz_all = length(zpts_nm);
zpts_V = zpts_nm*0.001; % 300 nm on zpts means 0.3 V PId output 
numTauPoints = 11; % same as in ESR GUI
numc=1;

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
sampEnable = ziDAQ('get',['/',zdevice,'/PIDS/0/ENABLE']);
eval(['isEnabled = sampEnable.',zdevice,'.pids.enable']);
if (isEnabled)
    'Turn off the HF2LI PID1 (/PIDS/0/ENABLE) before starting a z scan. Start assumption is that the tip is approached within 500 nm, but not engaged. Aborted.'
    return
end
%---------------

firstNum = '';

sweep=0;
for k=1:nz_all
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
        %currentDefaultOut=0; % commented out 10/05/15, not necessary
        ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],currentDefaultOut);
        
        % sample the current free amplitude to compute a setpoint
        sampStart = ziDAQ('get',['/',zdevice,'/DEMODS/0/SAMPLE']);
        eval(['samp_x = sampStart.',zdevice,'.demods.sample.x']);
        eval(['samp_y = sampStart.',zdevice,'.demods.sample.y']);
        R = sqrt(samp_x^2 + samp_y^2);
        if k ==1
            Rstpt = R*setptFrac;
        end
        
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
        % for the case that the new Z height is a 0 value, take this
        % to mean that it is to be in feedback mode, do not disable
        ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],currentDefaultOut);
        
        if zpts_nm(k) > 1
            ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],0);
        else
            % do not disable PID if the Z value is too small!! use feedback
            % but since this default out value won't be used set it higher
            % for safety in case the pid enable stops
            currentDefaultOut = outTotal-zpts_V(k)-0.01;
        end
        
        % record the temperature at this same time as surface reading
       % fprintf(lake,'KRDG?A');
        %response = fscanf(lake);
        %tempA = str2double(response);
       % fprintf(lake,'KRDG?B');
       % response = fscanf(lake);
       % tempB = str2double(response);
       tempA=0;
       tempB=0;
        
       set(esr_handles.writeDataFreq,'UserData',1);
       set(esr_handles.numFreqSteps,'String',num2str(numFreqPoints));
        % start the pulse sequence at this set height
        % first set the correct end tau value from list
        ['cwesr sequence ', num2str(k), ' started']
        %set(esr_handles.tauEnd,'String',num2str(ypts_ns(ycounter)));
        ycounter = ycounter+1;
        ESRControl('buttonStartCWESR_Callback',0,0,esr_handles); %Start current ESR sequence
        
        % be sure this is not skipped
        while ( get(esr_handles.writeDataFreq,'UserData') == 1)
                    'while loop for not skipping esrcontrol'
            pause(1); 
        end
        'ended past ESRControl and while loop enable'
        
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
        pathPrefix = [path1 path2 path3 '\' path2 path3]
        filepath1 = [pathPrefix ,'_1.txt'];
        d1 = importdata(filepath1);
        celld = {d1};
        signalArray = zeros(numc,numFreqPoints*2);
        for c=1:numc 
            for nf=1:numFreqPoints
                signalArray(c,2*nf-1) = celld{c}.data(nf,1); % gets frequency value
                signalArray(c,2*nf) = celld{c}.data(nf,2); % gets current count rate
            end
        end
        
        % put all data for single Z point into a matrix with 1 row
        % transpose first to take all of row 1, then all row 2, ...
        scanTauPLTuples = reshape(signalArray',1,numFreqPoints*2*numc);
        % concatenate the x,y,z,z,z,z data into this array
        zs = zpts_V(k)/10;% convert 1 um/V to 10 um/V for using same plotting script
        zpid = zpts_V(k);
        znmSet = zpts_nm(k);
        znmSurf = outTotal*1000;
        scanSaveArray = [0,0,zs,zpid,znmSet,znmSurf,scanTauPLTuples,tempA,tempB];
        %----------------------------------------------
        
        % format: make it the same as *.scan and *.info data for easy analysis
        % .scan format, but make Z stuff redundant here for Zscan
        % X | Y | Zfor | ZforFilt |Zrev |ZrevFilt | tau1 | sig1 | ref1 | tau2 | sig2| ref2 | ....
        scanFilename   = [path1,'\',path2,firstNum,'.scan'];         
        dlmwrite(scanFilename,scanSaveArray,'-append','delimiter','\t');
        
        % write the .info file on the first cycle
        if (k==1)
            % ---------write a .info file----------------
            infoFilename   = [path1,'\',path2,firstNum,'.info'];
            dlmwrite(infoFilename, datestr(date),'-append','delimiter','');
            dlmwrite(infoFilename, 'Size: 0.0 V x 0.0 V','-append','delimiter','');
            dlmwrite(infoFilename, 'Center: (0.0 V, 0.0 V)','-append','delimiter','');
            dlmwrite(infoFilename, ['Resolution: 0 x 0 x ',num2str(nz_all)],'-append','delimiter','');
            dlmwrite(infoFilename, 'Scan Speed: 0 Hz','-append','delimiter','');
            dlmwrite(infoFilename, 'Rotation: 0 deg','-append','delimiter','');
            dlmwrite(infoFilename, ' ','-append','delimiter','');
            dlmwrite(infoFilename, 'Column Headings:','-append','delimiter','');
            chanPosLabels = 'X / Y / Z - V / Z - PID / Z - set nm / Z - surf nm';
            chanMeasLabels = ' / freq / sig';
            chanTempLabels = ' / tempA / tempB';
            chanMeasLabels = repmat(chanMeasLabels,1,(numFreqPoints*numc));
            dlmwrite(infoFilename, [chanPosLabels,chanMeasLabels,chanTempLabels],'-append','delimiter','');
            %------------------------------------------------
        end
    end
    
end



% to clean up, set default out = 0 again, and leave in feedback mode to
% protect tip from long term drift if user doesn't take control at end
% immediately
ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],0.000);
ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],1);

%cleanup lakeshore 331
%fclose(lake);
%delete(lake)

end

