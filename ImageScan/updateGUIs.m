function updateGUIs()
% this function is the ImageScan timer function which updates the 
% zSet value, the tip signal value, the photoDiode value and the
% TransportGUI if they all exist
global measureTransportCont
global Img_handles;

try 
    % get optical power
    photoDiodeV = Img_handles.DAQManager.DAQ.ReadAnalogInVoltage(Img_handles.DAQManager.photoDiodeAI);
    photoDiodeVStr = sprintf('%.2f', photoDiodeV);
    Img_handles.photoDiodeVString.String = photoDiodeVStr;
    greenPower = (photoDiodeV-Img_handles.configS.photoDiodeDark)*Img_handles.configS.photoDiodeConversion;
    greenPowerStr = sprintf('%.1f', greenPower);
    Img_handles.greenPowerString.String = greenPowerStr;
    
    % update tip signal
    if(~isempty(findobj('Tag', 'ApproachGUI')))
        updateApproachSignal();
    end
    
%     updateBoxTemp();
    
%     % update transport signal
%     if(measureTransportCont)
%         updateTransportSignal();
%     end
    
catch ME
    disp(ME);
    for k=1:length(ME.stack)
        ME.stack(k)
    end
    ziDAQ('flush');
    
end

end

function updateTransportSignal()
global Img_handles;

niDiffV = mNIDAQ('ReadAnalogInVoltageTransportDiff', 'PXI1Slot2/ai0', 100000, 500 , 5);

set(Img_handles.TransportGUIHandles.axes1,'NextPlot','replacechildren')
plot(Img_handles.TransportGUIHandles.axes1, Img_handles.TransportMeasureTime, niDiffV*1e3) % [mV]

% update transport values
niDiffV_mean = mean(niDiffV);
Img_handles.TransportGUIHandles.niDiffV.String = sprintf('%.3f', niDiffV_mean*1e3);

end

function updateApproachSignal()
global zDAQOut;
global Img_handles;

d = ziDAQ('poll', 0.005, 1);

if (~isempty(d))
    dataR = sqrt(d.(Img_handles.ApproachGUIHandles.ziDAQ.Device).demods(Img_handles.ApproachGUIHandles.ziDAQ.TipChannel).sample.x.^2 + d.(Img_handles.ApproachGUIHandles.ziDAQ.Device).demods(Img_handles.ApproachGUIHandles.ziDAQ.TipChannel).sample.y.^2);
    dLength = max(size(dataR));
    if (dLength > 0 && dLength < length(Img_handles.ApproachGUIHandles.h.YData))
        Img_handles.ApproachGUIHandles.h.YData(1:end-dLength) = Img_handles.ApproachGUIHandles.h.YData(1+dLength:end);
        Img_handles.ApproachGUIHandles.h.YData(end-dLength+1:end) = dataR;
        Img_handles.ApproachGUIHandles.tipSignalDisplay.String = 1000*dataR(end);
        Img_handles.ApproachGUIHandles.ziPIDOut = ziDAQ('getDouble', ['/' Img_handles.ApproachGUIHandles.ziDAQ.Device '/auxouts/' num2str(Img_handles.ApproachGUIHandles.ziDAQ.PIDauxout-1) '/offset']);
%         disp(num2str(Img_handles.ApproachGUIHandles.ziPIDOut))
        Img_handles.ApproachGUIHandles.zValueText.String = sprintf('%1.3f', zDAQOut + Img_handles.ApproachGUIHandles.ziPIDOut);
    end
end

end

function updateBoxTemp()
global Img_handles;

t = datetime('now');
R296p5 = 1.0825e5;
Rexc = (1e6);

dtDisplay = seconds(t-Img_handles.boxDisplayTime);
dt = minutes(t-Img_handles.boxFeedBackTime);
dtLog = minutes(t-Img_handles.boxTempTime);

if (dtDisplay > 5)
    
    [Vtherm, ~] = mNIDAQ('ReadAnalogInVoltageStd', 'PXI1Slot3/ai6', 5000);
    [Vexc, ~] = mNIDAQ('ReadAnalogInVoltageStd', 'PXI1Slot3/ai3', 5000);
    
    Iexc = (Vexc-Vtherm)/Rexc;
    Rtherm = Vtherm/Iexc;
    
    Ttherm = 296.5 + (Rtherm - R296p5)/Img_handles.configS.thermistorConversion;
    
    Img_handles.boxTempString.String = sprintf('%.3f', Ttherm);
    Img_handles.boxDisplayTime = t;
    
end

if (dtLog > 2)
    [Vtherm, ~] = mNIDAQ('ReadAnalogInVoltageStd', 'PXI1Slot3/ai6', 20000);
    [Vexc, ~] = mNIDAQ('ReadAnalogInVoltageStd', 'PXI1Slot3/ai3', 20000);

    Iexc = (Vexc-Vtherm)/Rexc;
    Rtherm = Vtherm/Iexc;
    
    Ttherm = 296.5 + (Rtherm - R296p5)/Img_handles.configS.thermistorConversion;
    
    Img_handles.boxTempLog = [Img_handles.boxTempLog; [minutes(t-Img_handles.boxTempInitialTime), Ttherm]];
    Img_handles.boxTempTime = t;
    
    if (Img_handles.boxTempFeedBack)
        tempDiff = Img_handles.boxTempSP-Ttherm;
        Img_handles.accTempDiff = (tempDiff*dt) + Img_handles.accTempDiff;
        PowerFB = tempDiff*Img_handles.boxTempP + Img_handles.accTempDiff*Img_handles.boxTempI;
        heaterCurrent = sign(PowerFB)*sqrt(abs(PowerFB));
        if (heaterCurrent > Img_handles.boxTempCurrentMax)
            heaterCurrent = Img_handles.boxTempCurrentMax;
        elseif (heaterCurrent < 0)
            heaterCurrent = 0;
        end
        setCurrentCOM7(heaterCurrent);
        currentHeaterCurrent = str2double(getCurrentCOM7());
        Img_handles.boxHeaterCurrent.String = sprintf('%.3f', currentHeaterCurrent);
        
        Img_handles.boxFeedBackTime = t;
    end
    
end

end

