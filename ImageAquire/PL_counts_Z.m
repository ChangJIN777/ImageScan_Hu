
myDAQ = daq.createSession('ni') ;
%
%ch= addCounterInputChannel (myDAQ,'PXI1Slot2','ctr2' , 'EdgeCount')
%ch.ActiveEdge = 'Falling';
%ch2 = addCounterOutputChannel (myDAQ, 'PXI1Slot3','ctr0', 'PulseGeneration')
%ch2.Frequency = 100;

%ch2
ch= addAnalogInputChannel (myDAQ,'PXI1Slot2','ai0' , 'Voltage')
%ch2 =
%addTriggerConnection(myDAQ,'PXI1Slot3/PFI12','PXI1Slot2/PFI0','StartTrigger')
%myDAQ.Rate = 100;
%myDAQ.DurationInSeconds = 1;

myDAQ.DurationInSeconds = 2
[data,timestmp] = startForeground(myDAQ);
plot (data)


%pause(1)
%inputSingleScan(myDAQ)

removeChannel(myDAQ,1)
