function DEER_vary_SRS_freq()
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

numb_repeats = 10;

DEERfreq = [linspace(1008.6,1108.6,21),linspace(1008.6,1108.6,21),linspace(1008.6,1108.6,21),linspace(1008.6,1108.6,21),linspace(1008.6,1108.6,21),linspace(1008.6,1108.6,21),linspace(1008.6,1108.6,21)] ; %NVH12, 5/31, 90 uW

for freq = DEERfreq;

set(esr_handles.centerFreqB,'String',num2str(freq));
ESRControl('buttonStartSequence_Callback',0,0,esr_handles); %Start current ESR sequence


        % be sure this is not skipped
        while ( get(esr_handles.writeDataFreq,'UserData') == 1)
                    'while loop for not skipping esrcontrol'
            pause(0.5); 
        end
        'ended past ESRControl and while loop enable'
 
end

end