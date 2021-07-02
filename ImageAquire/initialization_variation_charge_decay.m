function initialization_variation_charge_decay()
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

numb_repeats = 5;

%initialization = [11000,18000,10000,15000,9000,12000,20000,16000,24000,14000,17000,5000,22000,7000,13000];
%initialization = [11000,29000,27000,17000,31000,15000,9000,19000,21000,17000,5000,33000,23000,7000,13000,25000,35000];
%initialization = [37000,39000,41000,43000,45000,47000,49000,51000,53000,55000,57000,59000,61000,66000,71000,76000,81000,86000,91000,100000];
%initialization = [39000,86000,37000,59000,71000,47000,61000,91000,81000,49000,76000,55000,100000,43000,45000,41000,53000,51000,57000,66000,37000,39000,41000,43000,45000,47000,49000,51000,53000,55000,57000,59000,61000,66000,71000,76000,81000,86000,91000,100000];
%initialization = [27000,23000,26000,19000,25000,21000];
%initialization = [1000,5000,7000,9000,13000,17000,21000,25000,31000];
%initialization = [25000,1000,31000,21000,7000,13000,17000,5000,9000]; 4/5
%initialization = %[10000,4000,8000,6000,2000]; 4/5
%initialization = [3000,25000,1000,31000,21000,7000,13000,17000,5000,9000,50000,10000,4000,8000,6000,2000];%4/5,  225 uW complete ordered list

%initialization = [3000,25000,1000,31000,21000,7000,13000,17000,5000,9000,50000];%4/5,  83 uW
%initialization =
%[3000,25000,1000,31000,21000,7000,13000,17000,5000,9000,50000, 120000, 90000, 40000, 100000, 11000, 160000, 80000, 60000, 70000, 28000, 110000, 200000, 10000,4000,8000,6000,2000, 65000, 55000, 45000, 75000, 105000]; %4/5, 83 uW 
%initialization = [500000, 200000, 10000, 100000, 300000, 3000, 50000, 400000, 50000, 80000, 150000, 20000, 250000, 30000]; %37 uW, 4/7
%initialization = [500000, 200000]; %37 uW, 4/7
%initialization = [10000, 100000, 3000, 50000, 150000, 80000, 20000, 30000, 120000, 70000]; 
%initialization = [250000, 380000, 300000, 40000, 60000, 14000, 600000];

%initialization = [500000, 200000, 10000, 100000, 3000, 50000, 150000, 80000, 20000, 30000, 120000, 70000, 250000, 380000, 300000, 40000, 60000, 14000, 600000]; %37 uW, 4/7 complete ordered list.

%initialization = [1000, 1500, 2000, 2500, 3000, 3500, 4000, 5000, 6000, 7000, 8000, 9000, 10000, 11000, 12000, 13000, 15000, 17000, 20000, 23000, 26000, 29000, 34000, 39000, 44000, 49000]

%initialization = [15000, 6000, 2500, 8000, 4500, 10000, 17000, 3000,
%26000, 2000, 4000, 23000, 3500, 13000, 20000, 24000, 11000, 7000, 6500,
%1000, 9000, 1250, 1500, 5000, 7500, 8500, 12000, 5500, 16000]; %310 uW,
%4/7, complete ordered list

%initialization = [12000, 2000, 7000, 500, 750, 1000, 2500, 1250, 3500, 1500, 3000, 5000, 6000, 4000, 8000, 4500, 9000, 10000, 11000, 13000,16000, 20000, 25000];]; %490 uW, 4/8

%initialization = [2000000, 800000, 40000, 400000, 12000, 200000, 600000, 320000, 80000, 120000, 480000, 280000, 1000000, 1520000, 1200000]; %14 uW, 4/9

initialization = [100:20:160, 180:40:500, 550:100:1850, 2000:200:4000, 4500:500:20000]; %NVH12, 5/31, 90 uW

for init = initialization;

    if init <= 300
        set(esr_handles.repsPerTau,'String',3000);
    elseif (init > 300) && (init <= 800)
        set(esr_handles.repsPerTau,'String',2000);
    elseif init > 800
        set(esr_handles.repsPerTau,'String',1000);
    end
    
set(esr_handles.initTime,'String',num2str(init));
ESRControl('buttonStartSequence_Callback',0,0,esr_handles); %Start current ESR sequence


        % be sure this is not skipped
        while ( get(esr_handles.writeDataFreq,'UserData') == 1)
                    'while loop for not skipping esrcontrol'
            pause(0.5); 
        end
        'ended past ESRControl and while loop enable'
 
end

end