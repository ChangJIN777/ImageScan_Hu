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
currentDefaultOut = 10.00; % V,ZHIRAN, NOTE THAT here 1 V is 1 micron, not 10.
Force_set_pnt = 89.0e-3; %chnage this each time. used only during first AFM scan, %ZHIRAN,MAKE SURE SET POINT IS RIGHT
x_points = linspace(-20,20,11);
y_points = linspace(-20,20,11); %ZHIRAN, sets scan window, in nanometers
scan_repeats =1; %ZHIRAN, like how many scans
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
outCenter = 0.0; %V, 500 mV
outRange = 10; % 5V = 5 microns on [center-range,center+range]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% added on 10/31/16: displacement between actual T1 scan and AFM image
% registration scans and turn off AOM except for T1 measurement and
% tracking

%in nm x,y

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% assumes that the tip position is at the center of the NV

%retract
ziDAQ('setInt',['/',zdevice,'/PIDS/0/OUTPUTDEFAULTENABLE'],1);
ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],currentDefaultOut);
ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],0);

pause(2);

%generate x,y points for T1 scan

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

for scan_repeat_numb = 1:scan_repeats
    while current_point < nx*ny
        
        current_point = current_point +1;
        
        %retract tip b4 tracking
        %ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],currentDefaultOut);
        %disable PID
        %ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],0);
        %pause(1);
        
        %%
        %go to the current x,y point
        dx = xy_points(current_point,1)-current_x_val;
        dy =  xy_points(current_point,2)-current_y_val;
        pause(0.1)
        current_x_val = xy_points(current_point,1);
        current_y_val = xy_points(current_point,2);
        
        dr = sqrt(dx*dx + dy*dy);
        
        %if (dr > 21 ) && (AFM_galvo_track>1)
        if (dr > 21 )
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
        
        
        %% Adjust AFM

       
        
  
        %% Adjust parameters for ESRControl

        %get(esr_handles.tauStart,'String')
        %set(esr_handles.tauStart,'String','16000')
        %extract result from the previous pixel
        path1 = get(esr_handles.esrSavePath,'String');
        path2 = get(esr_handles.esrSaveFilePrefix,'String');
        path3 = get(esr_handles.esrSaveFileNum,'String');
        pathPrefix = [path1 path2 path3 '\' path2 path3];
        numc=1;
        numb_repeats=length(dir([pathPrefix '_*.txt']))-1;
        signalArray = zeros(numc,numTauPoints*3);
        SNR=8;

        for sweep = 0:(numb_repeats-1)
            
            filepath1 = [pathPrefix '_',num2str(sweep),'.txt'];
            d1 = importdata(filepath1);
            celld = {d1};
            for c=1:numc
                for nt=1:numTauPoints
                    signalArray(c,3*nt-2) =signalArray(c,3*nt-2)+ celld{c}.data(nt,1); % gets 2 tau
                    signalArray(c,3*nt-1) =signalArray(c,3*nt-1)+ celld{c}.data(nt,2); % gets signal
                    signalArray(c,3*nt) = signalArray(c,3*nt)+celld{c}.data(nt,3);  % gets reference
                end
            end
        end
        signalArray=signalArray./(numb_repeats);
        load GdscanningSimulation_data.mat
        if (signalArray(2)-signalArray(6))/(signalArray(5)-signalArray(3))==0
            
        else
            guessT1=(signalArray(4)-signalArray(1))/2e9/(log((signalArray(2)-signalArray(6))/(signalArray(5)-signalArray(3)))); %T1 of previous pixel, in sec
            % set the upper and lower bond of expected T1, to facilitate
            % the measurement
            %if guessT1<0.000020
            %    guessT1=0.000020;
            if guessT1<0.003000
                guessT1=0.003000;
            end
            if guessT1>0.008
                guessT1=0.008;
            end
            taustartvalue=str2double(get(esr_handles.tauStart,'String'));
            measuretau=guessT1*interp1(mycurve3(1,:),mycurve3(2,:),guessT1); %in sec
            set(esr_handles.tauEnd,'String',num2str(round(measuretau*10^6)*1000+taustartvalue));
            measurereadoutime=interp1(mycurve3(1,:),mycurve3(3,:),guessT1); %in us
            set(esr_handles.readoutTime,'String',num2str(round(measurereadoutime*100)*10));
            measuresweeps=0.5*(SNR*(91.6381-84.6381*exp(-measurereadoutime^(-0.8038)))/exp(-measuretau/guessT1))^2;
            %repspertaupt=str2double(get(esr_handles.repsPerTau,'String'));
            set(esr_handles.repsPerTau,'String',num2str(2*round(measuresweeps/2)));
            set(esr_handles.numAverages,'String',num2str(1));
        end
        %if mod(current_point,40)==0  do NV tracking.
        
        pause(0.1)

        %%
        %ycounter = ycounter+1;
        ESRControl('buttonStartSequence_Callback',0,0,esr_handles); %Start current ESR sequence
        
        % be sure this is not skipped
        while ( get(esr_handles.writeDataFreq,'UserData') == 1)
            %'while loop for not skipping esrcontrol'
            pause(0.2);
        end
        %'ended past ESRControl and while loop enable'
        
        %turn off laser on the NV
        Img_handles.PulseInterpreter.stopPulse();
        set(Img_handles.buttonAOMOn, 'String', 'Turn AOM On');
        set(Img_handles.buttonAOMOn, 'Value', 1) ;
        

        
    end
    
    
    
    current_point = 0;
    
    %retract and move tip to scan center:
    ziDAQ('setInt',['/',zdevice,'/PIDS/0/OUTPUTDEFAULTENABLE'],1);
    ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],currentDefaultOut);
    ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],0);
    pause(1);
    
    
    %turn off laser on the NV
    Img_handles.PulseInterpreter.stopPulse();
    set(Img_handles.buttonAOMOn, 'String', 'Turn AOM On');
    set(Img_handles.buttonAOMOn, 'Value', 1) ;
end




