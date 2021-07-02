function approach_pid( )
%approach_pid
%   09/16/15
global Img_handles;
% approach steps:
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
    pause(0.2); % not necessary to pause but could be useful

    if (~isApproached)
        %3) now shift at its maximum allowed
        % we didn't hit the surface so turn off PID 
        %4)
        currentDefaultOut=0.0;
        ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],currentDefaultOut);
        ziDAQ('setInt',['/',zdevice,'/PIDS/0/OUTPUTDEFAULTENABLE'],1);
        ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],0);
        pause(1); % give it a moment to be safely at 0.

        %5) step the DAC up 
        % need to first query with some new mDAC function
        % the _DAC.z_in_current value.
        mDAC('z_in_relative_approach',DACzStep);

        %6,7
        % at this point either the DAC has stepped up and we restart the PID or the
        % DAC has reset to the bottom and we stepped up the micronix, this is all
        % done in the mDAC function in C++, so either way the next thing is to
        % retart the PID!
        pause(1);
    end
end

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
    outTotal = mean(outSamples);% so outTotal is now the voltage value (where 1 V=1 micron) of the
    % PID output going to MCL. for example
    % outTotal = 5.0 + 0.031  corresponds to MCL raised 5031 nm
    % so to back off some 1000 nm requires default out to be changed from
    % 0 to 5031 - 1000
    currentDefaultOut = outTotal-finalRetractStep;
    'retracted by safe amount default out'

    % set this default out and turn off the feedback
    ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],currentDefaultOut);
    ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],0);

end


