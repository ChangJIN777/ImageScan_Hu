function PL_vs_z()

global Img_handles;
global esr_handles;
global laser_x_handle;
global laser_y_handle;
global is_center;
is_center = 0;



% 0) ZiDAQ setup
% 1) turn on pid with setpoint, range, and Igain
% 2) let PID ramp until you query it and is a particular value
% 3) once it gets to specified maximum output...
% 4) set the output back to 0 V pid
% 5) step the DAC Z out up a value less than max pid
% 6) repeat this process until the ZDAC out gets to something like 9.0 V
% 7) then set ZDAC back to 1 V starting point and then step the micronix

%0)------ziDAQ setup------------
clear ziDAQ
ziDAQ('connect', 'localhost', 8005);
% get device name (e.g. 'dev236')
zdevice = ziAutoDetect();
%-------------------------------

%1) -----
setptFrac = 0.92; % fraction of the free R that the setpoint should be
Pgain = -0.3; % V/Vrms
% do a slow approach with low Igain and then increase it
IgainApproach = -35; %V/Vrms/s
currentDefaultOut = 0.000; % V, NOTE THAT here 1 V is 1 micron, not 10.
outCenter = 0.5; %V, 500 mV
outRange = 10; % 5V = 5 microns on [center-range,center+range]
outMaxApproach = 9; % something close to but less than outRange

finalRetractStep = 1.0; % 1 micron on pid LESS than computed current surface

errTol = 0.001; % 0.1 mV is the error tolerance to first know when in contact
errCurrent = 1; % just set to some large value
outTotal = 0; % current PID output
outShift = 0; % current PID shift
DACzMin = 1.0; % volts 1V = 10 µm
DACzMax = 9.0; % voltas 9V = 90 µm
DACzStep = 0.85; % 0.85V = 8.5 µm step size, smaller than  outMaxApproach

% first make sure the PID is disabled otherwise quit measurement
sampEnable = ziDAQ('get',['/',zdevice,'/PIDS/0/ENABLE']);
eval(['isEnabled = sampEnable.',zdevice,'.pids.enable']);
if (isEnabled)
    'Turn off the HF2LI PID1 (/PIDS/0/ENABLE) before starting an approach.'
    return
end

 % flags
isApproached = 0; % trigged = 1 if the PID doesn't go further

while(~isApproached)

    currentDefaultOut=0;
    ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],currentDefaultOut);

    % sample the current free amplitude to compute a setpoint
    sampStart = ziDAQ('get',['/',zdevice,'/DEMODS/0/SAMPLE']);
    eval(['samp_x = sampStart.',zdevice,'.demods.sample.x;']);
    eval(['samp_y = sampStart.',zdevice,'.demods.sample.y;']);
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

    % start PID0 with gradual engage speed
    ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],1);

    % 2) let PID ramp until you query shift and is a particular value
    sampPID =  ziDAQ('get',['/',zdevice,'/PIDS/0/SHIFT']);
    eval(['samp_shift = sampPID.',zdevice,'.pids.shift;']);
    outShift = samp_shift;

    while (outShift < (outMaxApproach-outCenter)) && ~isApproached
        sampPID = ziDAQ('get',['/',zdevice,'/PIDS/0/SHIFT']);
        eval(['samp_shift = sampPID.',zdevice,'.pids.shift;']);
        outShift = samp_shift;

        % and if the shift stays the same for a while we know it is approached
        % but unlike previous approach code the PID takes care of making sure
        % the tip doesn't go too far so it doesn't matter that we delay a bit
        % in the code before ending the approach sequence
        numAvg=300;
        errCurrent=0;
        %tic
        for k=1:numAvg
            sampPID = ziDAQ('get',['/',zdevice,'/PIDS/0/ERROR']);
            eval(['samp_err = sampPID.',zdevice,'.pids.error;']);
            errCurrent = (errCurrent+samp_err)/k;
            
        end
        if errCurrent>0
               % error going from neg to positive means we reached the setpoint

               isApproached = 1;
               'is now approached'
        end
        %toc

    end
    pause(.1); % not necessary to pause but could be useful

   
end


% have approached sample here
% now we saet the default out 1nm lower than surface and turn off feedback

     numSurfAverages = 100;
     outSamples = zeros(1,numSurfAverages);
    for s=1:numSurfAverages
        sampPID =  ziDAQ('get',['/',zdevice,'/PIDS/0/SHIFT']);
        eval(['samp_shift = sampPID.',zdevice,'.pids.shift;']);
        outShift = samp_shift;
        outSamples(s) = outCenter + outShift;
    end
    outTotal = mean(outSamples);% so outTotal is now the voltage value (where 1 V=1 micron) of the
    % PID output going to MCL. for example
    % outTotal = 5.0 + 0.031  corresponds to MCL raised 5031 nm
    % so to back off some 1000 nm requires default out to be changed from
    % 0 to 5031 - 1000
   
    
    %loop t0 change the height by a certian step size and measure PL counts
    
   z_step_size=0.005 ; %5nm 
   z_range = 2 ; %2um
  
   %the first point in 2nm from the enagage
   currentDefaultOut = outTotal-0.002;
    % set this default out and turn off the feedback
    ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],currentDefaultOut);
    ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],0);
    pause(0.1) ;
    retracted_distance = 2; %2nm
   i=1;
   
  while retracted_distance < (z_range*1000)
      
    clockFreq = 500; %Hz
    Nsamples = 50;

    mNIDAQ('CreateTask','PulseTrain2')


    mNIDAQ('ConfigureClockOut','PulseTrain2','PXI1Slot2/ctr1',clockFreq,.5,Nsamples)
    mNIDAQ('CreateTask','Counter2')
    mNIDAQ('ConfigureCounterIn','Counter2','PXI1Slot2/ctr2','/PXI1Slot2/PFI0','/PXI1Slot2/PFI13',clockFreq,Nsamples);
    mNIDAQ('StartTask','Counter2');
    mNIDAQ('StartTask','PulseTrain2')
   
    %wait till counts are aquired
    while (~mNIDAQ('IsTaskDone', 'Counter2'))        
       pause(0.1); 
    end
     
    %%read the samples from the Counter buffer
    Ncounts = mNIDAQ('GetAvailableSamples','Counter2');
    avg_counts = mean (mNIDAQ('ReadCounterBuffer','Counter2',Ncounts));
    mNIDAQ ('StopTask','PulseTrain2')
    mNIDAQ ('StopTask','Counter2')
    mNIDAQ('ClearAllTasks')
 
 
    height_data(i) = retracted_distance ; 
    PL_at_height(i) =avg_counts;
 
    currentDefaultOut = currentDefaultOut-z_step_size 
    ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],currentDefaultOut);
    retracted_distance = retracted_distance +  (z_step_size*1000);
    i=i+1;
    pause(0.1); 
  end
  
   figure;
   plot(height_data, PL_at_height)
   

   

end






