%test code by Amila to read counts from the APD

Nsamples = 10000;

mNIDAQ('CreateTask','PulseTrain2')


clockFreq = 1000; %Hz

mNIDAQ('ConfigureClockOut','PulseTrain2','PXI1Slot2/ctr1',clockFreq,.5,Nsamples)



mNIDAQ('CreateTask','Counter2')

mNIDAQ('ConfigureCounterIn','Counter2','PXI1Slot2/ctr2','/PXI1Slot2/PFI0','/PXI1Slot2/PFI13',clockFreq,Nsamples);

 mNIDAQ('StartTask','Counter2');
 
 mNIDAQ('StartTask','PulseTrain2')

 
%%read the samples from the Counter buffer
 while (~mNIDAQ('IsTaskDone', 'Counter2'))        
       pause(0.1); 
    end
 Ncounts = mNIDAQ('GetAvailableSamples','Counter2');
 
 PL_counts_raw = mNIDAQ('ReadCounterBuffer','Counter2',Ncounts) ;
 
PL_counts = diff(PL_counts_raw) ; 
 
 

 
 
 mNIDAQ ('StopTask','PulseTrain2')
 
  mNIDAQ ('StopTask','Counter2')
  
  mNIDAQ('ClearAllTasks')
  

 figure; 
  plot(PL_counts)
  'mean counts :'
  mean(PL_counts)
  
  'squareroot of mean :'
  sqrt(mean(PL_counts))
  
  'standard deviation of counts'
  std(PL_counts)