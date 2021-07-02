function ret = scan_pulse_seq( )
%SCAN_PULSE_SEQ Summary of this function goes here
%   Detailed explanation goes here
    
%mDAC('z_in',7) % to fix the piezo height at a given point. so this value
%can be changed in the middle of a scan process
% or check 'z_in_fast' in new mDAC file if an immediate z change is needed
global esr_handles;
    ESRControl('buttonStartSequence_Callback',0,0,esr_handles); %Start current ESR sequence
    
    % extract the data from the saved files from ESRControl
    path1 = get(esr_handles.esrSavePath,'String');
    path2 = get(esr_handles.esrSaveFilePrefix,'String');
    path3 = get(esr_handles.esrSaveFileNum,'String');
    
    % 1, and 2 file paths for the typical 2 counter pulse sequences
    filepath1 = [path1 path2 path3 '\' path2 path3 '_1_0.txt'];
    filepath2 = [path1 path2 path3 '\' path2 path3 '_2_0.txt'];
    
    d1 = importdata(filepath1);
    d2 = importdata(filepath2);
    
    %data(2) is signal, data(3) is reference,
    % so this returns the sig-ref averaged over d1 and d2 data.
    % I may want to change this to generalize. 
    ret = ((d1.data(2) - d1.data(3)) + (d2.data(2) - d2.data(3)))/2;

end

