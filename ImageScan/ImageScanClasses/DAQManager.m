classdef DAQManager < handle
    % class to configure all National Instruments DAQ input and output channels
    %
    % LTSPM #2 experimental setup: (the slot number refers to card slot in the chassis)
    % slot 1 - PXI internal
    % slot 2 - GPIB connection to SRS
    % slot 3 - 32 analog inputs, 4 analog outputs (top 2 breakout boxes)
    % slot 4 - 32 analog inputs, 4 analog outputs (breakout boxes 3&4)
    % slot 5 - 8 differential analog inputs, 2 analog outputs (breakout box 5)
    %
    % since the SRS is address via GPIB the GPIB address is defined here too
    
    
    events
        requestDAQ
    end
    
    properties
        DAQ;
        isDAQlocked = false;
        AnalogOutMinVoltages = [-5 -5 0.0];%[-4.0 -4.0 0.0];
        AnalogOutMaxVoltages = [5.0 5 10.0];%[3.0 3.0 10.0];
        defaultVoltage = 0.0; % default output voltage e.g. for confocal intialization
    end
    
    properties (Constant)
        X = 1;
        Y = 2;
        Z = 3;
        %set the hardcoded voltage limits for XYZ
        %galvos for XY can theoretically go up to +/-10 V
        %hard limit for MCL piezo Z voltage
        
         % confocal XYZ output voltage lines:
        confocalX = 'PXI1Slot2/ao0';
        confocalY = 'PXI1Slot2/ao1';
        confocalZ = 'PXI1Slot2/ao2';
        
        % counter lines: (e.g. the "counter in" is PFI0 and trigger is PFI12)
        counterLine1 = '/PXI1Slot2/PFI0';
        counterLine2 = '/PXI1Slot2/PFI1';
        
        % trigger lines/clock lines:
        triggerLine1 = '/PXI1Slot2/PFI12'; % internal DAQ clock line/trigger
        triggerLine2 = '/PXI1Slot2/PFI13'; % external PulseBlaster counter TTL line
%         triggerLine3 = '/PXI1Slot3/PFI7';  % external PulseBlaster RF TTL line for counting up/down
        
        %analog in for correlated counter, voltage measurement
        counterVoltageAI = 'PXI1Slot2/ai1';
        photoDiodeAI = 'PXI1Slot2/ai7';
        
        strDims = 'XYZ';
        CTR1 = 1;
        CTR2 = 2;
        CLK1 = 1;
        CLK2 = 2;
        ratioZtoX = 2.5;
        ratioYtoX = 1.0;
        
        % GPIB address:
        % Chang Jin 7/10/21
        srsGPIB = 22;
        srs2GPIB = 16; 
        srs3GPIB = 24;
        %-----------------
    end
    
    methods
        function obj = DAQManager(handles,configStruct)
            
            % moved AnalogOutMinVoltages and MaxVoltages from constant to
            % nont constant properties
            obj.AnalogOutMinVoltages = [configStruct.xMinVolts configStruct.yMinVolts configStruct.zMinVolts];
            obj.AnalogOutMaxVoltages = [configStruct.xMaxVolts configStruct.yMaxVolts configStruct.zMaxVolts];
            
            % set up DAQ lines for the scan
            LibraryName = 'nidaqmx';
            LibraryFilePath = 'C:\WINDOWS\system32\nicaiu.dll';
            % location of C header file for DLL.  Might need to modify due to unsupported datatypes
            HeaderFilePath = 'NIDAQmx.h';
            DeviceChannel = 'PXI1Slot2';
            % instantiate the driver (modified by Chang 07/10/21)
            obj.DAQ = NIDAQ_Driver(LibraryName,LibraryFilePath,HeaderFilePath,DeviceChannel);
%             if exist('handles', 'var')
%                 if handles.bSimulatedData == false
%                     obj.DAQ = NIDAQ_Driver(LibraryName,LibraryFilePath,HeaderFilePath,DeviceChannel);
%                 else
%                     obj.DAQ = SimulatedDAQ(LibraryName,LibraryFilePath,HeaderFilePath,DeviceChannel);
%                 end
%             else
%                 obj.DAQ = NIDAQ_Driver(LibraryName,LibraryFilePath,HeaderFilePath,DeviceChannel);
%             end

            % add confocal analog output lines
            obj.DAQ.addAOLine(obj.confocalX, obj.defaultVoltage, obj.AnalogOutMinVoltages(obj.X), obj.AnalogOutMaxVoltages(obj.X));%X voltage
            obj.DAQ.addAOLine(obj.confocalY, obj.defaultVoltage, obj.AnalogOutMinVoltages(obj.Y), obj.AnalogOutMaxVoltages(obj.Y));%Y voltage
            obj.DAQ.addAOLine(obj.confocalZ, obj.defaultVoltage, obj.AnalogOutMinVoltages(obj.Z), obj.AnalogOutMaxVoltages(obj.Z));%Z voltage
            %analog in for corelated counter, voltage measurment
            
            % add counter voltage analog input line
            obj.DAQ.addAILine(obj.counterVoltageAI);
            obj.DAQ.addAILine(obj.photoDiodeAI);
%             obj.DAQ.addAILine('PXI1Slot2/ai1');
%             % set all output lines to default voltage upon opening ImageScan
            obj.DAQ.WriteAnalogOutAllLines();


            % add Clock Line
%             obj.DAQ.addClockLine('PXI1Slot2/ctr0',obj.triggerLine1);
%             obj.DAQ.addClockLine('PXI1Slot2/ctr1',obj.triggerLine2);   
            obj.DAQ.addClockLine('PXI1Slot2/ctr1','/PXI1Slot2/PFI13');
            obj.DAQ.addClockLine('PXI1Slot2/ctr0','/PXI1Slot2/PFI12');             
          

        % 'Slot2' refers to our DAQ card being in '2' slot of the chassis.
        % the counter we use is PFI0 and trigger is PFI12
        % therefore, since there are 14 PFI labeled then perhaps for the 
        % other BNC block we use 'PFI15' instead of 'PFI0' and
        % 'PFI27' instead of 'PFI12' by just following the convention as
        % above where say 'ao2' is the 'AO0' of BNC block 2 for z piezo

%         obj.DAQ.addCounterInLine('PXI1Slot2/ctr2',obj.counterLine1,DAQManager.CLK2);
%         obj.DAQ.addCounterInLine('PXI1Slot2/ctr3',obj.counterLine2,DAQManager.CLK1);
        obj.DAQ.addCounterInLine('PXI1Slot2/ctr3','/PXI1Slot2/PFI1',DAQManager.CLK1);
        obj.DAQ.addCounterInLine('PXI1Slot2/ctr2','/PXI1Slot2/PFI0',DAQManager.CLK2);
            
            

        end
        
        function delete(obj)
            obj.DAQ.AnalogOutVoltages = zeros(length(obj.DAQ.AnalogOutVoltages));
            obj.DAQ.WriteAnalogOutAllLines();
            obj.DAQ.delete();
        end
    end
    
end

