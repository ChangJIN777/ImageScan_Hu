function t = CreateTempTimer()

logInterval_s = 3;
sPerHr = 3600;
totalLogTime_s = 120*sPerHr;

t = timer;
data = struct;
data.useFigure = 0;
if data.useFigure
    data.tFigure = figure;
else
    data.tFigure=[];
end
data.tStart = 0;
data.tA = []; % store times of the temperature data
data.tB = [];
data.t3 = [];
data.tempA = []; % store temperature measurements
data.tempB = [];
data.voltage = [];
daq.reset;
daq.HardwareInfo.getInstance('DisableReferenceClockSynchronization',true);
data.s = daq.createSession('ni');
data.s.addAnalogInputChannel('PXI1Slot3', 0, 'Voltage');
data.count = 0;
data.axA = 0;
data.axB = 0;
data.saveDirName = 'C:\Users\lab\Desktop\PassiveTempTimerLogs\';
data.saveFileName = datestr(now); % save file name is start date time
data.saveFileName = regexprep(data.saveFileName,':','-');
[data.saveDirName data.saveFileName '.txt']
data.saveFileId = fopen([data.saveDirName data.saveFileName '.txt'],'a+');
data.saveFileId
%fprintf(data.saveFileId,'%s\t%s\t%s\t%s',['timeA'; 'tempA'; 'timeB'; 'tempB\n']);
data.lake = gpib('ni',0,12);
fopen(data.lake);
t.UserData = data; 
t.StartFcn = @tempTimerStart; 
t.TimerFcn = @measureTemp;
t.StopFcn = @tempTimerCleanup;
t.Period = logInterval_s;
t.StartDelay = t.Period;
t.TasksToExecute = ceil(totalLogTime_s/logInterval_s); % number of points to take
t.ExecutionMode = 'fixedRate'; % don't wait for current execution to restart timer for next step
end

% local functions for execution
function tempTimerStart(mTimer,~)
sPerMin = 60;
sPerHr = 3600;
dat = mTimer.UserData;
dat.tStart = tic;
str1 = 'Starting temperature measurement timer. ';
disp(str1)
mTimer.UserData = dat;% save changes to data structure
end

function measureTemp(mTimer,~)

dat = mTimer.UserData; % user data structure
dat.count = dat.count+1;
g1 = dat.lake; % gpib handle
fprintf(g1,'KRDG?A');
 response = fscanf(g1);
 dat.tA = [dat.tA toc(dat.tStart)];
 dat.tempA = [dat.tempA str2num(response)];

fprintf(g1,'KRDG?B');
 response = fscanf(g1);
 dat.tB = [dat.tB toc(dat.tStart)];
 dat.tempB = [dat.tempB str2num(response)];
 
collect = dat.s.startForeground;
dat.t3 = [dat.t3 toc(dat.tStart)];
dat.voltage = [dat.voltage mean(collect)];
 
 if dat.useFigure
     if (dat.count==1)
        subplot(211);
        plot(dat.tA,dat.tempA);
        dat.axA=gca;

        subplot(212);
        plot(dat.tB,dat.tempB);
        dat.axB=gca;
     else
        subplot(211);
        plot(dat.axA,dat.tA,dat.tempA,'b-','LineWidth',2.0);
        xlabel('Time');
        ylabel('Therm A: inside table');

        subplot(212);
        plot(dat.axB,dat.tB,dat.tempB,'k-','LineWidth',2.0);
        xlabel('Time');
        ylabel('Therm B: outside table');

     end
 end
 
 j=dat.count;
 fprintf(dat.saveFileId,'%f\t%f\t%f\t%f\t%f\t%f\n',[dat.tA(j);dat.tempA(j);dat.tB(j);dat.tempB(j);dat.t3(j);dat.voltage(j)]);
 % update the UserData struct
 mTimer.UserData = dat;
end

function tempTimerCleanup(mTimer,~)
disp('Stopping temperature measurement timer.')
dat = mTimer.UserData;
fclose(dat.saveFileId);
g1 = dat.lake;
fclose(g1);
delete(g1)
delete(mTimer)
end