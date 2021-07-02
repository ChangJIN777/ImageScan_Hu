function scan_ps_pillar_xy_z_T100( )
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

x_size_nm = 0; %Dimensions of scan in nm, POSITIVE VALUED
y_size_nm = 0;
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

nx = 1; %Number of points along x axis
ny = 1; %y axis
nz=2;
xpts_nm = linspace(-x_size_nm/2, x_size_nm/2,nx);
xpts_V = xpts_nm*0.0001; % 10 µm/V
ypts_nm = linspace(-y_size_nm/2, y_size_nm/2,ny);
ypts_V = ypts_nm*0.0001; % 10 µm/V
current_xy = [0,0];
safeLiftZ_V = 0.5; % in Volts where 1 um = 1 Volt

% each height in nm to visit
% DON"T MAKE z=0 THE LAST POINT IN THE ARRAY OR IT WILL MOVE XY IN FEEDBACK
% WE CAN EASILY CHANGE THIS BY TURNING OFF PID AFTER MEASUREMENT BUT THAT
% JUST TAKES MORE TIME AWAY FROM EMASURING
zrange_nm = [0,1000]; %[6,10,20,30,40,50,75,100,125,150,200,300];
yrange_ns = [500,500]*10^3+500;%[500,600,600,600,600,600,600,700,700,800,800,800]*10^3;%[500,500,600,600,700,700,800,800,1000,1000,1000,1200]*10^3;
numzRange = length(zrange_nm);
numyRange = length(yrange_ns);
ycounter = 1;
if (numyRange~=numzRange)
   'Aborted z scan. The length of zrange must match length of end Tau time range' 
end
% make a list of the z values concatenated nz number of times
zpts_nm = repmat(zrange_nm,1,nz); %linspace(z_min_nm,z_max_nm,nz);
ypts_ns = repmat(yrange_ns,1,nz);
nz_all = length(zpts_nm); % don't use nz_all for xyz scan, only z scan
zpts_V = zpts_nm*0.001; % 300 nm on zpts means 0.3 V PId output 

setptFrac = 0.90; % fraction of the free R that the setpoint should be
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
outTotal = 0;
outShift = 0; % current PID shift

% for x,y, scans the range is [-x_size/2,x_size/2]
% however, for z scans you start at the surface so [0, z_size]

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
%Peform AFM_PL scan to get the initial drift compoansation image
%% assumes that the tip position is at the center of the NV

scan_size_x = 0.04;
scan_size_y = 0.04;
%set scan size to 400nm in x
mDAC('set_scan_size_x', scan_size_x);

%set scan size to 400nm in y
mDAC('set_scan_size_y',scan_size_y);



%set scan speed
afm_scan_speed = 10 ; %in hertz
mDAC('set_scan_speed',afm_scan_speed);


%set number of points in x and y
afm_scan_x_points_numb = 80;
afm_scan_y_points_numb = 80;

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


%perform a scan so that nv center is at the middle. after obtaining current
%tip position,

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
            pause(1);
%now perfrom afm scan
%mDAC('start_scan',0,0);

%while mDAC('is_scan')
  pause(2);   
%end

'initial scan done'

%need to retract here
 ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],0);

pause(2);
 
%move tip back to the NV-AFM tip aligned point
%mDAC('move_tip_laser',scan_size_x*10000/2,0,0,0);
pause(3);
%mDAC('move_tip_laser',0,-scan_size_y*10000/2,0,0);
pause(3);



%%%%
% original PL-AFM scan image, get the latest image on the scans folder.
initial_scan=importdata('C:/AFM/scans/current_scan.scan');


% image resolution
initial_image_x= initial_scan(:,1);
initial_image_y = initial_scan(:,2);
initial_image_PL = initial_scan(:,7);


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
            current_xy = [xpts_nm(i),ypts_nm(j)]
            pause(1);
            
            
            
            for k=1:nz   

               
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
                
                
                pause(2);

                % 5) average N times the PID OUTPUT to get surface position
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
                
                %8) Get a lift height
                %and feedback turned off
                currentDefaultOut = outTotal-zpts_V(k);
                ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],currentDefaultOut);
                if zpts_nm(k) > 1
                    ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],0);
                else
                    % do not disable PID if the Z value is too small!! use feedback
                    % but since this default out value won't be used set it
                    % higher 100nm for safety in case the pid enable stops
                    currentDefaultOut = outTotal-zpts_V(k)-0.1;
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
                ESRControl('buttonStartSequence_Callback',0,0,esr_handles); %Start current ESR sequence

                % note for later: keep (7) commented out for xy_z scans
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

                % before going to the next point:
                % if the pid is off. Lift up even more
                % if pid is on DON'T MAKE PID ON THE LASER Z POINT GO FROM 
                
                
                currentDefaultOut = currentDefaultOut-safeLiftZ_V;
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
                 zs = zpts_V(k)/10;% convert 1 um/V to 10 um/V for using same plotting script
                 zpid = zpts_V(k);
                 znmSet = zpts_nm(k);
                 znmSurf = outTotal*1000;
                scanSaveArray = [xpts_V(i),ypts_V(j),zs,zpid,znmSet,znmSurf,scanTauPLTriplets,tempA,tempB];
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
   
        
     %%% bigining of tip registration and correction code
  
    
   
    
  
    
    
   if not(mod(k,1))
       
        % first need to retract tip if not already retracted
    ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],0);
       
         %then go to previous AFM-pl image registration center
    mDAC('move_tip_laser',-current_xy(1),-current_xy(2),0,0);
    %wait for couple of seconds
    pause(5); 
    
    
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
                
                
                pause(1);
            
            
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
   second_image_PL = second_scan(:,7);

 
    %%convert the image 
   for ix = 0:(afm_scan_x_points_numb-1)
       for iy =0:(afm_scan_y_points_numb-1)
           initial_im(ix+1,iy+1) = initial_image_PL(ix*afm_scan_x_points_numb+iy+1);
           second_im(ix+1,iy+1) = second_image_PL(ix*afm_scan_x_points_numb+iy+1);
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
   mDAC ('move_tip_laser',drift_nm_x,drift_nm_y,0,0);
   drift_nm_x
   drift_nm_y
   
    %put current x,y to 0
    current_xy = [0,0]
   end
%%%end of tip registration and correction code   
   
        
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




