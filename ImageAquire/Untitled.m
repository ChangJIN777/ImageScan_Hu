 %Device = 'PXI1Slot3/ai3'
Device = 'PXI1Slot3'
 %NLines=10;
 
% NVoltagesPerLine=20;
% ClockLinePhysical=200;
% ClockRateL=1000;
 
% mNIDAQ('CreateTask','TiltreadX');
 
  
  
%  mNIDAQ('ConfigureVoltageIn','TiltreadX',Device,NLines,NVoltagesPerLine,ClockLinePhysical,ClockRateL,-10,...
   %              10,NVoltagesPerLine)
             
   %           mNIDAQ('StartTask','TiltreadX')
  % pause(1)
    
%   mNIDAQ('ReadVoltageIn','TiltreadX',3)
  %  
%   mNIDAQ('GetAvailableSamples', 'TiltreadX')
 %    mNIDAQ('ClearTask','TiltreadX');
 
 mydaq = daq.createSession ('ni')
 
 mydaq.addAnalogInputChannel (Device, 3:4, 'Voltage') 
 mydaq.Rate= 1000
 mydaq.NumberOfScans = 1000
 
 mydaq.inputSingleScan
 
 
 pause(1)

 removeChannel(mydaq, 1)