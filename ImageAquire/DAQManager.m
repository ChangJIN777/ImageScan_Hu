classdef DAQManager < handle
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    events
        requestDAQ
    end
    
    properties
        DAQ;
        isDAQlocked = false;
        AnalogOutMinVoltages = [-5 -5 0.0];%[-4.0 -4.0 0.0];
        AnalogOutMaxVoltages = [5.0 5 10.0];%[3.0 3.0 10.0];
    end
    
    properties (Constant)
        X = 1;
        Y = 2;
        Z = 3;
        %set the hardcoded voltage limits for XYZ
        %galvos for XY can theoretically go up to +/-10 V
        %hard limit for MCL piezo Z voltage
        
        strDims = 'XYZ';
        CTR1 = 1;
        CTR2 = 2;
        CLK1 = 1;
        CLK2 = 2;
        ratioZtoX = 2.5;
        ratioYtoX = 1.0;
    end
    
    methods
        function obj = DAQManager(handles,configStruct)
               
            % moved AnalogOutMinVoltages and MaxVoltages from constant to
            % nont constant properties
            obj.AnalogOutMinVoltages = [configStruct.xMinVolts,configStruct.yMinVolts,configStruct.zMinVolts];
            obj.AnalogOutMaxVoltages = [configStruct.xMaxVolts,configStruct.yMaxVolts,configStruct.zMaxVolts];
            
            % set up DAQ lines for the scan
            LibraryName = 'nidaqmx';
            LibraryFilePath = 'C:\WINDOWS\system32\nicaiu.dll';
            % location of C header file for DLL.  Might need to modify due to unsupported datatypes
            HeaderFilePath = 'NIDAQmx.h';
            DeviceChannel = 'PXI1Slot2';
            % instantiate the driver
            if exist('handles', 'var')
                if handles.bSimulatedData == false
                    obj.DAQ = NIDAQ_Driver(LibraryName,LibraryFilePath,HeaderFilePath,DeviceChannel);
                else
                    obj.DAQ = SimulatedDAQ(LibraryName,LibraryFilePath,HeaderFilePath,DeviceChannel);
                end
            else
                obj.DAQ = NIDAQ_Driver(LibraryName,LibraryFilePath,HeaderFilePath,DeviceChannel);
            end

            defaultVoltage = 0.00;
            obj.DAQ.addAOLine('PXI1Slot2/ao0',defaultVoltage,obj.AnalogOutMinVoltages(obj.X),obj.AnalogOutMaxVoltages(obj.X));%X voltage
            obj.DAQ.addAOLine('PXI1Slot2/ao1',defaultVoltage,obj.AnalogOutMinVoltages(obj.Y),obj.AnalogOutMaxVoltages(obj.Y));%Y voltage
            obj.DAQ.addAOLine('PXI1Slot2/ao2',defaultVoltage,obj.AnalogOutMinVoltages(obj.Z),obj.AnalogOutMaxVoltages(obj.Z));%Z voltage
            %analog in for corelated counter, voltage measurment
            obj.DAQ.addAILine('PXI1Slot2/ai1');
%             obj.DAQ.WriteAnalogOutAllLines;
            % add Clock Line
            obj.DAQ.addClockLine('PXI1Slot2/ctr1','/PXI1Slot2/PFI13');
            obj.DAQ.addClockLine('PXI1Slot2/ctr0','/PXI1Slot2/PFI12');             
            

        % 'Slot2' refers to our DAQ card being in '2' slot of the chassis.
        % the counter we use is PFI0 and trigger is PFI12
        % therefore, since there are 14 PFI labeled then perhaps for the 
        % other BNC block we use 'PFI15' instead of 'PFI0' and
        % 'PFI27' instead of 'PFI12' by just following the convention as
        % above where say 'ao2' is the 'AO0' of BNC block 2 for z piezo

        obj.DAQ.addCounterInLine('PXI1Slot2/ctr3','/PXI1Slot2/PFI1',DAQManager.CLK1);
        obj.DAQ.addCounterInLine('PXI1Slot2/ctr2','/PXI1Slot2/PFI0',DAQManager.CLK2);

            
            

        end
        
        function delete(obj)
            obj.DAQ.AnalogOutVoltages = zeros(length(obj.DAQ.AnalogOutVoltages));
            obj.DAQ.WriteAnalogOutAllLines();
           % obj.DAQ.delete();
        end
    end
    
end

