function Echo_varyWaitTime()
%we want to measure number of photons from 0 for a given readout
%time, then repeat the process immediately for the -1 state. 

%SNR = (Number measured from 0 - Number measured from -1) / sqrt(Number
%measured from 0 + Number measured from 1)
%This yields the biggest measurable difference between the 0 and -1 state,
%which correponds to the best measurement we can make.

%Make GUI where you can set range of readout times and number of points in
%the curve, and then have it plot the curve realtime.

firstTauCmd = 'divideBy2';
secondTauCmd = 'yMinusFirst';

global Scan_Finished_Flag
global Img_handles;
global esr_handles;

global laser_x_handle;
global laser_y_handle;

global ESR_pulsed_handles;

numb_repeats = 8;

waitTime = [30000, 10000, 250000, 150000, 18000, 1000, 80000, 50000, 2000, 90000, 130000, 170000, 220000, 22000, 28000, 4000, 3000, 180000, 400000,30000, 10000, 250000, 150000, 18000, 1000, 80000, 50000, 2000, 90000, 130000, 170000, 220000, 22000, 28000, 4000, 3000, 180000, 400000,30000, 10000, 250000, 150000, 18000, 1000, 80000, 50000, 2000, 90000, 130000, 170000, 220000, 22000, 28000, 4000, 3000, 180000, 400000,30000, 10000, 250000, 150000, 18000, 1000, 80000, 50000, 2000, 90000, 130000, 170000, 220000, 22000, 28000, 4000, 3000, 180000, 400000,30000, 10000, 250000, 150000, 18000, 1000, 80000, 50000, 2000, 90000, 130000, 170000, 220000, 22000, 28000, 4000, 3000, 180000, 400000,30000, 10000, 250000, 150000, 18000, 1000, 80000, 50000, 2000, 90000, 130000, 170000, 220000, 22000, 28000, 4000, 3000, 180000, 400000,30000, 10000, 250000, 150000, 18000, 1000, 80000, 50000, 2000, 90000, 130000, 170000, 220000, 22000, 28000, 4000, 3000, 180000, 400000,30000, 10000, 250000, 150000, 18000, 1000, 80000, 50000, 2000, 90000, 130000, 170000, 220000, 22000, 28000, 4000, 3000, 180000, 400000]

for wait = waitTime;

set(esr_handles.depopulationTime,'String',num2str(wait));
ESRControl('buttonStartSequence_Callback',0,0,esr_handles); %Start current ESR sequence


        % be sure this is not skipped
        while ( get(esr_handles.writeDataFreq,'UserData') == 1)
                    'while loop for not skipping esrcontrol'
            pause(0.5); 
        end
        'ended past ESRControl and while loop enable'
 
end

end