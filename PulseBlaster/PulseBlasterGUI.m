function PulseBlasterGUI()
%written by William Patterson for SpinCore Technologies Inc. 
%Modified by Song Kui for SpinCore Technologies Inc to adapt to SpinAPI version 20170111
%this is just a standard nam function that points to PulseBlaster_GUI_vX_X
%PulseBlaster_GUI_vX_X is found in the directory /GUI_Files

if (exist('C:\Users\user\Documents\Chang\ImageScan_GUI\ImageScan_Hu', 'dir') == 7)
    addpath('C:\Users\user\Documents\Chang\ImageScan_GUI\ImageScan_Hu\PulseBlaster\SpinAPI\GUI_Files');
else
    error('Cannot find ./SpinAPI/GUI_Files');
end

global SPINAPI_DLL_NAME;
global SPINAPI_DLL_PATH;
global CLOCK_FREQ;

CLOCK_FREQ = 500;

SPINAPI_DLL_PATH = 'C:\SpinCore\SpinAPI\lib\';
SPINAPI_DLL_NAME = 'spinapi64';


PulseBlasterGUI_v1_1();