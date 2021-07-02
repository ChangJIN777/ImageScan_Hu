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
        ClockRate % ??? FIX ME
        
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
            
%             if(ErrorCode ~= 0)
%                 % get the required buffer size
%                 BufferSize = 0;
%                 [BufferSize] = calllib(obj.LibraryName,'DAQmxGetErrorString',ErrorCode,[],BufferSize);
%                 % create a string of spaces
%                 ErrorString = char(32*ones(1,BufferSize));
%                 % now get the actual string
%                 [a,ErrorString] = calllib(obj.LibraryName,'DAQmxGetErrorString',ErrorCode,ErrorString,BufferSize);
                   if( mNIDAQ('NumErrors') ~= 0)
                       ErrorString =  mNIDAQ('CheckErrorStatus');
                       warning(['NIDAQ_Driver Error!! -- ',datestr(now),char(13),ErrorString]);
                   end

               % warning(['NIDAQ_Driver Error!! -- ',datestr(now),char(13),num2str(ErrorCode),'::',ErrorString]);
              %  obj.ErrorStrings{end+1} = ErrorString;
          %  end
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
           % mNIDAQ('addClockLine',Name,PhysicalName,0);
            ClockLine.LogicalName = Name;
            ClockLine.PhysicalName = PhysicalName;
            ClockLine.ClockRate = 0;
            obj.ClockLines = [obj.ClockLines,ClockLine]; %augment array of structures
        end
        
        function obj = addCounterInLine(obj,Name,PhysicalName,ClockLineNumber)
            
            CounterLine.LogicalName = Name; %logical name , eg /Dev1/ctr0
            CounterLine.PhysicalName = PhysicalName; % eg /Dev1/PFI0
            CounterLine.ClockLine = ClockLineNumber; %   eg 1, 2, 3; refers to the array index of obj.ClockLines
            
            obj.CountersIn = [obj.CountersIn,CounterLine];
            
        end
        
        
        % initialization function upon instantiation
        % loads the ni .dll library and header
        function Initialize(obj)
            obj.ResetDevice()
%             if  ~libisloaded(obj.LibraryName)
%                 fprintf('Loading NIDAQ library.....');
%                 [pOk,warnings] = loadlibrary(obj.LibraryFilePath,obj.HeaderFilePath,'alias',obj.LibraryName);
%                 fprintf('Done.\n');
%             end
        end
        
        
        
        function UpdateDigitalIO_All(obj)
            
            % iterate over the DigitalLines
            for k=1:length(obj.DigitalIOLines),
                Device = obj.DigitalIOLines{k};
                Value = obj.DigitalIOStates(k);
                WriteDigitalIO(obj,Device,Value);
            end
        end
        
        function WriteDigitalIO(obj,Device,Value)
            
                % create a task
                [status,b,obj.TaskHandles] = ...
                    calllib(obj.LibraryName,'DAQmxCreateTask','',obj.TaskHandles);
                
                    % Error Check
                    obj.CheckErrorStatus(status);
                
                % designate a digital output channel with new task
                [status,b,c] = calllib(obj.LibraryName,'DAQmxCreateDOChan',obj.TaskHandles,Device,'MyDO',0);
                
                    % Error Check
                    obj.CheckErrorStatus(status);

                % start the task
                [status] = calllib(obj.LibraryName,'DAQmxStartTask',obj.TaskHandles);
                
                    % Error Check
                    obj.CheckErrorStatus(status);
                
                % write the Value to the digital line defined in Task
                [status,b,c,d] = calllib(obj.LibraryName,'DAQmxWriteDigitalLines',obj.TaskHandles,1,1,10.0,0,Value,0,[]);
                
                    % Error Check
                    obj.CheckErrorStatus(status);

                % close up shop
                [status]=calllib(obj.LibraryName,'DAQmxStopTask',obj.TaskHandles);
                
                    % Error Check
                    obj.CheckErrorStatus(status);
                    
                [status]=calllib(obj.LibraryName,'DAQmxClearTask',obj.TaskHandles);
                
                    % Error Check
                    obj.CheckErrorStatus(status);
                    
                % return the TaskHandles back to 1
                obj.TaskHandles = 0;
        end
        
        function WriteAnalogOutLine(obj,Line)
            Device = obj.AnalogOutLines{Line};
            Value = obj.AnalogOutVoltages(Line);
            minV = obj.AnalogOutMinVoltages(Line);
            maxV = obj.AnalogOutMaxVoltages(Line);
        WriteAnalogOutVoltage(obj,Device,Value,minV,maxV);
        
           
        end
        
        function [Voltage] = ReadAnalogInLine(obj,Line)
                Device = obj.AnalogInLines{Line};
                Voltage = ReadAnalogInVoltageScalar(obj,Device);
        end
        
%         function WriteAnalogOutArray(obj,Lines,Values,Grouping)
%             
%             % create a new task
%             [status,b,obj.TaskHandles] = ...
%                     calllib(obj.LibraryName,'DAQmxCreateTask','',obj.TaskHandles);
%                 
%                     % Error Check
%                     obj.CheckErrorStatus(status);          
%         end
        
        function WriteAnalogOutAllLines(obj)
            for k=1:length(obj.AnalogOutLines),
                WriteAnalogOutLine(obj,k);
            end
        end
        
        function [err] = WriteAnalogOutVoltage(obj,Device,Value,MinVal,MaxVal)
            mNIDAQ('WriteAnalogOutVoltage',Device,double(Value),double(MinVal),double(MaxVal));
            err= mNIDAQ('NumErrors');
            obj.CheckErrorStatus(0);
%           
%             % explicit casting to double precision float
%             Value = double(Value);
%             MinVal = double(MinVal);
%             MaxVal = double(MaxVal);
%             
%             % create a new task
%    
%             [status,b,obj.TaskHandles] = ...
%                     calllib(obj.LibraryName,'DAQmxCreateTask','',obj.TaskHandles);
%               
%                     % Error Check
%                     obj.CheckErrorStatus(status);
%                 
%             % create an analog out voltage channel
%             [status] = calllib(obj.LibraryName,'DAQmxCreateAOVoltageChan',obj.TaskHandles,Device,'MyAO',...
%                 MinVal, MaxVal,obj.DAQmx_Val_Volts ,[]);
%             
%                     % Error Check
%                  obj.CheckErrorStatus(status);
%             
%             % write an arbitrary voltage to the task
%             AutoStart = 1;
%             DefaultTimeOut = 10; %seconds
%             
%             
%             [status] = calllib(obj.LibraryName,'DAQmxWriteAnalogScalarF64',...
%                 obj.TaskHandles, AutoStart, DefaultTimeOut, Value,[]);
%             
%                     % Error Check
%                     obj.CheckErrorStatus(status);
%             
%             % stop the task
%             [status]=calllib(obj.LibraryName,'DAQmxStopTask',obj.TaskHandles);
%             
%                     % Error Check
%                     obj.CheckErrorStatus(status);
%             
%             % clear the task
%             [status]=calllib(obj.LibraryName,'DAQmxClearTask',obj.TaskHandles);
%             
%                     % Error Check
%                     obj.CheckErrorStatus(status);
%             
%             % return the TaskHandles back to 0
%             obj.TaskHandles = 0;
        end % WriteAnalogOutVoltage
        
        function [Voltage] = ReadAnalogInVoltageScalar(obj,Device)
            
            MinVal = -10; %volts
            MaxVal = 10; %volts
            DefaultTimeOut = 10; %seconds
            Voltage = 0.0;
            pVoltage = libpointer('doublePtr',Voltage);
            
            pV = libpointer('doublePtr',0);
            % create a new task
            obj = obj.CreateTask('ReadAI');
                
            % create an analog out voltage channel
            [status] = calllib(obj.LibraryName,'DAQmxCreateAIVoltageChan',obj.Tasks.get('ReadAI'),Device,'',...
                obj.DAQmx_Val_Cfg_Default,MinVal, MaxVal,obj.DAQmx_Val_Volts ,[]);
            
                    % Error Check
                    obj.CheckErrorStatus(status);
            
            obj = obj.StartTask('ReadAI'); 
                       
            [status] = calllib(obj.LibraryName,'DAQmxReadAnalogScalarF64',...
                obj.Tasks.get('ReadAI'), DefaultTimeOut, pVoltage,[]);
           
                    % Error Check
                    obj.CheckErrorStatus(status);
          
                
           obj = obj.StopTask('ReadAI');

           obj = obj.ClearTask('ReadAI');

            
            % return voltage
            Voltage = pVoltage.Value;
        end % ReadAnalogInVoltage
        
                
        function [Voltage] = ReadAnalogInVoltage(obj,Device)
            
            MinVal = -10; %volts
            MaxVal = 10; %volts
            DefaultTimeOut = 10; %seconds
            Value = 0.0;
            
            Voltage = zeros(1,1000);
            read = int32(0);
            pRead = libpointer('int32Ptr',read);
            pVoltage = libpointer('doublePtr',Voltage);
            
            pV = libpointer('doublePtr',0);
            % create a new task
            obj = obj.CreateTask('ReadAI');
                
            % create an analog out voltage channel
            [status] = calllib(obj.LibraryName,'DAQmxCreateAIVoltageChan',obj.Tasks.get('ReadAI'),Device,'',...
                obj.DAQmx_Val_Cfg_Default,MinVal, MaxVal,obj.DAQmx_Val_Volts ,[]);
            
                    % Error Check
                    obj.CheckErrorStatus(status);
            
            [status] = calllib(obj.LibraryName,'DAQmxCfgSampClkTiming',obj.Tasks.get('ReadAI'),'',...
                10000.0,obj.DAQmx_Val_Rising,obj.DAQmx_Val_FiniteSamps,1000);
            
                        
            obj = obj.StartTask('ReadAI'); 
            
            [status] = calllib(obj.LibraryName,'DAQmxReadAnalogF64',obj.Tasks.get('ReadAI'),...
                1000,10.0,obj.DAQmx_Val_GroupByChannel,pVoltage,1000,pRead,[]);
            
                    % Error Check
                    obj.CheckErrorStatus(status);
                
           obj = obj.StopTask('ReadAI');

           obj = obj.ClearTask('ReadAI');

           Voltage = pVoltage.Value;
           
        end % ReadAnalogInVoltage
        
        
        function [count] = ReadCounter(obj,TaskName)
            % returns cumulative count from buffer
            % DAQmxGetCICount(TaskHandle taskHandle, const char channel[], uInt32 *data);
            th = obj.Tasks.get(TaskName);
            count = uint32(0);
            pCount = libpointer('uint32Ptr',count);
            TimeOut = 1; %read once, then report
            [status,count] = calllib(obj.LibraryName,'DAQmxReadCounterScalarU32',th,TimeOut,pCount,[]);
            
                % Error Check
                obj.CheckErrorStatus(status);
                
            count = pCount.value;
        end


        function [count] = GetAvailableSamples(obj,TaskName)
            %Get the number of samples currently in the counter buffer
           count = mNIDAQ('GetAvailableSamples',TaskName);
           obj.CheckErrorStatus(0); 
%             th = obj.Tasks.get(TaskName);
%             count = uint32(0);
%             TimeOut = 0; %read once, then report
%             
%             if th,
%                 [status,count] = calllib(obj.LibraryName,'DAQmxGetReadAvailSampPerChan',th,count);
% 
%                 % Error Check
%                 obj.CheckErrorStatus(status);
%             else
%                 count = 0;
%             end
        end

        function [BufferData] = ReadCounterBuffer(obj,TaskName,NumSamplesToRead)
            % C-reference
            %
            % int32 DAQmxReadCounterU32 (TaskHandle taskHandle, int32 numSampsPerChan,
            %       float64 timeout, uInt32 readArray[], uInt32 arraySizeInSamps, 
            %       int32 *sampsPerChanRead, bool32 *reserved);
            %
            
           
           
            % get task name
            %th = obj.Tasks.get(TaskName);
            
            % allocate buffer memory
            BufferData = zeros(1,NumSamplesToRead);
            
            % size of buffer
            SizeOfBuffer = uint32(NumSamplesToRead);
            %pBufferData = libpointer('uint32Ptr', BufferData);
            SampsPerChanRead = 0;
           % pSampsPerChanRead = libpointer('int32Ptr',SampsPerChanRead);
            
            [BufferData,SampsPerChanRead] = mNIDAQ('ReadCounterBuffer',TaskName,SizeOfBuffer);
           obj.CheckErrorStatus(0); 
           
            % when calling the functions in Matlab, the resultant data is
            % passed as an output from calllib instead of using a C-like
            % pointer or passing by reference
%             [status,BufferData] = calllib(obj.LibraryName,'DAQmxReadCounterU32',th,SizeOfBuffer,...
%                 obj.DAQmx_Val_WaitInfinitely,BufferData,SizeOfBuffer,pSampsPerChanRead,[]);
%             
%                 % Error Check
%                 obj.CheckErrorStatus(status);
        end
        
        function [obj] = CreateTask(obj,TaskName)
            mNIDAQ('CreateTask',TaskName);
            obj.CheckErrorStatus(0);
%             % before trying to create a task, check to see if the task
%             % exists already
%             
%             if obj.Tasks.containsKey(TaskName),
%                 % clear out the task
%                 [status] = calllib(obj.LibraryName,'DAQmxClearTask',obj.Tasks.get(TaskName));
%                 
%                     % Error Check
%                     obj.CheckErrorStatus(status);
%                     
%                 warning(sprintf('TaskName: %s already exists.  Purging old task and creating new one',TaskName));
%             end
%             th = 0;
%             [status,b,th] = ...
%                 calllib(obj.LibraryName,'DAQmxCreateTask',TaskName,th);
%             
%                 % Error Check
%                 obj.CheckErrorStatus(status);
%             
%             obj.Tasks.put(TaskName,th);
        end
        
        function [obj] = StartTask(obj,TaskName)
             mNIDAQ('StartTask',TaskName);
             obj.CheckErrorStatus(0);
%             % start the task
%             [status] = calllib(obj.LibraryName,'DAQmxStartTask',obj.Tasks.get(TaskName));
%             
%                 % Error Check
%                     obj.CheckErrorStatus(status);
        end
        
        function [obj] = StopTask(obj,TaskName)
             mNIDAQ('StopTask',TaskName);
             obj.CheckErrorStatus(0);
%             % start the task
%             th = obj.Tasks.get(TaskName);
%             if th,
%                 [status] = calllib(obj.LibraryName,'DAQmxStopTask',obj.Tasks.get(TaskName));
% 
%                 % Error Check
%                 obj.CheckErrorStatus(status);
%             end
            
        end

        function [obj] = ClearTask(obj,TaskName)
             mNIDAQ('ClearTask',TaskName);
             obj.CheckErrorStatus(0);
%             % check to see if the task name exists
%             if obj.Tasks.containsKey(TaskName)
%                 % start the task
%                 [status] = calllib(obj.LibraryName,'DAQmxClearTask',obj.Tasks.get(TaskName));
% 
%                 % Error Check
%                 obj.CheckErrorStatus(status);
% 
%                 % remove task from obj.Task MapContainer
%                 obj.Tasks.remove(TaskName);
%             end
        end
        
        function [obj] = ClearAllTasks(obj)
             mNIDAQ('ClearAllTasks');
             obj.CheckErrorStatus(0);
%             taskHandles = obj.Tasks.keys();
%             
%             while taskHandles.hasMoreElements,
%                 TaskName = taskHandles.nextElement;
%                 val = obj.Tasks.get(TaskName);
% 
%                 if val > 0,
%                     [status] = calllib(obj.LibraryName,'DAQmxClearTask',val);
%                     
%                         % Error Check
%                         obj.CheckErrorStatus(status);
%                 end
%                 obj.Tasks.remove(TaskName);
%             end
        end
            
        function [] = WaitUntilTaskDone(obj,TaskName)
             mNIDAQ('WaitUntilTaskDone',TaskName);
             obj.CheckErrorStatus(0);
%             % int32 DAQmxWaitUntilTaskDone (TaskHandle taskHandle, float64 timeToWait);
%             th = obj.Tasks.get(TaskName);
%             % check if th > 0 incase task was cancelled.
%             if th > 0,
%                 [status] = calllib(obj.LibraryName,'DAQmxWaitUntilTaskDone',th,obj.ReadTimeout);
% 
%                     % Error Check
%                     obj.CheckErrorStatus(status);
%                     if status == -200560, % task didn't finish,
% 
%                         %clear task
% 
%                         calllib(obj.LibraryName,'DAQmxStopTask',th);
%                         return;
%                     end
%             end
        end
        
        function [bool] = IsTaskDone(obj,TaskName)
            bool = mNIDAQ('IsTaskDone',TaskName);
            obj.CheckErrorStatus(0);
            
%             p = libpointer('ulongPtr',0);
%             th = obj.Tasks.get(TaskName);
%             if th,
%                  [status,bool] = calllib(obj.LibraryName,'DAQmxIsTaskDone',th,p);
%             
%                 % Error Check
%                 obj.CheckErrorStatus(status);
%             else
%                 bool = 1; % task done b/c doesn't exist
%             end
        end
        
        function [tasks] = GetSysTasks(obj)
            task = [];
            [status,tasks] = calllib(obj.LibraryName,'DAQmxGetSysTasks',[],0);
            
                % Error Check
                obj.CheckErrorStatus(status);
        end
        
        function [] = ResetDevice(obj)
            mNIDAQ('ResetDevice',obj.DeviceChannel);
            obj.CheckErrorStatus(0);
%             
%             [status] = calllib(obj.LibraryName,'DAQmxResetDevice',obj.DeviceChannel);
%                 % Error Check
%                 obj.CheckErrorStatus(status);
        end


        function [obj] = ConfigureClockOut(obj,TaskName,ClockLine,ClockFrequency,DutyCycle)
            Device = obj.ClockLines(ClockLine).LogicalName;
            mNIDAQ('StopTask',TaskName);
            obj.CheckErrorStatus(0);
            mNIDAQ('ConfigureClockOut',TaskName,Device,ClockFrequency,DutyCycle,obj.CounterOutSamples);
            obj.ClockLines(ClockLine).ClockRate = ClockFrequency;
            obj.CheckErrorStatus(0);
            
          %  mNIDAQ('StartTask',TaskName);
           %  obj.CheckErrorStatus(0);
%             th = obj.Tasks.get(TaskName);
%             
%             % initialize a Freq based pulse train
%             %
%             %       int32 DAQmxCreateCOPulseChanFreq (TaskHandle taskHandle, const
%             %               char counter[], const char nameToAssignToChannel[], int32 units, 
%             %               int32 idleState, float64 initialDelay, float64 freq, float64 dutyCycle);
%             %
%             initialDelay = 0.0;
%             [status] = calllib(obj.LibraryName,'DAQmxCreateCOPulseChanFreq',th,Device,'',obj.DAQmx_Val_Hz,obj.DAQmx_Val_Low,initialDelay,ClockFrequency,DutyCycle);
%             
%                 % Error Check
%                 obj.CheckErrorStatus(status);
%             
%             % Configure so that the pulse train is generated continuously
%             [status] = calllib(obj.LibraryName,'DAQmxCfgImplicitTiming',th,obj.DAQmx_Val_ContSamps,obj.CounterOutSamples);
%             
%                 % Error Check
%                 obj.CheckErrorStatus(status);
% 
%             obj.ClockLines(ClockLine).ClockRate = ClockFrequency;
        end

        
        function [obj] = ConfigureClockOutFiniteSamples(obj,TaskName,ClockLine,ClockFrequency,DutyCycle,NumberOfFiniteSamples)
            Device = obj.ClockLines(ClockLine).LogicalName;
            th = obj.Tasks.get(TaskName);
            
            % initialize a Freq based pulse train
            %
            %       int32 DAQmxCreateCOPulseChanFreq (TaskHandle taskHandle, const
            %               char counter[], const char nameToAssignToChannel[], int32 units, 
            %               int32 idleState, float64 initialDelay, float64 freq, float64 dutyCycle);
            %
            initialDelay = 0.0;
            [status] = calllib(obj.LibraryName,'DAQmxCreateCOPulseChanFreq',th,Device,'',obj.DAQmx_Val_Hz,obj.DAQmx_Val_Low,initialDelay,ClockFrequency,DutyCycle);
            
                % Error Check
                obj.CheckErrorStatus(status);
            
            % Configure so that the pulse train is generated continuously
            [status] = calllib(obj.LibraryName,'DAQmxCfgImplicitTiming',th,obj. DAQmx_Val_FiniteSamps,NumberOfFiniteSamples);
            
                % Error Check
                obj.CheckErrorStatus(status);
                
            % Route the output terminal to the PhysicalLine Spec'd in the
            % Configuration
            [status] = calllib(obj.LibraryName,'DAQmxSetCOPulseTerm',th,...
                obj.ClockLines(ClockLine).LogicalName,obj.ClockLines(ClockLine).PhysicalName);

                            obj.CheckErrorStatus(status);

            obj.ClockLines(ClockLine).ClockRate = ClockFrequency;
        end
        
        function ConfigureCounterIn(obj,TaskName,CounterInLine,NSamples)
            
            %th = obj.Tasks.get(TaskName);
            CounterDevice = obj.CountersIn(CounterInLine).LogicalName;
            
               %  updated 31 July 2009, jhodges
            % adds capability to adjust physical line
            CounterLinePhysical = obj.CountersIn(CounterInLine).PhysicalName;
            thisCounterLine = obj.CountersIn(CounterInLine).ClockLine;
            ClockLinePhysical = obj.ClockLines(thisCounterLine).PhysicalName;
            ClockRate = obj.ClockLines(thisCounterLine).ClockRate;
            % create a counter input channel
            %
            %       int32 DAQmxCreateCICountEdgesChan (TaskHandle taskHandle,
            %               const char counter[], const char nameToAssignToChannel[], 
            %               int32 edge, uInt32 initialCount, int32 countDirection);
            %
             mNIDAQ('StopTask',TaskName);
            obj.CheckErrorStatus(0);
            
            mNIDAQ('ConfigureCounterIn',TaskName,CounterDevice,CounterLinePhysical,ClockLinePhysical,ClockRate,NSamples);
            obj.CheckErrorStatus(0);
            
           %  mNIDAQ('StartTask',TaskName);
           % obj.CheckErrorStatus(0);
            
%             [status] = calllib(obj.LibraryName,'DAQmxCreateCICountEdgesChan',th,CounterDevice,'', obj.DAQmx_Val_Rising,0, obj.DAQmx_Val_CountUp);
%             
%                 % Error Check
%                 obj.CheckErrorStatus(status);
%             
%             [status] = calllib(obj.LibraryName,'DAQmxSetCICountEdgesTerm',th,CounterDevice,CounterLinePhysical);
%             
%                 % Error Check
%                 obj.CheckErrorStatus(status);
%             
%             % fixed bug here 31 july 2009, jhodges
%             % used to be if obj.ClockRate > 0
%             if ClockRate <= 0,
%                 Freq = 1000.0;
%             else
%                 Freq = ClockRate;
%             end
%             
%             % set counter clock to NIDAQ configured line
%             [status] = calllib(obj.LibraryName,'DAQmxCfgSampClkTiming',th, ClockLinePhysical,Freq  , obj.DAQmx_Val_Rising, obj.DAQmx_Val_FiniteSamps,NSamples);
%             
%                 % Error Check
%                 obj.CheckErrorStatus(status);
%             
        end
        
        
         function ConfigurePulseWidthCounterIn(obj,TaskName,CounterInLine,NSamples,MinCounts,MaxCounts)
            
            % use this style counter for pulsed spin measurements (i.e.
            % not imaging or basic counting
            
            th = obj.Tasks.get(TaskName);
            
            % logical name of counter channel
            CounterDevice = obj.CountersIn(CounterInLine).LogicalName;         
            
            % physical device line of counter channel
            CounterLinePhysical = obj.CountersIn(CounterInLine).PhysicalName;
            
            % gate/clock line for counter
            thisCounterLine = obj.CountersIn(CounterInLine).ClockLine;
            ClockLinePhysical = obj.ClockLines(thisCounterLine).PhysicalName;
     
            % create a counter input channel
            %
            %       int32 DAQmxCreateCIPulseWidthChan (TaskHandle
            %       taskHandle, const char counter[], const char nameToAssignToChannel[], 
            %           float64 minVal, float64 maxVal, int32 units, int32 startingEdge, const char customScaleName[]);
            %
            [status] = calllib(obj.LibraryName,'DAQmxCreateCIPulseWidthChan',th,CounterDevice,'', ...
                MinCounts,MaxCounts, obj.DAQmx_Val_Ticks,obj.DAQmx_Val_Rising,'');
                % Error Check
                obj.CheckErrorStatus(status);
            
            % the terminal hardware channel
            [status] = calllib(obj.LibraryName,'DAQmxSetCIPulseWidthTerm',th,CounterDevice,CounterLinePhysical);
                % Error Check
                obj.CheckErrorStatus(status);
 
            % set counter clock to NIDAQ configurereadd line
            [status] = calllib(obj.LibraryName,'DAQmxSetCICtrTimebaseSrc',th, CounterDevice,ClockLinePhysical);            
                % Error Check
                obj.CheckErrorStatus(status);
                
            % set to a finite number of samples
                [status] = calllib(obj.LibraryName,'DAQmxCfgImplicitTiming',th,obj.DAQmx_Val_FiniteSamps, NSamples );            
                % Error Check
                obj.CheckErrorStatus(status);
            
            % set Duplicate Counter prevention for this counting mode
                [status] = calllib(obj.LibraryName,'DAQmxSetCIDupCountPrevent',th,CounterDevice,1);            
                % Error Check
                obj.CheckErrorStatus(status);
         end
         
        function ConfigureVoltageOut(obj,TaskName,VoltageOutLines,WriteVoltages,ClockLine)
           % th = obj.Tasks.get(TaskName);
            NLines = length(VoltageOutLines);
            NVoltagesPerLine = length(WriteVoltages)/NLines;
            ClockLinePhysical = obj.ClockLines(ClockLine).PhysicalName;
            ClockRate = obj.ClockLines(ClockLine).ClockRate;
            minV = max(obj.AnalogOutMinVoltages(VoltageOutLines)); %-5V % to get XZ and YZ scans to work...
            maxV = min(obj.AnalogOutMaxVoltages(VoltageOutLines)); %10V % to get XZ and YZ scans to work...
            Device = '';
            for k=1:NLines,
                Device = [Device,',',obj.AnalogOutLines{VoltageOutLines(k)}];
            end
            mNIDAQ('ConfigureVoltageOut',TaskName,Device,NLines,NVoltagesPerLine,ClockLinePhysical,ClockRate,minV,maxV,WriteVoltages);
            obj.CheckErrorStatus(0);
            
           % create an analog out voltage channel
%             [status] = calllib(obj.LibraryName,'DAQmxCreateAOVoltageChan',th,Device,'MyAO',...
%                 minV, maxV,obj.DAQmx_Val_Volts ,[]);
%             
%                 % Error Check
%                 obj.CheckErrorStatus(status);
%             [status] = calllib(obj.LibraryName,'DAQmxCfgSampClkTiming',th, ClockLinePhysical, ClockRate, obj.DAQmx_Val_Rising, obj.DAQmx_Val_FiniteSamps,NVoltagesPerLine);
%                 % Error Check
%                 obj.CheckErrorStatus(status);
%         
%             AutoStart = 0; % don't autostart
%             % write an arbitrary voltage to the task
%             [status] = calllib(obj.LibraryName,'DAQmxWriteAnalogF64',th,...
%                 NVoltagesPerLine, AutoStart, obj.WriteTimeout, obj.DAQmx_Val_GroupByChannel, WriteVoltages, [],[]);
%             
%                 % Error Check
%                 obj.CheckErrorStatus(status);

        end
        
        function ConfigureVoltageIn(obj,TaskName,VoltageInLines,SamplesPerLine,ClockLine)
            
            %th = obj.Tasks.get(TaskName);
            NLines = length(VoltageInLines);
            obj.AnalogInputVoltages = zeros(NLines,SamplesPerLine);
            NVoltagesPerLine = SamplesPerLine;
            
            ClockLinePhysical = obj.ClockLines(ClockLine).PhysicalName;
            ClockRateL = obj.ClockLines(ClockLine).ClockRate;
            
            
            Device = '';
            %for k=1:NLines,
           %     Device = [Device,',',obj.AnalogInLines{VoltageInLines(k)}];
            %end
            
            TaskName
            %Device = 'PXI1Slot2/ai17'
            Device = 'PXI1Slot3/ai1'
            NLines
            NVoltagesPerLine
            ClockLinePhysical
            ClockRateL
            
            
            % replaced with mNIDAQ on 01/14/15 for AFM signal analog input
            mNIDAQ('ConfigureVoltageIn',TaskName,Device,NLines,NVoltagesPerLine,ClockLinePhysical,ClockRateL,-10,...
                 10,NVoltagesPerLine);
            obj.CheckErrorStatus(0);
            
%            % create an analog out voltage channel
%             [status] = calllib(obj.LibraryName,'DAQmxCreateAIVoltageChan',th,Device,'',...
%                 obj.DAQmx_Val_Cfg_Default,obj.AnalogInMinVoltage, obj.AnalogInMaxVoltage,obj.DAQmx_Val_Volts ,[]);
%             
%                 % Error Check
%                 obj.CheckErrorStatus(status);
% 
%             [status] = calllib(obj.LibraryName,'DAQmxCfgSampClkTiming',th, ClockLinePhysical, ClockRate, obj.DAQmx_Val_Rising, obj.DAQmx_Val_FiniteSamps,NVoltagesPerLine);
%             
%                 % Error Check
%                 obj.CheckErrorStatus(status);          

        end
        
        % ReadVoltageIn is the function now used for AFM input to confocal
        % 2D laser scan - 2015. disregard all other analog input functions
        % here
        function [Voltages]= ReadVoltageIn(obj,TaskName,NumSamplesToRead)
                        
            th = obj.Tasks.get(TaskName);
            
            %read = int32(0);
             % do not send pointer to C, rather get a return value from C
             % this libpointer stuff is what caused this original library
             % to have so many warnings when it ran originally
            %pRead = libpointer('int32Ptr',read);
%             VoltageIn = zeros(size(obj.AnalogInputVoltages(:)));
%             % do not send pointer to C, rather get a return value from C
%             %pVoltage = libpointer('doublePtr',VoltageIn);
%             %pVoltage = libpointer('singlePtr',VoltageIn);
%             
%             readArrayInitSize=200;
%             sampsPerLineInitSize=2; % for 2 lines, but 1 may be enough
%             
%             NumberOfSamples = length(VoltageIn);
            
            %-----------
            % allocate buffer memory
            Voltages = zeros(1,NumSamplesToRead);
            
            % size of buffer
            SizeOfBuffer = uint32(NumSamplesToRead);
            SampsPerChanRead = 0; 
            
            %-------------
            
            % replaced with mNIDAQ on 01/14/15 for AFM signal analog input
            %gotVoltages=mNIDAQ('ReadVoltageIn',TaskName,SamplesPerLine,obj.ReadTimeout,readArrayInitSize,NumberOfSamples,sampsPerLineInitSize);
            %[Voltages,SampsPerChanRead] = mNIDAQ('ReadVoltageIn',TaskName,SizeOfBuffer,0,0,0,0);
            [Voltages,SampsPerChanRead] = mNIDAQ('ReadVoltageIn',TaskName,SizeOfBuffer);
            obj.CheckErrorStatus(0);
%             [status] = calllib(obj.LibraryName,'DAQmxReadAnalogF64',th, SamplesPerLine, ...
%                 obj.ReadTimeout, obj.DAQmx_Val_GroupByChannel, pVoltage, NumberOfSamples, pRead,[]);
%             
%                 % Error Check
%                 obj.CheckErrorStatus(status);
 
        end
        
        function ConfigureDigitalOut(obj,TaskName,DigitalOutLines,ClockLine,WriteVoltages,ClockRate)
            
            % get the task handle
            th = obj.Tasks.get(TaskName);
            
            ClockLinePhysical = obj.ClockLines(ClockLine).PhysicalName;
            
            % get the total number of digital lines
            NLines = length(DigitalOutLines);
            NVoltagesPerLine = length(WriteVoltages)/NLines;
            
            Device = '';
            for k=1:NLines,
                Device = [Device,',',obj.DigitalIOLines{DigitalOutLines(k)}];
            end
            
           % create an digital out channel
            [status] = calllib(obj.LibraryName,'DAQmxCreateDOChan',th,Device,'MyDO',...
                obj.DAQmx_Val_ChanPerLine);
            
                % Error Check
                obj.CheckErrorStatus(status);
                
                
           % timing of the channel is set to that of the digial clock
            [status] = calllib(obj.LibraryName,'DAQmxCfgSampClkTiming',th, ClockLinePhysical,...
                ClockRate, obj.DAQmx_Val_Rising, obj.DAQmx_Val_FiniteSamps,NVoltagesPerLine);
            
                % Error Check
                obj.CheckErrorStatus(status);
        
            AutoStart = 0; % don't autostart
            % write an arbitrary voltage to the task
            [status] = calllib(obj.LibraryName,'DAQmxWriteAnalogF64',th,...
                NVoltagesPerLine, AutoStart, obj.WriteTimeout, obj.DAQmx_Val_GroupByChannel, WriteVoltages, [],[]);
            
                obj.CheckErrorStatus(status);
            
            [status] = calllib(obj.LibraryName,'DAQmxWriteDigitalLines',th,NVoltagesPerLine,AutoStart,...
                obj.WriteTimeout,obj.DAQmx_Val_GroupByChannel,WriteVoltages,[],[]);
            
                % Error Check
                obj.CheckErrorStatus(status);
        end
        

        function [varargout] = LibraryFunction(obj,FunctionName,argsin)
            % function LibraryFunction
            % jhodges, 5Apr2010
            % use this function to call arbitrary library functions from
            % nidaqmx DLL
            
            % determine how many outputs there should be for the function
            % call
            FunctionProto = libfunctions(obj.LibraryName,'-full');
            
            % find the matching name
            A = strfind(FunctionProto,FunctionName);
            for k=1:length(A),
                if isempty(A{k}),
                    continue;
                else
                    fIndex = k;
                    break;
                end
            end
            
            % use regexp to get the number of args, given as [a,b,c,d,...]
            argText = regexp(FunctionProto{fIndex},'\[(.*)\]','match');
            
            if isempty(argText) % no [] proto implies 1 return
                nargs = 1;
            else
                nargs = length(regexp(argText{1}(2:end-1),'\w+'));
            end
            % use feval and {:} to call `calllib` with variable args in
            % handle up to 5 arg outs
           switch nargs,
               case 1,
                   [status] = feval('calllib',obj.LibraryName,FunctionName,argsin{:});
               case 2,
                   [status,varargout{1}] = ...
                       feval('calllib',obj.LibraryName,FunctionName,argsin{:});
               case 3,
                   [status,varargout{1},varargout{2}] = ...
                       feval('calllib',obj.LibraryName,FunctionName,argsin{:});
              case 4,
                   [status,varargout{1},varargout{2},varargout{3}] = ...
                       feval('calllib',obj.LibraryName,FunctionName,argsin{:});
              case 5,
                   [status,varargout{1},varargout{2},varargout{3},varargout{4}] = ...
                       feval('calllib',obj.LibraryName,FunctionName,argsin{:});
           end
           % Error Check
           obj.CheckErrorStatus(status);
        end
        
        function delete(obj)
            % destructor method
            %
            % loop through tasks and clear
            % unload library
            if ~libisloaded(obj.LibraryName),
                [pOk,warnings] = unloadlibrary(obj.LibraryName);
            end
            
            % clear all tasks
            obj.ClearAllTasks();
            
        end %delete
            
            
    end % METHODS
end