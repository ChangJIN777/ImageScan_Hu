% Zhiran, 2/12/2020, measuring drift of sample/diamond in xyz, over hours.
% nor finished writing yet


% Take confocal of the diamond
% Take confocal of the sphere

% Figure out the engaging point (both engage/retract)

clear ziDAQ
ampthreshold=0.0254;
ziDAQ('connect', 'localhost', 8005);
zdevice = ziAutoDetect();
middlevar1=ziDAQ('get',['/',zdevice,'/DEMODS/0/SAMPLE']); %up to 65 points per second
currentamp=((middlevar1.dev531.demods.sample.x)^2+(middlevar1.dev531.demods.sample.y)^2)^0.5
middlevar2=ziDAQ('get',['/',zdevice,'/PIDS/0/SHIFT']);
Zshift=middlevar2.dev531.pids.shift;


while currentamp>ampthreshold
    middlevar1=ziDAQ('get',['/',zdevice,'/DEMODS/0/SAMPLE']); %%up to 65 points per second
    currentamp=((middlevar1.dev531.demods.sample.x)^2+(middlevar1.dev531.demods.sample.y)^2)^0.5
    pause(0.02)
end
Zengage=Zshift+0.001;
pause(1)
ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],Zshift-0.001);
Zshift=Zshift-0.001;
pause(1)
ziDAQ('setDouble',['/',zdevice,'/PIDS/0/OUTPUTDEFAULT'],Zshift-0.001);
Zshift=Zshift-0.001;




%%
periodregi=30; % in seconds
previousclock=clock;

while 1
    nowclock=clock;
    if etime(nowclock,previousclock)> periodregi
        1
        previousclock=clock;
    end
    pause(5)
end