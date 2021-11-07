function varargout = ESRControl(varargin)
% ESRCONTROL MATLAB code for ESRControl.fig
%      ESRCONTROL, by itself, creates a new ESRCONTROL or raises the existing
%      singleton*.
%
%      H = ESRCONTROL returns the handle to a new ESRCONTROL or the handle to
%      the existing singleton*.
%
%      ESRCONTROL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ESRCONTROL.M with the given input arguments.
%
%      ESRCONTROL('Property','Value',...) creates a new ESRCONTROL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ESRControl_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ESRControl_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ESRControl

% Last Modified by GUIDE v2.5 10-Jul-2021 22:08:15

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ESRControl_OpeningFcn, ...
                   'gui_OutputFcn',  @ESRControl_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
end

% --- Executes just before ESRControl is made visible.
function ESRControl_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ESRControl (see VARARGIN)



% Choose default command line output for ESRControl
handles.output = hObject;

% varargin
% first argument passed in will be the handle to instance of
% all Esr classes which are made in ImageScan.
handles.EsrGlobalMethods = varargin{1};
handles.EsrCWSweep = varargin{2};
handles.EsrPulsedSweep = varargin{3};
handles.EsrAutomation = varargin{4};

set(handles.checkboxAOMInverter,'Value',handles.EsrGlobalMethods.imageScanHandles.configS.bHaveInverterBoard);

% create a new directory name for the current date if needed:
mydate = date; %returns dd-mmm-yyyy
myyear = mydate(8:end); % returns yyyy
mymonth= mydate(4:6); % returns mmm
myday = mydate(1:2); % returns dd
myFormattedDate = [myyear '_' mymonth '_' myday '\'];

handles.esrSavePath.String = handles.EsrGlobalMethods.imageScanHandles.configS.dataFolder; 
% set(handles.esrSavePath,'String',[handles.EsrGlobalMethods.imageScanHandles.configS.dataFolder myFormattedDate]);
set(handles.esrSavePath,'String','C:\Users\lab\Documents\Data\2021_Jul_14\esr_000001');
set(handles.fileboxPulseSequence,'String',[handles.EsrGlobalMethods.imageScanHandles.configS.sequenceFolder 'inUseSequences\']);

% disable SavePath editing and SaveFileNumber editing, because now the
% program will update the data folder and file number automatically
% (updated 06/April/2017,SB)
set(handles.esrSavePath,'Enable','off')
set(handles.esrSaveFileNum,'Enable','off')

% Update handles structure
guidata(hObject, handles);

global esr_handles;
esr_handles = handles;
% UIWAIT makes ESRControl wait for user response (see UIRESUME)
% uiwait(handles.figure1);
end

% --- Outputs from this function are returned to the command line.
function varargout = ESRControl_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

% --- Executes on button press in toggleTimeSweep.
function toggleTimeSweep_Callback(hObject, eventdata, handles)
% hObject    handle to toggleTimeSweep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of toggleTimeSweep
end

% --- Executes on button press in toggleLoopSweep.
function toggleLoopSweep_Callback(hObject, eventdata, handles)
% hObject    handle to toggleLoopSweep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of toggleLoopSweep
end

% --- Executes on button press in checkboxIQEnabled.
function checkboxIQEnabled_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxIQEnabled (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxIQEnabled

newVal = get(hObject,'Value');
handles.EsrGlobalMethods.IQmodulationON(newVal);
end

% --- Executes on button press in buttonStartSequence.
function buttonStartSequence_Callback(hObject, eventdata, handles)
% hObject    handle to buttonStartSequence (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% make sure data is saved in current date folder
handles.EsrGlobalMethods.UpdateFolder(handles);

if get(handles.radioTauSweep,'Value')==1
    handles.EsrPulsedSweep.PerformSequence(handles);
elseif get(handles.radioPulsedESR,'Value')==1
    handles.EsrPulsedSweep.PerformPulsedESRSequence(handles);
elseif get(handles.radioCheckPiPulse,'Value')==1
    handles.EsrPulsedSweep.PerformPiPulsePowerCalibration(handles);
elseif get(handles.radioCheckRedSpec,'Value')==1
    handles.EsrPulsedSweep.PerformRedSpecSequence(handles);
end
end

% --- Executes on button press in buttonStopSequence.
function buttonStopSequence_Callback(hObject, eventdata, handles)
% hObject    handle to buttonStopSequence (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
disp('stopping scan')
handles.EsrGlobalMethods.stopScan=true;
handles.EsrGlobalMethods.EnableGui(handles);
end

% --- Executes on button press in buttonBrowseSequences.
function buttonBrowseSequences_Callback(hObject, eventdata, handles)
% hObject    handle to buttonBrowseSequences (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
            
   [filename pathname] = uigetfile('*.esr', 'Select Pulse Sequence',...
            handles.EsrGlobalMethods.imageScanHandles.configS.sequenceFolder);
    try
         file1 = [pathname filename];
    catch err %#ok
         file1 = [];
    end

    %return if no good file is available
    if isempty(file1) || ~ischar(file1)
        return;
    end
    %Check to see that the file is good
    fid = fopen(file1);
    if fid == -1
        return;
    end
    fclose(fid);
    % if the file looks fine set the path/file on GUI:
    set(handles.fileboxPulseSequence, 'String', file1);
end


function fileboxPulseSequence_Callback(hObject, eventdata, handles)
% hObject    handle to fileboxPulseSequence (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of fileboxPulseSequence as text
%        str2double(get(hObject,'String')) returns contents of fileboxPulseSequence as a double
end

% --- Executes during object creation, after setting all properties.
function fileboxPulseSequence_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fileboxPulseSequence (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on button press in buttonTestSequence.
function buttonTestSequence_Callback(hObject, eventdata, handles)
% hObject    handle to buttonTestSequence (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.EsrPulsedSweep.TestOutputSequence(handles);
end

% --- Executes on button press in buttonStopTestSequence.
function buttonStopTestSequence_Callback(hObject, eventdata, handles)
% hObject    handle to buttonStopTestSequence (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.EsrPulsedSweep.StopTestSequence();
end

% --- Executes on button press in checkboxUseTracking.
function checkboxUseTracking_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxUseTracking (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxUseTracking
end

% --- Executes on button press in buttonOpenTrackingParameters.
function buttonOpenTrackingParameters_Callback(hObject, eventdata, handles)
% hObject    handle to buttonOpenTrackingParameters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


ConfigureTracking(handles.ScanControl.TrackingParameters);
end


function centerFreq_Callback(hObject, eventdata, handles)
% hObject    handle to centerFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of centerFreq as text
%        str2double(get(hObject,'String')) returns contents of centerFreq as a double
end

% --- Executes during object creation, after setting all properties.
function centerFreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to centerFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function amplitude_Callback(hObject, eventdata, handles)
% hObject    handle to amplitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of amplitude as text
%        str2double(get(hObject,'String')) returns contents of amplitude as a double
input = str2num(get(hObject,'String'));
            if (isempty(input))
                set(hObject,'String',-110); % default for empty string
            end
                    if (input > -5)   
                        set(hObject,'String','-5');
                    end
                    if (input<-110) 
                        set(hObject,'String','-110');
                    end
                    
             set(hObject, 'String', num2str(input));       
                    % now actually set the frequency on the instrument
                    
end

% --- Executes during object creation, after setting all properties.
function amplitude_CreateFcn(hObject, eventdata, handles)
% hObject    handle to amplitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function cwTrackingPeriod_Callback(hObject, eventdata, handles)
% hObject    handle to cwTrackingPeriod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of cwTrackingPeriod as text
%        str2double(get(hObject,'String')) returns contents of cwTrackingPeriod as a double

% make the variable an integer greater than 4
set(hObject,'String',num2str(floor(str2double(get(hObject,'String')))));
if str2double(get(hObject,'String')) <= 5
    set(hObject,'String',num2str(5));
end
end

% --- Executes during object creation, after setting all properties.
function cwTrackingPeriod_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cwTrackingPeriod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function pulseTrackingPeriod_Callback(hObject, eventdata, handles)
% hObject    handle to pulseTrackingPeriod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of pulseTrackingPeriod as text
%        str2double(get(hObject,'String')) returns contents of pulseTrackingPeriod as a double

% make the variable an integer greater than 4
set(hObject,'String',num2str(floor(str2double(get(hObject,'String')))));
if str2double(get(hObject,'String')) <= 2
    set(hObject,'String',num2str(5));
end
end

% --- Executes during object creation, after setting all properties.
function pulseTrackingPeriod_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pulseTrackingPeriod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function trackingGarbagePoints_Callback(hObject, eventdata, handles)
% hObject    handle to trackingGarbagePoints (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of trackingGarbagePoints as text
%        str2double(get(hObject,'String')) returns contents of trackingGarbagePoints as a double

% make the variable an integer greater than 0
set(hObject,'String',num2str(floor(str2double(get(hObject,'String')))));
if str2double(get(hObject,'String')) <= 0
    set(hObject,'String',num2str(1));
end
end

% --- Executes during object creation, after setting all properties.
function trackingGarbagePoints_CreateFcn(hObject, eventdata, handles)
% hObject    handle to trackingGarbagePoints (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function esrSavePath_Callback(hObject, eventdata, handles)
% hObject    handle to esrSavePath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of esrSavePath as text
%        str2double(get(hObject,'String')) returns contents of esrSavePath as a double
end

% --- Executes during object creation, after setting all properties.
function esrSavePath_CreateFcn(hObject, eventdata, handles)
% hObject    handle to esrSavePath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function CWFreqDeviation_Callback(hObject, eventdata, handles)
% hObject    handle to CWFreqDeviation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of CWFreqDeviation as text
%        str2double(get(hObject,'String')) returns contents of CWFreqDeviation as a double
input = abs(str2num(get(hObject, 'String')));
            if isempty(input)
                input = 100;
            else
            %N-type output
                        if input > 1999.9
                            input = 100;
                        end
            end
            set(hObject, 'String', num2str(input));
end

% --- Executes during object creation, after setting all properties.
function CWFreqDeviation_CreateFcn(hObject, eventdata, handles)
% hObject    handle to CWFreqDeviation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function pulseFreqDeviation_Callback(hObject, eventdata, handles)
% hObject    handle to pulseFreqDeviation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of pulseFreqDeviation as text
%        str2double(get(hObject,'String')) returns contents of pulseFreqDeviation as a double
input = abs(str2num(get(hObject, 'String')));
            if isempty(input)
                input = 2.5;
            else
            %N-type output
                        if input > 1999.9
                            input = 2.5;
                        end
            end
            set(hObject, 'String', num2str(input));
end

% --- Executes during object creation, after setting all properties.
function pulseFreqDeviation_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pulseFreqDeviation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function numFreqSteps_Callback(hObject, eventdata, handles)
% hObject    handle to numFreqSteps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numFreqSteps as text
%        str2double(get(hObject,'String')) returns contents of numFreqSteps as a double

% make the variable an integer greater than 1
set(hObject,'String',num2str(floor(str2double(get(hObject,'String')))));
if str2double(get(hObject,'String')) <= 1
    set(hObject,'String',num2str(2));
end
end

% --- Executes during object creation, after setting all properties.
function numFreqSteps_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numFreqSteps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function timePerFreqStep_Callback(hObject, eventdata, handles)
% hObject    handle to timePerFreqStep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of timePerFreqStep as text
%        str2double(get(hObject,'String')) returns contents of timePerFreqStep as a double

% make the variable an integer greater than 0
set(hObject,'String',num2str(floor(str2double(get(hObject,'String')))));
if str2double(get(hObject,'String')) <= 0
    set(hObject,'String',num2str(1));
end
end

% --- Executes during object creation, after setting all properties.
function timePerFreqStep_CreateFcn(hObject, eventdata, handles)
% hObject    handle to timePerFreqStep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function esrSaveFilePrefix_Callback(hObject, eventdata, handles)
% hObject    handle to esrSaveFilePrefix (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of esrSaveFilePrefix as text
%        str2double(get(hObject,'String')) returns contents of esrSaveFilePrefix as a double
end

% --- Executes during object creation, after setting all properties.
function esrSaveFilePrefix_CreateFcn(hObject, eventdata, handles)
% hObject    handle to esrSaveFilePrefix (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function esrSaveFileNum_Callback(hObject, eventdata, handles)
% hObject    handle to esrSaveFileNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of esrSaveFileNum as text
%        str2double(get(hObject,'String')) returns contents of esrSaveFileNum as a double
end

% --- Executes during object creation, after setting all properties.
function esrSaveFileNum_CreateFcn(hObject, eventdata, handles)
% hObject    handle to esrSaveFileNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function writeDataFreq_Callback(hObject, eventdata, handles)
% hObject    handle to writeDataFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of writeDataFreq as text
%        str2double(get(hObject,'String')) returns contents of writeDataFreq as a double
end

% --- Executes during object creation, after setting all properties.
function writeDataFreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to writeDataFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on selection change in popupmenuSequenceDefaults.
function popupmenuSequenceDefaults_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuSequenceDefaults (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuSequenceDefaults contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuSequenceDefaults
end

% --- Executes during object creation, after setting all properties.
function popupmenuSequenceDefaults_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuSequenceDefaults (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on button press in buttonStartCWESR.
function buttonStartCWESR_Callback(hObject, eventdata, handles)
% hObject    handle to buttonStartCWESR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.EsrCWSweep.PerformCWESR(handles);
end

% --- Executes on button press in buttonStopCWESR.
function buttonStopCWESR_Callback(hObject, eventdata, handles)
% hObject    handle to buttonStopCWESR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.EsrGlobalMethods.stopScan=true;
handles.EsrGlobalMethods.EnableGui(handles);
end


function numAverages_Callback(hObject, eventdata, handles)
% hObject    handle to numAverages (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numAverages as text
%        str2double(get(hObject,'String')) returns contents of numAverages as a double

% make the variable an integer greater than 0
set(hObject,'String',num2str(floor(str2double(get(hObject,'String')))));
if str2double(get(hObject,'String')) <= 0
    set(hObject,'String',num2str(1));
end
end

% --- Executes during object creation, after setting all properties.
function numAverages_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numAverages (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on button press in buttonAddNVPosition.
function buttonAddNVPosition_Callback(hObject, eventdata, handles)
% hObject    handle to buttonAddNVPosition (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

arrayNV = get(handles.tableNVPositions,'Data');
    xposAdd = str2num(get(handles.EsrGlobalMethods.imageScanHandles.editPositionX,'String'));
    yposAdd = str2num(get(handles.EsrGlobalMethods.imageScanHandles.editPositionY,'String'));
    nextLine = str2num(get(handles.nextNVLineToEdit,'String'));
    nextName = get(handles.nextNVName,'String');
    arrayNV(nextLine,:) = {nextName, xposAdd, yposAdd};
    
    set(handles.tableNVPositions,'Data',arrayNV);
    
    % increment the next line to add
    set(handles.nextNVLineToEdit,'String',num2str(nextLine+1));
end

% --- Executes on button press in buttonClearPositionsList.
function buttonClearPositionsList_Callback(hObject, eventdata, handles)
% hObject    handle to buttonClearPositionsList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

choice = questdlg('Are you sure you want to clear the table?','NV Table','Yes','No','No');

switch(choice)
    case 'Yes'
        arrayNV = {};
        set(handles.tableNVPositions,'Data',arrayNV);
        set(handles.nextNVLineToEdit,'String',num2str(1));
    case 'No'
    case 'Cancel'
end
end

% --- Executes on button press in buttonStartAutomation.
function buttonStartAutomation_Callback(hObject, eventdata, handles)
% hObject    handle to buttonStartAutomation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end

% --- Executes on button press in buttonStopAutomation.
function buttonStopAutomation_Callback(hObject, eventdata, handles)
% hObject    handle to buttonStopAutomation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end


function preReadoutWait_Callback(hObject, eventdata, handles)
% hObject    handle to preReadoutWait (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of preReadoutWait as text
%        str2double(get(hObject,'String')) returns contents of preReadoutWait as a double

% make the variable an integer greater than 1 ns
set(hObject,'String',num2str(floor(str2double(get(hObject,'String')))));
if str2double(get(hObject,'String')) <= 1
    set(hObject,'String',num2str(0));
end
end

% --- Executes during object creation, after setting all properties.
function preReadoutWait_CreateFcn(hObject, eventdata, handles)
% hObject    handle to preReadoutWait (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function depopulationTime_Callback(hObject, eventdata, handles)
% hObject    handle to depopulationTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of depopulationTime as text
%        str2double(get(hObject,'String')) returns contents of depopulationTime as a double

% make the variable an integer greater than 1 ns
set(hObject,'String',num2str(floor(str2double(get(hObject,'String')))));
if str2double(get(hObject,'String')) <= 0
    set(hObject,'String',num2str(0));
end
end

% --- Executes during object creation, after setting all properties.
function depopulationTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to depopulationTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function piTime_Callback(hObject, eventdata, handles)
% hObject    handle to piTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of piTime as text
%        str2double(get(hObject,'String')) returns contents of piTime as a double

% make the variable an integer greater than 1 ns
set(hObject,'String',num2str(floor(str2double(get(hObject,'String')))));
if str2double(get(hObject,'String')) <= 1
    set(hObject,'String',num2str(2));
end
end

% --- Executes during object creation, after setting all properties.
function piTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to piTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function sampleWidth_Callback(hObject, eventdata, handles)
% hObject    handle to sampleWidth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of sampleWidth as text
%        str2double(get(hObject,'String')) returns contents of sampleWidth as a double

% make the variable an integer greater than 1 ns
set(hObject,'String',num2str(floor(str2double(get(hObject,'String')))));
if str2double(get(hObject,'String')) <= 1
    set(hObject,'String',num2str(2));
end
end

% --- Executes during object creation, after setting all properties.
function sampleWidth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sampleWidth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function delayTimeAOM_Callback(hObject, eventdata, handles)
% hObject    handle to delayTimeAOM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of delayTimeAOM as text
%        str2double(get(hObject,'String')) returns contents of delayTimeAOM as a double

% make the variable an integer greater than 1 ns
set(hObject,'String',num2str(floor(str2double(get(hObject,'String')))));
if str2double(get(hObject,'String')) <= 1
    set(hObject,'String',num2str(2));
end
end

% --- Executes during object creation, after setting all properties.
function delayTimeAOM_CreateFcn(hObject, eventdata, handles)
% hObject    handle to delayTimeAOM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function initTime_Callback(hObject, eventdata, handles)
% hObject    handle to initTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of initTime as text
%        str2double(get(hObject,'String')) returns contents of initTime as a double

% make the variable an integer greater than 1 ns
set(hObject,'String',num2str(floor(str2double(get(hObject,'String')))));
if str2double(get(hObject,'String')) <= 1
    set(hObject,'String',num2str(2));
end
end

% --- Executes during object creation, after setting all properties.
function initTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to initTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function readoutTime_Callback(hObject, eventdata, handles)
% hObject    handle to readoutTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of readoutTime as text
%        str2double(get(hObject,'String')) returns contents of readoutTime as a double

% make the variable an integer greater than 1 ns
set(hObject,'String',num2str(floor(str2double(get(hObject,'String')))));
if str2double(get(hObject,'String')) <= 1
    set(hObject,'String',num2str(2));
end
end

% --- Executes during object creation, after setting all properties.
function readoutTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to readoutTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function repsPerTau_Callback(hObject, eventdata, handles)
% hObject    handle to repsPerTau (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of repsPerTau as text
%        str2double(get(hObject,'String')) returns contents of repsPerTau as a double
% make the variable an integer greater than 10
set(hObject,'String',num2str(floor(str2double(get(hObject,'String')))));
if str2double(get(hObject,'String')) <= 10
    set(hObject,'String',num2str(10));
end
end

% --- Executes during object creation, after setting all properties.
function repsPerTau_CreateFcn(hObject, eventdata, handles)
% hObject    handle to repsPerTau (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function numLoops_Callback(hObject, eventdata, handles)
% hObject    handle to numLoops (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numLoops as text
%        str2double(get(hObject,'String')) returns contents of numLoops as a double

% make the variable an integer greater than 0
set(hObject,'String',num2str(floor(str2double(get(hObject,'String')))));
if str2double(get(hObject,'String')) <= 0
    set(hObject,'String',num2str(1));
end
end

% --- Executes during object creation, after setting all properties.
function numLoops_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numLoops (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function numTauPoints_Callback(hObject, eventdata, handles)
% hObject    handle to numTauPoints (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numTauPoints as text
%        str2double(get(hObject,'String')) returns contents of numTauPoints as a double

% make the variable an integer greater than 1
set(hObject,'String',num2str(floor(str2double(get(hObject,'String')))));
if str2double(get(hObject,'String')) <= 1
    set(hObject,'String',num2str(1));
end
end

% --- Executes during object creation, after setting all properties.
function numTauPoints_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numTauPoints (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function tauEnd_Callback(hObject, eventdata, handles)
% hObject    handle to tauEnd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tauEnd as text
%        str2double(get(hObject,'String')) returns contents of tauEnd as a double

% make the variable an integer greater or equal to 10 ns
input = floor(str2double(get(hObject,'String')));
if input < 10
    input = 10;
end
input = input - mod(input,2); % and make it modulus 2 for the pulseblaster
set(hObject,'String',num2str(input));
end

% --- Executes during object creation, after setting all properties.
function tauEnd_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tauEnd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function tauStart_Callback(hObject, eventdata, handles)
% hObject    handle to tauStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tauStart as text
%        str2double(get(hObject,'String')) returns contents of tauStart as a double

% make the variable an integer greater or equal to 0 ns
input = floor(str2double(get(hObject,'String')));
if input < 0
    input = 0;
end
input = input - mod(input,2); % and make it modulus 2 for the pulseblaster
set(hObject,'String',num2str(input));
end

% --- Executes during object creation, after setting all properties.
function tauStart_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tauStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on button press in buttonSetParamsToSelection.
function buttonSetParamsToSelection_Callback(hObject, eventdata, handles)
% hObject    handle to buttonSetParamsToSelection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% this must set all the GUI edit boxes for the particular choice.
measurementSelection = get(handles.popupmenuSequenceDefaults,'Value');

EsrDefaultSequenceSettings( measurementSelection, handles );
    
end


function preMeasurePause_Callback(hObject, eventdata, handles)
% hObject    handle to preMeasurePause (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of preMeasurePause as text
%        str2double(get(hObject,'String')) returns contents of preMeasurePause as a double

% make the variable an positive value
if str2double(get(hObject,'String')) < 0
    set(hObject,'String',num2str(0));
end
end

% --- Executes during object creation, after setting all properties.
function preMeasurePause_CreateFcn(hObject, eventdata, handles)
% hObject    handle to preMeasurePause (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on button press in togglebuttonRF.
function togglebuttonRF_Callback(hObject, eventdata, handles)
% hObject    handle to togglebuttonRF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togglebuttonRF

newVal = get(hObject,'Value');
handles.EsrGlobalMethods.ToggleRF(newVal,handles);
end


function numPulseFreqPoints_Callback(hObject, eventdata, handles)
% hObject    handle to numPulseFreqPoints (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numPulseFreqPoints as text
%        str2double(get(hObject,'String')) returns contents of numPulseFreqPoints as a double

% make the variable an integer greater than 1
set(hObject,'String',num2str(floor(str2double(get(hObject,'String')))));
if str2double(get(hObject,'String')) <= 1
    set(hObject,'String',num2str(2));
end
end

% --- Executes during object creation, after setting all properties.
function numPulseFreqPoints_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numPulseFreqPoints (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function repsPerFreqPoint_Callback(hObject, eventdata, handles)
% hObject    handle to repsPerFreqPoint (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of repsPerFreqPoint as text
%        str2double(get(hObject,'String')) returns contents of repsPerFreqPoint as a double

% make the variable an integer greater than 10
set(hObject,'String',num2str(floor(str2double(get(hObject,'String')))));
if str2double(get(hObject,'String')) <= 10
    set(hObject,'String',num2str(10));
end
end

% --- Executes during object creation, after setting all properties.
function repsPerFreqPoint_CreateFcn(hObject, eventdata, handles)
% hObject    handle to repsPerFreqPoint (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes when selected object is changed in panelMultipleDAQ.
function panelMultipleDAQ_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in panelMultipleDAQ 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
end


% --- Executes on button press in checkboxAOMInverter.
function checkboxAOMInverter_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxAOMInverter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxAOMInverter
end


% --- Executes on button press in checkboxDoAutoFit.
function checkboxDoAutoFit_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxDoAutoFit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxDoAutoFit
end



function Dsplitting_Callback(hObject, eventdata, handles)
% hObject    handle to Dsplitting (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Dsplitting as text
%        str2double(get(hObject,'String')) returns contents of Dsplitting as a double
end

% --- Executes during object creation, after setting all properties.
function Dsplitting_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Dsplitting (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function trackingCountThreshold_Callback(hObject, eventdata, handles)
% hObject    handle to trackingCountThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of trackingCountThreshold as text
%        str2double(get(hObject,'String')) returns contents of trackingCountThreshold as a double

% make the variable a number < 1, > 0
if str2double(get(hObject,'String')) < 0
    set(hObject,'String',num2str(0));
end
if str2double(get(hObject,'String')) > 1
    set(hObject,'String',num2str(1));
end
end

% --- Executes during object creation, after setting all properties.
function trackingCountThreshold_CreateFcn(hObject, eventdata, handles)
% hObject    handle to trackingCountThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function IQTime_Callback(hObject, eventdata, handles)
% hObject    handle to IQTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of IQTime as text
%        str2double(get(hObject,'String')) returns contents of IQTime as a double

% make the variable an integer greater than 1 ns
set(hObject,'String',num2str(floor(str2double(get(hObject,'String')))));
if str2double(get(hObject,'String')) <= 1
    set(hObject,'String',num2str(2));
end
end

% --- Executes during object creation, after setting all properties.
function IQTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to IQTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function nextNVLineToEdit_Callback(hObject, eventdata, handles)
% hObject    handle to nextNVLineToEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of nextNVLineToEdit as text
%        str2double(get(hObject,'String')) returns contents of nextNVLineToEdit as a double

% make the variable an integer greater than 0
set(hObject,'String',num2str(floor(str2double(get(hObject,'String')))));
if str2double(get(hObject,'String')) < 1
    set(hObject,'String',num2str(1));
end
end

% --- Executes during object creation, after setting all properties.
function nextNVLineToEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to nextNVLineToEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function nextNVName_Callback(hObject, eventdata, handles)
% hObject    handle to nextNVName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of nextNVName as text
%        str2double(get(hObject,'String')) returns contents of nextNVName as a double
end

% --- Executes during object creation, after setting all properties.
function nextNVName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to nextNVName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in buttonSaveNVTableData.
function buttonSaveNVTableData_Callback(hObject, eventdata, handles)
% hObject    handle to buttonSaveNVTableData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[NVTfilename NVTpathname] = uiputfile('*.nvt', 'Select file to save NV table to', ...
                    [handles.EsrGlobalMethods.imageScanHandles.configS.dataFolder 'savedNVPositionConfigurations\']);
                
NVTfid = fopen([NVTpathname NVTfilename], 'w');
arrayNV = get(handles.tableNVPositions,'Data');
[nnmax, ~] = size(arrayNV);
fprintf(NVTfid,'%s\t%s\t%s\n','NVname','Xcursor','Ycursor');
for nn=1:nnmax
    fprintf(NVTfid,'%s\t%d\t%d\n',(arrayNV{nn,1}),(arrayNV{nn,2}),(arrayNV{nn,3}));
end
fclose(NVTfid);
end


% --- Executes on button press in buttonLoadNVTableData.
function buttonLoadNVTableData_Callback(hObject, eventdata, handles)
% hObject    handle to buttonLoadNVTableData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[filename, pathname, filterindex] = uigetfile( ...
       {'*.nvt', 'NV Table Files (*.nvt)'}, ...
        'Pick a file',[handles.EsrGlobalMethods.imageScanHandles.configS.dataFolder 'savedNVPositionConfigurations\']);
    
nvtStruct = tdfread([pathname filename]);
[m, ~] = size(nvtStruct.Xcursor);

for nn=1:m
    arrayNVloaded{nn,1} = nvtStruct.NVname(nn,:); % char type so use (nn,:) for all characters
    arrayNVloaded{nn,2} =  nvtStruct.Xcursor(nn); % numerical type
    arrayNVloaded{nn,3} = nvtStruct.Ycursor(nn); % numerical type
end
set(handles.tableNVPositions,'Data',arrayNVloaded);
end


% --- Executes on button press in buttonBrowseAutomationSequence.
function buttonBrowseAutomationSequence_Callback(hObject, eventdata, handles)
% hObject    handle to buttonBrowseAutomationSequence (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end


% --- Executes on button press in buttonSetNewCursorReference.
function buttonSetNewCursorReference_Callback(hObject, eventdata, handles)
% hObject    handle to buttonSetNewCursorReference (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

arrayNV = get(handles.tableNVPositions,'Data');
    xposAdd = str2num(get(handles.EsrGlobalMethods.imageScanHandles.editPositionX,'String'));
    yposAdd = str2num(get(handles.EsrGlobalMethods.imageScanHandles.editPositionY,'String'));
    nextLine = 1;
    nextName = arrayNV{1,1};
    line1OldX = arrayNV{1,2};
    line1OldY = arrayNV{1,3};
    arrayNV(nextLine,:) = {nextName, xposAdd, yposAdd};
    
    % compute the rest of the coordinates relative to this new value
    [m, n] = size(arrayNV);
    if m > 1     
        for nn=2:m
            oldx = arrayNV{nn,2};
            delx = oldx-line1OldX;
            newx = xposAdd+delx;
            arrayNV{nn,2} = newx;
            
            oldy = arrayNV{nn,3};
            dely = oldy-line1OldY;
            newy = yposAdd+dely;
            arrayNV{nn,3} = newy;
        end
    end
    set(handles.tableNVPositions,'Data',arrayNV);
    
end


% --- Executes on button press in buttonOpenNVAutomationEditor.
function buttonOpenNVAutomationEditor_Callback(hObject, eventdata, handles)
% hObject    handle to buttonOpenNVAutomationEditor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% pass to the Auto Editor Gui the ESRControl Handles 
handles.ESRAutoEditor = ESRAutoEditor(handles); 
end


% --- Executes on button press in buttonSaveSettingsFile.
function buttonSaveSettingsFile_Callback(~, ~, handles)
% hObject    handle to buttonSaveSettingsFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
settingsS.preMeasurePause = str2double(get(handles.preMeasurePause,'String'));
settingsS.tauStart = str2double(get(handles.tauStart,'String'));
settingsS.tauEnd = str2double(get(handles.tauEnd,'String'));
settingsS.numTauPoints = str2double(get(handles.numTauPoints,'String'));
settingsS.numLoops = str2double(get(handles.numLoops,'String'));
settingsS.pulseFreqDeviation = str2double(get(handles.pulseFreqDeviation,'String'));
settingsS.numPulseFreqPoints = str2double(get(handles.numPulseFreqPoints,'String'));
settingsS.repsPerFreqPoint = str2double(get(handles.repsPerFreqPoint,'String'));
settingsS.repsPerTau = str2double(get(handles.repsPerTau,'String'));
settingsS.depopulationTime = str2double(get(handles.depopulationTime,'String'));
settingsS.preReadoutWait = str2double(get(handles.preReadoutWait,'String'));
settingsS.sampleWidth = str2double(get(handles.sampleWidth,'String'));
settingsS.delayTimeAOM = str2double(get(handles.delayTimeAOM,'String'));
settingsS.initTime = str2double(get(handles.initTime,'String'));
settingsS.readoutTime = str2double(get(handles.readoutTime,'String'));
settingsS.fileboxPulseSequence = get(handles.fileboxPulseSequence,'String');
settingsS.radio1Channel = get(handles.radio1Channel,'Value');
settingsS.checkboxSaveDataPerShot = get(handles.checkboxSaveDataPerShot,'Value');
% settingsS.radio2Channel = get(handles.radio2Channel,'Value');
% settingsS.radio4Channel = get(handles.radio4Channel,'Value');
settingsS.radio1Trig2Sig = get(handles.radio1Trig2Sig,'Value');
settingsS.radioTauSweep = get(handles.radioTauSweep,'Value');
settingsS.radioPulsedESR = get(handles.radioPulsedESR,'Value');
settingsS.radioCheckPiPulse = get(handles.radioCheckPiPulse,'Value');
settingsS.radioCheckRedSpec = get(handles.radioCheckRedSpec,'Value');
settingsS.checkboxIQEnabled = get(handles.checkboxIQEnabled,'Value');
settingsS.checkboxSignal50ns = get(handles.checkboxSignal50ns,'Value');
settingsS.checkboxReference50ns = get(handles.checkboxReference50ns,'Value');

defaultPath = [handles.EsrGlobalMethods.imageScanHandles.configS.sequenceFolder 'PulseSequenceSettings\'];
if exist(defaultPath,'dir') ==0 %path does not exist?
    mkdir(defaultPath);
end
[filename, fpath, ~] = uiputfile('*.pss','Save Settings As...',defaultPath);

tdfwrite([fpath filename],settingsS);

end

% --- Executes on button press in buttonLoadSettingsFile.
function buttonLoadSettingsFile_Callback(hObject, eventdata, handles)
% hObject    handle to buttonLoadSettingsFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[filename pathname] = uigetfile('*.pss', 'Select Pulse Sequence Settings',...
                    [handles.EsrGlobalMethods.imageScanHandles.configS.sequenceFolder 'PulseSequenceSettings\']);
            try
                 file1 = [pathname filename];
            catch err %#ok
                 file1 = [];
            end
            
            %return if no good file is available
            if isempty(file1) || ~ischar(file1)
                return;
            end
            %Check to see that the file is good
            fid = fopen(file1);
            if fid == -1
                return;
            end
            fclose(fid);

settingsS = tdfread([pathname filename]);

set(handles.preMeasurePause,'String',num2str(settingsS.preMeasurePause));
set(handles.tauStart,'String',num2str(settingsS.tauStart));
set(handles.tauEnd,'String',num2str(settingsS.tauEnd));
set(handles.numTauPoints,'String',num2str(settingsS.numTauPoints));
set(handles.numLoops,'String',num2str(settingsS.numLoops));
set(handles.repsPerTau,'String',num2str(settingsS.repsPerTau));
set(handles.pulseFreqDeviation,'String',num2str(settingsS.pulseFreqDeviation));
set(handles.numPulseFreqPoints,'String',num2str(settingsS.numPulseFreqPoints));
set(handles.repsPerFreqPoint,'String',num2str(settingsS.repsPerFreqPoint));
set(handles.depopulationTime,'String',num2str(settingsS.depopulationTime));
set(handles.preReadoutWait,'String',num2str(settingsS.preReadoutWait));
set(handles.sampleWidth,'String',num2str(settingsS.sampleWidth));
set(handles.delayTimeAOM,'String',num2str(settingsS.delayTimeAOM));
set(handles.initTime,'String',num2str(settingsS.initTime));
set(handles.readoutTime,'String',num2str(settingsS.readoutTime));
set(handles.fileboxPulseSequence,'String',settingsS.fileboxPulseSequence);
set(handles.radio1Channel,'Value',settingsS.radio1Channel);
% set(handles.radio2Channel,'Value',settingsS.radio2Channel);
% set(handles.radio4Channel,'Value',settingsS.radio4Channel);
set(handles.radio1Trig2Sig,'Value',settingsS.radio1Trig2Sig);
set(handles.radioTauSweep,'Value',settingsS.radioTauSweep);
set(handles.radioPulsedESR,'Value',settingsS.radioPulsedESR);
set(handles.radioPulsedESR,'Value',settingsS.radioPulsedESR);
set(handles.radioCheckPiPulse,'Value',settingsS.radioCheckPiPulse);
set(handles.radioCheckRedSpec,'Value',settingsS.radioCheckRedSpec);
set(handles.checkboxIQEnabled,'Value',settingsS.checkboxIQEnabled);
set(handles.checkboxSignal50ns,'Value',settingsS.checkboxSignal50ns);
set(handles.checkboxReference50ns,'Value',settingsS.checkboxReference50ns);
set(handles.checkboxSaveDataPerShot,'Value',settingsS.checkboxSaveDataPerShot);

guidata(hObject, handles);
end

function tdfwrite(filename,st)
%
% function tdfwrite(filename,st)
%
% Saves structure st into filename
% st is a structure created with st=tdfread('file.tab');
%
% st is a structure with several fields.  Each field is a vector of numbers
% or a matrix of char. Field names are used as headers of each column.
%
% Warning: General format %.20g is used for numerical values. It works fine most
% of the time. Some applications may need to change the output format.
%
% Rafael Palacios, Oct 2009
%

%%Error checking
error(nargchk(2, 2, nargin));  %2 arguments required, 2 maximum
if (~ischar(filename))
    error('First argument must be the name of the file');
end
if (~isstruct(st))
    error('Second argument must be a strcuture');
end
%Field names
names=fieldnames(st);
rows=size(getfield(st,names{1}),1);
for j=2:length(names)
    if (rows~=size(getfield(st,names{j}),1))
        error('Field $s has a different length than first field (%s)',names{j},names{1});
    end
end


[fp,message]=fopen(filename,'w');
if (fp==-1)
    error('Error opening file: %s',message);
end
%header
fprintf(fp,'%s',names{1});
fprintf(fp,'\t%s',names{2:end});
fprintf(fp,'\n');
%values
for i=1:rows
    for j=1:length(names)
        if (j~=1)
            fprintf(fp,'\t');
        end
        v=getfield(st,names{j});
        if (ischar(v(1,1)))
            fprintf(fp,'%s',v(i,:));
        else
            fprintf(fp,'%.20g',v(i));  %general format
        end
    end
    fprintf(fp,'\n');
end
fclose(fp);
end


% --- Executes on button press in checkboxSignal50ns.
function checkboxSignal50ns_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxSignal50ns (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxSignal50ns
end

% --- Executes on button press in checkboxReference50ns.
function checkboxReference50ns_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxReference50ns (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxReference50ns
end



function plotAverageToStartAt_Callback(hObject, eventdata, handles)
% hObject    handle to plotAverageToStartAt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of plotAverageToStartAt as text
%        str2double(get(hObject,'String')) returns contents of plotAverageToStartAt as a double
end

% --- Executes during object creation, after setting all properties.
function plotAverageToStartAt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to plotAverageToStartAt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in checkboxUseExtraTauPoints.
function checkboxUseExtraTauPoints_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxUseExtraTauPoints (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxUseExtraTauPoints
end


function listExtraTauPoints_Callback(hObject, eventdata, handles)
% hObject    handle to listExtraTauPoints (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of listExtraTauPoints as text
%        str2double(get(hObject,'String')) returns contents of listExtraTauPoints as a double
end

% --- Executes during object creation, after setting all properties.
function listExtraTauPoints_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listExtraTauPoints (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in buttonCopySaveFileToClipboard.
function buttonCopySaveFileToClipboard_Callback(hObject, eventdata, handles)
% hObject    handle to buttonCopySaveFileToClipboard (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

clipboard('copy', [get(handles.esrSaveFilePrefix,'String') get(handles.esrSaveFileNum,'String')]);
end


% --- Executes on button press in buttonCopyFullPathToClipboard.
function buttonCopyFullPathToClipboard_Callback(hObject, eventdata, handles)
% hObject    handle to buttonCopyFullPathToClipboard (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
clipboard('copy', [get(handles.esrSavePath,'String') get(handles.esrSaveFilePrefix,'String') get(handles.esrSaveFileNum,'String')]);
end



function pulseAmplDeviation_Callback(hObject, eventdata, handles)
% hObject    handle to pulseAmplDeviation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of pulseAmplDeviation as text
%        str2double(get(hObject,'String')) returns contents of pulseAmplDeviation as a double
end

% --- Executes during object creation, after setting all properties.
function pulseAmplDeviation_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pulseAmplDeviation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function numAmplPoints_Callback(hObject, eventdata, handles)
% hObject    handle to numAmplPoints (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numAmplPoints as text
%        str2double(get(hObject,'String')) returns contents of numAmplPoints as a double

% make the variable an integer greater than 1
set(hObject,'String',num2str(floor(str2double(get(hObject,'String')))));
if str2double(get(hObject,'String')) <= 1
    set(hObject,'String',num2str(2));
end
end

% --- Executes during object creation, after setting all properties.
function numAmplPoints_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numAmplPoints (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function repsPerAmplPoint_Callback(hObject, eventdata, handles)
% hObject    handle to repsPerAmplPoint (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of repsPerAmplPoint as text
%        str2double(get(hObject,'String')) returns contents of repsPerAmplPoint as a double
% make the variable an integer greater than 10
set(hObject,'String',num2str(floor(str2double(get(hObject,'String')))));
if str2double(get(hObject,'String')) <= 10
    set(hObject,'String',num2str(10));
end
end

% --- Executes during object creation, after setting all properties.
function repsPerAmplPoint_CreateFcn(hObject, eventdata, handles)
% hObject    handle to repsPerAmplPoint (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function numPiCycles_Callback(hObject, eventdata, handles)
% hObject    handle to numPiCycles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numPiCycles as text
%        str2double(get(hObject,'String')) returns contents of numPiCycles as a double

% make the variable an integer greater than 0
set(hObject,'String',num2str(floor(str2double(get(hObject,'String')))));
if str2double(get(hObject,'String')) < 1
    set(hObject,'String',num2str(1));
end
end

% --- Executes during object creation, after setting all properties.
function numPiCycles_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numPiCycles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in checkboxDifferentialMeasurement.
function checkboxDifferentialMeasurement_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxDifferentialMeasurement (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxDifferentialMeasurement
end


% --- Executes on selection change in popupClipboardIgorString.
function popupClipboardIgorString_Callback(hObject, eventdata, handles)
% hObject    handle to popupClipboardIgorString (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupClipboardIgorString contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupClipboardIgorString
end

% --- Executes during object creation, after setting all properties.
function popupClipboardIgorString_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupClipboardIgorString (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in buttonClipboardIgor.
function buttonClipboardIgor_Callback(hObject, eventdata, handles)
% hObject    handle to buttonClipboardIgor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
IgorSelection = get(handles.popupClipboardIgorString,'Value');

igorDateFull = get(handles.esrSavePath,'String');
igorDateTrunc = igorDateFull((end-6):(end-1));
latestIndex = num2str(str2num(get(handles.numCompleted,'String'))-2);
igorFolderName = [get(handles.esrSaveFilePrefix,'String') get(handles.esrSaveFileNum,'String')];
igorReps = get(handles.repsPerTau,'String');

switch(IgorSelection)
    case 1
        clipboard('copy', ['LoadCWESRsweep(' latestIndex ', "' igorDateTrunc '", "' igorFolderName '")']);

    case 2 % rabi x/pulsed ESR now
        clipboard('copy', ['LoadPulsedESR(' latestIndex ', "' igorDateTrunc '", "' igorFolderName '")']);
        
    case 3 % rabi XX or XY diff
        clipboard('copy', ['LoadESEEMDifferential(' latestIndex ', "' igorDateTrunc '", "' igorFolderName '",' igorReps ',1)']);
    
    case 4 % 1 tau X axis echo
        clipboard('copy', ['LoadN15ESEEM2chan(' latestIndex ', "' igorDateTrunc '", "' igorFolderName '",0,0,' igorReps ',1)']);
    
    case 5 % 2tau X axis echo
        clipboard('copy', ['LoadN15ESEEM2chan(' latestIndex ', "' igorDateTrunc '", "' igorFolderName '",0,0,' igorReps ',0)']);
        
    case 6 % 1tau X axis diff echo
        clipboard('copy', ['LoadESEEMDifferential(' latestIndex ', "' igorDateTrunc '", "' igorFolderName '",' igorReps ',1)']);
        
    case 7 % 2tau X axis diff echo
        clipboard('copy', ['LoadESEEMDifferential(' latestIndex ', "' igorDateTrunc '", "' igorFolderName '",' igorReps ',0)']);
        
    case 8 % T1 pi no-pi diff
        clipboard('copy', ['LoadESEEMDifferential(' latestIndex ', "' igorDateTrunc '", "' igorFolderName '",' igorReps ',2)']);
        
    case 9 % T1 zero state, NEEDS UPDATING
        clipboard('copy', ['LoadN15ESEEM2chan(' latestIndex ', "' igorDateTrunc '", "' igorFolderName '",0,0,' igorReps ',1)']);
        
    case 10  % XY4-n
        clipboard('copy', ['LoadN15ESEEM2chan(' latestIndex ', "' igorDateTrunc '", "' igorFolderName '",0,0,' igorReps ',8)']);
        
    case 11 % 1tau ramsey X 
        clipboard('copy', ['LoadN15ESEEM2chan(' latestIndex ', "' igorDateTrunc '", "' igorFolderName '",0,0,' igorReps ',1)']);
        
    case 12 % 1tau Ramsey X axis diff echo
        clipboard('copy', ['LoadESEEMDifferential(' latestIndex ', "' igorDateTrunc '", "' igorFolderName '",' igorReps ',1)']);
end
end


% --- Executes on button press in checkboxWithSwitch.
function checkboxWithSwitch_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxWithSwitch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxWithSwitch
end



function yPiTime_Callback(hObject, eventdata, handles)
% hObject    handle to yPiTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of yPiTime as text
%        str2double(get(hObject,'String')) returns contents of yPiTime as a double

% make the variable an integer greater than 1 ns
set(hObject,'String',num2str(floor(str2double(get(hObject,'String')))));
if str2double(get(hObject,'String')) <= 1
    set(hObject,'String',num2str(2));
end
end

% --- Executes during object creation, after setting all properties.
function yPiTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to yPiTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in checkboxPiCalSetTau.
function checkboxPiCalSetTau_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxPiCalSetTau (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxPiCalSetTau
end


% --- Executes on button press in checkboxShowTotalCounts.
function checkboxShowTotalCounts_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxShowTotalCounts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxShowTotalCounts
end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over buttonStartSequence.
function buttonStartSequence_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to buttonStartSequence (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end

% --- Executes on key press with focus on buttonStartSequence and none of its controls.
function buttonStartSequence_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to buttonStartSequence (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
end



function delayTimeAOMred_Callback(hObject, eventdata, handles)
% hObject    handle to delayTimeAOMred (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of delayTimeAOMred as text
%        str2double(get(hObject,'String')) returns contents of delayTimeAOMred as a double
end

% --- Executes during object creation, after setting all properties.
function delayTimeAOMred_CreateFcn(hObject, eventdata, handles)
% hObject    handle to delayTimeAOMred (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function numRedFreq_Callback(hObject, eventdata, handles)
% hObject    handle to numRedFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numRedFreq as text
%        str2double(get(hObject,'String')) returns contents of numRedFreq as a double
end

% --- Executes during object creation, after setting all properties.
function numRedFreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numRedFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function numRedLoops_Callback(hObject, eventdata, handles)
% hObject    handle to numRedLoops (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numRedLoops as text
%        str2double(get(hObject,'String')) returns contents of numRedLoops as a double
end

% --- Executes during object creation, after setting all properties.
function numRedLoops_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numRedLoops (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function redPulseLength_Callback(hObject, eventdata, handles)
% hObject    handle to redPulseLength (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of redPulseLength as text
%        str2double(get(hObject,'String')) returns contents of redPulseLength as a double
end

% --- Executes during object creation, after setting all properties.
function redPulseLength_CreateFcn(hObject, eventdata, handles)
% hObject    handle to redPulseLength (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function redDetuning_Callback(hObject, eventdata, handles)
% hObject    handle to redDetuning (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of redDetuning as text
%        str2double(get(hObject,'String')) returns contents of redDetuning as a double
handles.EsrPulsedSweep.ChangeRedDetuning(handles);
end

% --- Executes during object creation, after setting all properties.
function redDetuning_CreateFcn(hObject, eventdata, handles)
% hObject    handle to redDetuning (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in incDetuning.
function incDetuning_Callback(hObject, eventdata, handles)
% hObject    handle to incDetuning (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.EsrPulsedSweep.IncreaseRedDetuning(handles);
end
% --- Executes on button press in decDetuning.
function decDetuning_Callback(hObject, eventdata, handles)
% hObject    handle to decDetuning (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.EsrPulsedSweep.DecreaseRedDetuning(handles);
end

function stepDetuning_Callback(hObject, eventdata, handles)
% hObject    handle to stepDetuning (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of stepDetuning as text
%        str2double(get(hObject,'String')) returns contents of stepDetuning as a double
end

% --- Executes during object creation, after setting all properties.
function stepDetuning_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stepDetuning (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in redTuning.
function redTuning_Callback(hObject, eventdata, handles)
% hObject    handle to redTuning (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.EsrPulsedSweep.RedTuningSequence(handles);
end


function RedCenterFreq_Callback(hObject, eventdata, handles)
% hObject    handle to RedCenterFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of RedCenterFreq as text
%        str2double(get(hObject,'String')) returns contents of RedCenterFreq as a double
end

% --- Executes during object creation, after setting all properties.
function RedCenterFreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to RedCenterFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function RedFreqDev_Callback(hObject, eventdata, handles)
% hObject    handle to RedFreqDev (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of RedFreqDev as text
%        str2double(get(hObject,'String')) returns contents of RedFreqDev as a double
end

% --- Executes during object creation, after setting all properties.
function RedFreqDev_CreateFcn(hObject, eventdata, handles)
% hObject    handle to RedFreqDev (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function RedAverages_Callback(hObject, eventdata, handles)
% hObject    handle to RedAverages (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of RedAverages as text
%        str2double(get(hObject,'String')) returns contents of RedAverages as a double
end

% --- Executes during object creation, after setting all properties.
function RedAverages_CreateFcn(hObject, eventdata, handles)
% hObject    handle to RedAverages (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function delayTimeYellow_Callback(hObject, eventdata, handles)
% hObject    handle to delayTimeYellow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of delayTimeYellow as text
%        str2double(get(hObject,'String')) returns contents of delayTimeYellow as a double

% --- Executes during object creation, after setting all properties.
end
function delayTimeYellow_CreateFcn(hObject, eventdata, handles)
% hObject    handle to delayTimeYellow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function delayTimeRed_Callback(hObject, eventdata, handles)
% hObject    handle to delayTimeRed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of delayTimeRed as text
%        str2double(get(hObject,'String')) returns contents of delayTimeRed as a double

% --- Executes during object creation, after setting all properties.
end
function delayTimeRed_CreateFcn(hObject, eventdata, handles)
% hObject    handle to delayTimeRed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function greenShelfTime_Callback(hObject, eventdata, handles)
% hObject    handle to greenShelfTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of greenShelfTime as text
%        str2double(get(hObject,'String')) returns contents of greenShelfTime as a double


% --- Executes during object creation, after setting all properties.
end
function greenShelfTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to greenShelfTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

end

function redIonTime_Callback(hObject, eventdata, handles)
% hObject    handle to redIonTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of redIonTime as text
%        str2double(get(hObject,'String')) returns contents of redIonTime as a double


% --- Executes during object creation, after setting all properties.
end
function redIonTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to redIonTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

end

function userVar2_Callback(hObject, eventdata, handles)
% hObject    handle to userVar2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of userVar2 as text
%        str2double(get(hObject,'String')) returns contents of userVar2 as a double


% --- Executes during object creation, after setting all properties.
end
function userVar2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to userVar2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


end
function userVar3_Callback(hObject, eventdata, handles)
% hObject    handle to userVar3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of userVar3 as text
%        str2double(get(hObject,'String')) returns contents of userVar3 as a double


% --- Executes during object creation, after setting all properties.
end
function userVar3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to userVar3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function centerFreqB_Callback(hObject, eventdata, handles)
% hObject    handle to centerFreqB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of centerFreqB as text
%        str2double(get(hObject,'String')) returns contents of centerFreqB as a double
end

% --- Executes during object creation, after setting all properties.
function centerFreqB_CreateFcn(hObject, eventdata, handles)
% hObject    handle to centerFreqB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function centerFreqC_Callback(hObject, eventdata, handles)
% hObject    handle to centerFreqC (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of centerFreqC as text
%        str2double(get(hObject,'String')) returns contents of centerFreqC as a double
end

% --- Executes during object creation, after setting all properties.
function centerFreqC_CreateFcn(hObject, eventdata, handles)
% hObject    handle to centerFreqC (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function amplitudeB_Callback(hObject, eventdata, handles)
% hObject    handle to amplitudeB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of amplitudeB as text
%        str2double(get(hObject,'String')) returns contents of amplitudeB as a double
end

% --- Executes during object creation, after setting all properties.
function amplitudeB_CreateFcn(hObject, eventdata, handles)
% hObject    handle to amplitudeB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function amplitudeC_Callback(hObject, eventdata, handles)
% hObject    handle to amplitudeC (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of amplitudeC as text
%        str2double(get(hObject,'String')) returns contents of amplitudeC as a double
end

% --- Executes during object creation, after setting all properties.
function amplitudeC_CreateFcn(hObject, eventdata, handles)
% hObject    handle to amplitudeC (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in checkboxSaveDataPerShot.
function checkboxSaveDataPerShot_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxSaveDataPerShot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxSaveDataPerShot
end


% --- Executes on button press in useSRS2inPESR.
function useSRS2inPESR_Callback(hObject, eventdata, handles)
% hObject    handle to useSRS2inPESR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of useSRS2inPESR
end


% --- Executes on button press in quantInterpXY8.
function quantInterpXY8_Callback(hObject, eventdata, handles)
% hObject    handle to quantInterpXY8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of quantInterpXY8
end


% --- Executes on button press in prelocateSwitch.
function prelocateSwitch_Callback(hObject, eventdata, handles)
% hObject    handle to prelocateSwitch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of prelocateSwitch
end 
