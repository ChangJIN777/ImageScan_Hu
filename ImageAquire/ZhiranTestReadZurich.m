%Jan 24 2020, Zhiran 
%reading the Zurich input's time trace. Assume engaged at first, then
%change the output default to current output and disable PID. ANd then
%retract by some distance and engage again same distance, while measuring
%input's time trace.


global Img_handles;
global esr_handles;

clear ziDAQ
ziDAQ('connect', 'localhost', 8005);
zdevice = ziAutoDetect();
%get the actual output voltage (not default) and will start increasing from there.
Zshift_struct=ziDAQ('get',['/',zdevice,'/PIDS/0/SHIFT']);
Zshift=Zshift_struct.dev531.pids.shift;
ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],Zshift);
pause(15);

ziDAQ('setInt',['/',zdevice,'/PIDS/0/ENABLE'],0);

MaxN=1000;

Results2=zeros(4,MaxN);%First row is timestamp. Second row is signal. Third row is the output voltage which is controlling Z piezo.
for k=1:MaxN 
    Results1(k)=ziDAQ('get',['/',zdevice,'/DEMODS/0/SAMPLE']); %65 points per second
    Results2(1,k)=Results1(k).dev531.demods.sample.timestamp-Results1(1).dev531.demods.sample.timestamp;
    Results2(1,k)=Results2(1,k)/210e6;
    Results2(2,k)=((Results1(k).dev531.demods.sample.x)^2+(Results1(k).dev531.demods.sample.y)^2)^0.5;
    if mod(k,99)==0
        ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],Zshift+0.001*floor(k/99));
    end
end
for k=1:MaxN 
    Results2(3,k)=Zshift+0.001*floor((k-1)/99);
end


%%
Zshift=Zshift+0.001*floor(MaxN/99);
Results4=zeros(4,MaxN);%First row is timestamp. Second row is signal. Third row is the output voltage which is controlling Z piezo.
for k=1:MaxN 
    Results3(k)=ziDAQ('get',['/',zdevice,'/DEMODS/0/SAMPLE']); %65 points per second
    Results4(1,k)=Results3(k).dev531.demods.sample.timestamp-Results3(1).dev531.demods.sample.timestamp;
    Results4(1,k)=Results4(1,k)/210e6;
    Results4(2,k)=((Results3(k).dev531.demods.sample.x)^2+(Results3(k).dev531.demods.sample.y)^2)^0.5;
    if mod(k,99)==0
        ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],Zshift-0.001*floor(k/99));
    end
end
for k=1:MaxN 
    Results4(3,k)=Zshift-0.001*floor((k-1)/99);
end


