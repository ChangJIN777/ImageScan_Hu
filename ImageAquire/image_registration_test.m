  
 % scan parameters
scan_size_x = 0.05;
   scan_size_y = 0.05;
   afm_scan_x_points_numb = 50;
   afm_scan_y_points_numb = 50;
   
   x_pixel_volts = scan_size_x/afm_scan_x_points_numb;
   y_pixel_volts = scan_size_y/afm_scan_y_points_numb;


initial_scan=importdata('C:/AFM/scans/8043/008043.scan');


% initial image
initial_image_x= initial_scan(:,1);
initial_image_y = initial_scan(:,2);
initial_image_z = initial_scan(:,4);
initial_image_PL = initial_scan(:,7);



    
   second_scan=importdata('C:/AFM/scans/8044/008044.scan');

    
   second_image_x= second_scan(:,1);
   second_image_y = second_scan(:,2);
   second_image_z = second_scan(:,4);
   second_image_PL = second_scan(:,7);
 
    %%convert the image 
   for jx = 0:(afm_scan_x_points_numb-1)
       for jy =0:(afm_scan_y_points_numb-1)
           
           initial_im_Z(jx+1,jy+1) = initial_image_z(jx*afm_scan_x_points_numb+jy+1);
           second_im_Z(jx+1,jy+1) = second_image_z(jx*afm_scan_x_points_numb+jy+1);
           
           initial_im_PL(jx+1,jy+1) = initial_image_PL(jx*afm_scan_x_points_numb+jy+1);
           second_im_PL(jx+1,jy+1) = second_image_PL(jx*afm_scan_x_points_numb+jy+1);
                    
       end
   end
  
  %%perform image reg with topo images
  [abc,def] = dftregistration(fft2(initial_im_Z), fft2(second_im_Z), 20); 
  
% 'drift in x is'
  drift_tip_x = abc(3);
%'the drift in y is'
  drift_tip_y = abc(4);
  
   %%convert pixel dirfts to nm
   % conversion between volts and distance: 1V is 10um
  
 
   
   drift_V_x= x_pixel_volts*drift_tip_x ;
   drift_V_y= y_pixel_volts*drift_tip_y;
 
   'drift based on topo images'
 drift_nm_x = drift_V_x*10000
 drift_nm_y = drift_V_y*10000
   
   %%perform image reg with PL images
  [abc,def] = dftregistration(fft2(initial_im_PL), fft2(second_im_PL), 20); 
  
% 'drift in x is'
  drift_tip_x = abc(3);
%'the drift in y is'
  drift_tip_y = abc(4);
  
   %%convert pixel dirfts to nm
   % conversion between volts and distance: 1V is 10um
  
   
   drift_V_x= x_pixel_volts*drift_tip_x ;
   drift_V_y= y_pixel_volts*drift_tip_y;

   'drift based on PL images'
 drift_nm_x = drift_V_x*10000
 drift_nm_y = drift_V_y*10000