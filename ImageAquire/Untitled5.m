function [  ] = Untitled5(  )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

global Img_handles
global esr_handles 
global ESR_pulsed_handles;


%Img_handles.PulseInterpreter.stopPulse();
%set(Img_handles.buttonAOMOn, 'String', 'Turn AOM On');
%set(Img_handles.buttonAOMOn, 'Value', 1) ;

Img_handles.PulseInterpreter.setCurrentPulse([Img_handles.configS.sequenceFolder 'bit1_on.txt']);
Img_handles.PulseInterpreter.loadToPulseblaster();
Img_handles.PulseInterpreter.runPulse();
set(Img_handles.buttonAOMOn, 'String', 'Turn AOM off');
set(Img_handles.buttonAOMOn, 'Value', 0);
pause(0.1)

ESR_pulsed_handles.gesr.RunSingleTrackPulsedESR(ESR_pulsed_handles.imageScanHandles);


'amila'

if get(Img_handles.buttonAOMOn, 'Value') == true
%Img_handles.PulseInterpreter.setCurrentPulse([Img_handles.configS.sequenceFolder 'bit1_on.txt']);
%Img_handles.PulseInterpreter.loadToPulseblaster();
%Img_handles.PulseInterpreter.runPulse();
%set(Img_handles.buttonAOMOn, 'String', 'Turn AOM off');
%set(Img_handles.buttonAOMOn, 'Value', 0);
 else
%Img_handles.PulseInterpreter.stopPulse();
%set(Img_handles.buttonAOMOn, 'String', 'Turn AOM On');
%set(Img_handles.buttonAOMOn, 'Value', 1) ;
 end
       
   
end

