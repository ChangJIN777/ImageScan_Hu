function [ ret1, ret2, ret3, ret4, ret5 ] = scan_pulse_seq_nchan(  ) %( numDataChan)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

% return array size depends on number of channels of matlab data collected
% as specified in the scan.h variable "num_matlab_chan", initialized in
% scan.cpp constructor.
% matlab_data is dynamically allocated in scan::scan_line_sequence to the 
% size required by num_matlab_chan

%mDAC('z_in',7) % to fix the piezo height at a given point. so this value
%can be changed in the middle of a scan process
% or check 'z_in_fast' in new mDAC file if an immediate z change is needed

    global esr_handles;
    
    % tip scan routine here
    % 0) temporarily turn off the scan_pulse_Seq flag to enter the
    % scan_line_smooth function
    % 1) take a smooth line scan at the middle of the scan range or the
    % current line by calling the scan_line_smooth function without the
    % part that saves the data to the z piezo channel (or it's okay if it
    % does) The middle scan line may have to be taken because for example
    % the edge scan line cannot see a negative shift in Y since it wasn't
    % part of the original topographic image unless the original image is
    % of a larger scan area. But the filtered image also has a particular
    % center which depends on the points included in the plane fit.
    % 2) compare this scan line to the topographic image taken at the
    % start. The challenge is with the Z height correlations, which will
    % give the Y axis shift. I want to use the filtered image so that slow
    % drifts in the MCL position do not affect this Z correlation
    % 3) The Offset in X will supply the X shift since the whole line is
    % taken
    %Get original image for tracking
    global ESR_pulsed_handles;
    global AFMpulseCounter;
    AFMpulseCounter = AFMpulseCounter+1
    %track every 5 steps
    if (mod(AFMpulseCounter,6)==0)
        ESR_pulsed_handles.gesr.RunSingleTrackPulsedESR(ESR_pulsed_handles.imageScanHandles);
       ESR_pulsed_handles.PerformImageRegistration(0,0);
    end
    

    ESRControl('buttonStartSequence_Callback',0,0,esr_handles); %Start current ESR sequence
    
    % extract the data from the saved files from ESRControl
    path1 = get(esr_handles.esrSavePath,'String');
    path2 = get(esr_handles.esrSaveFilePrefix,'String');
    path3 = get(esr_handles.esrSaveFileNum,'String');
    % 1, and 2 file paths for the typical 2 counter pulse sequences
    
    % for every signal channel of the sequence, there is 1 file to read in
    % containing a sig and ref.
    filepath1 = [path1 path2 path3 '\' path2 path3 '_1_0.txt'];
    filepath2 = [path1 path2 path3 '\' path2 path3 '_2_0.txt'];
    
    
    %-------- output the return data to C++ function-------
    numc = 0;
    numDataChan=4;
    if numDataChan<=2
        d1 = importdata(filepath1);
        celld = {d1};
        numc=1;
    elseif numDataChan<=4
        d1 = importdata(filepath1);
        d2 = importdata(filepath2);
        celld = {d1,d2};
        numc=2;
    end
    
    returnArray = zeros(numDataChan,1);
    % this assumes that the data has 4 columns (2tau,sig,ref,norm) and only
    % 1 row (row is for numtau points but there is only 1 tau point)
    % if I need to do something with more tau points just get from
    % different rows, e.g., data(2,2) data(3,2), etc...
    for c=1:numc 
        returnArray(2*c-1,1) = celld{c}.data(1,2);
        returnArray(2*c,1) = celld{c}.data(1,3); 
    end
    ret1 = returnArray(1);
    ret2 = returnArray(2);
    ret3 = returnArray(3);
    ret4 = returnArray(4);
    % r1=sig_pi, r2=ref_pi, r3=sig_0, r4=ref_0
    %ret5 = (returnArray(3)-returnArray(1))/(returnArray(4)-returnArray(2));
    %ret5 = 0.5*(returnArray(4)-returnArray(3))/returnArray(4) + 0.5*(returnArray(2)-returnArray(1))/returnArray(2); % should be a positive number here.
    ret5 = (returnArray(2)-returnArray(1))/(returnArray(4)-returnArray(3));
    % --------------------------------------------------------
end


