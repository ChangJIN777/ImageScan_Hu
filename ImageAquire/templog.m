instrreset
g1 = gpib('ni',0,12);
fopen(g1);
temp1 = [];
temp2 = [];
voltage = [];
t1 = [];
t2 = [];
t3 = [];
daq.reset;
daq.HardwareInfo.getInstance('DisableReferenceClockSynchronization',true);
s = daq.createSession('ni');
s.addAnalogInputChannel('PXI1Slot3', 0, 'Voltage');
s.DurationInSeconds = 0.5;
s.Rate = 5000;

tfig = figure;

tstart = tic;
ax0=0; ax1=0; ax3=0;
for i=1:300000
    

 fprintf(g1,'KRDG?A');
 resp = fscanf(g1);
 t1 = [t1 toc(tstart)];
 temp1 = [temp1 str2num(resp)];
% 
 if (i==1) 
     subplot(311);
    plot(t1,temp1);
    ax0=gca; 
 else
     subplot(311);
    plot(ax0,t1,temp1);
 end
 xlabel('Time');
 ylabel('Therm A: inside table');
% 
 fprintf(g1,'KRDG?B');
 resp = fscanf(g1);
 t2 = [t2 toc(tstart)];
 temp2 = [temp2 str2num(resp)];
 if (i==1)
     subplot(312);
    plot(t2,temp2);
    ax1=gca; 
 else
     subplot(312);
    plot(ax1,t2,temp2);
 end
  xlabel('Time');
  ylabel('Therm B: outside table');

data = s.startForeground;
t3 = [t3 toc(tstart)];
voltage = [voltage mean(data)];

if (i==1)
     subplot(313);
    plot(t3,voltage);
    ax2=gca; 
else
     subplot(313);
    plot(ax2,t3,voltage);
end
xlabel('Time');
ylabel('Voltage z MCL (10 um/V)');

pause(1)

end