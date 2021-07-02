function  ret = tip_tracking(is_first)
%Only Ch0,Ch7 should be selected during the scan

current_scan=importdata('C:/AFM/scans/7209/007209.scan');
global z_original;

[row,col] = size(current_scan);
if col~=8
    error('Error: Wrong number of channels for tracking AFM scan');
   ret = 0;
   return;
end

        
if is_first==1
    n = 200;
   % n=20;
    % this is the first scan that it is comparing it to each pixel,
    % manually changed
    %current_scan=importdata('C:/AFM/scans/5951/005951.scan');
    current_scan = importdata('C:/AFM/scans/7209/007209.scan');
    x = linspace(min(current_scan(:,1)),max(current_scan(:,1)),n);
    y = linspace(min(current_scan(:,2)),max(current_scan(:,2)),n)';
    
    z = griddata(current_scan(:,1),current_scan(:,2),current_scan(:,7),x,y,'cubic');
    zb = griddata(current_scan(:,1),current_scan(:,2),current_scan(:,8),x,y,'cubic');
 
     xcenter = mean(x);
        ycenter = mean(y);
        
        z_original = z;
        filt = (fspecial('gaussian', 20,2));
        figure; imagesc(x,y,z);
        z1 = medfilt2(z);

        z2 = conv2(z1,filt,'same');
        figure; imagesc(x,y,z2);
        z3 = imregionalmax(mat2gray(z2),8);
        figure; imagesc(x,y,z3);

        figure; imagesc(x,y,zb);
        zb1 = medfilt2(zb);
        %filt = (fspecial('gaussian', 10,2));
        zb2 = conv2(zb1,filt,'same');
        figure; imagesc(x,y,zb2);
        zb3 = imregionalmax(mat2gray(zb2),8);
        figure; imagesc(x,y,zb3);


        xmax = [];
        ymax = [];

        for i=1:length(x)
           for j=1:length(y)
               if z3(j,i) == 1
                  xmax = [xmax x(i)];
                  ymax = [ymax y(j)];
               end
           end
        end

        xmaxb = [];
        ymaxb = [];

        for i=1:length(x)
           for j=1:length(y)
               if zb3(j,i) == 1
                  xmaxb = [xmaxb x(i)];
                  ymaxb = [ymaxb y(j)];
               end
           end
        end

        %return the point closest to the center (previous tip position)

       

        dist = sqrt((xmax - xcenter).^2 + (ymax - ycenter).^2);
        [val, I] = min(dist);

        distb = sqrt((xmaxb - xcenter).^2 + (ymaxb - ycenter).^2);
        [valb, Ib] = min(distb);

        [xmax(I) ymax(I) dist(I)];
        [xmaxb(Ib) ymaxb(Ib) distb(Ib)];

        tol = 0.05;

        if (dist(I) <= tol && distb(Ib) <= tol)  
            xc = (xmax(I) + xmaxb(Ib))/2;
            yc = (ymax(I) + ymaxb(Ib))/2;
            distc = sqrt((xc - xcenter).^2 + (yc - ycenter).^2);

        elseif (dist(I) <= tol && distb(Ib) > tol)  

            xc = xmax(I);
            yc = ymax(I);
            distc = dist(I);

        elseif (dist(I) > tol && distb(Ib) <= tol)

            xc = xmaxb(Ib);
            yc = ymaxb(Ib);
            distc = distb(Ib);

        else
            xc = xcenter;
            yc = ycenter;
            distc = 0;
        end


        ret = [xc yc distc];

else
      n = 100;
     % n=20;
    x = linspace(min(current_scan(:,1)),max(current_scan(:,1)),n);
    y = linspace(min(current_scan(:,2)),max(current_scan(:,2)),n)';
    
    z = griddata(current_scan(:,1),current_scan(:,2),current_scan(:,7),x,y,'cubic');
    zb = griddata(current_scan(:,1),current_scan(:,2),current_scan(:,8),x,y,'cubic');
 
     xcenter = mean(x);
        ycenter = mean(y);
        
        c = normxcorr2(z,z_original);
            figure(150); surf(c); shading flat;
       [max_c, imax] = max(abs(c(:)));
       [ypeak, xpeak] = ind2sub(size(c),imax(1));
       
       dx = (xpeak-150)*(x(2)-x(1));
       dy = (ypeak-150)*(y(2)-y(1));
       xc = xcenter - dx;
       yc = ycenter - dy;
       
       distc = sqrt(dx^2+dy^2);
       ret = [xc yc distc];
       
  
     %  imageRegSubPixelFactor=10;
       % perform the registration 
      %[outRegValues GOutRegImage] = dftregistration(fft2(z_original),fft2(z),imageRegSubPixelFactor);
      % outRegValues(3)*(x(2)-x(1))*10
      % outRegValues(4)*(y(2)-y(1))*10
           
        
end

end