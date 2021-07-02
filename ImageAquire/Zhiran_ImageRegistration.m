%%Image registration during scanning usuing Confocal images taken in series.
%Don't stop the program while doing confocal scanning.

pixels_x = 200;%first dicide how many pixels. This decision is made manually
pixels_y = 200;
periodregi=3600;%set how frequetly for image registration, in seconds
%ImageScan GUI's handle, got from the last line in ImageScan.m's opening
%fucntion.
global Img_handles;
%call out the Setup Scan GUI to adjust the scanning parameters easily
ConfigureScan(Img_handles.ScanControl.ScanParameters(1),...
    str2double(get(Img_handles.editPositionX,'String')),...
    str2double(get(Img_handles.editPositionY,'String')),Img_handles);
global ConfcScanParm_handles;
iffirstrun=1;
cyclenum=0;
driftingdata=zeros(1000,4);
while 1
    'pause start'
    pause(100);
    'pause stop'
    nowclock=clock;
    if iffirstrun==1 || etime(nowclock,previousclock)> periodregi
        ConfcScanParm_handles.ConfocalScan.NPoints=[pixels_x,pixels_y,2];
        
        'Confocal parameters changed.'
        if iffirstrun==0
            close(RegistrationFig);
        end
        RegistrationFig=figure; hold on
        %Turn on the green AOM by using ImageScan's handles, and commend
        %Pulseblaster by using PulseInterpreter class's functions.
        Img_handles.PulseInterpreter.setCurrentPulse([Img_handles.configS.sequenceFolder 'bit_red.txt']); %Turn on red laser. Make sure this is red.
        Img_handles.PulseInterpreter.loadToPulseblaster();
        Img_handles.PulseInterpreter.runPulse();
        %Then also set the ImageScan's button to correct state if using
        %green laser.
        %set(Img_handles.buttonAOMOn, 'String', 'Turn AOM Off');
        
        %Get a confocal scan image.
        Img_handles = guidata(Img_handles.buttonStartStopScan);
        if Img_handles.StateControl.state == Img_handles.StateControl.SCANNING
            Img_handles.StateControl.changeToIdleState(Img_handles);
        else
            Img_handles.StateControl.changeToScanningState(Img_handles);
        end
        
        Img_handles.PulseInterpreter.stopPulse();
        %set(Img_handles.buttonAOMOn, 'String', 'Turn AOM On');
        
        'One confocal scan finished.'
        hold off
        
        if iffirstrun==1 %get the information for the very first scan
            FilePath=get(Img_handles.inputSaveImagePath,'String');
            FirstFileNum=get(Img_handles.inputSaveImageFileNum,'String');
        else
            NewFileNum=get(Img_handles.inputSaveImageFileNum,'String');
        end
        
        % Run the registration algorism, and move the sample.
        if iffirstrun==0
            %Also get the information of the confocal image at the beginning
            cd('C:\Users\lab\Documents\MATLAB\ImageScan\ImageAquire\ConfocalImageRegistration');
            image_name1= ['image_',FirstFileNum,'.txt'];
            confocal_image = flipud(import_200by200confocalscan([FilePath,image_name1])); %If image size changed, manually change the loading script.
            
            image_name2= ['image_',NewFileNum,'.txt'];
            confocal_image = flipud(import_200by200confocalscan([FilePath,image_name2]));%If image size changed, manually change the loading script.

            A=importfile_X([FilePath,image_name1]);
            MinX= A(1);
            MaxX= A(2);
            A=importfile_Y([FilePath,image_name1]);
            MinY= A(1);
            MaxY= A(2);
            
            nm_per_pixel_y = 1000*(MaxY - MinY)/pixels_y;
            nm_per_pixel_x = 1000*(MaxX - MinX)/pixels_x;
            
            confocal_image1 = flipud(import_200by200confocalscan([FilePath,image_name1]));%If image size changed, manually change the loading script.
            confocal_image2 = flipud(import_200by200confocalscan([FilePath,image_name2]));%If image size changed, manually change the loading script.
            
            [abc,def] = dftregistration(fft2(confocal_image1), fft2(confocal_image2), 20); %This function is adpated from other researchers, see the file
            drift_tip_x = nm_per_pixel_x*abc(4)
            drift_tip_y = nm_per_pixel_y*abc(3)
            cyclenum=cyclenum+1;
            %driftingdata(cyclenum,1)=NewFileNum; %record the corresponding image number
            driftingdata(cyclenum,2)=drift_tip_x; %record the drifting x
            driftingdata(cyclenum,3)=drift_tip_y; %record the drifting y
            %Then if the drifting is bigger than... then move the sample back.
            %Then engage, and record the Zurich output.
            %driftingdata(cyclenum,4)=; %record the drifting z
            %Then retract a certain amount of distance.
            %and get another confocal image to check whether the sample is
            %really back, if not move again...
            
        end
        previousclock=clock; %record the time of previous registration.
    end
    iffirstrun=0;
    'One cycle finished'
    %%
    
end