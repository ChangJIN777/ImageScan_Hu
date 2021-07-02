function out = perform_confocal_tilt_measure()

%code to perform line scan in X or Y and measure focus

global Img_handles;
global esr_handles;
global laser_x_handle;
global laser_y_handle;
global is_center;
is_center = 0;



 clockFreq = 500; %Hz
    Nsamples = 100;

    
    for i =1:200
    
    mNIDAQ('CreateTask','PulseTrain2')


    mNIDAQ('ConfigureClockOut','PulseTrain2','PXI1Slot2/ctr1',clockFreq,.5,Nsamples)
    mNIDAQ('CreateTask','Counter2')
    mNIDAQ('ConfigureCounterIn','Counter2','PXI1Slot2/ctr2','/PXI1Slot2/PFI0','/PXI1Slot2/PFI13',clockFreq,Nsamples);
    mNIDAQ('StartTask','Counter2');
    mNIDAQ('StartTask','PulseTrain2')
   
    %wait till counts are aquired
    while (~mNIDAQ('IsTaskDone', 'Counter2'))        
       pause(0.1); 
    end
     
    %%read the samples from the Counter buffer
    Ncounts = mNIDAQ('GetAvailableSamples','Counter2');
    avg_counts = mean (mNIDAQ('ReadCounterBuffer','Counter2',Ncounts))
    mNIDAQ ('StopTask','PulseTrain2')
    mNIDAQ ('StopTask','Counter2')
    mNIDAQ('ClearAllTasks')


    zscan_data (i) =avg_counts;
    
Img_handles.CursorControl.updatePositionFromEdit(Img_handles,Img_handles.editPositionZ,3,0.02);
pause(0.1);

    end
    



figure;
plot(1:200,zscan_data)

out = zscan_data;
















end
