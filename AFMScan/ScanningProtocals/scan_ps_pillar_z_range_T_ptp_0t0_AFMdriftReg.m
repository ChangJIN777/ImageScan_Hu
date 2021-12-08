function scan_ps_pillar_z_range_T_ptp_0t0_AFMdriftReg( )
%scan_ps_pillar_z scanning pulse sequence at a range of Z heights
%   Added temperature sensing output on 08/13/15

global Img_handles;
global esr_handles;

global laser_x_handle;
global laser_y_handle;
 global is_center;
 is_center = 0;

 
 AFM_track_number = 28; % roughy every 3 hours with current settings
 
 %Generate a list of points to measure

z_size_nm = 1000; %Dimensions of scan in nm, POSITIVE VALUED
if z_size_nm<0
    z_size_nm=-z_size_nm; % safety
end
z_min_nm = 10;
z_max_nm = z_min_nm+z_size_nm;
nx=1; ny=1;
nz = 25; %Number of times to visit each height point
setptFrac = 0.92; % fraction of the free R that the setpoint should be
forceSetpt = 14.9*10^-3; %in volts
Pgain = -0.5; % V/Vrms
% do a slow approach with low Igain and then increase it
IgainApproach = -35; %V/Vrms/s
IgainEngaged = -35; % 
currentDefaultOut = 0.000; % V, NOTE THAT here 1 V is 1 micron, not 10.
outCenter = 0.5; %V, 500 mV
outRange = 10; % 5V = 5 microns on [center-range,center+range]
errTol = 0.001; % 0.1 mV is the error tolerance to first know when in contact
errCurrent = 1; % just set to some large value
outTotal = 0; % current PID output
outShift = 0; % current PID shift
safeLiftZ_endPixel_V = 0.3; % in Volts where 1 um = 1 Volt
% for x,y, scans the range is [-x_size/2,x_size/2]
% however, for z scans you start at the surface so [0, z_size]
outTotal_changeSpeed = 0.005;

% each height in nm to visit
zrange_nm = [1,10,50,100,500,1000];%[10,50, 200, 1000];%[10,13,18,25,30,35,40,50,75,100,175,250,300,400,500];%[10,30,60,90,120,150,200,400,600,1000]; %[6,10,20,30,40,50,75,100,125,150,200,300];
yrange_ns_omega = [4000,4000,4000,4000,4000,4000]*10^3+500;%[1000,2000 ,4000,4000 ]*10^3+500;%[1000,1000,1200,1200,1400,1800,1800,2000,2400,3500,4500,7000,7000,8000,10000]*10^3+10;%[800,800,800,1000,800,1000,1000,1200,1500,1500,2500,4000]*10^3+10;%[500,500,600,600,700,700,800,800,1000,1000,1000,1200]*10^3;2001000*ones(1,length(zrange_nm));%[1000010,1000010,];%
yrange_ns_gamma = [3000,3000,3000,3000,3000,3000]*10^3+500;%[2000, 2000, 2000, 2000]*10^3+500;
numzRange = length(zrange_nm);
numyRange = length(yrange_ns_omega);
ycounter = 1;
if (numyRange~=numzRange)
   'Aborted z scan. The length of zrange must match length of end Tau time range' 
end

% make a list of the z values concatenated nz number of times
zpts_nm = repmat(zrange_nm,1,nz); %linspace(z_min_nm,z_max_nm,nz);
ypts_ns_omega = repmat(yrange_ns_omega,1,nz);
ypts_ns_gamma = repmat(yrange_ns_gamma,1,nz);

nz_all = length(zpts_nm);
zpts_V = zpts_nm*0.001; % 300 nm on zpts means 0.3 V PId output 
numTauPoints = 41; % same as in ESR GUI
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


%Peform AFM_PL scan to get the initial drift compoansation image
%% assumes that the tip position is at the center of the NV

scan_size_x = 0.03;
scan_size_y = 0.03;
%set scan size to 400nm in x
mDAC('set_scan_size_x', scan_size_x);

%set scan size to 400nm in y
mDAC('set_scan_size_y',scan_size_y);



%set scan speed
afm_scan_speed = 10 ; %in hertz
mDAC('set_scan_speed',afm_scan_speed);


%set number of points in x and y
afm_scan_x_points_numb = 60;
afm_scan_y_points_numb = 60;

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


%need to approach here
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
mDAC('move_tip_laser',scan_size_x*10000/2,0,0,0);
pause(3);
mDAC('move_tip_laser',0,-scan_size_y*10000/2,0,0);
pause(3);



%%%%
% original PL-AFM scan image, get the latest image on the scans folder.
initial_scan=importdata('C:/AFM/scans/current_scan.scan');


% image resolution
initial_image_x= initial_scan(:,1);
initial_image_y = initial_scan(:,2);
initial_image_z = initial_scan(:,4);



% end of initial AFM image aquiring code

%-------------------
firstNum = '';
secondNum='';
useNum='';

sweep=0;

is_omega = 1;
k=0;
numSequences=2;

for ka=1:(nz_all*numSequences)
   
    
    if is_omega ==1
        k = k+1;
    end
    
    
    
    
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
            %Rstpt = R*setptFrac;
            Rstpt = forceSetpt;
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
       
       
       if is_omega ==1
           set(esr_handles.fileboxPulseSequence, 'String', 'C:\Users\lab\Documents\MATLAB\ImageScan\NewPulseBlaster\SavedPulseSequences\DQrelaxation2016\T1_0t0_0tpi_IQ.esr');
           set(esr_handles.tauEnd,'String',num2str(ypts_ns_omega(k)));
       else
           set(esr_handles.fileboxPulseSequence, 'String', 'C:\Users\lab\Documents\MATLAB\ImageScan\NewPulseBlaster\SavedPulseSequences\DQrelaxation2016\T1_PiTauPi_IQ.esr');
           set(esr_handles.tauEnd,'String',num2str(ypts_ns_gamma(k)));
       end
       
           
           
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
        ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],currentDefaultOut-safeLiftZ_endPixel_V);
        
        % extract the pulse sequence data at this height
        path1 = get(esr_handles.esrSavePath,'String');
        path2 = get(esr_handles.esrSaveFilePrefix,'String');
        path3 = get(esr_handles.esrSaveFileNum,'String');
        if (k==1)
           
           if is_omega==1
               firstNum = path3;
               
           else
                secondNum = path3;
                
           end
        end
        if is_omega==1
               useNum=firstNum;
        else
            useNum=secondNum;
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
        
        % put all data for single Z point into a matrix with 1 row
        % transpose first to take all of row 1, then all row 2, ...
        scanTauPLTriplets = reshape(signalArray',1,numTauPoints*3*numc);
        % concatenate the x,y,z,z,z,z data into this array
        zs = zpts_V(k)/10;% convert 1 um/V to 10 um/V for using same plotting script
        zpid = zpts_V(k);
        znmSet = zpts_nm(k);
        znmSurf = outTotal*1000;
        scanSaveArray = [0,0,zs,zpid,znmSet,znmSurf,scanTauPLTriplets,tempA,tempB];
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
            dlmwrite(infoFilename, ['Resolution: 1 x 1 x ',num2str(nz_all)],'-append','delimiter','');
            dlmwrite(infoFilename, 'Scan Speed: 0 Hz','-append','delimiter','');
            dlmwrite(infoFilename, 'Rotation: 0 deg','-append','delimiter','');
            dlmwrite(infoFilename, ' ','-append','delimiter','');
            dlmwrite(infoFilename, 'Column Headings:','-append','delimiter','');
            chanPosLabels = 'X / Y / Z - V / Z - PID / Z - set nm / Z - surf nm';
            chanMeasLabels = ' / tau / sig / ref';
            chanTempLabels = ' / tempA / tempB';
            chanMeasLabels = repmat(chanMeasLabels,1,(numTauPoints*numc));
            dlmwrite(infoFilename, [chanPosLabels,chanMeasLabels,chanTempLabels],'-append','delimiter','');
            %------------------------------------------------
        end
    end
   is_omega  = not(is_omega);

   
   if (mod(ka,AFM_track_number) ==0)
 % ************** code to re take AFM image 
    % first need to retract tip if not already retracted
    ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],0);
       
        
    
   %start scan with previous parameters, with NV-tip at the center of the
   %scan area
   %scan center is current tip x,y
   
   %move tip to the top left point of the scan 
   % and engage
   mDAC('move_tip_laser', -scan_size_x*10000/2,-scan_size_y*10000/2,0,0);
   pause(10);

   %turn feedback on
   % compute the percentage setpoint
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
   second_image_z = second_scan(:,4);

 
    %%convert the image 
   for ix = 0:(afm_scan_x_points_numb-1)
       for iy =0:(afm_scan_y_points_numb-1)
           initial_im(ix+1,iy+1) = initial_image_z(ix*afm_scan_x_points_numb+iy+1);
           second_im(ix+1,iy+1) = second_image_z(ix*afm_scan_x_points_numb+iy+1);
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
  mDAC('move_tip_laser',dx,-dy,0,0);
  
  %give some time to move
  pause(10);
  
  
   %% now incremnt x , y to new drifted points
  
   if (abs(drift_nm_x) < 100 & abs(drift_nm_y) < 100)
  'move tip'
       mDAC ('move_tip_laser',-drift_nm_x,-drift_nm_y,0,0);
   end
   
   drift_nm_x
   drift_nm_y
   
   %update initial position
   initial_pos (1) = initial_pos(1) - drift_V_x;
   initial_pos (2) = initial_pos(2) - drift_V_y;
   
   mDAC('set_scan_center_x',initial_pos(1));
   mDAC('set_scan_center_y',initial_pos(2));

   
   end
%%*************%end of tip registration and correction code   
   
   
   
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

