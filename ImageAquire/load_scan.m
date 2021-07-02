function load_scan( start,fin )
%LOAD_SCAN Summary of this function goes here
%   Detailed explanation goes here

dir = 'C:/Users/lab/Documents/Data/2014_Jun_13/';
%dir = 'C:/Users/10-9Lab/Documents/MATLAB/2014_May_29/1dscan4tauJune2/';
x = [];
y = [];
z = [];
z_2t = [];
z_0 = [];
dx = [];
dy = [];
dz = [];
counts=[];
repspertau = 2e6;
%repspertau = 6e6;
timemeasured =350e-9;
znoise=[];
znoise_2t=[];
tau= 4; %tau in microseconds


for i=start:fin
    
    fname = [dir sprintf('%.4d',i) '.scan'];
    
    d = importdata(fname);
    
    x = [x d(1)];
    y = [y d(2)];
    val_zero = d(3)-d(4);
     val_t = (d(7)-d(8) - val_zero)/(2*d(8)) + (d(9) - d(10) - val_zero)/(2*d(10));
     
     signal_t = 2*repspertau*timemeasured*(d(7)+d(9))/2*1e3;
     ref_t = 2*repspertau*timemeasured*(d(8)+d(10))/2*1e3;
     signalzero_t = repspertau*timemeasured*d(3)*1e3;
     refzero_t =repspertau*timemeasured*d(4)*1e3;
     
     signalnoise_t = sqrt(signal_t);
     refnoise_t = sqrt(ref_t);
     signalzeronoise_t = sqrt(signalzero_t);
     refzeronoise_t = sqrt(refzero_t);
     
     noise_t = sqrt((signalnoise_t/ref_t)^2+((-signal_t/ref_t^2+(signalzero_t-refzero_t)/ref_t^2)*refnoise_t)^2+(signalzeronoise_t/ref_t)^2+(refzeronoise_t/ref_t)^2);
     
     
    val_2t = (d(5)-d(6)-val_zero)/(d(6));
    
     signal_2t = 2*repspertau*timemeasured*(d(5))*1e3;
     ref_2t = 2*repspertau*timemeasured*(d(6))/2*1e3;
     signalzero_2t = repspertau*timemeasured*d(3)*1e3;
     refzero_2t =repspertau*timemeasured*d(4)*1e3;
     
     signalnoise_2t = sqrt(signal_t);
     refnoise_2t = sqrt(ref_t);
     signalzeronoise_2t = sqrt(signalzero_t);
     refzeronoise_2t = sqrt(refzero_t);
     
     noise_2t = sqrt((signalnoise_2t/ref_2t)^2+((-signal_2t/ref_2t^2+(signalzero_2t-refzero_2t)/ref_2t^2)*refnoise_2t)^2+(signalzeronoise_2t/ref_2t)^2+(refzeronoise_2t/ref_2t)^2);
     
    
     znoise =[znoise noise_t/2];
     znoise_2t = [znoise_2t noise_2t/2];
     z = [z val_t];
     z_2t = [z_2t val_2t];
     z_0 = [z_0 val_zero];
     dx = [dx d(11)];
     dy = [dy d(12)];

end
x;
unique(x);
length(unique(x));
length(unique(y));
    x1 = linspace(min(x),max(x),length(unique(x)));
    y1 = linspace(min(y),max(y),length(unique(y)))';
    
    z1 = griddata(x,y,z,x1,y1,'linear');
   z_2t2 = griddata(x,y,z_2t,x1,y1,'linear');
   z_00 = griddata(x,y,z_0,x1,y1,'linear');
   

    
    filt = (fspecial('average', 2));
  z2 = conv2(z1,filt,'same');
  z2sq = conv2(z1.^2,filt,'same');
  
  
  z_2t22 = conv2(z_2t2,filt,'same');
  
  z_2tsq = conv2(z_2t2.^2,filt,'same');
  
  z_000 = conv2(z_00,filt,'same');
  z2noise = sqrt(z2sq - z2.^2);
  z2noise_2t = sqrt(z_2tsq - z_2t22.^2);
  
  figure(2000);  
  imagesc(x1,y1,z2noise);
   colormap(bone(256));
   h=  colorbar;
    xlabel('Position (nm)');
    ylabel('Position (nm)');
    ylabel(h,'(sig - ref)/ref');
    title('z2noise');
 % z2noise=griddata(x,y,znoise,x1,y1,'linear');
 % z2noise_2t = griddata(x,y,znoise_2t,x1,y1,'linear');
  
  %calculate T1
 contrast = (-.07);
 %maxval_t = -6e-5;
 maxval_t = -2e-4;
  maxval_2t =-4e-4; 
 
 
 z2min = z2-z2noise;
 T1min = z2min.*(z2min <= maxval_t) + maxval_t*(z2min > maxval_t);
T1min =  -tau./log(1-T1min./contrast);
z2max = z2+z2noise;
T1max = z2max.*(z2max <= maxval_t) + maxval_t*(z2max > maxval_t);
T1max =  -tau./log(1-T1max./contrast);
  
T1sigma_t = abs((T1max - T1min)./2)+ (T1max-T1min == 0).*( T1max.*(T1max>=T1min) + T1min.*(T1min<T1max))

  z2norm = z2.*(z2 <= (maxval_t)) + (maxval_t)*(z2 > (maxval_t));
  T1 =  -tau./log(1-z2norm./contrast);
  
  %T1sigma_t = abs( ((T1.^2)./tau).*(1-z2norm./contrast)*(-1./contrast) ).*z2noise;
  
 z_2t22min = z_2t22-z2noise_2t;
 T1min_2t = z_2t22min.*(z_2t22min <= maxval_2t) + maxval_2t*(z_2t22min >maxval_2t);
 T1min_2t =  -2*tau./log(1-T1min_2t./contrast);
  
 z_2t22max = z_2t22+z2noise_2t;
 T1max_2t = z_2t22max.*(z_2t22max <= maxval_2t) + maxval_2t*(z_2t22max >maxval_2t);
 T1max_2t =  -2*tau./log(1-T1max_2t./contrast);
  
 
  z_2tnorm = z_2t22.*(z_2t22 <= (maxval_2t)) + (maxval_2t)*(z_2t22 > (maxval_2t));
  T1_2t =  -2*tau./log(1-z_2tnorm./contrast)
  
  T1sigma_2t =(T1max_2t-T1min_2t)./2 + (T1max_2t-T1min_2t == 0).*( T1max_2t.*(T1max_2t>=T1min_2t) + T1min_2t.*(T1min_2t<T1max_2t));
  %T1sigma_2t = abs( (T1_2t.^2)/(2*tau).*(1-z_2tnorm./contrast)*(-1./contrast)  ).*z2noise_2t;
  
  %Weighted average of T1 values from tau and 2tau data
  
  T1_w = ((T1sigma_t.^(-2)).*T1 + (T1sigma_2t.^(-2)).*T1_2t)./((T1sigma_t.^(-2))+(T1sigma_2t.^(-2)));
  T1_w_sigma = sqrt(1./((T1sigma_t.^(-2))+(T1sigma_2t.^(-2))));
  
  %crop data to remove outer edge
  msize = size(T1_w);
  mrow = msize(1);
  mcol = msize(2);
  
  T1_wcrop = abs(T1_w(:,[2:mcol-1]));
  T1_wcrop = T1_wcrop([2:mrow-1],:);
  
  x1crop = x1(2:length(x1)-1);
  y1crop = y1(2:length(y1)-1);
  
  %crop error
  msizesig = size(T1_w_sigma);
  mrowsig = msizesig(1);
  mcolsig = msizesig(2);
  
  T1_w_sigmacrop = T1_w_sigma(:,[2:mcolsig-1]);
  T1_w_sigmacrop = T1_w_sigmacrop([2:mrowsig-1],:);
  
  
  
  
  
  
  figure(1000);  
  imagesc(x1,y1,z2);
   colormap(bone(256));
   h=  colorbar;
    xlabel('Position (nm)');
    ylabel('Position (nm)');
    ylabel(h,'(sig - ref)/ref');
    title('tau = 4 us avg');
    
  figure(1001);
  imagesc(x1,y1,T1);
 
    colormap(bone(256));
   h=  colorbar;
    xlabel('Position (nm)');
    ylabel('Position (nm)');
    ylabel(h,'(sig - ref)/ref');
        title('T1');
        
        figure(1002);
  imagesc(x1,y1,T1sigma_t);
    colormap(bone(256));
   h=  colorbar;
    xlabel('Position (nm)');
    ylabel('Position (nm)');
    ylabel(h,'(sig - ref)/ref');
        title('T1_sigma');
    
    figure(1006);
  imagesc(x1crop,y1crop,log(T1_wcrop)/log(10));
    colormap(bone(256));
   h=  colorbar;
    xlabel('Position (nm)');
    ylabel('Position (nm)');
    ylabel(h,' ');
      title(' ');
    
      figure(1003);
  imagesc(x1,y1,T1);
    colormap(bone(256));
   h=  colorbar;
    xlabel('Position (nm)');
    ylabel('Position (nm)');
    ylabel(h,'(sig - ref)/ref');
      title('T1_w');
    
      figure(1004);
  imagesc(x1,y1,log(abs(T1_w))/log(10));
    colormap(bone(256));
   h=  colorbar;
    xlabel('Position (nm)');
    ylabel('Position (nm)');
     ylabel(h,'');
      title('log(weightedT1)');
    
%       figure(1005);
%   imagesc(x1,y1,z_000);
%     colormap(bone(256));
%    h=  colorbar;
%     xlabel('Position (nm)');
%     ylabel('Position (nm)');
%     ylabel(h,'(sig - ref)/ref');
%       title('tau = 0 us (nn averaged)');
%       
%       figure(1007);
%       scatter(dx,dy);
    

lineno3 = (((T1_w_sigma(:,3)).^(-2)).*T1_w(:,3) + ((T1_w_sigma(:,3)).^(-2)).*T1_w(:,3))./((T1_w_sigma(:,3)).^(-2)+(T1_w_sigma(:,3)).^(-2));
lineno3err = sqrt(1./((T1_w_sigma(:,3).^(-2))+(T1_w_sigma(:,3).^(-2))));
lineno3crop = lineno3(2:length(lineno3)-1);
lineno3errcrop = lineno3err(2:length(lineno3err)-1);


figure(100)


%plot(dx,dy,'-')
errorbar(y1crop,lineno3crop,lineno3errcrop);
%hold on;
%errorbar(y1,T1(:,5),T1sigma_t(:,5),'-r');

 save T11Dscandata40tau.out T1_wcrop -ASCII
 save T11Derr40tau.out T1_w_sigmacrop -ASCII
% save T11Dscanyaxis.out y1crop -ASCII
% save T11Dlinecut.out lineno3crop -ASCII
% save T11Dlinecutyaxis.out y1crop -ASCII
% save T11Derrorbarvalues.out lineno3errcrop -ASCII

