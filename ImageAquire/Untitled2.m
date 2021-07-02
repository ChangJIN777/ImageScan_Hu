global Img_handles;
global esr_handles;
global ConfcScanParm_handles;
global driftingdata 

global laser_x_handle;
global laser_y_handle;
global is_center;
pixels_x = 80;% first dicide how many pixels. This decision is made manually
pixels_y = 80;
periodregi=10;% set how frequetly at least for image registration, in seconds
iffirstrun=1;
cyclenum=2;
driftingdata=zeros(1000,10);

global ESR_pulsed_handles;

%%
handles = guidata(MyImageScan)
MyConfigScan=ConfigureScan(handles.ScanControl.ScanParameters(1),...
        str2double(get(handles.editPositionX,'String')),...
        str2double(get(handles.editPositionY,'String')),handles)
myhandles = guidata(MyConfigScan)
set(myhandles.minX,'String','-100')

import java.awt.Robot;
import java.awt.event.*;
mouse = Robot;
mouse.mouseMove(1000, 630); % relates to my personal location of open program instance
pause(1.5)
mouse.mousePress(InputEvent.BUTTON1_MASK); % actual left click press
pause(0.1);
mouse.mouseRelease(InputEvent.BUTTON1_MASK);




%%
handles = guidata(MyConfigScan)
ConfigureScanFunctions('Save',MyConfigScan,[],handles)
handles.output = handles.ConfocalScan;
% notify of a state change
close();
