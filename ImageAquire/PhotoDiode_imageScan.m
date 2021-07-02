%photodiode image scan

global Img_handles;
global esr_handles;

global laser_x_handle;
global laser_y_handle;
 global is_center;
 is_center = 0;


 Xlimits= get(Img_handles. confocalAxes,'XLim');
 Ylimits= get(Img_handles. confocalAxes,'YLim');
 
 points_X=80;
 points_Y=80;
 
                   
            
% generate xy coordinate list

x_microns= linspace(Xlimits(1), Xlimits(2), points_X);
y_microns=linspace(Ylimits(1),Ylimits(2), points_Y);


% copnvert to volta
Xvolts = x_microns/Img_handles.ScanControl.ScanParameters.micronsPerVoltX;
Yvolts = y_microns/Img_handles.ScanControl.ScanParameters.micronsPerVoltY;

 Va = Xvolts;
                Vb = Yvolts;
                %store voltage Tuples where Row# gives A position, Col#
                %gives B
                %position, and Page# is the voltage for A or B galvos
                VoltageMatrix = zeros(length(Va),length(Vb),2);

                %generate X voltages that vary in Row# but not Col#
                VoltageMatrix(:,:,1) = Va(:) * ones(1,length(Vb));
                %generate Y voltages that vary in Col# but not Row#
                VoltageMatrix(:,:,2) = ones(length(Va),1)*Vb;
                %Reverse every other X column, so each scanning position is
                %close to the next position.
                VoltageMatrix(:,2:2:end,1)=flipdim(VoltageMatrix(:,2:2:end,1),1);
                %z 2:2:end

                %reshape into an ordered list of Tuples, first column is X voltage,
                %second is Y
                VoltageTuples = reshape(VoltageMatrix,[],2,1);
                VoltageTuples=flipud(VoltageTuples)
clockFreq = 200; %Hz
Nsamples = points_X*points_Y;

mNIDAQ('CreateTask','PulseTrain2')
mNIDAQ('CreateTask','ScanVoltageOut')
mNIDAQ('CreateTask','ReadPhotodiode')

devices1 = ['PXI1Slot2/ao0',',','PXI1Slot2/ao1'];

    mNIDAQ('ConfigureClockOut','PulseTrain2','PXI1Slot2/ctr1',clockFreq,.5,Nsamples)
 
    % mNIDAQ('ConfigureVoltageOut',TaskName,Device,NLines,NVoltagesPerLine,ClockLinePhysical,ClockRate,minV,maxV,WriteVoltages);
    mNIDAQ('ConfigureVoltageOut','ScanVoltageOut',devices1,2,points_X*points_Y,'/PXI1Slot2/PFI13',200,-5,10,VoltageTuples);
   
    
   %  mNIDAQ('ConfigureVoltageIn',TaskName,Device,NLines,NVoltagesPerLine,ClockLinePhysical,ClockRateL,-10,...
    %             10,NVoltagesPerLine);
  devices2 ='PXI1Slot2/ai0'  ;
  
     mNIDAQ('ConfigureVoltageIn','ReadPhotodiode',devices2,1,points_X*points_Y,'/PXI1Slot2/PFI13',200,-10,...
                 10,points_X*points_Y);
             
             
             
   mNIDAQ('StartTask','ScanVoltageOut');
   mNIDAQ('StartTask','ReadPhotodiode');
   
   
   
   % mNIDAQ('ConfigureCounterIn','Counter2','PXI1Slot2/ctr2','/PXI1Slot2/PFI0','/PXI1Slot2/PFI13',clockFreq,Nsamples);
   % mNIDAQ('StartTask','Counter2');
    mNIDAQ('StartTask','PulseTrain2')
   
  
    %wait till counts are aquired
    while (~mNIDAQ('IsTaskDone', 'ScanVoltageOut'))        
       pause(0.1); 
    end
     
    %%read the samples from the Counter buffer
    Ncounts = mNIDAQ('GetAvailableSamples','ReadPhotodiode');
    photo_diode_V = mNIDAQ('ReadVoltageIn','ReadPhotodiode',Ncounts);
    reflected_Img1=   reshape (photo_diode_V , points_X, points_Y);
   reflected_Img1(:,2:2:end) = flipdim(reflected_Img1(:,2:2:end),1);
   figure; 
   imshow(reflected_Img1*8);
   
   
   
   
   mNIDAQ ('StopTask','PulseTrain2')
    mNIDAQ ('StopTask','ScanVoltageOut')
    mNIDAQ ('StopTask','ReadPhotodiode')
    
    mNIDAQ('ClearAllTasks')
 
 
  
   

   

