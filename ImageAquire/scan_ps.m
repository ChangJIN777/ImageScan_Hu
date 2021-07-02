function scan_ps( )

%Routine for taking a scan with a pulse sequence at each point, with
%tracking after each point

global Img_handles;
global esr_handles;

global laser_x_handle;
global laser_y_handle;
 global is_center;
 is_center = 0;
%Generate a list of points to measure

x_size = 10; %Dimensions of scan area in nm
y_size = 1000;

nx = 1; %Number of points along each axis
ny = 100;

%x = linspace(-x_size/2,x_size/2,nx)-571
%y = linspace(-y_size/2,y_size/2,ny)-0

x = ones(100)*(-576);
y = ones(100)*(0);


%Get original image for tracking
global ESR_pulsed_handles;
ESR_pulsed_handles.PerformImageRegistration(0,1);

for i=1:nx
    for j=1:ny
        
        %Run tracking to center the laser and tip on the NV
      
          
                global curr_center_x;
                global curr_center_y;
               
                
                if is_center==1
                    'y'
                     mDAC('tip_tracking',curr_center_x,curr_center_y); 
                end
                
                
                % For this tip tracking scan, the scan size corresponds to
                % what is set on the test_gui at the start, as it is just
                % calling 'start_scan'
                laser_x = str2double(get(laser_x_handle,'String'));
                laser_y = str2double(get(laser_y_handle,'String'));
                mDAC('start_scan',laser_x,laser_y);
                
                %center = tip_tracking() %Gets data from current_scan.scan file in AFM file system directory
                
                pause(1);
                while mDAC('is_scan') == 1 %Wait for scan to end
                   pause(1);    
                end
                center = [0 0 0];
                %Find center
                try
                     center = tip_tracking(0) %Gets data from current_scan.scan file in AFM file system directory
                catch
                    center = [curr_center_x curr_center_y 0];
                end
                offset = [0.0 0]%offset in volts
                if(center(3) <= 0.02) %track only if motion is less than 200 nm
                    curr_center_x = center(1);
                    curr_center_y = center(2);
                    is_center = 1;
                    mDAC('tip_tracking',center(1)-offset(1),center(2)-offset(2)); %Move tip center and reset scan center to be new center
                else
                    'Error: tracking outside range'
                end

        ESR_pulsed_handles.PerformImageRegistration(0,0);
 
 
         %Offset the laser and the tip to the measurement position
        mDAC('move_tip_laser',x(i),y(j),str2double(get(laser_x_handle,'String')), str2double(get(laser_y_handle,'String')) );

   
        %Run the pulse sequence
        ESRControl('buttonStartSequence_Callback',0,0,esr_handles); %Start current ESR sequence
    
        %Parse the data from the pulse sequence
        path1 = get(esr_handles.esrSavePath,'String');
        path2 = get(esr_handles.esrSaveFilePrefix,'String');
        path3 = get(esr_handles.esrSaveFileNum,'String');

        filepath1 = [path1 path2 path3 '\' path2 path3 '_1_0.txt'];
        filepath2 = [path1 path2 path3 '\' path2 path3 '_2_0.txt'];

        

        d1 = importdata(filepath1);
        d2 = importdata(filepath2);


        %Save the measurement position, measured center, pulse sequence data
        
        filepath_save = [path1 '\' path3 '.scan'];
        
        % two tau points per file
       output = [x(i) y(j) d1.data(1,2) d1.data(1,3) d1.data(2,2) d1.data(2,3) d2.data(1,2)  d2.data(1,3) d2.data(2,2)  d2.data(2,3) center(1) center(2) center(3)];
       dlmwrite(filepath_save,output,'-append');

   end
end

end

