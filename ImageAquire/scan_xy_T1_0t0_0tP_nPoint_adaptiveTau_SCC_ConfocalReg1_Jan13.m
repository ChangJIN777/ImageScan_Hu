
%DOLEV AND ZHIRAN: MOST UP TO DATE SCANNING CODE JUNE 26 2019
%perform image registration
%XY scan with scan style similar to Imagescan
%also implemented adaptive tau points where we go to the next x,y point if
%the current x,y point gives a good contrast

%Zhiran modified the image (confocal) registratin part on 7/31/2019

global Img_handles;
global esr_handles;
global ConfcScanParm_handles;
global driftingdata;

global laser_x_handle;
global laser_y_handle;
global is_center;
is_center = 0;

%%
RegImageOffset=5; %Z offset(confocal axis) of confocal image taken for registration. in um
pixels_x = 200;% first dicide how many pixels. This decision is made manually
pixels_y = 200;
periodregi=7200;% set how frequetly at least for image registration, in seconds
iffirstrun=1;
cyclenum=2;
driftingdata=zeros(1000,14);
%%

%Get original image for tracking
global ESR_pulsed_handles;
%ESR_pulsed_handles.PerformImageRegistration(0,1);
bTipTrackXY = false;
galvoTrackPeriod = 6;

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
IgainApproach = 25; %V/Vrms/s
IgainEngaged = 25; %
currentDefaultOut = 0.000; % V, NOTE THAT here 1 V is 1 micron, not 10.
outCenter = 0.0; %V, 500 mV
outRange = 10; % 5V = 5 microns on [center-range,center+range]
errTol = 0.001; % 0.1 mV is the error tolerance to first know when in contact
errCurrent = 1; % just set to some large value
outTotal = 0; % current PID output
outShift = 0; % current PID shift
safeLiftZ_endPixel_V = 0.5*0.8; % 0.5um safelift
outTotal_changeSpeed = 0.004;  %5nm
setptFrac =0.97;


Force_set_pnt = 134.5e-3; %chnage this each time. used only during first AFM scan, %ZHIRAN,MAKE SURE SET POINT IS RIGHT



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% added on 10/31/16: displacement between actual T1 scan and AFM image
% registration scans and turn off AOM except for T1 measurement and
% tracking
displacement_AFM_T1 = [-0.00,-0.0]*10000;

%in nm x,y

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%code to get the first AFM scan for subsequent image registration purposes

%turn off AOM if its on
%  Img_handles.PulseInterpreter.stopPulse();
%  set(Img_handles.buttonAOMOn, 'String', 'Turn AOM On');
%  set(Img_handles.buttonAOMOn, 'Value', 1) ;

%get current Zurich output when in contact:
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
pause(6);% 6 seconds to really make sure that we enagage
numSurfAverages = 100;
outSamples = zeros(1,numSurfAverages);
for s=1:numSurfAverages
    sampPID =  ziDAQ('get',['/',zdevice,'/PIDS/0/SHIFT']);
    eval(['samp_shift = sampPID.',zdevice,'.pids.shift;']);
    outShift = samp_shift;
    outSamples(s) = outCenter + outShift;
    pause(0.01);
end
outTotal = mean(outSamples);
%Then retract 2um away to take confocal image
currentDefaultOut = outTotal +(2000*0.8e-3);% position 2um above the surface
ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],currentDefaultOut);
ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],0);
pause(3);
currentDefaultOut = 0.000; 


%First get this original confocal axis/pixels information and keep it.
ConfigureScan(Img_handles.ScanControl.ScanParameters(1),...
        str2double(get(Img_handles.editPositionX,'String')),...
        str2double(get(Img_handles.editPositionY,'String')),Img_handles);
set(ConfcScanParm_handles.pointsX,'String',num2str(pixels_x))
set(ConfcScanParm_handles.pointsY,'String',num2str(pixels_y))
MinValuesConfocal=ConfcScanParm_handles.ConfocalScan.MinValues; %record the X,Y limits for confocal, make sure it's the same all the way
MaxValuesConfocal=ConfcScanParm_handles.ConfocalScan.MaxValues; %record the X,Y limits for confocal, make sure it's the same all the way
import java.awt.Robot;
import java.awt.event.*;
mouse = Robot;
pause(1.5)
mouse.mouseMove(1000, 630); % relates to my personal location of open program instance
mouse.mousePress(InputEvent.BUTTON1_MASK); % actual left click press
pause(0.1);
mouse.mouseRelease(InputEvent.BUTTON1_MASK);
pause(1);
'Confocal parameters changed.'

if iffirstrun==0
    close(RegistrationFig);
end

%Then in order to avoid the weird problem in the ImageScan code, where
%there's a bug after tracking, you have to do a scan over the ImageScan gui
%before uncheck the "Scan using axes limits".
set(Img_handles.checkUseZoomboxLimits,'Value',1)
Img_handles.PulseInterpreter.setCurrentPulse([Img_handles.configS.sequenceFolder 'bit_red.txt']); %Turn on red laser. Make sure this is red.
Img_handles.PulseInterpreter.loadToPulseblaster();
Img_handles.PulseInterpreter.runPulse();
pause(1)
ConfigureScan(Img_handles.ScanControl.ScanParameters(1),...
        str2double(get(Img_handles.editPositionX,'String')),...
        str2double(get(Img_handles.editPositionY,'String')),Img_handles);
set(ConfcScanParm_handles.pointsX,'String',num2str(10))
set(ConfcScanParm_handles.pointsY,'String',num2str(10))
import java.awt.Robot;
import java.awt.event.*;
mouse = Robot;
pause(1.5)
mouse.mouseMove(1000, 630); 
mouse.mousePress(InputEvent.BUTTON1_MASK); 
pause(0.1);
mouse.mouseRelease(InputEvent.BUTTON1_MASK);
pause(1.5)
mouse.mouseMove(3105, 20); 
mouse.mousePress(InputEvent.BUTTON1_MASK); 
pause(0.1);
mouse.mouseRelease(InputEvent.BUTTON1_MASK);
pause(1.5);
mouse.mouseMove(2958, 95); 
mouse.mousePress(InputEvent.BUTTON1_MASK);
pause(0.1);
mouse.mouseRelease(InputEvent.BUTTON1_MASK);
pause(2)
Img_handles.PulseInterpreter.stopPulse();

%Now set the paramters for confocal:
ConfigureScan(Img_handles.ScanControl.ScanParameters(1),...
        str2double(get(Img_handles.editPositionX,'String')),...
        str2double(get(Img_handles.editPositionY,'String')),Img_handles);
set(ConfcScanParm_handles.pointsX,'String',num2str(pixels_x));
set(ConfcScanParm_handles.pointsY,'String',num2str(pixels_y));
set(ConfcScanParm_handles.minX,'String',num2str(MinValuesConfocal(1)));
set(ConfcScanParm_handles.minY,'String',num2str(MinValuesConfocal(2)));
set(ConfcScanParm_handles.maxX,'String',num2str(MaxValuesConfocal(1)));
set(ConfcScanParm_handles.maxY,'String',num2str(MaxValuesConfocal(2)));
mouse = Robot;
pause(1.5)
mouse.mouseMove(1000, 630); % relates to my personal location of open program instance
mouse.mousePress(InputEvent.BUTTON1_MASK); % actual left click press
pause(0.1);
mouse.mouseRelease(InputEvent.BUTTON1_MASK);
'Confocal parameters changed.'
set(Img_handles.checkUseZoomboxLimits,'Value',0)

%Then do the confocal image
RegistrationFig=figure; hold on
%Turn on the green AOM by using ImageScan's handles, and commend
%Pulseblaster by using PulseInterpreter class's functions.
Img_handles.PulseInterpreter.setCurrentPulse([Img_handles.configS.sequenceFolder 'bit_red.txt']); %Turn on red laser. Make sure this is red.
Img_handles.PulseInterpreter.loadToPulseblaster();
Img_handles.PulseInterpreter.runPulse();
pause(1);
%Get a confocal scan image.
NVConfocalZ=str2num(get(Img_handles.editPositionZ,'String'));
TipConfocalZ=NVConfocalZ+RegImageOffset; %in um.
set(Img_handles.editPositionZ,'String',num2str(TipConfocalZ));
Img_handles.CursorControl.updatePositionFromEdit(Img_handles,Img_handles.editPositionZ,3,0.0);
pause(1);
Img_handles = guidata(Img_handles.buttonStartStopScan);
if Img_handles.StateControl.state == Img_handles.StateControl.SCANNING
    Img_handles.StateControl.changeToIdleState(Img_handles);
else
    Img_handles.StateControl.changeToScanningState(Img_handles);
end
pause(0.5);
Img_handles.PulseInterpreter.stopPulse();
'One confocal scan finished.'
set(Img_handles.editPositionZ,'String',num2str(NVConfocalZ));
Img_handles.CursorControl.updatePositionFromEdit(Img_handles,Img_handles.editPositionZ,3,0.0);
pause(1);
hold off
FilePath=get(Img_handles.inputSaveImagePath,'String');
FirstFileNum=get(Img_handles.inputSaveImageFileNum,'String');
previousclock=clock; %record the time of previous registration.
driftingdata(1,5:10)=previousclock;
driftingdata(1,11)=0;driftingdata(1,12)=str2num(get(Img_handles.editPositionX,'String')); 
driftingdata(1,13)=str2num(get(Img_handles.editPositionY,'String')); 
driftingdata(1,14)=str2num(get(Img_handles.editPositionZ,'String')); %#ok<*ST2NM>
fileID = fopen('driftingdata.txt','a');
fprintf(fileID,'%7.2f %7.2f %7.2f %7.2f %7.2f %7.2f %7.2f %7.2f %7.2f %7.2f %7.2f %7.2f %7.2f %7.2f\n',driftingdata(1,:));
fclose(fileID);


%Then do another 50^2 pixels scan to quick fix the bug in NV-tracking code
%Now set the paramters for confocal:
ConfigureScan(Img_handles.ScanControl.ScanParameters(1),...
        str2double(get(Img_handles.editPositionX,'String')),...
        str2double(get(Img_handles.editPositionY,'String')),Img_handles);
set(ConfcScanParm_handles.pointsX,'String',num2str(50));
set(ConfcScanParm_handles.pointsY,'String',num2str(50));
set(ConfcScanParm_handles.minX,'String',num2str(MinValuesConfocal(1)));
set(ConfcScanParm_handles.minY,'String',num2str(MinValuesConfocal(2)));
set(ConfcScanParm_handles.maxX,'String',num2str(MaxValuesConfocal(1)));
set(ConfcScanParm_handles.maxY,'String',num2str(MaxValuesConfocal(2)));
mouse = Robot;
pause(1.5)
mouse.mouseMove(1000, 630); % relates to my personal location of open program instance
mouse.mousePress(InputEvent.BUTTON1_MASK); % actual left click press
pause(0.1);
mouse.mouseRelease(InputEvent.BUTTON1_MASK);
'Confocal parameters changed.'
set(Img_handles.checkUseZoomboxLimits,'Value',0)
Img_handles.PulseInterpreter.setCurrentPulse([Img_handles.configS.sequenceFolder 'bit1_on.txt']); %Turn on red laser. Make sure this is red.
Img_handles.PulseInterpreter.loadToPulseblaster();
Img_handles.PulseInterpreter.runPulse();
pause(1.5);
mouse.mouseMove(2958, 95); % relates to my personal location of open program instance
mouse.mousePress(InputEvent.BUTTON1_MASK); % actual left click press
pause(0.1);
mouse.mouseRelease(InputEvent.BUTTON1_MASK);
pause(1.5)
Img_handles.PulseInterpreter.stopPulse();
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% assumes that the tip position is at the center of the NV

scan_size_x = 0.003;
scan_size_y = 0.003;
%set scan size to 1000nm in x
mDAC('set_scan_size_x', scan_size_x);

%set scan size to 1000nm in y
mDAC('set_scan_size_y',scan_size_y);


%set scan speed
afm_scan_speed = 5 ; %in hertz
mDAC('set_scan_speed',afm_scan_speed);

%set number of points in x and y
afm_scan_x_points_numb = 3;
afm_scan_y_points_numb = 3;

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

numSurfAverages = 100;
outSamples = zeros(1,numSurfAverages);
for s=1:numSurfAverages
    sampPID =  ziDAQ('get',['/',zdevice,'/PIDS/0/SHIFT']);
    eval(['samp_shift = sampPID.',zdevice,'.pids.shift;']);
    outShift = samp_shift;
    outSamples(s) = outCenter + outShift;
    pause(0.01);
end
outTotal = mean(outSamples);

currentDefaultOut = outTotal +(2000*0.8e-3);% position 2um above the surface

%now perfrom afm scan
mDAC('start_scan',0,0);

while mDAC('is_scan')
    pause(2);
end

'initial scan done'

%need to retract here to 2000nm above surface.
ziDAQ('setInt',['/',zdevice,'/PIDS/0/OUTPUTDEFAULTENABLE'],1);
ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],currentDefaultOut);
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


x_points = linspace(-100,100,3);
y_points = linspace(-100,100,3); %ZHIRAN, sets scan window, in nanometers




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

working_z = 1 ; % 1nm from surface to measure T1 curves


%new_tau_value = 1400e3 + 1000; %ZHIRAN, initial tau value used
%T1_limit = 4500e3 + 1000;


%%main T1 scan loop bigins here

current_point =0 ;


use_single_tau = 0;  %set this = 0 to do adaptive tau

scan_repeats =1; %ZHIRAN, like how many scans
numb_repeats = 80; %ZHIRAN, must be same as in ESR GUI
numTauPoints = 2; % same as in ESR GUI
numc=2;

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


%set the pulse sequence
%set(esr_handles.fileboxPulseSequence, 'String', 'C:\Users\lab\Documents\MATLAB\ImageScan\NewPulseBlaster\SavedPulseSequences\inUse_sequences\spin2chargeSEQ\spin2chargeT1.esr');

for scan_repeat_numb = 1:scan_repeats
    
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
                %retract tip b4 tracking
                ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],currentDefaultOut+safeLiftZ_endPixel_V);
                % disable PID
                ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],0);
                pause(0.2);
                
                %turn on laser b4 tracking
                Img_handles.PulseInterpreter.setCurrentPulse([Img_handles.configS.sequenceFolder 'bit1_on.txt']);
                Img_handles.PulseInterpreter.loadToPulseblaster();
                Img_handles.PulseInterpreter.runPulse();
                set(Img_handles.buttonAOMOn, 'String', 'Turn AOM off');
                set(Img_handles.buttonAOMOn, 'Value', 0);
                pause(0.1)
                
                %ESR_pulsed_handles.gesr.RunSingleTrackPulsedESR(ESR_pulsed_handles.imageScanHandles);
                
                %turn off AOM after tracking
                Img_handles.PulseInterpreter.stopPulse();
                set(Img_handles.buttonAOMOn, 'String', 'Turn AOM On');
                set(Img_handles.buttonAOMOn, 'Value', 1) ;
                
            end
            
            % first reset the default out back to 10 (for first time only) so that the engage can be
            % smooth and robust if drift occurs
            % for 2nd time and beyond, the tip is already 1.005um above the
            % sample at this point
            if (AFM_galvo_track==1)
                ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],currentDefaultOut);
            end
            
            
            %go to the current x,y point
            dx = current_x_val - xy_points(current_point,1)
            dy = current_y_val - xy_points(current_point,2)
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
            
            mDAC ('move_tip_laser',-dx,-dy ,0 ,0)
            
            if dr > 21
                pause(6) ; %just to be safe since tip is moving far
            else
                pause(0.2);
            end
            
            
            sampEnable = ziDAQ('get',['/',zdevice,'/PIDS/0/ENABLE']);
            eval(['isEnabled = sampEnable.',zdevice,'.pids.enable']);
            
            if ~isEnabled
                
                
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
                
                %check if the zurich restarted
                
                sampFreq = ziDAQ('get',['/',zdevice,'/OSCS/0/FREQ']);
                if double(sampFreq.dev236.oscs.freq)  > 35e3
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
                
            end
            
            outSamples = zeros(1,numSurfAverages);
            for s=1:numSurfAverages
                sampPID =  ziDAQ('get',['/',zdevice,'/PIDS/0/SHIFT']);
                eval(['samp_shift = sampPID.',zdevice,'.pids.shift;']);
                outShift = samp_shift;
                outSamples(s) = outCenter + outShift;
                pause(0.01);
            end
            outTotal = mean(outSamples);
            currentDefaultOut = outTotal+ working_z*(0.8e-3);
            
            
            ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],currentDefaultOut);
            
            
            if working_z > 1
                ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],0);
            end
            
            
            
            
            
            % set the corresponding tau max value for the xy point
            %       set(esr_handles.tauEnd,'String',num2str(new_tau_value));
            
            
            
            
            
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
            
            for sweep = 0:(numb_repeats-1)
                
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
                
                if sweep ==0
                    scanTauPLTriplets_all = scanTauPLTriplets;
                else
                    scanTauPLTriplets_all = [scanTauPLTriplets_all, scanTauPLTriplets];
                end
                
                
                
            end
            
            % concatenate the x,y,z,z,z,z data into this array
            xs = xy_points(current_point,1);%
            ys = xy_points(current_point,2);
            
            znmSet = working_z;
            znmSurf = outTotal*1000;
            scanSaveArray = [xs,ys,znmSet,znmSurf,scanTauPLTriplets_all];
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
                
                %         C = -mean (scanTauPLTriplets_all(12:12:12*numb_repeats )) + mean (scanTauPLTriplets_all(3:12:12*numb_repeats));
                %         Sig = -mean (scanTauPLTriplets_all(12:12:12*numb_repeats)) + mean (scanTauPLTriplets_all(9:12:12*numb_repeats));
                %
                %         decay_frac = Sig/C;
                
                %         if (decay_frac > 0.7)
                %             current_point = current_point-1;
                %             new_tau_value = new_tau_value/(1.4*1000);
                %             new_tau_value = round(new_tau_value)*1000; % tau value is in nanosec
                %
                %         elseif (decay_frac <0.2)
                %              current_point = current_point-1;
                %              new_tau_value = new_tau_value*1.4/1000;
                %             new_tau_value = round(new_tau_value)*1000; % tau value is in nanosec
                %
                %         else
                
                %do adaptive tau based on current pixel T1
                %                 tau_value = scanTauPLTriplets_all(4)/1000; %divide by 1000 to get microsecond value
                %
                %                 C2 = -mean (scanTauPLTriplets_all(12:12:12*numb_repeats )) + mean (scanTauPLTriplets_all(3:12:12*numb_repeats));
                %                 Sig2 = -mean (scanTauPLTriplets_all(9:12:12*numb_repeats)) + mean(scanTauPLTriplets_all(6:12:12*numb_repeats));
                
                %                 T1 = (tau_value - tauStartVal/1000)/ (log(C2) - log (Sig2)); %in microseconds
                %                 new_tau_value = real(0.8*T1);
                %                 %condition the calculated value so ESRgui wont get stuck
                %                 new_tau_value = round(new_tau_value)*1000; % tau value is in nanosec
                %
                %                 if new_tau_value > T1_limit
                %                     new_tau_value = T1_limit;
                %                 elseif new_tau_value < tauStartVal
                %                     new_tau_value = 1000e3+1000;
                %                 end
                
                %new_tau_value = 1400e3+1000;
                %         end
                
            end
            
            
            
        end
        
        
        %% Registration started
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        nowclock=clock
        if etime(nowclock,previousclock)> periodregi
            %first retract 2um
            numSurfAverages = 100;
            outSamples = zeros(1,numSurfAverages);
            for s=1:numSurfAverages
                sampPID =  ziDAQ('get',['/',zdevice,'/PIDS/0/SHIFT']);
                eval(['samp_shift = sampPID.',zdevice,'.pids.shift;']);
                outShift = samp_shift;
                outSamples(s) = outCenter + outShift;
                pause(0.01);
            end
            outTotal = mean(outSamples);
            currentDefaultOut = outTotal +(2000*0.8e-3);% position 2um above the surface
            ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],currentDefaultOut);
            ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],0);
            pause(3);
            ziDAQ('setDouble',['/',zdevice,'/PIDS/0/SETPOINT'],Force_set_pnt);
            mDAC ('move_tip_laser',-current_x_val,-current_y_val,0,0); %then move back to scan center
            pause(1);

            %get current Zurich output when in contact:
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
            pause(6);% 6 seconds to really make sure that we enagage
            numSurfAverages = 100;
            outSamples = zeros(1,numSurfAverages);
            for s=1:numSurfAverages
                sampPID =  ziDAQ('get',['/',zdevice,'/PIDS/0/SHIFT']);
                eval(['samp_shift = sampPID.',zdevice,'.pids.shift;']);
                outShift = samp_shift;
                outSamples(s) = outCenter + outShift;
                pause(0.01);
            end
            outTotal = mean(outSamples);
            
            %Then retract 2um away to take confocal image
            currentDefaultOut = outTotal +(2000*0.8e-3);% position 2um above the surface
            ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],currentDefaultOut);
            ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],0);
            pause(2);
            
            
            %Then in order to avoid the weird problem in the ImageScan code, where
            %there's a bug after tracking, you have to do a scan over the ImageScan gui
            %before uncheck the "Scan using axes limits".
            set(Img_handles.checkUseZoomboxLimits,'Value',1)
            Img_handles.PulseInterpreter.setCurrentPulse([Img_handles.configS.sequenceFolder 'bit_red.txt']); %Turn on red laser. Make sure this is red.
            Img_handles.PulseInterpreter.loadToPulseblaster();
            Img_handles.PulseInterpreter.runPulse();
            pause(1)
            ConfigureScan(Img_handles.ScanControl.ScanParameters(1),...
                str2double(get(Img_handles.editPositionX,'String')),...
                str2double(get(Img_handles.editPositionY,'String')),Img_handles);
            set(ConfcScanParm_handles.pointsX,'String',num2str(10))
            set(ConfcScanParm_handles.pointsY,'String',num2str(10))
            import java.awt.Robot;
            import java.awt.event.*;
            mouse = Robot;
            pause(1.5)
            mouse.mouseMove(1000, 630); % relates to my personal location of open program instance
            mouse.mousePress(InputEvent.BUTTON1_MASK); % actual left click press
            pause(0.1);
            mouse.mouseRelease(InputEvent.BUTTON1_MASK);
            pause(1.5)
            if strcmp(get(Img_handles.buttonStartStopRunningCount,'String'),'Stop Running Count')
                mouse.mouseMove(3105, 20); % relates to my personal location of open program instance
                mouse.mousePress(InputEvent.BUTTON1_MASK); % actual left click press
                pause(0.1);
                mouse.mouseRelease(InputEvent.BUTTON1_MASK);
                pause(1.5);
                mouse.mouseMove(3105, 480); % relates to my personal location of open program instance
                mouse.mousePress(InputEvent.BUTTON1_MASK); % actual left click press
                pause(0.1);
                mouse.mouseRelease(InputEvent.BUTTON1_MASK);
                pause(1.5);
            end
            mouse.mouseMove(2958, 95); % relates to my personal location of open program instance
            mouse.mousePress(InputEvent.BUTTON1_MASK); % actual left click press
            pause(0.1);
            mouse.mouseRelease(InputEvent.BUTTON1_MASK);
            pause(3)
            Img_handles.PulseInterpreter.stopPulse();
            
            %Now set the paramters for confocal:
            ConfigureScan(Img_handles.ScanControl.ScanParameters(1),...
                str2double(get(Img_handles.editPositionX,'String')),...
                str2double(get(Img_handles.editPositionY,'String')),Img_handles);
            set(ConfcScanParm_handles.pointsX,'String',num2str(pixels_x));
            set(ConfcScanParm_handles.pointsY,'String',num2str(pixels_y));
            set(ConfcScanParm_handles.minX,'String',num2str(MinValuesConfocal(1)));
            set(ConfcScanParm_handles.minY,'String',num2str(MinValuesConfocal(2)));
            set(ConfcScanParm_handles.maxX,'String',num2str(MaxValuesConfocal(1)));
            set(ConfcScanParm_handles.maxY,'String',num2str(MaxValuesConfocal(2)));
            mouse = Robot;
            pause(1.5)
            mouse.mouseMove(1000, 630); % relates to my personal location of open program instance
            mouse.mousePress(InputEvent.BUTTON1_MASK); % actual left click press
            pause(0.1);
            mouse.mouseRelease(InputEvent.BUTTON1_MASK);
            pause(1)
            'Confocal parameters changed.'
            set(Img_handles.checkUseZoomboxLimits,'Value',0)
            
            
            %Then take confocal image when the sample is 2um below diamond:
            close(RegistrationFig);
            RegistrationFig=figure; hold on
            %Pulseblaster by using PulseInterpreter class's functions.
            Img_handles.PulseInterpreter.setCurrentPulse([Img_handles.configS.sequenceFolder 'bit_red.txt']); %Turn on red laser. Make sure this is red.
            Img_handles.PulseInterpreter.loadToPulseblaster();
            Img_handles.PulseInterpreter.runPulse();
            pause(1);
            %Get a confocal scan image.
            NVConfocalZ=str2num(get(Img_handles.editPositionZ,'String'));
            TipConfocalZ=NVConfocalZ+RegImageOffset; %in um.
            set(Img_handles.editPositionZ,'String',num2str(TipConfocalZ));
            Img_handles.CursorControl.updatePositionFromEdit(Img_handles,Img_handles.editPositionZ,3,0.0);
            pause(1);
            Img_handles = guidata(Img_handles.buttonStartStopScan);
            if Img_handles.StateControl.state == Img_handles.StateControl.SCANNING
                Img_handles.StateControl.changeToIdleState(Img_handles);
            else
                Img_handles.StateControl.changeToScanningState(Img_handles);
            end
            pause(0.5);
            Img_handles.PulseInterpreter.stopPulse();
            %set(Img_handles.buttonAOMOn, 'String', 'Turn AOM On');
            'One confocal scan finished.'
            pause(0.5);
            set(Img_handles.editPositionZ,'String',num2str(NVConfocalZ));
            Img_handles.CursorControl.updatePositionFromEdit(Img_handles,Img_handles.editPositionZ,3,0.0);
            pause(1);
            hold off
            NewFileNum=get(Img_handles.inputSaveImageFileNum,'String');
            % Run the registration algorism, and move the sample.
            %Also get the information of the confocal image at the beginning
            
            image_name1= ['image_',FirstFileNum,'.txt'];
            if pixels_x==200
                confocal_image = flipud(import_200by200confocalscan([FilePath,image_name1])); %If image size changed, manually change the loading script.
            elseif pixels_x==80
                confocal_image = flipud(import_80by80confocalscan([FilePath,image_name1])); %If image size changed, manually change the loading script.
            else
                'Make sure the pixels for confocal is correct in the code'
                pause(1000000000)
            end
            image_name2= ['image_',NewFileNum,'.txt'];
            if pixels_x==200
                confocal_image = flipud(import_200by200confocalscan([FilePath,image_name2]));%If image size changed, manually change the loading script.
            elseif pixels_x==80
                confocal_image = flipud(import_80by80confocalscan([FilePath,image_name2]));%If image size changed, manually change the loading script.
            end
            A=importfile_X([FilePath,image_name1]);
            MinX= A(1);
            MaxX= A(2);
            A=importfile_Y([FilePath,image_name1]);
            MinY= A(1);
            MaxY= A(2);
            nm_per_pixel_y = 1000*(MaxY - MinY)/pixels_y;
            nm_per_pixel_x = 1000*(MaxX - MinX)/pixels_x;
            if pixels_x==200
                confocal_image1 = flipud(import_200by200confocalscan([FilePath,image_name1]));%If image size changed, manually change the loading script.
                confocal_image2 = flipud(import_200by200confocalscan([FilePath,image_name2]));%If image size changed, manually change the loading script.
            elseif pixels_x==80
                confocal_image1 = flipud(import_80by80confocalscan([FilePath,image_name1]));%If image size changed, manually change the loading script.
                confocal_image2 = flipud(import_80by80confocalscan([FilePath,image_name2]));%If image size changed, manually change the loading script.
            end
            [abc,def] = dftregistration(fft2(confocal_image1), fft2(confocal_image2), 20); %This function is adpated from other researchers, see the file
            drift_nm_x = nm_per_pixel_x*abc(4);
            drift_nm_x = round(drift_nm_x)
            drift_nm_y = nm_per_pixel_y*abc(3);
            drift_nm_y = round(drift_nm_y)
            %and get another confocal image to check whether the sample is
            %really back, if not move again...
            previousclock=clock; %record the time of previous registration.
            
            %convert pixel dirfts to nm
            %conversion between volts and distance: 1V is 10um
            drift_V_x = drift_nm_x/10000;
            drift_V_y = drift_nm_y/10000;
            driftingdata(cyclenum,2)=drift_nm_x; %record the drifting x (of the sample)
            driftingdata(cyclenum,3)=drift_nm_y; %record the drifting y (of the sample)
            driftingdata(cyclenum,4)=outTotal*1.25; %record the drifting z (of the sample)
            driftingdata(cyclenum,5:10)=nowclock;%record the time
            driftingdata(1,11)=0;driftingdata(1,12)=str2num(get(Img_handles.editPositionX,'String'));
            driftingdata(1,13)=str2num(get(Img_handles.editPositionY,'String'));
            driftingdata(1,14)=str2num(get(Img_handles.editPositionZ,'String')); %#ok<*ST2NM>
            fileID = fopen('driftingdata.txt','a');
            fprintf(fileID,'%7.2f %7.2f %7.2f %7.2f %7.2f %7.2f %7.2f %7.2f %7.2f %7.2f %7.2f %7.2f %7.2f %7.2f\n',driftingdata(cyclenum,:));
            fclose(fileID);
            cyclenum=cyclenum+1;
            
            %Then do another 50^2 pixels scan to quick fix the bug in NV-tracking code
            ConfigureScan(Img_handles.ScanControl.ScanParameters(1),...
                str2double(get(Img_handles.editPositionX,'String')),...
                str2double(get(Img_handles.editPositionY,'String')),Img_handles);
            set(ConfcScanParm_handles.pointsX,'String',num2str(50));
            set(ConfcScanParm_handles.pointsY,'String',num2str(50));
            set(ConfcScanParm_handles.minX,'String',num2str(MinValuesConfocal(1)));
            set(ConfcScanParm_handles.minY,'String',num2str(MinValuesConfocal(2)));
            set(ConfcScanParm_handles.maxX,'String',num2str(MaxValuesConfocal(1)));
            set(ConfcScanParm_handles.maxY,'String',num2str(MaxValuesConfocal(2)));
            mouse = Robot;
            pause(1.5)
            mouse.mouseMove(1000, 630); % relates to my personal location of open program instance
            mouse.mousePress(InputEvent.BUTTON1_MASK); % actual left click press
            pause(0.1);
            mouse.mouseRelease(InputEvent.BUTTON1_MASK);
            'Confocal parameters changed.'
            set(Img_handles.checkUseZoomboxLimits,'Value',0)
            Img_handles.PulseInterpreter.setCurrentPulse([Img_handles.configS.sequenceFolder 'bit1_on.txt']); %Turn on red laser. Make sure this is red.
            Img_handles.PulseInterpreter.loadToPulseblaster();
            Img_handles.PulseInterpreter.runPulse();
            pause(1.5);
            mouse.mouseMove(2958, 95); % relates to my personal location of open program instance
            mouse.mousePress(InputEvent.BUTTON1_MASK); % actual left click press
            pause(0.1);
            mouse.mouseRelease(InputEvent.BUTTON1_MASK);
            pause(1.5)
            Img_handles.PulseInterpreter.stopPulse();
            
            % now incremnt x , y to new drifted points
            %if abs(drift_nm_x)<1500 && abs(drift_nm_y)<1500
            %    if (drift_nm_x^2+drift_nm_y^2)^0.5 > 200
            %       'Move the tip.'
            %        driftingdata(cyclenum,1)=1;
            %        mDAC ('move_tip_laser',-drift_nm_x,-drift_nm_y,0,0);
            %        %update initial position and scan center
            %        initial_pos (1) = initial_pos(1) - drift_V_x;
            %        initial_pos (2) = initial_pos(2) - drift_V_y;
            %        mDAC('set_scan_center_x',initial_pos(1));
            %        mDAC('set_scan_center_y',initial_pos(2));
            %    else
            %        'The drift seems smaller than 200 nm, so not moving tip'
            %    end
            %else
            %    'The drift seems to be bigger than 1.5 um in X/Y, so not moving tip.'
            %end
            mDAC ('move_tip_laser',current_x_val,current_y_val,0,0); %then move back to current scan point
            pause(0.5);
            'move back to scanning'
            ziDAQ('setDouble',['/',zdevice,'/PIDS/0/SETPOINT'],Rstpt);
        end
        %%*************%end of tip registration and correction code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    end
    
    current_point = 0;
    AFM_galvo_track=0;
    
    %retract and move tip to scan center:
    ziDAQ('setInt',['/',zdevice,'/PIDS/0/OUTPUTDEFAULTENABLE'],1);
    ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],0);
    currentDefaultOut = 0;
    ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],0);
    pause(1);
    mDAC('move_tip_laser', -current_x_val, -current_y_val, 0,0);
    pause(6);
    
    current_x_val = 0;
    current_y_val = 0;
    
end




