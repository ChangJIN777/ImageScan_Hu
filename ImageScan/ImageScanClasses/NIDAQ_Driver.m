classdef NIDAQ_Driver < handle
    % Matlab Object Class implementing control for National Instruments
    % Digital Acquistion Card
    %
    % Jonathan Hodges, jhodges@mit.edu, 26 March 2009
    
    properties
        LibraryName             % alias for library loaded
        LibraryFilePath         % path to nicaiu.dll on Windows
        HeaderFilePath          % path to NIDAQmx.h on Windows
        DigitalIOLines          % Digital Output Line Port Names
        DigitalIOStates         % Digital IO Line States
        AnalogOutLines          % Analog Out Lines
        AnalogInLines           % Analog In Lines
        AnalogOutVoltages       % Analog Output Voltages
        AnalogInputVoltages     % Analog Input Voltages
        DeviceChannel           % device handle from MAX, eg. Dev1, Dev2, etc
        
        % Changing CounterInLines, etc to CountersIn[], which is an
        % array of Hashtables
        CountersIn = struct([]);             % array of structures for counters
        ClockLines = struct([]);                 % array of structures for clocks
        TaskHandles = 0;        % Task Handles
        
        % replaced containers.Map data type with java.util.Hashtable for
        % 7.6 compatability
        %Tasks = containers.Map(); % Task Map Container (key/value pairs)
        Tasks = java.util.Hashtable;
        
        ReadTimeout = 10;       % Timeout for a read operation (sec)
        WriteTimeout = 10;      % Timeout for a write operation (sec)
        
        ErrorStrings = {};      % Strings from DAQmx Errors
        
        CounterOutSamples = 10000; % default value for implicit timing buffer size
        
        % constant for object
        AnalogOutMaxVoltage = 2;
        AnalogOutMinVoltage = -2;
        AnalogOutMaxVoltages;
        AnalogOutMinVoltages;
        AnalogInMaxVoltage = 10;
        AnalogInMinVoltage = -10;
    end
    
    
    properties (Constant, GetAccess = public)
        % constants for NI Board
        DAQmx_Val_Volts =  10348;
        DAQmx_Val_Rising = 10280; % Rising
        DAQmx_Val_Falling =10171; % Falling
        DAQmx_Val_CountUp =10128; % Count Up
        DAQmx_Val_CountDown =10124; % Count Down
        DAQmx_Val_ExtControlled =10326; % Externally Controlled
        DAQmx_Val_Hz = 10373; % Hz
        DAQmx_Val_Low =10214; % Low
        DAQmx_Val_ContSamps =10123; % Continuous Samples
        DAQmx_Val_GroupByChannel = 0;
        DAQmx_Val_Cfg_Default = int32(-1);
        DAQmx_Val_FiniteSamps =10178; % Finite Samples
        DAQmx_Val_Auto = -1;
        DAQmx_Val_WaitInfinitely = -1.0 %*** Value for the Timeout parameter of DAQmxWaitUntilTaskDone
        DAQmx_Val_Ticks =10304;
        DAQmx_Val_Seconds =10364;
        DAQmx_Val_ChanPerLine = 0;
        
    end
    
    methods
        
        % instantiation function
        function obj = NIDAQ_Driver(LibraryName,LibraryFilePath,HeaderFilePath,DeviceChannel)
            obj.LibraryName = LibraryName;
            obj.LibraryFilePath = LibraryFilePath;
            obj.HeaderFilePath = HeaderFilePath;
            obj.DeviceChannel = DeviceChannel;
            obj.Initialize();
        end
        
        function [obj] = CheckErrorStatus(obj,ErrorCode)
            
            if( mNIDAQ('NumErrors') ~= 0)
                ErrorString =  mNIDAQ('CheckErrorStatus');
                warning(['NIDAQ_Driver Error!! -- ',datestr(now),char(13),ErrorString]);
            end
        end
        
        
        % adds a named line (e.g. Dev1/PFI1.0 )for digital IO to the driver object with
        % default State = 0 or 1
        function obj = addDIOLine(obj,Name,State)
            obj.DigitalIOLines{end+1} = Name;
            obj.DigitalIOStates(end+1) = State;
        end
        
        % adds a named line (e.g. Dev1/ao0 ) for analog output with default
        % output Voltage value
        function obj = addAOLine(obj,Name,Voltage,minVoltage,maxVoltage)
            obj.AnalogOutLines{end+1} = Name;
            obj.AnalogOutVoltages(end+1) = Voltage;
            obj.AnalogOutMaxVoltages(end+1) = maxVoltage;
            obj.AnalogOutMinVoltages(end+1) = minVoltage;
        end
        
        function obj = addAILine(obj,Name)
            obj.AnalogInLines{end+1} = Name;
            xx = obj.AnalogInLines{1,:}
            size(xx)
        end
        
        function obj = addClockLine(obj,Name,PhysicalName)
            ClockLine.LogicalName = Name;
            ClockLine.PhysicalName = PhysicalName;
            ClockLine.ClockRate = 0;
            obj.ClockLines = [obj.ClockLines,ClockLine]; %augment array of structures
        end
        
        function obj = addCounterInLine(obj,Name,PhysicalName,ClockLineNumber)
            
            CounterLine.LogicalName = Name;          %logical name , eg /Dev1/ctr0
            CounterLine.PhysicalName = PhysicalName; % eg /Dev1/PFI0
            CounterLine.ClockLine = ClockLineNumber; % eg 1, 2, 3; refers to the array index of obj.ClockLines
            
            obj.CountersIn = [obj.CountersIn,CounterLine];
            
        end
        
        
        % initialization function upon instantiation
        function Initialize(obj)
            obj.ResetDevice()
        end
        
        
        % iterate over the DigitalLines
        function UpdateDigitalIO_All(obj)
            for k=1:length(obj.DigitalIOLines)
                Device = obj.DigitalIOLines{k};
                Value = obj.DigitalIOStates(k);
                WriteDigitalIO(obj,Device,Value);
            end
        end
        
%         %%% not working: only mNIDAQ commands are still functional
%                 function WriteDigitalIO(obj,Device,Value)
%         
%                         % create a task
%                         [status,b,obj.TaskHandles] = ...
%                             calllib(obj.LibraryName,'DAQmxCreateTask','',obj.TaskHandles);
%                         obj.CheckErrorStatus(status);
%         
%                         % designate a digital output channel with new task
%                         [status,b,c] = calllib(obj.LibraryName,'DAQmxCreateDOChan',obj.TaskHandles,Device,'MyDO',0);
%                         obj.CheckErrorStatus(status);
%         
%                         % start the task
%                         [status] = calllib(obj.LibraryName,'DAQmxStartTask',obj.TaskHandles);
%                         obj.CheckErrorStatus(status);
%         
%                         % write the Value to the digital line defined in Task
%                         [status,b,c,d] = calllib(obj.LibraryName,'DAQmxWriteDigitalLines',obj.TaskHandles,1,1,10.0,0,Value,0,[]);
%                         obj.CheckErrorStatus(status);
%         
%                         % close up shop
%                         [status]=calllib(obj.LibraryName,'DAQmxStopTask',obj.TaskHandles);
%                         obj.CheckErrorStatus(status);
%         
%                         [status]=calllib(obj.LibraryName,'DAQmxClearTask',obj.TaskHandles);
%                         obj.CheckErrorStatus(status);
%         
%                         % return the TaskHandles back to 1
%                         obj.TaskHandles = 0;
%                 end
        
        
        function WriteAnalogOutLine(obj,Line)
            Device = obj.AnalogOutLines{Line};
            Value = obj.AnalogOutVoltages(Line);
            minV = obj.AnalogOutMinVoltages(Line);
            maxV = obj.AnalogOutMaxVoltages(Line);
            
            WriteAnalogOutVoltage(obj,Device,Value,minV,maxV);
   
        end
        
        %%% ReadAnalogInVoltageScalar does not exist in mNiDAQ.cpp file
        %         function [Voltage] = ReadAnalogInLine(obj,Line)
        %             Device = obj.AnalogInLines{Line};
        %             Voltage = ReadAnalogInVoltageScalar(obj,Device);
        %         end
        
        function WriteAnalogOutAllLines(obj)
            for k=1:length(obj.AnalogOutLines)
                WriteAnalogOutLine(obj,k);
            end
        end
        
        function [err] = WriteAnalogOutVoltage(obj,Device,Value,MinVal,MaxVal)   
            mNIDAQ('WriteAnalogOutVoltage',Device,double(Value),double(MinVal),double(MaxVal));
            err= mNIDAQ('NumErrors');
            obj.CheckErrorStatus(0);
        end % WriteAnalogOutVoltage
        
        
        %%% function does not exist in mNiDAQ.cpp file
        %         function [Voltage] = ReadAnalogInVoltageScalar(~,channel)
        %
        %             MinVal = -10; %volts
        %             MaxVal = 10; %volts
        %             DefaultTimeOut = 10; %seconds
        %             Voltage = 0.0;
        %
        %             mNIDAQ('ReadAnalogInVoltageScalar', channel, double(Value), double(MinVal), double(MaxVal));
        %
        %         end % ReadAnalogInVoltage
        
        
        function [Voltage] = ReadAnalogInVoltage(obj,channel)
            Voltage = mNIDAQ('ReadAnalogInVoltage', channel);
            obj.CheckErrorStatus(0);       
        end % ReadAnalogInVoltage
        
        
        
        %%% not working: only mNIDAQ commands are still functional
        %         function [count] = ReadCounter(obj,TaskName)
        %             % returns cumulative count from buffer
        %             % DAQmxGetCICount(TaskHandle taskHandle, const char channel[], uInt32 *data);
        %             th = obj.Tasks.get(TaskName);
        %             count = uint32(0);
        %             pCount = libpointer('uint32Ptr',count);
        %             TimeOut = 1;  %read once, then report
        %             [status,count] = calllib(obj.LibraryName,'DAQmxReadCounterScalarU32',th,TimeOut,pCount,[]);
        %             obj.CheckErrorStatus(status);
        %
        %             count = pCount.value;
        %         end
        
        
        function [count] = GetAvailableSamples(obj,TaskName)
            %Get the number of samples currently in the counter buffer
            count = mNIDAQ('GetAvailableSamples',TaskName);
            obj.CheckErrorStatus(0);
        end
        
        function [BufferData] = ReadCounterBuffer(obj,TaskName,NumSamplesToRead)
            % C-reference
            %
            % int32 DAQmxReadCounterU32 (TaskHandle taskHandle, int32 numSampsPerChan,
            %       float64 timeout, uInt32 readArray[], uInt32 arraySizeInSamps,
            %       int32 *sampsPerChanRead, bool32 *reserved);
            %
            
            % allocate buffer memory
            BufferData = zeros(1,NumSamplesToRead);
            
            % size of buffer
            SizeOfBuffer = uint32(NumSamplesToRead);
            SampsPerChanRead = 0;
            
            [BufferData,SampsPerChanRead] = mNIDAQ('ReadCounterBuffer',TaskName,SizeOfBuffer);
            obj.CheckErrorStatus(0);
            
            
        end
        
        function [obj] = CreateTask(obj,TaskName)
            mNIDAQ('CreateTask',TaskName);
            obj.CheckErrorStatus(0);
        end
        
        function [obj] = StartTask(obj,TaskName)
            mNIDAQ('StartTask',TaskName);
            obj.CheckErrorStatus(0);
        end
        
        function [obj] = StopTask(obj,TaskName)
            mNIDAQ('StopTask',TaskName);
            obj.CheckErrorStatus(0);
        end
        
        function [obj] = ClearTask(obj,TaskName)
            mNIDAQ('ClearTask',TaskName);
            obj.CheckErrorStatus(0);
        end
        
        function [obj] = ClearAllTasks(obj)
            mNIDAQ('ClearAllTasks');
            obj.CheckErrorStatus(0);
        end
        
        function [] = WaitUntilTaskDone(obj,TaskName)
            mNIDAQ('WaitUntilTaskDone',TaskName);
            obj.CheckErrorStatus(0);
        end
        
        function [bool] = IsTaskDone(obj,TaskName)
            bool = mNIDAQ('IsTaskDone',TaskName);
            obj.CheckErrorStatus(0);
        end
        
        %%% not working: only mNIDAQ commands are still functional
        %         function [tasks] = GetSysTasks(obj)
        %             tasks = [];
        %             [status,tasks] = calllib(obj.LibraryName,'DAQmxGetSysTasks',[],0);
        %
        %             obj.CheckErrorStatus(status);
        %         end
        
        function [] = ResetDevice(obj)
            mNIDAQ('ClearAllTasks');
            obj.CheckErrorStatus(0);
        end
        
        
        function [obj] = ConfigureClockOut(obj,TaskName,ClockLine,ClockFrequency,DutyCycle)
            Device = obj.ClockLines(ClockLine).LogicalName;
            mNIDAQ('StopTask',TaskName);
            obj.CheckErrorStatus(0);
            mNIDAQ('ConfigureClockOut',TaskName,Device,ClockFrequency,DutyCycle,obj.CounterOutSamples);
            obj.ClockLines(ClockLine).ClockRate = ClockFrequency;
            obj.CheckErrorStatus(0);
        end
        
        
        %%% not working: only mNIDAQ commands are still functional
        %         function [obj] = ConfigureClockOutFiniteSamples(obj,TaskName,ClockLine,ClockFrequency,DutyCycle,NumberOfFiniteSamples)
        %             Device = obj.ClockLines(ClockLine).LogicalName;
        %             th = obj.Tasks.get(TaskName);
        %
        %             % C-reference: initialize a Freq based pulse train
        %             %       int32 DAQmxCreateCOPulseChanFreq (TaskHandle taskHandle, const
        %             %               char counter[], const char nameToAssignToChannel[], int32 units,
        %             %               int32 idleState, float64 initialDelay, float64 freq, float64 dutyCycle);
        %             %
        %             initialDelay = 0.0;
        %             [status] = calllib(obj.LibraryName,'DAQmxCreateCOPulseChanFreq',th,Device,'',obj.DAQmx_Val_Hz,obj.DAQmx_Val_Low,initialDelay,ClockFrequency,DutyCycle);
        %             obj.CheckErrorStatus(status);
        %
        %             % Configure so that the pulse train is generated continuously
        %             [status] = calllib(obj.LibraryName,'DAQmxCfgImplicitTiming',th,obj. DAQmx_Val_FiniteSamps,NumberOfFiniteSamples);
        %             obj.CheckErrorStatus(status);
        %
        %             % Route the output terminal to the PhysicalLine Spec'd in the configuration
        %             [status] = calllib(obj.LibraryName,'DAQmxSetCOPulseTerm',th,...
        %                 obj.ClockLines(ClockLine).LogicalName,obj.ClockLines(ClockLine).PhysicalName);
        %
        %             obj.CheckErrorStatus(status);
        %
        %             obj.ClockLines(ClockLine).ClockRate = ClockFrequency;
        %         end
        
        function ConfigureCounterIn(obj,TaskName,CounterInLine,NSamples)
            
            CounterDevice = obj.CountersIn(CounterInLine).LogicalName;
            
            %  updated 31 July 2009, jhodges
            % adds capability to adjust physical line
            CounterLinePhysical = obj.CountersIn(CounterInLine).PhysicalName;
            thisCounterLine = obj.CountersIn(CounterInLine).ClockLine;
            ClockLinePhysical = obj.ClockLines(thisCounterLine).PhysicalName;
            ClockRate = obj.ClockLines(thisCounterLine).ClockRate;
            
            mNIDAQ('StopTask',TaskName);
            obj.CheckErrorStatus(0);
            
            mNIDAQ('ConfigureCounterIn',TaskName,CounterDevice,CounterLinePhysical,ClockLinePhysical,ClockRate,NSamples);
            obj.CheckErrorStatus(0);
            
        end
        
        function ConfigureCounterUpDownIn(obj,TaskName,CounterInLine,NSamples)
            
            CounterDevice = obj.CountersIn(CounterInLine).LogicalName;
            
            %  updated 31 July 2009, jhodges
            % adds capability to adjust physical line
            CounterLinePhysical = obj.CountersIn(CounterInLine).PhysicalName;
            thisCounterLine = obj.CountersIn(CounterInLine).ClockLine;
            ClockLinePhysical = obj.ClockLines(thisCounterLine).PhysicalName;
            ClockRate = obj.ClockLines(thisCounterLine).ClockRate;
            % create a counter input channel
            
            mNIDAQ('StopTask',TaskName);
            obj.CheckErrorStatus(0);
            
            mNIDAQ('ConfigureCounterUpDownIn',TaskName,CounterDevice,CounterLinePhysical,ClockLinePhysical,ClockRate,NSamples);
            obj.CheckErrorStatus(0);
        end
        
        
        %%% not working: only mNIDAQ commands are still functional
        %         function ConfigurePulseWidthCounterIn(obj,TaskName,CounterInLine,NSamples,MinCounts,MaxCounts)
        %
        %             % use this style counter for pulsed spin measurements (i.e. not imaging or basic counting
        %
        %             th = obj.Tasks.get(TaskName);
        %
        %             % logical name of counter channel
        %             CounterDevice = obj.CountersIn(CounterInLine).LogicalName;
        %
        %             % physical device line of counter channel
        %             CounterLinePhysical = obj.CountersIn(CounterInLine).PhysicalName;
        %
        %             % gate/clock line for counter
        %             thisCounterLine = obj.CountersIn(CounterInLine).ClockLine;
        %             ClockLinePhysical = obj.ClockLines(thisCounterLine).PhysicalName;
        %
        %             % C-reference: create a counter input channel
        %             %       int32 DAQmxCreateCIPulseWidthChan (TaskHandle
        %             %       taskHandle, const char counter[], const char nameToAssignToChannel[],
        %             %           float64 minVal, float64 maxVal, int32 units, int32 startingEdge, const char customScaleName[]);
        %             %
        %             [status] = calllib(obj.LibraryName,'DAQmxCreateCIPulseWidthChan',th,CounterDevice,'', ...
        %                 MinCounts,MaxCounts, obj.DAQmx_Val_Ticks,obj.DAQmx_Val_Rising,'');
        %             obj.CheckErrorStatus(status);
        %
        %             % the terminal hardware channel
        %             [status] = calllib(obj.LibraryName,'DAQmxSetCIPulseWidthTerm',th,CounterDevice,CounterLinePhysical);
        %             obj.CheckErrorStatus(status);
        %
        %             % set counter clock to NIDAQ configured line
        %             [status] = calllib(obj.LibraryName,'DAQmxSetCICtrTimebaseSrc',th, CounterDevice,ClockLinePhysical);
        %             obj.CheckErrorStatus(status);
        %
        %             % set to a finite number of samples
        %             [status] = calllib(obj.LibraryName,'DAQmxCfgImplicitTiming',th,obj.DAQmx_Val_FiniteSamps, NSamples );
        %             obj.CheckErrorStatus(status);
        %
        %             % set Duplicate Counter prevention for this counting mode
        %             [status] = calllib(obj.LibraryName,'DAQmxSetCIDupCountPrevent',th,CounterDevice,1);
        %             obj.CheckErrorStatus(status);
        %         end
        
        function ConfigureVoltageOut(obj,TaskName,VoltageOutLines,WriteVoltages,ClockLine)
            % th = obj.Tasks.get(TaskName);
            NLines = length(VoltageOutLines);
            NVoltagesPerLine = length(WriteVoltages)/NLines;
            ClockLinePhysical = obj.ClockLines(ClockLine).PhysicalName;
            ClockRate = obj.ClockLines(ClockLine).ClockRate;
            minV = max(obj.AnalogOutMinVoltages(VoltageOutLines));
            maxV = min(obj.AnalogOutMaxVoltages(VoltageOutLines));
            Device = '';
            for k=1:NLines
                Device = [Device,',',obj.AnalogOutLines{VoltageOutLines(k)}];
            end
            
            mNIDAQ('ConfigureVoltageOut',TaskName,Device,NLines,NVoltagesPerLine,ClockLinePhysical,ClockRate,minV,maxV,WriteVoltages);
            obj.CheckErrorStatus(0);
            
        end
        
        function ConfigureVoltageOutCont(obj,TaskName,VoltageOutLines,WriteVoltages,ClockLine)
            % th = obj.Tasks.get(TaskName);
            NLines = length(VoltageOutLines);
            bufferSize = length(WriteVoltages)/NLines;
            ClockLinePhysical = obj.ClockLines(ClockLine).PhysicalName;
            ClockRate = obj.ClockLines(ClockLine).ClockRate;
            minV = max(obj.AnalogOutMinVoltages(VoltageOutLines));
            maxV = min(obj.AnalogOutMaxVoltages(VoltageOutLines));
            Device = '';
            for k=1:NLines
                Device = [Device,',',obj.AnalogOutLines{VoltageOutLines(k)}];
            end
            
            mNIDAQ('ConfigureVoltageOutCont',TaskName,Device,NLines,bufferSize,ClockLinePhysical,ClockRate,minV,maxV,WriteVoltages);
            obj.CheckErrorStatus(0);
            
        end
        
        %%% not working: only mNIDAQ commands are still functional
        %         function ConfigureVoltageIn(obj,TaskName,VoltageInLines,SamplesPerLine,ClockLine)
        %
        %             th = obj.Tasks.get(TaskName);
        %             NLines = length(VoltageInLines);
        %             obj.AnalogInputVoltages = zeros(NLines,SamplesPerLine);
        %             NVoltagesPerLine = SamplesPerLine;
        %
        %             ClockLinePhysical = obj.ClockLines(ClockLine).PhysicalName;
        %             ClockRate = obj.ClockLines(ClockLine).ClockRate;
        %
        %             Device = '';
        %             for k=1:NLines
        %                 Device = [Device,',',obj.AnalogInLines{VoltageInLines(k)}];
        %             end
        %
        %             % create an analog out voltage channel
        %             [status] = calllib(obj.LibraryName,'DAQmxCreateAIVoltageChan',th,Device,'',...
        %                 obj.DAQmx_Val_Cfg_Default,obj.AnalogInMinVoltage, obj.AnalogInMaxVoltage,obj.DAQmx_Val_Volts ,[]);
        %             obj.CheckErrorStatus(status);
        %
        %             [status] = calllib(obj.LibraryName,'DAQmxCfgSampClkTiming',th, ClockLinePhysical, ClockRate, obj.DAQmx_Val_Rising, obj.DAQmx_Val_FiniteSamps,NVoltagesPerLine);
        %             obj.CheckErrorStatus(status);
        %
        %         end
        
        %%% not working: only mNIDAQ commands are still functional
        %         function [Voltages]= ReadVoltageIn(obj,TaskName,SamplesPerLine)
        %
        %             th = obj.Tasks.get(TaskName);
        %
        %             read = int32(0);
        %             pRead = libpointer('int32Ptr',read);
        %             VoltageIn = zeros(size(obj.AnalogInputVoltages(:)));
        %             pVoltage = libpointer('doublePtr',VoltageIn);
        %
        %             NumberOfSamples = length(VoltageIn);
        %             % write an arbitrary voltage to the task
        %             [status] = calllib(obj.LibraryName,'DAQmxReadAnalogF64',th, SamplesPerLine, ...
        %                 obj.ReadTimeout, obj.DAQmx_Val_GroupByChannel, pVoltage, NumberOfSamples, pRead,[]);
        %             obj.CheckErrorStatus(status);
        %
        %             Voltages = pVoltage.Value;
        %
        %         end
        
        %%% not working: only mNIDAQ commands are still functional
        %         function ConfigureDigitalOut(obj,TaskName,DigitalOutLines,ClockLine,WriteVoltages,ClockRate)
        %
        %             % get the task handle
        %             th = obj.Tasks.get(TaskName);
        %
        %             ClockLinePhysical = obj.ClockLines(ClockLine).PhysicalName;
        %
        %             % get the total number of digital lines
        %             NLines = length(DigitalOutLines);
        %             NVoltagesPerLine = length(WriteVoltages)/NLines;
        %
        %             Device = '';
        %             for k=1:NLines
        %                 Device = [Device,',',obj.DigitalIOLines{DigitalOutLines(k)}];
        %             end
        %
        %             % create an digital out channel
        %             [status] = calllib(obj.LibraryName,'DAQmxCreateDOChan',th,Device,'MyDO',...
        %                 obj.DAQmx_Val_ChanPerLine);
        %             obj.CheckErrorStatus(status);
        %
        %
        %             % timing of the channel is set to that of the digial clock
        %             [status] = calllib(obj.LibraryName,'DAQmxCfgSampClkTiming',th, ClockLinePhysical,...
        %                 ClockRate, obj.DAQmx_Val_Rising, obj.DAQmx_Val_FiniteSamps,NVoltagesPerLine);
        %             obj.CheckErrorStatus(status);
        %
        %             AutoStart = 0; % don't autostart
        %             % write an arbitrary voltage to the task
        %             [status] = calllib(obj.LibraryName,'DAQmxWriteAnalogF64',th,...
        %                 NVoltagesPerLine, AutoStart, obj.WriteTimeout, obj.DAQmx_Val_GroupByChannel, WriteVoltages, [],[]);
        %             obj.CheckErrorStatus(status);
        %
        %             [status] = calllib(obj.LibraryName,'DAQmxWriteDigitalLines',th,NVoltagesPerLine,AutoStart,...
        %                 obj.WriteTimeout,obj.DAQmx_Val_GroupByChannel,WriteVoltages,[],[]);
        %             obj.CheckErrorStatus(status);
        %
        %         end
        
        %%% not working: only mNIDAQ commands are still functional
        %         function [varargout] = LibraryFunction(obj,FunctionName,argsin)
        %             % function LibraryFunction
        %             % jhodges, 5Apr2010
        %             % use this function to call arbitrary library functions from nidaqmx DLL
        %
        %             % determine how many outputs there should be for the function call
        %             FunctionProto = libfunctions(obj.LibraryName,'-full');
        %
        %             % find the matching name
        %             A = strfind(FunctionProto,FunctionName);
        %             for k=1:length(A)
        %                 if isempty(A{k})
        %                     continue;
        %                 else
        %                     fIndex = k;
        %                     break;
        %                 end
        %             end
        %
        %             % use regexp to get the number of args, given as [a,b,c,d,...]
        %             argText = regexp(FunctionProto{fIndex},'\[(.*)\]','match');
        %
        %             if isempty(argText) % no [] proto implies 1 return
        %                 nargs = 1;
        %             else
        %                 nargs = length(regexp(argText{1}(2:end-1),'\w+'));
        %             end
        %             % use feval and {:} to call `calllib` with variable args in
        %             % handle up to 5 arg outs
        %             switch nargs
        %                 case 1
        %                     [status] = feval('calllib',obj.LibraryName,FunctionName,argsin{:});
        %                 case 2
        %                     [status,varargout{1}] = ...
        %                         feval('calllib',obj.LibraryName,FunctionName,argsin{:});
        %                 case 3
        %                     [status,varargout{1},varargout{2}] = ...
        %                         feval('calllib',obj.LibraryName,FunctionName,argsin{:});
        %                 case 4
        %                     [status,varargout{1},varargout{2},varargout{3}] = ...
        %                         feval('calllib',obj.LibraryName,FunctionName,argsin{:});
        %                 case 5
        %                     [status,varargout{1},varargout{2},varargout{3},varargout{4}] = ...
        %                         feval('calllib',obj.LibraryName,FunctionName,argsin{:});
        %             end
        %             obj.CheckErrorStatus(status);
        %
        %         end
        
        
        % clear all tasks
        function delete(obj)
            obj.ClearAllTasks();
        end %delete
        
        
    end % METHODS
end