function scan_xy_MRI_nPoint_AFMreg( )

%perform image registration 
%XY scan with scan style similar to Imagescan
%also implemented adaptive tau points where we go to the next x,y point if
%the current x,y point gives a good contrast



global Scan_Finished_Flag
global Img_handles;
global esr_handles;

global laser_x_handle;
global laser_y_handle;
global is_center;
is_center = 0;

%Get original image for tracking
global ESR_pulsed_handles;
%ESR_pulsed_handles.PerformImageRegistration(0,1);
bTipTrackXY = false;
galvoTrackPeriod = 50;
AFM_track_number =70000;

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


%%AFM parameters for T1 scan and image registration
Pgain = 0.4; % V/Vrms
% do a slow approach with low Igain and then increase it
IgainApproach = 35; %V/Vrms/s
IgainEngaged = 45; % 
currentDefaultOut = 10.000; % V, NOTE THAT here 1 V is 1 micron, not 10.
outCenter = 0.0; %V, 500 mV
outRange = 10; % 5V = 5 microns on [center-range,center+range]
errTol = 0.001; % 0.1 mV is the error tolerance to first know when in contact
errCurrent = 1; % just set to some large value
outTotal = 0; % current PID output
outShift = 0; % current PID shift
safeLiftZ_endPixel_V = 0.5*0.8; % 0.5um safelift
outTotal_changeSpeed = 0.004;  %5nm
setptFrac =0.96;


Force_set_pnt = 110.0e-3; %chnage this each time. used only during first AFM scan



%%%%%%%%%%%%%%%
% added on 10/31/16: displacement between actual T1 scan and AFM image
% registration scans and turn off AOM except for T1 measurement and
% tracking
displacement_AFM_T1 = [0.0,0.0]*10000;

%in nm x,y

%%

%turn off AOM if its on

    %    Img_handles.PulseInterpreter.stopPulse();
    %    set(Img_handles.buttonAOMOn, 'String', 'Turn AOM On');
    %    set(Img_handles.buttonAOMOn, 'Value', 1) ;


%code to get the first AFM scan for subsequent image registration purposes

%% assumes that the tip position is at the center of the NV

scan_size_x = 0.08;
scan_size_y = 0.08;
%set scan size to 800nm in x
mDAC('set_scan_size_x', scan_size_x);

%set scan size to 800nm in y
mDAC('set_scan_size_y',scan_size_y);


%set scan speed
afm_scan_speed = 14 ; %in hertz
mDAC('set_scan_speed',afm_scan_speed);

%set number of points in x and y
afm_scan_x_points_numb = 75;
afm_scan_y_points_numb = 75;

mDAC('set_scan_points_x',afm_scan_x_points_numb); 
mDAC('set_scan_points_y',afm_scan_y_points_numb);


pause(0.5);

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



%setting the afm scan center to the entered values from the dialog box
% because the user enters the x and y when the NV and the tip are aligned
mDAC('set_scan_center_x',initial_pos(1));
mDAC('set_scan_center_y',initial_pos(2));

%move the tip to the begining point of the scan before calling the start
%scan func. takes nanometers
mDAC('move_tip_laser', -scan_size_x*10000/2,-scan_size_y*10000/2,0,0);
pause(10);

% set this setpoint and other parameters in the Zurich
            Rstpt = Force_set_pnt;
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
            
            % 6 seconds to really make sure that we enagage
  
            pause(6);
            
            
%now perfrom afm scan
mDAC('start_scan',0,0);

while mDAC('is_scan')
  pause(2);   
end

'initial scan done'

%need to retract here
 ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],0);

pause(2);
 
%move tip back to the NV-AFM tip aligned point
mDAC('move_tip_laser',scan_size_x*10000/2+ displacement_AFM_T1(1),0,0,0);
pause(3);
mDAC('move_tip_laser',0,-scan_size_y*10000/2 + displacement_AFM_T1(2),0,0);
pause(3);



%%%%
% original PL-AFM scan image, get the latest image on the scans folder.
initial_scan=importdata('C:/AFM/scans/current_scan.scan');


% image resolution
initial_image_x= initial_scan(:,1);
initial_image_y = initial_scan(:,2);
initial_image_z = initial_scan(:,7);

% end of initial AFM image aquiring code


%generate x,y point for T1 scan

%x_points = linspace(-500,500,51);
x_points = linspace(-400,400,41);
y_points = linspace(-400,400,41);


nx = length (x_points);
ny = length (y_points);
xy_points = zeros (nx*ny,2);
i = 0;

for ix = 1:nx    
    for iy = 1:ny        
        i = i+1;
        xy_points(i,1) = x_points(ix);
        xy_points(i,2) = y_points(iy);                
    end    
end

working_z = 1 ; % 1nm from surface to measure T1 curves 

Omega_range = [1500e3,2000e3,3000e3,4000e3] +1000;



%%main T1 scan loop bigins here

current_point =0 ;
Omega_to_use = 1;

use_single_tau = 1;


numTauPoints = 2; % same as in ESR GUI
numc=1;

% how to trat the tau data----------
% for a T1 use:
firstTauCmd = 'divideBy2';
secondTauCmd = 'yMinusFirst';

%-----------------



firstNum = '';
secondNum='';
useNum='';

sweep=0;

current_x_val = 0;
current_y_val = 0;


AFM_galvo_track=0;

use_adaptive_tau_flag = 0;

%set the pulse sequence
set(esr_handles.fileboxPulseSequence, 'String', 'C:\Users\lab\Documents\MATLAB\ImageScan\NewPulseBlaster\SavedPulseSequences\inUse_sequences\MRI_rf_on_off_2Signal1Counter.esr');

wait_dist = 100; %100 nanometers. Matlab will wait longer if r greater than wait_dist

while current_point < nx*ny
    
    
    current_point = current_point +1;
    AFM_galvo_track = AFM_galvo_track+1;

    
    if (bTipTrackXY)
            % ...
    else
        % don't track tip-NV/pillar separation in XY
        % assumed starting conditions
            % 1) the user sets desired tip position for x,y
            % 2) The tip is approached, but Zurich PID0 ("1") is off
            % 3) All pulse sequence settings are set in ESRControl GUI
            
     if (mod(AFM_galvo_track,galvoTrackPeriod)==0)
       

        ESR_pulsed_handles.gesr.RunSingleTrackPulsedESR(ESR_pulsed_handles.imageScanHandles);
        
       
      
     end
     
        % first reset the default out back to 10 (for first time only) so that the engage can be
        % smooth and robust if drift occurs
        % for 2nd time and beyond, the tip is already 1.005um above the
        % sample at this point
        if (AFM_galvo_track==1)
            ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],currentDefaultOut);
        end
        
        
        %go to the current x,y point
        dx = current_x_val - xy_points(current_point,1);
        dy = current_y_val - xy_points(current_point,2);
        current_x_val = xy_points(current_point,1); 
        current_y_val = xy_points(current_point,2);
        mDAC ('move_tip_laser',-dx,-dy ,0 ,0);
      
        if sqrt(dx^2 + dy^2) > wait_dist
            pause(2);
        end
        
        pause(0.1) ; %just to be safe.
        
        
        % sample the current free amplitude to compute a setpoint
        
        sampEnable = ziDAQ('get',['/',zdevice,'/PIDS/0/ENABLE']);
        eval(['isEnabled = sampEnable.',zdevice,'.pids.enable']);
        if (~isEnabled)
        
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
        if AFM_galvo_track ==1
            Rstpt = Force_set_pnt;
        else
            Rstpt = R*setptFrac;            
        end
        
        
        % set this setpoint and other parameters in the Zurich
        ziDAQ('setDouble',['/',zdevice,'/PIDS/0/SETPOINT'],Rstpt);
        ziDAQ('setDouble',['/',zdevice,'/PIDS/0/P'],Pgain);
        ziDAQ('setDouble',['/',zdevice,'/PIDS/0/I'],IgainEngaged);
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
        
        end
        
       
       
       % set the corresponding tau max value for the xy point  
       if use_adaptive_tau_flag == 0
       set(esr_handles.tauEnd,'String',num2str(Omega_range(Omega_to_use)));
       else
       set(esr_handles.tauEnd,'String',num2str(new_tau_value));           
       end
       
           
           
       set(esr_handles.writeDataFreq,'UserData',1);
        % start the pulse sequence at this set height
        % first set the correct end tau value from list
        ['pulse sequence ', num2str(AFM_galvo_track), ' started']
        
        %ycounter = ycounter+1;
        ESRControl('buttonStartSequence_Callback',0,0,esr_handles); %Start current ESR sequence
        
        % be sure this is not skipped
        pause(0.1)
        while Scan_Finished_Flag == 0
            'while loop for not skipping esrcontrol'
            pause(0.1); 
        end
        'ended past ESRControl and while loop enable'
        %pause(0.5)
      
        if (mod(AFM_galvo_track,ny) ==0)
        % after sequence ends, retract some minimum amount EVERY time so
        % that we have a relatively free amplitude in case the lift height
        % was just a few nm to 10s nm
        ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],currentDefaultOut+safeLiftZ_endPixel_V);
        % disable PID
        ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],0);
        pause(1);
        end
        

        
        % extract the pulse sequence data at this height
        path1 = get(esr_handles.esrSavePath,'String');
        path2 = get(esr_handles.esrSaveFilePrefix,'String');
        path3 = get(esr_handles.esrSaveFileNum,'String');
        
        
        if (AFM_galvo_track==1)
               useNum = path3;          
        end
        
     
        
        
        % for every signal channel of the sequence, there is 1 file to read in
        % containing a sig and ref.
        % '_a_b.txt' where a=1,2 for channel and b=0,1,2... for tau points
        pathPrefix = [path1 path2 path3 '\' path2 path3];
        
        filepath1 = [pathPrefix '_0','.txt'];
        
       % filepath2 = [pathPrefix '_2_',num2str(sweep),'.txt'];
        d1 = importdata(filepath1);
        %d2 = importdata(filepath2);
        celld = {d1};
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
        
        
        % put all data for single x point into a matrix with 1 row
        % transpose first to take all of row 1, then all row 2, ...
        scanTauPLTriplets = reshape(signalArray',1,numTauPoints*3*numc);
        % concatenate the x,y,z,z,z,z data into this array
        xs = xy_points(current_point,1);% 
        ys = xy_points(current_point,2);
        
        znmSet = working_z;
        znmSurf = outTotal*1000;
        scanSaveArray = [xs,ys,znmSet,znmSurf,scanTauPLTriplets];
        %----------------------------------------------
        
        % format: make it the same as *.scan and *.info data for easy analysis
        % .scan format, but make Z stuff redundant here for Zscan
        % X | Y | Zfor | ZforFilt |Zrev |ZrevFilt | tau1 | sig1 | ref1 | tau2 | sig2| ref2 | ....
        scanFilename   = [path1,'\',path2,useNum,'.scan'];         
        dlmwrite(scanFilename,scanSaveArray,'-append','delimiter','\t');
        
        % write the .info file on the first cycle
        if (AFM_galvo_track==1)
            % ---------write a .info file----------------
            infoFilename   = [path1,'\',path2,useNum,'.dat'];
            dlmwrite(infoFilename, datestr(date),'-append','delimiter','');
            dlmwrite(infoFilename, 'Size: 0.0 V x 0.0 V','-append','delimiter','');
            dlmwrite(infoFilename, 'Center: (0.0 V, 0.0 V)','-append','delimiter','');
            dlmwrite(infoFilename, ['Resolution: 1 x 1 x ',num2str(1)],'-append','delimiter','');  % should change this later to give the correct resolution
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
        
        
        %%%%decide to advance to the next xy point or try another tau
        % set the target reduction in PL to be 40% or better compared to the full contrast
        
        if use_single_tau == 0
            
        C = scanTauPLTriplets(11) - scanTauPLTriplets(2);
        Sig = scanTauPLTriplets(8) - scanTauPLTriplets(5) ;
        
        decay_frac = Sig/C;
        
        if (decay_frac > 0.6 ) || (Sig < 0)
            current_point = current_point-1;
            
            if use_adaptive_tau_flag ==1            
                Omega_to_use =  1; 
                use_adaptive_tau_flag = 0;
            else
                Omega_to_use = Omega_to_use+1;
            end
            
            
            use_adaptive_tau_flag = 0 ;
        elseif (decay_frac <0.2 )
             current_point = current_point-1;
            Omega_to_use = 1;
            use_adaptive_tau_flag =0;
            
            
        else
               %do adaptive tau based on current pixel T1 
                Omega_to_use = 1; 
                tau_value = scanTauPLTriplets(4)/1000; %divide by 1000 to get microsecond value
                T1 = tau_value/ (log(C) - log (Sig)); %in microseconds
                new_tau_value = 0.7*T1;
                use_adaptive_tau_flag = 1;
                %condition the calculated value so ESRgui wont get stuck
                new_tau_value = round(new_tau_value)*1000; % tau value is in nanosec 
        end
        
        end
        
       
        
    end
    
    
    
    
   if (mod(AFM_galvo_track,AFM_track_number) ==0)
 % ************** code to re take AFM image 
    % first need to retract tip if not already retracted
    ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],0);
       
            
   %start scan with previous parameters, with NV-tip at the center of the
   %scan area
   %scan center is current tip x,y
   %move tip to the top left point of the scan 
   % and engage
   mDAC('move_tip_laser', -xy_points(current_point,1) -scan_size_x*10000/2 - displacement_AFM_T1(1),-xy_points(current_point,2)-scan_size_y*10000/2 - displacement_AFM_T1(2),0,0);
   pause(10);

   %turn feedback on
   % compute the percentage setpoint
            % sample the current free amplitude to compute a setpoint
            R=0;
            for temp =1:100
            sampStart = ziDAQ('get',['/',zdevice,'/DEMODS/0/SAMPLE']);
            eval(['samp_x = sampStart.',zdevice,'.demods.sample.x']);
            eval(['samp_y = sampStart.',zdevice,'.demods.sample.y']);
            R = R + sqrt(samp_x^2 + samp_y^2);
            pause(0.01);
            end
            
            Rstpt = R/100;
            Rstpt = Rstpt*0.92;
            
   
             % set this setpoint and other parameters in the Zurich
               
                ziDAQ('setDouble',['/',zdevice,'/PIDS/0/SETPOINT'],Rstpt);
                ziDAQ('setDouble',['/',zdevice,'/PIDS/0/P'],Pgain);
                ziDAQ('setDouble',['/',zdevice,'/PIDS/0/I'],IgainEngaged);
                ziDAQ('setDouble',['/',zdevice,'/PIDS/0/D'],0.000);
               % ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],currentDefaultOut);
                ziDAQ('setInt',['/',zdevice,'/PIDS/0/OUTPUTDEFAULTENABLE'],1);
                ziDAQ('setDouble',['/',zdevice,'/PIDS/0/CENTER'],outCenter);
                ziDAQ('setDouble',['/',zdevice,'/PIDS/0/RANGE'],outRange);

             % turn on feedback
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
                
                % 6 seconds to make sure enage is fine
                pause(6);
            
            
    mDAC('start_scan',0,0);
    
    
    %wait till scan is done
    
    while mDAC('is_scan')
    pause(1); 
    end
    'AFM-PL scan done'
  
    %retract tip
     ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],0);
     pause(1);
     
    %%%%%%%%%%%%
    %grab the image from scan
    
    second_scan=importdata('C:/AFM/scans/current_scan.scan');

    
   second_image_x= second_scan(:,1);
   second_image_y = second_scan(:,2);
   second_image_z = second_scan(:,7);

 
    %%convert the image 
   for jx = 0:(afm_scan_x_points_numb-1)
       for jy =0:(afm_scan_y_points_numb-1)
           initial_im(jx+1,jy+1) = initial_image_z(jx*afm_scan_x_points_numb+jy+1);
           second_im(jx+1,jy+1) = second_image_z(jx*afm_scan_x_points_numb+jy+1);
       end
   end
  
  %%perform image reg
  [abc,def] = dftregistration(fft2(initial_im), fft2(second_im), 20); 
  
 'drift in x is'
  drift_tip_x = abc(3)
'the drift in y is'
  drift_tip_y = abc(4)
  
   %%convert pixel dirfts to nm
   % conversion between volts and distance: 1V is 10um
  
   
   x_pixel_volts = scan_size_x/afm_scan_x_points_numb;
   y_pixel_volts = scan_size_y/afm_scan_y_points_numb;
   
   drift_V_x= x_pixel_volts*drift_tip_x ;
   drift_V_y= y_pixel_volts*drift_tip_y;
   
 drift_nm_x = drift_V_x*10000;
 drift_nm_y = drift_V_y*10000;
   
  %%first move tip to old center position 
   dx = scan_size_x*10000/2;
   dy = scan_size_y*10000/2;
  mDAC('move_tip_laser',dx+displacement_AFM_T1(1),-dy+displacement_AFM_T1(2),0,0);
  
  %give some time to move
  pause(10);
  
  
   %% now incremnt x , y to new drifted points
  
   if (abs(drift_nm_x) < 100 & abs(drift_nm_y) < 100)
  'move tip'
       mDAC ('move_tip_laser',-drift_nm_x,-drift_nm_y,0,0);
   
   
   drift_nm_x
   drift_nm_y
   
   %update initial position
   initial_pos (1) = initial_pos(1) - drift_V_x;
   initial_pos (2) = initial_pos(2) - drift_V_y;
   
   mDAC('set_scan_center_x',initial_pos(1));
   mDAC('set_scan_center_y',initial_pos(2));
  
   else
       'drift distances greater than 100nm. so not going to change x,y';
   end
   
   %now move the tip over to current_x_val, current_y_val
   mDAC('move_tip_laser', current_x_val, current_y_val, 0,0);
   pause(6);
   
   end
%%*************%end of tip registration and correction code   
    
    
    
    
    
    
    
end

ziDAQ('setInt',['/',zdevice,'/PIDS/0/OUTPUTDEFAULTENABLE'],1);
ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],10.000);
ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],0);



end
