function varargout = EsrResonanceLock(varargin)
% ESRRESONANCELOCK MATLAB code for EsrResonanceLock.fig
%      ESRRESONANCELOCK, by itself, creates a new ESRRESONANCELOCK or raises the existing
%      singleton*.
%
%      H = ESRRESONANCELOCK returns the handle to a new ESRRESONANCELOCK or the handle to
%      the existing singleton*.
%
%      ESRRESONANCELOCK('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ESRRESONANCELOCK.M with the given input arguments.
%
%      ESRRESONANCELOCK('Property','Value',...) creates a new ESRRESONANCELOCK or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before EsrResonanceLock_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to EsrResonanceLock_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help EsrResonanceLock

% Last Modified by GUIDE v2.5 22-Jan-2015 10:56:25

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @EsrResonanceLock_OpeningFcn, ...
                   'gui_OutputFcn',  @EsrResonanceLock_OutputFcn, ...
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


% --- Executes just before EsrResonanceLock is made visible.
function EsrResonanceLock_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to EsrResonanceLock (see VARARGIN)

% Choose default command line output for EsrResonanceLock
handles.output = hObject;

%varargin
handles.imageScanHandles = varargin{1};
handles.srs = handles.imageScanHandles.srs;
handles.PulseInterpreter = handles.imageScanHandles.PulseInterpreter;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes EsrResonanceLock wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = EsrResonanceLock_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in button_startGraph.
function button_startGraph_Callback(hObject, eventdata, handles)
% hObject    handle to button_startGraph (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in button_stopGraph.
function button_stopGraph_Callback(hObject, eventdata, handles)
% hObject    handle to button_stopGraph (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in checkbox_toggleFM.
function checkbox_toggleFM_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_toggleFM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_toggleFM
if get(hObject,'Value')
    % toggle on: turn on any modulation
    %fclose(obj.srs);
    fopen(handles.srs);
    fprintf(handles.srs, 'TYPE1'); % sets type of modulation, 1=FM 
    fprintf(handles.srs, 'COUP1'); % set 1=DC coupling for modulation ext. input (0=AC coupling)
    fprintf(handles.srs, ['FDEV' num2str(get(handles.maxModulationFreq,'String')) 'MHz']); 
    fprintf(handles.srs, 'MODL1'); % set modulation on
    fclose(handles.srs);   
else
    % toggle off: turn off any modulation
    %fclose(obj.srs);
    fopen(handles.srs);
    fprintf(handles.srs, 'MODL0');
    fclose(handles.srs);    
end

% --- Executes on button press in checkbox_toggleRF.
function checkbox_toggleRF_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_toggleRF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_toggleRF
if get(hObject,'Value')
    %toggle on: set Rf amplitude, set frequency, open switch and laser on
    fopen(handles.srs);
    fprintf(handles.srs, ['ENBL ', '0']);
    fprintf(handles.srs, ['ENBR ', '1']);
    
    inputFreq = str2double(get(handles.centerFrequency,'String'));
        fprintf(handles.srs,['FREQ ', num2str(inputFreq),' MHz']); % center freq. MHz
    inputAmp = str2double(get(handles.RFamplitude,'String'));
        fprintf(handles.srs, ['AMPR ', num2str(inputAmp)]); % Ntype out
    
    handles.PulseInterpreter.stopPulse();
    if handles.imageScanHandles.configS.bHaveInverterBoard == 0
        handles.PulseInterpreter.setCurrentPulse([handles.imageScanHandles.configS.sequenceFolder 'bit1_3_on.txt']);
    else
        handles.PulseInterpreter.setCurrentPulse([handles.imageScanHandles.configS.sequenceFolder 'bit3_on.txt']);
    end
    handles.PulseInterpreter.loadToPulseblaster();
    handles.PulseInterpreter.runPulse();
    
else
    %toggle off: turn off RF, close microwave switch, leave laser on
    fprintf(handles.srs, ['ENBR ', '0']); % turn off the N RF output
    
    handles.PulseInterpreter.stopPulse();
    handles.PulseInterpreter.setCurrentPulse([handles.imageScanHandles.configS.sequenceFolder 'bit1_on.txt']);
    handles.PulseInterpreter.loadToPulseblaster();
    if handles.imageScanHandles.configS.bHaveInverterBoard == 0
        % no inverter board, so start the laser on
        handles.PulseInterpreter.runPulse();
    end
end


function centerFrequency_Callback(hObject, eventdata, handles)
% hObject    handle to centerFrequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of centerFrequency as text
%        str2double(get(hObject,'String')) returns contents of centerFrequency as a double
input=str2double(get(hObject,'String'));
if input<100
    input=100; % MHz
elseif input>4050
    input=4050; % max allowed by Ntype output SRS is 4.05 GHz
end
set(hObject,'String',num2str(input));
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function centerFrequency_CreateFcn(hObject, eventdata, handles)
% hObject    handle to centerFrequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function RFamplitude_Callback(hObject, eventdata, handles)
% hObject    handle to RFamplitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of RFamplitude as text
%        str2double(get(hObject,'String')) returns contents of RFamplitude as a double
input=str2double(get(hObject,'String'));
if input<-110
    input=-110;
elseif input>13
    input=13;
end
set(hObject,'String',num2str(input));
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function RFamplitude_CreateFcn(hObject, eventdata, handles)
% hObject    handle to RFamplitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function maxModulationFreq_Callback(hObject, eventdata, handles)
% hObject    handle to maxModulationFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxModulationFreq as text
%        str2double(get(hObject,'String')) returns contents of maxModulationFreq as a double
input=str2double(get(hObject,'String'));
if input<0
    input=0;
elseif input>32
    input=32; % max allowed FM mod is +/-32 MHz for 2-4 GHz SRS output
end
set(hObject,'String',num2str(input));
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function maxModulationFreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxModulationFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
