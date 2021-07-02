function AFM_img_reg_test( )
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


% bCheckPID
bCheckPID=0; % don't need to do this check if you're careful. see below


current_xy = [0,0];
safeLiftZ_V = 0.5; % in Volts where 1 um = 1 Volt



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
%mDAC('move_tip_laser', -scan_size_x*10000/2,-scan_size_y*10000/2,0,0);
%pause(10);


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
               
               
                
                while(errCurrent < 0 )
                    sampPID = ziDAQ('get',['/',zdevice,'/PIDS/0/ERROR']);
                   eval(['samp_err = sampPID.',zdevice,'.pids.error;']);
                    errCurrent = samp_err;                 
                end
                
              
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
   
%%%end of tip registration and correction code   
   
       



end

