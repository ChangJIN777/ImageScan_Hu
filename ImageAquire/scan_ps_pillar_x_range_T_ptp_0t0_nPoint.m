function scan_ps_pillar_x_range_T_ptp_0t0_nPoint( )
%scan_ps_pillar_x scanning pulse sequence at a range of x values keeping
%contant height above surface


global Img_handles;
global esr_handles;

global laser_x_handle;
global laser_y_handle;
global is_center;
is_center = 0;


%Generate a list of points to measure


nz = 20; %Number of times to visit each height point
ny = 1;
x_pnts = linspace(-200,200,41);   %x points in nm wrt current tip pos, in nm.

nx = length(x_pnts);

working_z = 10 ; % 10nm from surface to measure T1 curves 

%yrange_ns_omega = [4000,4000,4000,4000,4000,4000,4000,4000,4000,4000,4000,4000,4000,4000,4000,4000,4000,4000,4000,4000,4000]*10^3+500;
yrange_ns_omega = ones(1,41)*(4000e3+1000);

numyRange = length(yrange_ns_omega);
ycounter = 1;
if (numyRange~=nx)
   'Aborted x scan. The length of xrange must match length of end Tau time range' 
end

% make a list of the x values concatenated nz number of times
xpts_nm = repmat(x_pnts,1,nz); 
ypts_ns_omega = repmat(yrange_ns_omega,1,nz);

nx_all = length(xpts_nm);

% PID parameters

forceSetpt = 27.3e-3 ; %27.3mV set point
setptFrac = 0.92; % fraction of the free R that the setpoint should be
Pgain = 0.3; % V/Vrms
% do a slow approach with low Igain and then increase it
IgainApproach = 35; %V/Vrms/s
IgainEngaged = 25; % 
currentDefaultOut = 10.000; % V, NOTE THAT here 1 V is 1 micron, not 10.
outCenter = 0.0; %V, 500 mV
outRange = 10; % 5V = 5 microns on [center-range,center+range]
errTol = 0.001; % 0.1 mV is the error tolerance to first know when in contact
errCurrent = 1; % just set to some large value
outTotal = 0; % current PID output
outShift = 0; % current PID shift
safeLiftZ_endPixel_V = 2*0.8; % 2um safelift
outTotal_changeSpeed = 0.004;  %5nm



numTauPoints = 11; % same as in ESR GUI
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
galvoTrackPeriod = 4;

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
secondNum='';
useNum='';

sweep=0;

current_x_val = 0;

k=0;


numSequences=1;

%set the pulse sequence
set(esr_handles.fileboxPulseSequence, 'String', 'C:\Users\lab\Documents\MATLAB\ImageScan\NewPulseBlaster\SavedPulseSequences\inUse_sequences\T1_PiPulse_2Signal1Counter.esr');
          

for ka=1:(nx_all*numSequences)
   
    
    
        k = k+1;
  
    
    
    
    
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
     
        % first reset the default out back to 10 (for first time only) so that the engage can be
        % smooth and robust if drift occurs
        % for 2nd time and beyond, the tip is already 1.005um above the
        % sample at this point
        if (k==1)
            ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],currentDefaultOut);
        end
        
        
        %go to the kth x point
        dx = current_x_val - xpts_nm(k);
        current_x_val = xpts_nm(k); 
        mDAC ('move_tip_laser',-dx,0 ,0 ,0);
        pause(2) ; %just to be safe.
        
        
        % sample the current free amplitude to compute a setpoint
        R=0;
        for repeat_sampling =1:100
        sampStart = ziDAQ('get',['/',zdevice,'/DEMODS/0/SAMPLE']);
        eval(['samp_x = sampStart.',zdevice,'.demods.sample.x']);
        eval(['samp_y = sampStart.',zdevice,'.demods.sample.y']);
        R = R + sqrt(samp_x^2 + samp_y^2);
        pause(0.01);
        end
        R=R/100;
        
        %use a forced set point for the first time only as we have retratced by a lot here due
        %to setting the defaultout to +10V
        if k ==1
            Rstpt = forceSetpt;
        else
            Rstpt = R*setptFrac;            
        end
        
        
        % set this setpoint and other parameters in the Zurich
        ziDAQ('setDouble',['/',zdevice,'/PIDS/0/SETPOINT'],Rstpt);
        ziDAQ('setDouble',['/',zdevice,'/PIDS/0/P'],Pgain);
        ziDAQ('setDouble',['/',zdevice,'/PIDS/0/I'],IgainApproach);
        ziDAQ('setDouble',['/',zdevice,'/PIDS/0/D'],0.000);        
        ziDAQ('setInt',['/',zdevice,'/PIDS/0/OUTPUTDEFAULTENABLE'],1);
        ziDAQ('setDouble',['/',zdevice,'/PIDS/0/CENTER'],outCenter);
        ziDAQ('setDouble',['/',zdevice,'/PIDS/0/RANGE'],outRange);
        
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
        
        % so outTotal is now the voltage value (where 1 V=1 micron) of the
        % PID output going to MCL. for example
        % outTotal = 0.5 + 0.031  corresponds to MCL raised 531 nm
        % so to back off some 60 nm requires default out to be changed from
        % 0 to 531 - 60
        currentDefaultOut = outTotal+ working_z*(0.8e-3);
        
        % set this default out and turn off the feedback
        % for the case that the new Z height is a 0 value, take this
        % to mean that it is to be in feedback mode, do not disable
        ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],currentDefaultOut);
        
        
        if working_z > 1
            ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],0);
        else
            % do not disable PID if the Z value is too small!! use feedback
            % but since this default out value won't be used set it higher
            % for safety in case the pid enable stops
           % currentDefaultOut = outTotal+zpts_V(k)+0.008;
        end
        
      
       
       
       % set the corresponding tau max value for the x point  
       set(esr_handles.tauEnd,'String',num2str(ypts_ns_omega(k)));
        
           
           
       set(esr_handles.writeDataFreq,'UserData',1);
        % start the pulse sequence at this set height
        % first set the correct end tau value from list
        ['pulse sequence ', num2str(k), ' started']
        
        %ycounter = ycounter+1;
        ESRControl('buttonStartSequence_Callback',0,0,esr_handles); %Start current ESR sequence
        
        % be sure this is not skipped
        while ( get(esr_handles.writeDataFreq,'UserData') == 1)
                    'while loop for not skipping esrcontrol'
            pause(1); 
        end
        'ended past ESRControl and while loop enable'
        
        % after sequence ends, retract some minimum amount EVERY time so
        % that we have a relatively free amplitude in case the lift height
        % was just a few nm to 10s nm
        ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],currentDefaultOut+safeLiftZ_endPixel_V);
        % disable PID
        ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],0);
        pause(3);

        
        % extract the pulse sequence data at this height
        path1 = get(esr_handles.esrSavePath,'String');
        path2 = get(esr_handles.esrSaveFilePrefix,'String');
        path3 = get(esr_handles.esrSaveFileNum,'String');
        
        
        if (k==1)
               useNum = path3;          
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
                tauStartVal = str2double(get(esr_handles.tauStart,'String'));
                signalArray(2,1:3:end) = tauEndVal +tauStartVal - signalArray(1,1:3:end); % get tau
        end
        
        % put all data for single x point into a matrix with 1 row
        % transpose first to take all of row 1, then all row 2, ...
        scanTauPLTriplets = reshape(signalArray',1,numTauPoints*3*numc);
        % concatenate the x,y,z,z,z,z data into this array
        xs = xpts_nm(k);% 
        znmSet = working_z;
        znmSurf = outTotal*1000;
        scanSaveArray = [xs,0,znmSet,znmSurf,scanTauPLTriplets];
        %----------------------------------------------
        
        % format: make it the same as *.scan and *.info data for easy analysis
        % .scan format, but make Z stuff redundant here for Zscan
        % X | Y | Zfor | ZforFilt |Zrev |ZrevFilt | tau1 | sig1 | ref1 | tau2 | sig2| ref2 | ....
        scanFilename   = [path1,'\',path2,useNum,'.scan'];         
        dlmwrite(scanFilename,scanSaveArray,'-append','delimiter','\t');
        
        % write the .info file on the first cycle
        if (k==1)
            % ---------write a .info file----------------
            infoFilename   = [path1,'\',path2,useNum,'.dat'];
            dlmwrite(infoFilename, datestr(date),'-append','delimiter','');
            dlmwrite(infoFilename, 'Size: 0.0 V x 0.0 V','-append','delimiter','');
            dlmwrite(infoFilename, 'Center: (0.0 V, 0.0 V)','-append','delimiter','');
            dlmwrite(infoFilename, ['Resolution: 1 x 1 x ',num2str(nx_all)],'-append','delimiter','');  % should change this later to give the correct resolution
            dlmwrite(infoFilename, 'Scan Speed: 0 Hz','-append','delimiter','');
            dlmwrite(infoFilename, 'Rotation: 0 deg','-append','delimiter','');
            dlmwrite(infoFilename, ' ','-append','delimiter','');
            dlmwrite(infoFilename, 'Column Headings:','-append','delimiter','');
            chanPosLabels = 'X / Y / Z nm from surf / Z - surf nm';
            chanMeasLabels = ' / tau / sig / ref';
            chanMeasLabels = repmat(chanMeasLabels,1,(numTauPoints*numc));
            dlmwrite(infoFilename, [chanPosLabels,chanMeasLabels],'-append','delimiter','');
            %------------------------------------------------
        end
    end
   
  
end



% to clean up, set default out = 0 again, and leave in feedback mode to
% protect tip from long term drift if user doesn't take control at end
% immediately
ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],10.000);
ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],1);

%cleanup lakeshore 331
%fclose(lake);
%delete(lake)
 
end

