%ZHIRAN: MOST UP TO DATE SCANNING CODE JAN 03 2020
%Simple scan, no registration, no adapted tau, constant setpoint and default Zurich output,
%Suitable for scanning top of microsphere sample.
%I use it to measure engaged SCC-T1 and retracted SCC-T1
%%
global Img_handles;
global esr_handles;
global ConfcScanParm_handles;
global laser_x_handle;
global laser_y_handle;

%% Things to be set everytime you run this program !!!!!!!!!!!!!!!
currentDefaultOut = -6.500; % V,ZHIRAN, NOTE THAT here 1 V is 1 micron, not 10.
Force_set_pnt = 20.0e-3; %chnage this each time. used only during first AFM scan, %ZHIRAN,MAKE SURE SET POINT IS RIGHT
x_points = linspace(-140,140,8);
y_points = linspace(-140,140,8); %ZHIRAN, sets scan window, in nanometers
scan_repeats =1; %ZHIRAN, like how many scans
numb_repeats = 120; %ZHIRAN, must be the same as in ESR GUI
numTauPoints = 2; % same as in ESR GUI



%%

%Get original image for tracking
global ESR_pulsed_handles;
%ESR_pulsed_handles.PerformImageRegistration(0,1);

%------ziDAQ setup------------
clear ziDAQ
ziDAQ('connect', 'localhost', 8005);
% get device name (e.g. 'dev236')
zdevice = ziAutoDetect();
%-------------------------------

% first make sure the PID is disabled otherwise quit measurement
sampEnable = ziDAQ('get',['/',zdevice,'/PIDS/0/ENABLE']);
eval(['isEnabled = sampEnable.',zdevice,'.pids.enable']);
if (isEnabled)
    'Turn off the HF2LI PID1 (/PIDS/0/ENABLE) before starting a z scan. Start assumption is that the tip is approached within 500 nm, but not engaged. Aborted.'
    return
end
%---------------


%%AFM parameters for T1 scan and image registration
Pgain = 0.5; % V/Vrms
% do a slow approach with low Igain and then increase it
IgainApproach = 35; %V/Vrms/s
IgainEngaged = 35; %
errCurrent = 1; % just set to some large value
outTotal = 0; % current PID output
outShift = 0; % current PID shift
safeLiftZ_endPixel_V = 0.5*0.8; % 0.5um safelift
outTotal_changeSpeed = 0.004;  %5nm





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% added on 10/31/16: displacement between actual T1 scan and AFM image
% registration scans and turn off AOM except for T1 measurement and
% tracking

%in nm x,y

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
previousclock=clock; %record the time of previous registration.

%% assumes that the tip position is at the center of the NV



prompt = {'Enter current tip X (V)', 'Enter current tip Y (V)'};
dlg_title = 'Position inputs';
num_lines = 1;
defaultans = {'2.5','2.5'};
initial_pos_string = inputdlg(prompt, dlg_title,num_lines,defaultans);

initial_pos(1) = str2num(initial_pos_string{1});
initial_pos(2) = str2num(initial_pos_string{2});

if (initial_pos(1) >10) ||  (initial_pos(1) <0)
    'Numbers out of range'
    return;
end

if (initial_pos(2) >10) || (initial_pos(2) <0)
    'Numbers Out of range'
    return;
end

'initial scan done'

%retract
ziDAQ('setInt',['/',zdevice,'/PIDS/0/OUTPUTDEFAULTENABLE'],1);
ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],currentDefaultOut);
ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],0);

pause(2);

%generate x,y point for T1 scan


nx = length (x_points);
ny = length (y_points);

xy_points = zeros (nx*ny,2);
i = 0;

for iy = 1:ny
    for ix = 1:nx
        i = i+1;
        xy_points(i,1) = x_points(ix);
        xy_points(i,2) = y_points(iy);
    end
end

%% main T1 scan loop bigins here

current_point =0 ;


%-----------------
current_x_val = 0;
current_y_val = 0;

%%
for scan_repeat_numb = 1:scan_repeats
    while current_point < nx*ny
        
        current_point = current_point +1;
        
        %retract tip b4 tracking
        ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],currentDefaultOut);
        % disable PID
        ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],0);
        pause(3);
        
        %%
        %go to the current x,y point
        dx = xy_points(current_point,1)-current_x_val
        dy =  xy_points(current_point,2)-current_y_val
        pause(0.1)
        current_x_val = xy_points(current_point,1)
        current_y_val = xy_points(current_point,2)
        
        dr = sqrt(dx*dx + dy*dy)
        
        if (dr > 21 ) && (AFM_galvo_track>1)
            %retract tip b4 moving tip since its going to move far.
            ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],currentDefaultOut+safeLiftZ_endPixel_V);
            % disable PID
            ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],0);
            pause(0.2);
        end
        
        mDAC ('move_tip_laser',dx,dy ,0 ,0)
        
        if dr > 21
            pause(6) ; %just to be safe since tip is moving far
        else
            pause(0.2);
        end
        
        %%
        set(esr_handles.writeDataFreq,'UserData',1);
        ['pulse sequence ', num2str(AFM_galvo_track), ' started']
        
        ESRControl('buttonStartSequence_Callback',0,0,esr_handles); %Start current ESR sequence
        
        % be sure this is not skipped
        while ( get(esr_handles.writeDataFreq,'UserData') == 1)
            'while loop for not skipping esrcontrol'
            pause(1);
        end
        'ended past ESRControl and while loop enable'
        
        %turn off laser on the NV
        Img_handles.PulseInterpreter.stopPulse();
        set(Img_handles.buttonAOMOn, 'String', 'Turn AOM On');
        set(Img_handles.buttonAOMOn, 'Value', 1) ;
        

        Rstpt = Force_set_pnt;
        % set this setpoint and other parameters in the Zurich
        ziDAQ('setDouble',['/',zdevice,'/PIDS/0/SETPOINT'],Rstpt);
        ziDAQ('setDouble',['/',zdevice,'/PIDS/0/P'],Pgain);
        ziDAQ('setDouble',['/',zdevice,'/PIDS/0/I'],IgainEngaged);
        ziDAQ('setDouble',['/',zdevice,'/PIDS/0/D'],0.000);
        ziDAQ('setInt',['/',zdevice,'/PIDS/0/OUTPUTDEFAULTENABLE'],1);
        ziDAQ('setDouble',['/',zdevice,'/PIDS/0/CENTER'],outCenter);
        ziDAQ('setDouble',['/',zdevice,'/PIDS/0/RANGE'],10);
        %check if the zurich restarted
        sampFreq = ziDAQ('get',['/',zdevice,'/OSCS/0/FREQ']);
        if double(sampFreq.dev531.oscs.freq)  > 35e3
            % probably a reset did happen. stop the code here.
            return
        end

        
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
            pause(0.01);
        end
        outTotal = mean(outSamples); %in volts
        
        skipSpeedCheck=1;
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
        
        
        set(esr_handles.writeDataFreq,'UserData',1);
        ['pulse sequence ', num2str(AFM_galvo_track), ' started']
        
        %ycounter = ycounter+1;
        ESRControl('buttonStartSequence_Callback',0,0,esr_handles); %Start current ESR sequence
        
        % be sure this is not skipped
        while ( get(esr_handles.writeDataFreq,'UserData') == 1)
            'while loop for not skipping esrcontrol'
            pause(1);
        end
        'ended past ESRControl and while loop enable'
        
        %turn off laser on the NV
        Img_handles.PulseInterpreter.stopPulse();
        set(Img_handles.buttonAOMOn, 'String', 'Turn AOM On');
        set(Img_handles.buttonAOMOn, 'Value', 1) ;
        
        
    end
    
    
    
    current_point = 0;
    AFM_galvo_track=0;
    
    %retract and move tip to scan center:
    ziDAQ('setInt',['/',zdevice,'/PIDS/0/OUTPUTDEFAULTENABLE'],1);
    ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],0);
    currentDefaultOut = 0;
    ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],0);
    pause(1);
    
    
    %turn off laser on the NV
    Img_handles.PulseInterpreter.stopPulse();
    set(Img_handles.buttonAOMOn, 'String', 'Turn AOM On');
    set(Img_handles.buttonAOMOn, 'Value', 1) ;
end


 Rstpt = Force_set_pnt;
        % set this setpoint and other parameters in the Zurich
        ziDAQ('setDouble',['/',zdevice,'/PIDS/0/SETPOINT'],Rstpt);
        ziDAQ('setDouble',['/',zdevice,'/PIDS/0/P'],Pgain);
        ziDAQ('setDouble',['/',zdevice,'/PIDS/0/I'],IgainEngaged);
        ziDAQ('setDouble',['/',zdevice,'/PIDS/0/D'],0.000);
        ziDAQ('setInt',['/',zdevice,'/PIDS/0/OUTPUTDEFAULTENABLE'],1);
        ziDAQ('setDouble',['/',zdevice,'/PIDS/0/CENTER'],outCenter);
        ziDAQ('setDouble',['/',zdevice,'/PIDS/0/RANGE'],10);
        %check if the zurich restarted
        sampFreq = ziDAQ('get',['/',zdevice,'/OSCS/0/FREQ']);
        if double(sampFreq.dev531.oscs.freq)  > 35e3
            % probably a reset did happen. stop the code here.
            return
        end

        
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
            pause(0.01);
        end
        outTotal = mean(outSamples); %in volts
        
        skipSpeedCheck=1;
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
        
        
        set(esr_handles.writeDataFreq,'UserData',1);
        ['pulse sequence ', num2str(AFM_galvo_track), ' started']

