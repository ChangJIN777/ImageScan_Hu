global ESR_pulsed_handles;
global AFMpulseCounter;
AFMpulseCounter = 0;

ESR_pulsed_handles.PerformImageRegistration(0,1);

% this will save an image to be used for the (0,0) call to the function
% during a measurement.

%ESR_pulsed_handles.gesr.RunSingleTrackPulsedESR(ESR_pulsed_handles.imageScanHandles)