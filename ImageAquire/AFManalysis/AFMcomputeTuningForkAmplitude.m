function varargout = AFMcomputeTuningForkAmplitude(varargin)
% AFMCOMPUTETUNINGFORKAMPLITUDE MATLAB code for AFMcomputeTuningForkAmplitude.fig
%      AFMCOMPUTETUNINGFORKAMPLITUDE, by itself, creates a new AFMCOMPUTETUNINGFORKAMPLITUDE or raises the existing
%      singleton*.
%
%      H = AFMCOMPUTETUNINGFORKAMPLITUDE returns the handle to a new AFMCOMPUTETUNINGFORKAMPLITUDE or the handle to
%      the existing singleton*.
%
%      AFMCOMPUTETUNINGFORKAMPLITUDE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in AFMCOMPUTETUNINGFORKAMPLITUDE.M with the given input arguments.
%
%      AFMCOMPUTETUNINGFORKAMPLITUDE('Property','Value',...) creates a new AFMCOMPUTETUNINGFORKAMPLITUDE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before AFMcomputeTuningForkAmplitude_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to AFMcomputeTuningForkAmplitude_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help AFMcomputeTuningForkAmplitude

% Last Modified by GUIDE v2.5 14-Mar-2015 11:22:05

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @AFMcomputeTuningForkAmplitude_OpeningFcn, ...
                   'gui_OutputFcn',  @AFMcomputeTuningForkAmplitude_OutputFcn, ...
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


% --- Executes just before AFMcomputeTuningForkAmplitude is made visible.
function AFMcomputeTuningForkAmplitude_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to AFMcomputeTuningForkAmplitude (see VARARGIN)

% Choose default command line output for AFMcomputeTuningForkAmplitude
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes AFMcomputeTuningForkAmplitude wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = AFMcomputeTuningForkAmplitude_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function W_Callback(hObject, eventdata, handles)
% hObject    handle to W (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of W as text
%        str2double(get(hObject,'String')) returns contents of W as a double


% --- Executes during object creation, after setting all properties.
function W_CreateFcn(hObject, eventdata, handles)
% hObject    handle to W (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function L_Callback(hObject, eventdata, handles)
% hObject    handle to L (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of L as text
%        str2double(get(hObject,'String')) returns contents of L as a double


% --- Executes during object creation, after setting all properties.
function L_CreateFcn(hObject, eventdata, handles)
% hObject    handle to L (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Vdrive_Callback(hObject, eventdata, handles)
% hObject    handle to Vdrive (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Vdrive as text
%        str2double(get(hObject,'String')) returns contents of Vdrive as a double


% --- Executes during object creation, after setting all properties.
function Vdrive_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Vdrive (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Q_Callback(hObject, eventdata, handles)
% hObject    handle to Q (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Q as text
%        str2double(get(hObject,'String')) returns contents of Q as a double


% --- Executes during object creation, after setting all properties.
function Q_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Q (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Vmeas_Callback(hObject, eventdata, handles)
% hObject    handle to Vmeas (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Vmeas as text
%        str2double(get(hObject,'String')) returns contents of Vmeas as a double


% --- Executes during object creation, after setting all properties.
function Vmeas_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Vmeas (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function gain_Callback(hObject, eventdata, handles)
% hObject    handle to gain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of gain as text
%        str2double(get(hObject,'String')) returns contents of gain as a double


% --- Executes during object creation, after setting all properties.
function gain_CreateFcn(hObject, eventdata, handles)
% hObject    handle to gain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton1.
function buttonCompute_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%handles % print handles
L_um = str2double(get(handles.L,'String'));
W_um = str2double(get(handles.W,'String'));
T_um = str2double(get(handles.T,'String'));
E_GPa = str2double(get(handles.E,'String'));

f_kHz = str2double(get(handles.f,'String'));
VdrivePeak_mV = str2double(get(handles.Vdrive,'String'));
Q = str2double(get(handles.Q,'String'));
VmeasRMS_mV = str2double(get(handles.Vmeas,'String'));
gain = str2double(get(handles.gain,'String'));

if get(handles.radio1FreeProng,'Value')
    factor = 0.5;
elseif get(handles.radio2FreeProngs,'Value')
    factor = 1;
end

E_Nm2 = E_GPa*10^9;
L_m = L_um/10^6;
W_m = W_um/10^6;
T_m = T_um/10^6;
k_Nm = 0.25*(T_m^3*W_m*E_Nm2/L_m^3);
set(handles.k,'String',num2str(k_Nm));

VdriveRMS_V = VdrivePeak_mV/(sqrt(2)*1000);
VmeasRMS_V = VmeasRMS_mV/1000;
f_Hz = f_kHz*1000;
ImeasRMS_A = VmeasRMS_V/gain;
a0_m = sqrt(Q*VdriveRMS_V*ImeasRMS_A/(factor*k_Nm*2*pi*f_Hz));
ppa0_m = 2*sqrt(2)*a0_m;
set(handles.Imeas,'String',num2str(ImeasRMS_A*10^9));
set(handles.a0,'String',num2str(a0_m*10^9));
set(handles.ppa0,'String',num2str(ppa0_m*10^9));
