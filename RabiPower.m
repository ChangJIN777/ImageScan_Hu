function varargout = RabiPower(varargin)
% RABIPOWER MATLAB code for RabiPower.fig
%      RABIPOWER, by itself, creates a new RABIPOWER or raises the existing
%      singleton*.
%
%      H = RABIPOWER returns the handle to a new RABIPOWER or the handle to
%      the existing singleton*.
%
%      RABIPOWER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RABIPOWER.M with the given input arguments.
%
%      RABIPOWER('Property','Value',...) creates a new RABIPOWER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before RabiPower_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to RabiPower_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help RabiPower

% Last Modified by GUIDE v2.5 12-Jul-2016 11:40:45

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @RabiPower_OpeningFcn, ...
                   'gui_OutputFcn',  @RabiPower_OutputFcn, ...
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


% --- Executes just before RabiPower is made visible.
function RabiPower_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to RabiPower (see VARARGIN)

% Choose default command line output for RabiPower
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

initialize_gui(hObject, handles, false);

% UIWAIT makes RabiPower wait for user response (see UIRESUME)
%uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = RabiPower_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


function input_power_Callback(hObject, eventdata, handles)
% hObject    handle to input_power (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of input_power as text
%        str2double(get(hObject,'String')) returns contents of input_power as a double
input_power = str2double(get(hObject, 'String'));
if isnan(input_power)
    set(hObject, 'String', 0);
    errordlg('Input must be a number','Error');
end

% Save the new input_power value
handles.metricdata.input_power = input_power;
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function input_power_CreateFcn(hObject, eventdata, handles)
% hObject    handle to input_power (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function freq_now_Callback(hObject, eventdata, handles)
% hObject    handle to freq_now (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of freq_now as text
%        str2double(get(hObject,'String')) returns contents of freq_now as a double
freq_now = str2double(get(hObject, 'String'));
if isnan(freq_now)
    set(hObject, 'String', 0);
    errordlg('Input must be a number','Error');
end

% Save the new input_power value
handles.metricdata.freq_now = freq_now;
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function freq_now_CreateFcn(hObject, eventdata, handles)
% hObject    handle to freq_now (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function freq_wanted_Callback(hObject, eventdata, handles)
% hObject    handle to freq_wanted (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of freq_wanted as text
%        str2double(get(hObject,'String')) returns contents of freq_wanted as a double
freq_wanted = str2double(get(hObject, 'String'));
if isnan(freq_wanted)
    set(hObject, 'String', 0);
    errordlg('Input must be a number','Error');
end

% Save the new input_power value
handles.metricdata.freq_wanted = freq_wanted;
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function freq_wanted_CreateFcn(hObject, eventdata, handles)
% hObject    handle to freq_wanted (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

input_power = handles.metricdata.input_power;
freq_now = handles.metricdata.freq_now;
freq_wanted = handles.metricdata.freq_wanted;

Pin_mw = 10^(input_power/10); 
Pout_mw = Pin_mw * freq_wanted.^2/freq_now.^2; 
new_power = 10 * log10(Pout_mw);
set(handles.new_power, 'String', new_power)

function initialize_gui(fig_handle, handles, isreset)
% If the metricdata field is present and the reset flag is false, it means
% we are we are just re-initializing a GUI by calling it from the cmd line
% while it is up. So, bail out as we dont want to reset the data.
if isfield(handles, 'metricdata') && ~isreset
    return;
end

handles.metricdata.input_power = 0;
handles.metricdata.freq_now  = 0;
handles.metricdata.freq_wanted = 0;

set(handles.input_power, 'String', handles.metricdata.input_power);
set(handles.freq_now,  'String', handles.metricdata.freq_now);
set(handles.freq_wanted, 'String', handles.metricdata.freq_wanted);
set(handles.new_power, 'String', 0);

% Update handles structure
guidata(handles.figure1, handles);
