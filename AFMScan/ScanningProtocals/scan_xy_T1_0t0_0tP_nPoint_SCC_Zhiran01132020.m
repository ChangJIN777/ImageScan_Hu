%ZHIRAN: MOST UP TO DATE SCANNING CODE JAN 13 2020 ( "Snake" curve, scanning)
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
currentDefaultOut = -3.500; % V,ZHIRAN, NOTE THAT here 1 V is 1 micron, not 10.
Force_set_pnt = 19.85e-3; %chnage this each time. used only during first AFM scan, %ZHIRAN,MAKE SURE SET POINT IS RIGHT
x_points = linspace(-20,20,21);
y_points = linspace(-20,20,21); %ZHIRAN, sets scan window, in nanometers
scan_repeats =1; %ZHIRAN, like how many scans
numb_repeats = 70; %ZHIRAN, must be the same as in ESR GUI
numTauPoints = 2; % same as in ESR GUI

%%

%Get original image for tracking
global ESR_pulsed_handles;
%ESR_pulsed_handles.PerformImageRegistration(0,1);


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


%% assumes that the tip position is at the center of the NV

%generate x,y point for T1 scan

nx = length (x_points);
ny = length (y_points);

xy_points = zeros (nx*ny,2);
i = 0;

for iy = 1:ny
    for ix = 1:nx
        i = i+1;
        if mod(iy,2)==0
        xy_points(i,1) = -x_points(ix);
        xy_points(i,2) = y_points(iy);
        else
        xy_points(i,1) = x_points(ix);
        xy_points(i,2) = y_points(iy);
        end
    end
end

xy_points=-xy_points;
%% main T1 scan loop bigins here

current_point =0 ;

%-----------------
current_x_val = 0;
current_y_val = 0;
AFM_galvo_track=0;
%%
for scan_repeat_numb = 1:scan_repeats
    while current_point < nx*ny
        
        current_point = current_point +1;
        AFM_galvo_track = AFM_galvo_track+1;
        
        %%
        %go to the current x,y point
        dx = xy_points(current_point,1)-current_x_val
        dy =  xy_points(current_point,2)-current_y_val
        pause(0.1)
        current_x_val = xy_points(current_point,1)
        current_y_val = xy_points(current_point,2)
        
        dr = sqrt(dx*dx + dy*dy)
        
        
        mDAC ('move_tip_laser',dx,dy ,0 ,0)
        
        if dr > 21 % in nm
            pause(6) ; %just to be safe since tip is moving far
        else
            pause(0.2);
        end
        
        %%
   
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
    
    %turn off laser on the NV
    Img_handles.PulseInterpreter.stopPulse();
    set(Img_handles.buttonAOMOn, 'String', 'Turn AOM On');
    set(Img_handles.buttonAOMOn, 'Value', 1) ;
end




