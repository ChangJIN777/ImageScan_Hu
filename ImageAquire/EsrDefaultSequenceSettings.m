function EsrDefaultSequenceSettings( measurementSelection, handles )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
    
    switch(measurementSelection)
        case 1 % 'Rabi 1 Channel'
            set(handles.tauStart,'String',num2str(0));
            set(handles.tauEnd,'String',num2str(600));
            set(handles.numTauPoints,'String',num2str(31));
            set(handles.repsPerTau,'String',num2str(100000));
            set(handles.depopulationTime,'String',num2str(500));
            set(handles.preReadoutWait,'String',num2str(1000));
            set(handles.sampleWidth,'String',num2str(50));
            set(handles.delayTimeAOM,'String',num2str(490));
            set(handles.initTime,'String',num2str(1000));
            set(handles.readoutTime,'String',num2str(400));
            set(handles.fileboxPulseSequence,'String',[handles.EsrGlobalMethods.imageScanHandles.configS.sequenceFolder 'inUse_sequences\RabiSequence_1channel_50ns.esr']);
            set(handles.radio1Channel,'Value',1);
            set(handles.radioTauSweep,'Value',1);

        case 2 % 'Pulsed ESR freq sweep'
            set(handles.pulseFreqDeviation,'String',num2str(2.5));
            set(handles.numPulseFreqPoints,'String',num2str(100));
            set(handles.repsPerFreqPoint,'String',num2str(30000));
            set(handles.depopulationTime,'String',num2str(500));
            set(handles.preReadoutWait,'String',num2str(1000));
            set(handles.sampleWidth,'String',num2str(50));
            set(handles.delayTimeAOM,'String',num2str(490));
            set(handles.initTime,'String',num2str(1000));
            set(handles.readoutTime,'String',num2str(400));
            set(handles.fileboxPulseSequence,'String',[handles.EsrGlobalMethods.imageScanHandles.configS.sequenceFolder 'inUse_sequences\PulsedESR.esr']);
            set(handles.radio1Channel,'Value',1);
            set(handles.radioPulsedESR,'Value',1);    

        case 3 % 'Ramsey 2 Channel'
            piPulse = str2num(get(handles.piTime,'String'));
            set(handles.tauStart,'String',num2str(0));
            set(handles.tauEnd,'String',num2str(10000));
            set(handles.numTauPoints,'String',num2str(251));
            set(handles.repsPerTau,'String',num2str(20000));
            set(handles.depopulationTime,'String',num2str(500));
            set(handles.preReadoutWait,'String',num2str(1000+2*piPulse));
            set(handles.sampleWidth,'String',num2str(50));
            set(handles.delayTimeAOM,'String',num2str(490));
            set(handles.initTime,'String',num2str(1000));
            set(handles.readoutTime,'String',num2str(400));
            set(handles.fileboxPulseSequence,'String',[handles.EsrGlobalMethods.imageScanHandles.configS.sequenceFolder 'inUse_sequences\RamseySequence_2channel_50ns.esr']);
            set(handles.radio2Channel,'Value',1);
            set(handles.radioTauSweep,'Value',1);

    end

end

