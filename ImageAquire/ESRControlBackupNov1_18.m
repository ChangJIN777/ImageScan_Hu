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

% Last Modified by GUIDE v2.5 11-Jan-2018 20:04:31

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

set(handles.esrSavePath,'String',[handles.EsrGlobalMethods.imageScanHandles.configS.dataFolder myFormattedDate]);
set(handles.fileboxPulseSequence,'String',[handles.EsrGlobalMethods.imageScanHandles.configS.sequenceFolder 'inUseSequences\']);

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

if get(handles.radioTauSweep,'Value')==1
    handles.EsrPulsedSweep.PerformSequence(handles);
elseif get(handles.radioPulsedESR,'Value')==1
    handles.EsrPulsedSweep.PerformPulsedESRSequence(handles);
elseif get(handles.radioCheckPiPulse,'Value')==1
    handles.EsrPulsedSweep.PerformPiPulsePowerCalibration(handles);
end
end

% --- Executes on button press in buttonStopSequence.
function buttonStopSequence_Callback(hObject, eventdata, handles)
% hObject    handle to buttonStopSequence (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

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

runMode = 1;  %0 = only log, no actual measurements, 1=full measurements

handles.stopAutomation = 0;
% first we need to load the .nva and .nvcs files, and then make sure that
% there are some NVs labelled to measure, and go to the first one

% automation filebox should be valid already, I am going to not check every
% detail and assume for the first version of automation that the user has
% set up everything correctly
fileNVA = get(handles.fileboxAutomationSequence,'String');
fileNVCS = regexprep(fileNVA,'.nva','.nvcs');
autoCommandStruct = tdfread(fileNVA);
autoSettingsArray = dlmread(fileNVCS,'\t');
% row is the setting number, column is the command number

% cell array of command names
autoCommandList = fieldnames(autoCommandStruct); % new cell 
[numCommands, ~] = size(autoCommandList); 

% long way to update image scan handles if needed...and short name
handles.EsrGlobalMethods.imageScanHandles = guidata(handles.EsrGlobalMethods.imageScanHandles.buttonSaveLoadNVMarkers);
imageHand = handles.EsrGlobalMethods.imageScanHandles;

% get the NV positions information first from image scan
% the main important thing is the index, 0,1,2,3.. and positions of NVs
autoNVidList = handles.EsrGlobalMethods.imageScanHandles.listNVMarkers;
autoNVPosArray = handles.EsrGlobalMethods.imageScanHandles.listNVMarkerPos;
autoNVName = num2str(get(handles.EsrGlobalMethods.imageScanHandles.NVmarkerLetter,'String'));

autoNVindices=find(autoNVidList); % indices of the nonzero NV id #s, in case some are skipped
numNVs = length(autoNVindices); % total number of nonzero NV id #s

%--------------------------------
% start a log file to keep track of what this automation sequence is doing
autoSaveString = get(handles.fileboxAutomationSaveString,'String');
autoSavePath = get(handles.esrSavePath,'String');
if exist(autoSavePath,'dir') ==0 %path does not exist?
    mkdir(autoSavePath);
end
logfile = [autoSavePath autoSaveString '_log.txt'];
logid = fopen(logfile,'a');
if logid ~= -1
    DateVector = clock;
    startTime = datestr(DateVector);
    fprintf(logid,'%s\nAutomation %s started\n',startTime,autoSaveString);
    fprintf(logid,'Command file: %s\n',fileNVA);
    fprintf(logid,'Settings file: %s\n\n',fileNVCS);
    currLog = get(handles.automationLogBox,'String');
    newLog = sprintf('%s%s\nAutomation %s started\nCommand file: %s\nSettings file: %s\n\n',currLog,startTime,autoSaveString,fileNVA,fileNVCS);
    set(handles.automationLogBox,'String',newLog);
    guidata(hObject, handles);
end
fclose(logid);
%----------------------------------

%-----------------------------------
% move to the first NV using an implicit "zeroth" command
jNV = 1;
NVindex = autoNVindices(jNV);
oldNVpos = [autoNVPosArray(1,NVindex),autoNVPosArray(2,NVindex)]; %[x,y]
NVpos = oldNVpos;
NVid = autoNVidList(NVindex); 
set(handles.outputAutoCurrentNV,'String',['NV ', autoNVName, num2str(NVindex)]);
set(handles.outputAutoCurrentStatus,'String','Moving laser cursor');
        % use the absolute move command setting for the 1st NV
        set( imageHand.editPositionX,'String',num2str(NVpos(1)) );
        set( imageHand.editPositionY,'String',num2str(NVpos(2)) );
        % update the graphical cursor
        imageHand.CursorControl.deleteManualCursor(imageHand);
        imageHand.CursorControl.createManualCursor(imageHand);
        imageHand.CursorControl.updatePositionFromCursor(imageHand,[NVpos(1),NVpos(2)]);
logid = fopen(logfile,'a');
if logid ~= -1
    DateVector = clock;
    thisTime = datestr(DateVector);
    fprintf(logid,'----------------- NV %s%d ----------------\n',autoNVName,NVindex);
    fprintf(logid,'%s\nMoved laser to first target: NV %s%d position\n\n',thisTime,autoNVName,NVindex);
end
fclose(logid);        
%-----------------------------------
kC = 0;
while (kC <= numCommands) && (handles.stopAutomation==0)
    kC = kC + 1;
    
    % first decide what command this is.
    fullCommand = autoCommandList{kC}; % returns a 'char' class
    baseCommand = regexprep(fullCommand,'\d',''); % get rid of numbers at end to identify command
        
    % determine the type of command
    switch(baseCommand)
        case 'Move_cursor_to_next_NV'
            handles.EsrGlobalMethods.imageScanHandles = guidata(handles.EsrGlobalMethods.imageScanHandles.buttonSaveLoadNVMarkers);
            imageHand = handles.EsrGlobalMethods.imageScanHandles;
            oldNVpos = NVpos; % for relative positions
            jNV = jNV + 1;
            if jNV <= numNVs
                NVindex = autoNVindices(jNV);
                prevNVindex = autoNVindices(jNV-1);
                NVpos = [autoNVPosArray(1,NVindex),autoNVPosArray(2,NVindex)]; %[x,y]
                prevNVpos = [autoNVPosArray(1,prevNVindex),autoNVPosArray(2,prevNVindex)];
                NVid = autoNVidList(NVindex);
                set(handles.outputAutoCurrentNV,'String',['NV ', autoNVName, num2str(NVindex)]);
                set(handles.outputAutoCurrentStatus,'String','Moving laser cursor');

                % use the move command setting for the other NVs
                % typically this will be relative, but it is a setting
                if autoSettingsArray(2,kC) == 0 % relative
                    deltaPos = NVpos - prevNVpos;
                    prevCursor = [str2num(get( imageHand.editPositionX,'String')),...
                                    str2num(get( imageHand.editPositionY,'String'))];
                    set( imageHand.editPositionX,'String',num2str(prevCursor(1)+deltaPos(1)) );
                    set( imageHand.editPositionY,'String',num2str(prevCursor(2)+deltaPos(2)) );
                    % update the graphical cursor
                    imageHand.CursorControl.deleteManualCursor(imageHand);
                    imageHand.CursorControl.createManualCursor(imageHand);
                    imageHand.CursorControl.updatePositionFromCursor(imageHand,[prevCursor(1)+deltaPos(1),prevCursor(2)+deltaPos(2)]);
                    
                elseif autoSettingsArray(2,kC) == 1 % absolute
                    set( imageHand.editPositionX,'String',num2str(NVpos(1)) );
                    set( imageHand.editPositionY,'String',num2str(NVpos(2)) );
                    % update the graphical cursor
                    imageHand.CursorControl.deleteManualCursor(imageHand);
                    imageHand.CursorControl.createManualCursor(imageHand);
                    imageHand.CursorControl.updatePositionFromCursor(imageHand,[NVpos(1),NVpos(2)]);
                end
                logid = fopen(logfile,'a');
                if logid ~= -1
                    DateVector = clock;
                    thisTime = datestr(DateVector);
                    fprintf(logid,'----------------- NV %s%d ----------------\n',autoNVName,NVindex);
                    fprintf(logid,'%s\nMoved laser to NV %s%d position\n\n',thisTime,autoNVName,NVindex);
                end
                fclose(logid); 
                
                % since this Move_cursor_to_next_NV is typically the last command
                % we want to reset the command counter kC to loop again
                kC = 0;
                
            else
               break; % get out of the for loop if we are done with all NVs
            end
                   
        case 'Track_current_NV'
            % the single track could be carried out just as it is from ESR
            % control and CW sweep.
            set(handles.outputAutoCurrentStatus,'String','3D Tracking');
            handles.EsrGlobalMethods.imageScanHandles = guidata(handles.EsrGlobalMethods.imageScanHandles.buttonSaveLoadNVMarkers);
            imageHand = handles.EsrGlobalMethods.imageScanHandles;
            numTrackCycles = autoSettingsArray(1,kC);
            trackFilterPos = autoSettingsArray(2,kC);
            
                logid = fopen(logfile,'a');
                if logid ~= -1
                    DateVector = clock;
                    thisTime = datestr(DateVector);
                    fprintf(logid,'%s\nStarted 3D tracking of NV %s%d for %d cycles\n\n',thisTime,autoNVName,NVindex,numTrackCycles);
                end
                fclose(logid); 
                
                if runMode==1
                    if imageHand.configS.numUSBFilterWheels>0
                        imageHand.FilterWheel.goToFilter(imageHand, trackFilterPos);
                        logid = fopen(logfile,'a');
                        if logid ~= -1
                            fprintf(logid,'Filter wheel to position %d\n',trackFilterPos);
                        end
                        fclose(logid);
                    end
                    for tt=1:numTrackCycles
                        logid = fopen(logfile,'a');
                        if logid ~= -1
                            fprintf(logid,'Track cycle %d begins\n',tt);
                        end
                        fclose(logid);
                        handles.EsrGlobalMethods.RunSingleTrackPulsedESR(imageHand); 
                    end
                end
                
                logid = fopen(logfile,'a');
                if logid ~= -1
                    DateVector = clock;
                    thisTime = datestr(DateVector);
                    fprintf(logid,'%s\nCompleted 3D tracking of NV %s%d\n\n',thisTime,autoNVName,NVindex);
                end
                fclose(logid);
                
            
        case 'CWESR_measurement' 
                logid = fopen(logfile,'a');
                if logid ~= -1
                    DateVector = clock;
                    thisTime = datestr(DateVector);
                    fprintf(logid,'%s\nStarted CWESR of NV %s%d\n\n',thisTime,autoNVName,NVindex);
                end
                fclose(logid);
                set(handles.outputAutoCurrentStatus,'String','CW ESR');
                
                commSave = autoCommandStruct.(autoCommandList{kC});
                    set(handles.esrSaveFilePrefix,'String',[get(handles.fileboxAutomationSaveString,'String'),...
                                                            '_NV' autoNVName num2str(NVindex) '_' commSave]);
                if runMode==1
                    % first initialize settings on the esrcontrol GUI
                    set(handles.amplitude,'String',num2str(autoSettingsArray(1,kC)));
                    set(handles.centerFreq,'String',num2str(autoSettingsArray(2,kC)));
                    set(handles.CWFreqDeviation,'String',num2str(autoSettingsArray(3,kC)));
                    set(handles.numFreqSteps,'String',num2str(autoSettingsArray(4,kC)));
                    set(handles.timePerFreqStep,'String',num2str(autoSettingsArray(5,kC)));
                    cwesrFilterPos = autoSettingsArray(6,kC);
                    set(handles.cwTrackingPeriod,'String',num2str(autoSettingsArray(7,kC)));
                    set(handles.numAverages,'String',num2str(autoSettingsArray(8,kC)));
                    set(handles.checkboxUseTracking,'Value',autoSettingsArray(9,kC));
                    set(handles.checkboxDoAutoFit,'Value',autoSettingsArray(10,kC));
                    set(handles.checkboxExpectHyperfine,'Value',autoSettingsArray(11,kC));
                    set(handles.Dsplitting,'String',num2str(autoSettingsArray(12,kC)));
                    
                    % also set the save file name
                    commSave = autoCommandStruct.(autoCommandList{kC});
                    set(handles.esrSaveFilePrefix,'String',[get(handles.fileboxAutomationSaveString,'String'),...
                                                            '_NV' autoNVName num2str(NVindex) '_' commSave]);

                    guidata(hObject, handles); % update ESRcontrol gui
                    
                    % second, set filter wheel if applicable
                    if imageHand.configS.numUSBFilterWheels>0
                        imageHand.FilterWheel.goToFilter(imageHand, cwesrFilterPos);
                        logid = fopen(logfile,'a');
                        if logid ~= -1
                            fprintf(logid,'Filter wheel to position %d\n',cwesrFilterPos);
                        end
                        fclose(logid);
                    end
                    
                    % third, call the performCWESR.
                    % argument is 'esrGUI' which is esrcontrol handles
                    handles.EsrCWSweep.PerformCWESR(handles);
                    igorDateFull = get(handles.esrSavePath,'String');
                    igorDateTrunc = igorDateFull((end-6):(end-1));
                    latestIndex = num2str(str2num(get(handles.numCompleted,'String'))-2);
                    igorFolderName = [get(handles.esrSaveFilePrefix,'String') get(handles.esrSaveFileNum,'String')];
                    %clipboard('copy', ['LoadCWESRsweep(' latestIndex ', "' igorDateTrunc '", "' igorFolderName '")']);
                    logid = fopen(logfile,'a');
                        if logid ~= -1
                            fprintf(logid,'LoadCWESRsweep(%s,"%s","%s")\n',latestIndex,igorDateTrunc,igorFolderName);
                        end
                    fclose(logid);
                    
                    try
                    % also opens the file in igor to current experiment
                    igorString = ['LoadCWESRsweep(' latestIndex ', "' igorDateTrunc '", "' igorFolderName '")'];
                    imageHand.sIgor.Execute(igorString);
                    catch
                        'failed igor load'
                    end
                    
                    guidata(hObject, handles); % update ESRcontrol gui
                    if autoSettingsArray(10,kC)==1 % do fit
                        % get the data from the table of fit results
                        fitResultsLog = get(handles.esrResultsTable,'Data');
                        fitResultsNumRows = str2num(get(handles.outNumPeaksFound,'String'));
                        logid = fopen(logfile,'a');
                        if logid ~= -1
                            for fr = 1:fitResultsNumRows
                                showpeak1 = fitResultsLog(fr,1);
                                showwidth = fitResultsLog(fr,2);
                                showB0 = fitResultsLog(fr,4);
                                showtheta = fitResultsLog(fr,5);
                                fprintf(logid,'peak %4.2f: %4.2f\nwidth: %4.2f\nB0: %4.2f\ntheta: %4.2f\n',...
                                            fr,showpeak1,showwidth,showB0,showtheta);
                            end
                        end
                        fclose(logid);
                    end
                    
                end
                logid = fopen(logfile,'a');
                if logid ~= -1
                    DateVector = clock;
                    thisTime = datestr(DateVector);
                    fprintf(logid,'%s\nCompleted CWESR of NV %s%d\n\n',thisTime,autoNVName,NVindex);
                end
                fclose(logid);
                
        case 'Pulsed_measurement'
            logid = fopen(logfile,'a');
                if logid ~= -1
                    DateVector = clock;
                    thisTime = datestr(DateVector);
                    fprintf(logid,'%s\nStarted Pulsed measurement of NV %s%d\n\n',thisTime,autoNVName,NVindex);
                end
                fclose(logid);
                set(handles.outputAutoCurrentStatus,'String','Pulse sequence');
                
                commSave = autoCommandStruct.(autoCommandList{kC});
                    set(handles.esrSaveFilePrefix,'String',[get(handles.fileboxAutomationSaveString,'String'),...
                                                            '_NV' autoNVName num2str(NVindex) '_' commSave]);
                if runMode==1
                    % first initialize settings on the esrcontrol GUI
                    
                    % in the future this can all be modified so there is
                    % one separate function for all of esrcontrol that has
                    % a structure where elements can be added as needed and
                    % each one sets a parameter on the GUI, e.g. a state of
                    % the GUI, sort of like PulseSequenceSettings. The save
                    % file of the automation can have headers so the
                    % structure variable names are automatically generated
                    set(handles.amplitude,'String',num2str(autoSettingsArray(1,kC)));
                    set(handles.centerFreq,'String',num2str(autoSettingsArray(2,kC)));
                    pulseSweepMode = autoSettingsArray(3,kC); %0=tau,1=freq,2=rf
                    numSweepPoints = autoSettingsArray(4,kC); % for tau, freq, or amplitude
                    numShotReps = autoSettingsArray(5,kC); %for tau, freq, or amplitude
                    set(handles.pulseTrackingPeriod,'String',num2str(autoSettingsArray(6,kC)));
                    set(handles.trackingGarbagePoints,'String',num2str(autoSettingsArray(7,kC)));
                    set(handles.checkboxUseTracking,'Value',autoSettingsArray(8,kC));
                    set(handles.tauStart,'String',num2str(autoSettingsArray(9,kC)));
                    set(handles.tauEnd,'String',num2str(autoSettingsArray(10,kC)));
                    set(handles.listExtraTauPoints,'String',num2str(autoSettingsArray(11,kC)));
                    set(handles.checkboxUseExtraTauPoints,'Value',autoSettingsArray(12,kC));
                    set(handles.pulseFreqDeviation,'String',num2str(autoSettingsArray(13,kC)));
                    set(handles.pulseAmplDeviation,'String',num2str(autoSettingsArray(14,kC)));
                    set(handles.numPiCycles,'String',num2str(autoSettingsArray(15,kC)));
                    set(handles.preMeasurePause,'String',num2str(autoSettingsArray(16,kC)));
                    set(handles.depopulationTime,'String',num2str(autoSettingsArray(17,kC)));
                    set(handles.preReadoutWait,'String',num2str(autoSettingsArray(18,kC)));
                    set(handles.piTime,'String',num2str(autoSettingsArray(19,kC)));
                    set(handles.sampleWidth,'String',num2str(autoSettingsArray(20,kC)));
                    set(handles.delayTimeAOM,'String',num2str(autoSettingsArray(21,kC)));
                    set(handles.initTime,'String',num2str(autoSettingsArray(22,kC)));
                    set(handles.readoutTime,'String',num2str(autoSettingsArray(23,kC)));
                    set(handles.IQTime,'String',num2str(autoSettingsArray(24,kC)));
                    set(handles.checkboxIQEnabled,'Value',autoSettingsArray(25,kC));
                    DAQTriggerMode = autoSettingsArray(26,kC); %1,2,3,4,... for radio button
                    set(handles.checkboxSignal50ns,'Value',autoSettingsArray(27,kC));
                    set(handles.checkboxReference50ns,'Value',autoSettingsArray(28,kC));
                    set(handles.checkboxDifferentialMeasurement,'Value',autoSettingsArray(29,kC));
                    %set(handles.fileboxPulseSequence,'String',autoSettingsArray(30,kC));
                    if autoSettingsArray(30,kC) == 1
                    set(handles.fileboxPulseSequence,'String','C:\Users\lab\Documents\MATLAB\ImageScan\NewPulseBlaster\SavedPulseSequences\inUse_sequences\ionizationmeasurements\yellowCW.esr')
                    end
                    if autoSettingsArray(30,kC) == 2
                    set(handles.fileboxPulseSequence,'String','C:\Users\lab\Documents\MATLAB\ImageScan\NewPulseBlaster\SavedPulseSequences\inUse_sequences\ionizationmeasurements\chargedecay.esr')
                    end
                    % for now just use the file that's already in the box
                    set(handles.numAverages,'String',num2str(autoSettingsArray(31,kC)));
                    
                    switch(DAQTriggerMode)
                        case 1
                            set(handles.radio1Channel,'Value',1);
                            set(handles.radio2Channel,'Value',0);
                            set(handles.radio4Channel,'Value',0);
                            set(handles.radio1Trig2Sig,'Value',0);
                        case 2
                            set(handles.radio1Channel,'Value',0);
                            set(handles.radio2Channel,'Value',1);
                            set(handles.radio4Channel,'Value',0);
                            set(handles.radio1Trig2Sig,'Value',0);
                        case 3
                            set(handles.radio1Channel,'Value',0);
                            set(handles.radio2Channel,'Value',0);
                            set(handles.radio4Channel,'Value',1);
                            set(handles.radio1Trig2Sig,'Value',0);
                        case 4
                            set(handles.radio1Channel,'Value',0);
                            set(handles.radio2Channel,'Value',0);
                            set(handles.radio4Channel,'Value',0);
                            set(handles.radio1Trig2Sig,'Value',1);
                    end
                    switch(pulseSweepMode)
                        case 0
                            set(handles.radioTauSweep,'Value',1);
                            set(handles.radioPulsedESR,'Value',0);
                            set(handles.radioCheckPiPulse,'Value',0);
                        case 1
                            set(handles.radioTauSweep,'Value',0);
                            set(handles.radioPulsedESR,'Value',1);
                            set(handles.radioCheckPiPulse,'Value',0);
                        case 2
                            set(handles.radioTauSweep,'Value',0);
                            set(handles.radioPulsedESR,'Value',0);
                            set(handles.radioCheckPiPulse,'Value',1);
                    end
                    set(handles.repsPerTau,'String',num2str(numShotReps));
                    set(handles.repsPerFreqPoint,'String',num2str(numShotReps));
                    set(handles.repsPerAmplPoint,'String',num2str(numShotReps));
                    set(handles.numTauPoints,'String',num2str(numSweepPoints));
                    set(handles.numFreqSteps,'String',num2str(numSweepPoints));
                    set(handles.numPulseFreqPoints,'String',num2str(numSweepPoints));
                    
                    % also set the save file name
                    commSave = autoCommandStruct.(autoCommandList{kC});
                    set(handles.esrSaveFilePrefix,'String',[get(handles.fileboxAutomationSaveString,'String'),...
                                                            '_NV' autoNVName num2str(NVindex) '_' commSave]);

                    guidata(hObject, handles); % update ESRcontrol gui
                    
                    % second, set filter wheel if applicable
%                     if imageHand.configS.numUSBFilterWheels>0
%                         imageHand.FilterWheel.goToFilter(imageHand, cwesrFilterPos);
%                         logid = fopen(logfile,'a');
%                         if logid ~= -1
%                             fprintf(logid,'Filter wheel to position %d\n',cwesrFilterPos);
%                         end
%                         fclose(logid);
%                     end
                    
                    % argument is 'esrGUI' which is esrcontrol handles
                    handles.EsrPulsedSweep.PerformSequence(handles);
                    %----commented out since I'll load another way similar to IgorPlottingScript for CWESR-----
%                     igorDateFull = get(handles.esrSavePath,'String');
%                     igorDateTrunc = igorDateFull((end-6):(end-1));
%                     latestIndex = num2str(str2num(get(handles.numCompleted,'String'))-2);
%                     igorFolderName = [get(handles.esrSaveFilePrefix,'String') get(handles.esrSaveFileNum,'String')];
%                     logid = fopen(logfile,'a');
%                         if logid ~= -1
%                             fprintf(logid,'LoadCWESRsweep(%s,"%s","%s")\n',latestIndex,igorDateTrunc,igorFolderName);
%                         end
%                     fclose(logid);
%                     
%                     try
%                     % also opens the file in igor to current experiment
%                     igorString = ['LoadCWESRsweep(' latestIndex ', "' igorDateTrunc '", "' igorFolderName '")'];
%                     imageHand.sIgor.Execute(igorString);
%                     catch
%                         'failed igor load'
%                     end
                    %---------------------------------------------------
                    
                    guidata(hObject, handles); % update ESRcontrol gui
                    
                end
                logid = fopen(logfile,'a');
                if logid ~= -1
                    DateVector = clock;
                    thisTime = datestr(DateVector);
                    fprintf(logid,'%s\nCompleted Pulse sequence of NV %s%d\n\n',thisTime,autoNVName,NVindex);
                end
                fclose(logid);
                
        case 'Fit_to_data'
                
        case 'Confocal_scan_XY'
                
        case 'Meas_result_to_params'
                logid = fopen(logfile,'a');
                if logid ~= -1
                    fprintf(logid,'Getting fit result for parameter on NV %s%d\n',autoNVName,NVindex);
                end
                fclose(logid);
                set(handles.outputAutoCurrentStatus,'String','Fit result to parameter');
                
                autoSettingsArray(1,kC)
                
                if autoSettingsArray(1,kC)
                   % center frequency will depend on previous measurement
                   
                   % make sure next measurement is CWESR or pulse sequence
                   nextC = kC+1;
                   nextFullCommand = autoCommandList{nextC}; % returns a 'char' class
                   nextBaseCommand = regexprep(nextFullCommand,'\d','');
                   switch(nextBaseCommand)
                       case 'CWESR_measurement'
                           fitsDataTable = get(handles.esrResultsTable,'Data');
                           % leftmost peak should be -1 state
                           tempFrequency = fitsDataTable(1,1)
                           if (tempFrequency>2000) && (tempFrequency<4000) % make sure it is reasonable to drive this freq 
                               autoSettingsArray(2,nextC)=tempFrequency;
                               
                               logid = fopen(logfile,'a');
                               if logid ~= -1
                                    fprintf(logid,'From fit, set ESR frequency to %4.2f MHz\n\n',tempFrequency);
                               end
                               fclose(logid);
                           else
                               % otherwise don't set a new frequency
                           end
                   end
                   
                end
    end
end
set(handles.outputAutoCurrentStatus,'String','not running');
set(handles.outputAutoCurrentNV,'String','none');
handles.stopAutomation = 0;
end

% --- Executes on button press in buttonStopAutomation.
function buttonStopAutomation_Callback(hObject, eventdata, handles)
% hObject    handle to buttonStopAutomation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.stopAutomation = 1;
guidata(hObject, handles);
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
if str2double(get(hObject,'String')) <= 0
    set(hObject,'String',num2str(0));
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

%newVal = str2double(get(hObject,'UserData'));
handles.EsrGlobalMethods.ToggleRF(0,handles);
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

defaultPath = [handles.EsrGlobalMethods.imageScanHandles.configS.sequenceFolder '\AutomationSequenceSettings\'];
[filename pathname] = uigetfile('*.nva', 'Select Automation Sequence',defaultPath);
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
            set(handles.fileboxAutomationSequence, 'String', file1);
end

% 
% % --- Executes on button press in buttonSetNewCursorReference.
% function buttonSetNewCursorReference_Callback(hObject, eventdata, handles)
% % hObject    handle to buttonSetNewCursorReference (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% arrayNV = get(handles.tableNVPositions,'Data');
%     xposAdd = str2num(get(handles.EsrGlobalMethods.imageScanHandles.editPositionX,'String'));
%     yposAdd = str2num(get(handles.EsrGlobalMethods.imageScanHandles.editPositionY,'String'));
%     nextLine = 1;
%     nextName = arrayNV{1,1};
%     line1OldX = arrayNV{1,2};
%     line1OldY = arrayNV{1,3};
%     arrayNV(nextLine,:) = {nextName, xposAdd, yposAdd};
%     
%     % compute the rest of the coordinates relative to this new value
%     [m, n] = size(arrayNV);
%     if m > 1     
%         for nn=2:m
%             oldx = arrayNV{nn,2};
%             delx = oldx-line1OldX;
%             newx = xposAdd+delx;
%             arrayNV{nn,2} = newx;
%             
%             oldy = arrayNV{nn,3};
%             dely = oldy-line1OldY;
%             newy = yposAdd+dely;
%             arrayNV{nn,3} = newy;
%         end
%     end
%     set(handles.tableNVPositions,'Data',arrayNV);
%     
% end


% --- Executes on button press in buttonOpenNVAutomationEditor.
function buttonOpenNVAutomationEditor_Callback(hObject, eventdata, handles)
% hObject    handle to buttonOpenNVAutomationEditor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% pass to the Auto Editor Gui the ESRControl Handles 
handles.ESRAutoEditor = ESRAutoEditor(handles); 
end


% --- Executes on button press in buttonSaveSettingsFile.
function buttonSaveSettingsFile_Callback(hObject, eventdata, handles)
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
settingsS.radio2Channel = get(handles.radio2Channel,'Value');
settingsS.radio4Channel = get(handles.radio4Channel,'Value');
settingsS.radio1Trig2Sig = get(handles.radio1Trig2Sig,'Value');
settingsS.radioTauSweep = get(handles.radioTauSweep,'Value');
settingsS.radioPulsedESR = get(handles.radioPulsedESR,'Value');
settingsS.radioCheckPiPulse = get(handles.radioCheckPiPulse,'Value');
settingsS.checkboxIQEnabled = get(handles.checkboxIQEnabled,'Value');
settingsS.checkboxSignal50ns = get(handles.checkboxSignal50ns,'Value');
settingsS.checkboxReference50ns = get(handles.checkboxReference50ns,'Value');
%Below were added by Dolev on 1/11/2018
settingsS.checkboxSaveDataPerShot = get(handles.checkboxSaveDataPerShot,'Value');
settingsS.quantInterpXY8 = get(handles.quantInterpXY8,'Value');
settingsS.delayTimeYellow = get(handles.delayTimeYellow,'Value');
settingsS.delayTimeRed = get(handles.delayTimeRed,'Value');
settingsS.greenShelfTime = get(handles.greenShelfTime,'Value');
settingsS.redIonTime = get(handles.redIonTime,'Value');
settingsS.yPiTime = get(handles.yPiTime,'Value');
settingsS.userVar2 = get(handles.userVar2,'Value');
settingsS.userVar3 = get(handles.userVar3,'Value');

defaultPath = [handles.EsrGlobalMethods.imageScanHandles.configS.sequenceFolder 'PulseSequenceSettings\'];
if exist(defaultPath,'dir') ==0 %path does not exist?
    mkdir(defaultPath);
end
[filename fpath ~] = uiputfile('*.pss','Save Settings As...',defaultPath);

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
set(handles.radio2Channel,'Value',settingsS.radio2Channel);
set(handles.radio4Channel,'Value',settingsS.radio4Channel);
set(handles.radio1Trig2Sig,'Value',settingsS.radio1Trig2Sig);
set(handles.radioTauSweep,'Value',settingsS.radioTauSweep);
set(handles.radioPulsedESR,'Value',settingsS.radioPulsedESR);
set(handles.radioCheckPiPulse,'Value',settingsS.radioCheckPiPulse);
set(handles.checkboxIQEnabled,'Value',settingsS.checkboxIQEnabled);
set(handles.checkboxSignal50ns,'Value',settingsS.checkboxSignal50ns);
set(handles.checkboxReference50ns,'Value',settingsS.checkboxReference50ns);
%Below added by Dolev on 1/11/18
set(handles.checkboxSaveDataPerShot,'Value',settingsS.checkboxSaveDataPerShot);
set(handles.quantInterpXY8,'Value',settingsS.quantInterpXY8);
set(handles.delayTimeYellow,'Value',settingsS.delayTimeYellow);
set(handles.delayTimeRed,'Value',settingsS.delayTimeRed);
set(handles.greenShelfTime,'Value',settingsS.greenShelfTime);
set(handles.redIonTime,'Value',settingsS.redIonTime);
set(handles.yPiTime,'Value',settingsS.yPiTime);
set(handles.userVar2,'Value',settingsS.userVar2);
set(handles.userVar3,'Value',settingsS.userVar3);

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
clipboard('copy', [get(handles.esrSavePath,'String') get(handles.esrSaveFilePrefix,'String') get(handles.esrSaveFileNum,'String') '\']);
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


% --- Executes on button press in checkbox_twoRFSweeps.
function checkbox_twoRFSweeps_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_twoRFSweeps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_twoRFSweeps
end



function fileboxAutomationSaveString_Callback(hObject, eventdata, handles)
% hObject    handle to fileboxAutomationSaveString (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of fileboxAutomationSaveString as text
%        str2double(get(hObject,'String')) returns contents of fileboxAutomationSaveString as a double
end

% --- Executes during object creation, after setting all properties.
function fileboxAutomationSaveString_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fileboxAutomationSaveString (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function automationLogBox_Callback(hObject, eventdata, handles)
% hObject    handle to automationLogBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of automationLogBox as text
%        str2double(get(hObject,'String')) returns contents of automationLogBox as a double
end

% --- Executes during object creation, after setting all properties.
function automationLogBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to automationLogBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function fileboxAutomationSequence_Callback(hObject, eventdata, handles)
% hObject    handle to fileboxAutomationSequence (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of fileboxAutomationSequence as text
%        str2double(get(hObject,'String')) returns contents of fileboxAutomationSequence as a double
end

% --- Executes during object creation, after setting all properties.
function fileboxAutomationSequence_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fileboxAutomationSequence (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in checkboxExpectHyperfine.
function checkboxExpectHyperfine_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxExpectHyperfine (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxExpectHyperfine
end


% --- Executes on button press in checkboxUseImageRegistration.
function checkboxUseImageRegistration_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxUseImageRegistration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxUseImageRegistration
end


% --- Executes on button press in checkboxRecordTemp.
function checkboxRecordTemp_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxRecordTemp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxRecordTemp
end

% --- Executes on button press in checkboxRecordLaser.
function checkboxRecordLaser_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxRecordLaser (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxRecordLaser
end



function laserMeterRange_Callback(hObject, eventdata, handles)
% hObject    handle to laserMeterRange (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of laserMeterRange as text
%        str2double(get(hObject,'String')) returns contents of laserMeterRange as a double
end

% --- Executes during object creation, after setting all properties.
function laserMeterRange_CreateFcn(hObject, eventdata, handles)
% hObject    handle to laserMeterRange (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

input = str2double(get(hObject,'String'));
if input<1
    input=1;
end
set(hObject,'String',num2str(input));
end


% --- Executes on button press in checkboxUsePhaseNoiseModulation.
function checkboxUsePhaseNoiseModulation_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxUsePhaseNoiseModulation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxUsePhaseNoiseModulation
end



function phaseNoiseRate_Callback(hObject, eventdata, handles)
% hObject    handle to phaseNoiseRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of phaseNoiseRate as text
%        str2double(get(hObject,'String')) returns contents of phaseNoiseRate as a double
input = str2double(get(hObject,'String'));
if input<0 
    input=0.1;
end
if input>50
    input=50;
end
set(hObject,'String',num2str(input));
end

% --- Executes during object creation, after setting all properties.
function phaseNoiseRate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to phaseNoiseRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function phaseNoiseDev_Callback(hObject, eventdata, handles)
% hObject    handle to phaseNoiseDev (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of phaseNoiseDev as text
%        str2double(get(hObject,'String')) returns contents of phaseNoiseDev as a double

input = str2double(get(hObject,'String'));
if input<0 
    input=0.1;
end
if input>72
    input=72;
end
set(hObject,'String',num2str(input));
end

% --- Executes during object creation, after setting all properties.
function phaseNoiseDev_CreateFcn(hObject, eventdata, handles)
% hObject    handle to phaseNoiseDev (see GCBO)
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



function amplitudeB_Callback(hObject, eventdata, handles)
% hObject    handle to amplitudeB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of amplitudeB as text
%        str2double(get(hObject,'String')) returns contents of amplitudeB as a double
input = str2num(get(hObject,'String'));
            if (isempty(input))
                set(hObject,'String',-110); % default for empty string
            end
                    if (input > 10)   
                        set(hObject,'String','0');
                    end
                    if (input<-110) 
                        set(hObject,'String','-110');
                    end
                    
             set(hObject, 'String', num2str(input));       
                    % now actually set the frequency on the instrument
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


% --- Executes on button press in checkboxUsePhaseNoiseModulationB.
function checkboxUsePhaseNoiseModulationB_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxUsePhaseNoiseModulationB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxUsePhaseNoiseModulationB
end



function delayTimeYellow_Callback(hObject, eventdata, handles)
% hObject    handle to delayTimeYellow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of delayTimeYellow as text
%        str2double(get(hObject,'String')) returns contents of delayTimeYellow as a double
end

% --- Executes during object creation, after setting all properties.
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
end

% --- Executes during object creation, after setting all properties.
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
end

% --- Executes during object creation, after setting all properties.
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
end

% --- Executes during object creation, after setting all properties.
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
end

% --- Executes during object creation, after setting all properties.
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
end

% --- Executes during object creation, after setting all properties.
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


% --- Executes on button press in quantInterpXY8.
function quantInterpXY8_Callback(hObject, eventdata, handles)
% hObject    handle to quantInterpXY8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of quantInterpXY8
end