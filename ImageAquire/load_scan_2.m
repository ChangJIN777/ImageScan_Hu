function load_scan( start,fin )
%LOAD_SCAN Summary of this function goes here
%   Detailed explanation goes here

dir = 'C:/Users/lab/Documents/Data/2014_Jun_13/';

x = [];
y = [];
z = [];
z_2t = [];
z_0 = [];
dx = [];
dy = [];
dz = [];
counts=[];

for i=start:fin
    
    fname = [dir sprintf('%.4d',i) '.scan'];
    
    d = importdata(fname);
    
    x = [x d(1)];
    y = [y d(2)];
    val_zero = d(3)-d(4);
     val_t = (d(7)-d(8) - val_zero)/(2*d(8)) + (d(9) - d(10) - val_zero)/(2*d(10));
    val_2t = (d(5)-d(6)-val_zero)/(d(6));
     z = [z val_t];
     z_2t = [z_2t val_2t];
     z_0 = [z_0 val_zero];
     dx = [dx d(11)];
     dy = [dy d(12)];
     dz=[dz d(13)];

end

length(unique(x))
length(unique(y))
    x1 = linspace(min(x),max(x),length(unique(x)));
    y1 = linspace(min(y),max(y),length(unique(y)))';
    
    z1 = griddata(x,y,z,x1,y1,'linear');
   z_2t2 = griddata(x,y,z_2t,x1,y1,'linear');
   z_00 = griddata(x,y,z_0,x1,y1,'linear');
   
   filt = (fspecial('average', 2));
   z_trunc = removerows(z1,'ind',[1 length(unique(y))]);
   z_trunc = removerows(z_trunc','ind',[1 length(unique(x))]);
   
   z_trunc_2t = removerows(z_2t2,'ind',[1 length(unique(y))]);
   z_trunc_2t = removerows(z_trunc_2t','ind',[1 length(unique(x))]);
   
  
 
z_avg = sum(z1')/2;
z_avg_2t = sum(z_2t2')/2;
%Do adjacent averaging
z_avg_filt = conv(z_avg,[0.5 0.5],'same');
z_avg_filt_2t = conv(z_avg_2t,[0.5 0.5],'same');

 %z_avg_filt =  -4./log(1-z_avg_filt./(-0.14));
% z_avg_filt_2t =  -8./log(1-z_avg_filt_2t./(-0.14));
    
  z2 = conv2(z1,filt,'same');
  z_2t22 = conv2(z_2t2,filt,'same');
  z_000 = conv2(z_00,filt,'same');
  z2a=z2;
  z2a = z2.*(z2 <= (-2e-4)) + (-2e-4)*(z2 > (-2e-4));
     z2a = log( -4./log(1-z2a./(-0.07)))/log(10);
  figure(1000);  
  imagesc(x1,y1,z1);
   colormap(bone(256));
   h=  colorbar;
    xlabel('Position (nm)');
    ylabel('Position (nm)');
    ylabel(h,'(sig - ref)/ref');
    title('tau = 400 us');
  figure(1001);
  imagesc(x1,y1,z2);
    colormap(bone(256));
   h=  colorbar;
    xlabel('Position (nm)');
    ylabel('Position (nm)');
    ylabel(h,'(sig - ref)/ref');
        title('tau = 400 us (nn averaged)');
        
        figure(1006);
  imagesc(x1,y1,z2a);
    colormap(bone(256));
   h=  colorbar;
    xlabel('Position (nm)');
    ylabel('Position (nm)');
    ylabel(h,'(sig - ref)/ref');
        title('tau = 400 us (nn averaged)');
    
    figure(1002);
  imagesc(x1,y1,z_2t2);
    colormap(bone(256));
   h=  colorbar;
    xlabel('Position (nm)');
    ylabel('Position (nm)');
    ylabel(h,'(sig - ref)/ref');
      title('tau = 800 us');
    
      figure(1003);
  imagesc(x1,y1,z_2t22);
    colormap(bone(256));
   h=  colorbar;
    xlabel('Position (nm)');
    ylabel('Position (nm)');
    ylabel(h,'(sig - ref)/ref');
      title('tau = 800 us (nn averaged)');
    
      figure(1004);
  imagesc(x1,y1,z_00);
    colormap(bone(256));
   h=  colorbar;
    xlabel('Position (nm)');
    ylabel('Position (nm)');
    ylabel(h,'(sig - ref)/ref');
      title('tau = 0 us');
    
      figure(1005);
  imagesc(x1,y1,z_000);
    colormap(bone(256));
   h=  colorbar;
    xlabel('Position (nm)');
    ylabel('Position (nm)');
    ylabel(h,'(sig - ref)/ref');
      title('tau = 0 us (nn averaged)');
      
      figure(1007);
     imagesc(x1(:,1),y1,z_avg_filt');
      colormap(bone(256));
      
   h=  colorbar;
    xlabel('Position (nm)');
    ylabel('Position (nm)');
    ylabel(h,'(sig - ref)/ref');
      title('tau = 400 us (nn averaged)');
     hold on;
     figure(1009);
     imagesc(x1(:,1),y1,z_avg_filt_2t');
      colormap(bone(256));
      h=  colorbar;
    xlabel('Position (nm)');
    ylabel('Position (nm)');
    ylabel(h,'(sig - ref)/ref');
      title('tau = 800 us (nn averaged)');
     figure(1008);
     plot(dz);
    
 

