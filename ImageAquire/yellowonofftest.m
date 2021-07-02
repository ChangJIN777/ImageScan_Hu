%%turn on off yellow laser

global Img_handles;
global esr_handles;
global ESR_pulsed_handles;



turnonlaser =0;

if turnonlaser ==1
        %Img_handles.PulseInterpreter.setCurrentPulse([Img_handles.configS.sequenceFolder 'bit10and11_on.txt']);
        Img_handles.PulseInterpreter.setCurrentPulse([Img_handles.configS.sequenceFolder 'bit11_on.txt']);
        Img_handles.PulseInterpreter.loadToPulseblaster();
        Img_handles.PulseInterpreter.runPulse();
        
        
        pause(0.1)
end


if turnonlaser == 0
    
      
       
        %turn off AOM 
        Img_handles.PulseInterpreter.stopPulse();
       
end
