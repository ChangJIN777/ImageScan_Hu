  %grab the image from scan
    
    
   initial_scan=importdata('C:/AFM/scans/7505/007505.scan');
  
   initial_image_x= initial_scan(:,1);
   initial_image_y = initial_scan(:,2);
   initial_image_z = initial_scan(:,4);

   second_scan=importdata('C:/AFM/scans/7506/007506.scan');

    
   second_image_x= second_scan(:,1);
   second_image_y = second_scan(:,2);
   second_image_z = second_scan(:,4);

 
   afm_scan_x_points_numb =80;
   afm_scan_y_points_numb =80;
   scan_size_x = 0.04;
   scan_size_y = 0.04;
   
   
    %%convert the image 
   for ix = 0:(afm_scan_x_points_numb-1)
       for iy =0:(afm_scan_y_points_numb-1)
           initial_im(ix+1,iy+1) = initial_image_z(ix*afm_scan_x_points_numb+iy+1);
           second_im(ix+1,iy+1) = second_image_z(ix*afm_scan_x_points_numb+iy+1);
       end
   end
  
  %%perform image reg
  [abc,def] = dftregistration(fft2(initial_im), fft2(second_im), 20); 
  
 'drift in x is'
  drift_tip_x = abc(3)
'the drift in y is'
  drift_tip_y = abc(4)
  
   %%convert pixel dirfts to nm
   % conversion between volts and distance: 1V is 10um
  
   
   x_pixel_volts = scan_size_x/afm_scan_x_points_numb;
   y_pixel_volts = scan_size_y/afm_scan_y_points_numb;
   
   drift_V_x= x_pixel_volts*drift_tip_x ;
   drift_V_y= y_pixel_volts*drift_tip_y;
   
 drift_nm_x = drift_V_x*10000;
 drift_nm_y = drift_V_y*10000;
   

  
  
   %% now incremnt x , y to new drifted points
   %mDAC ('move_tip_laser',drift_nm_x,drift_nm_y,0,0);
   drift_nm_x
   drift_nm_y