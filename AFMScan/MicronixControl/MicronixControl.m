function varargout = MicronixControl(varargin)
% MICRONIXCONTROL MATLAB code for MicronixControl.fig
%      MICRONIXCONTROL, by itself, creates a new MICRONIXCONTROL or raises the existing
%      singleton*.
%
%      H = MICRONIXCONTROL returns the handle to a new MICRONIXCONTROL or the handle to
%      the existing singleton*.
%
%      MICRONIXCONTROL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MICRONIXCONTROL.M with the given input arguments.
%
%      MICRONIXCONTROL('Property','Value',...) creates a new MICRONIXCONTROL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before MicronixControl_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to MicronixControl_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help MicronixControl

% Last Modified by GUIDE v2.5 08-Feb-2016 10:12:42

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @MicronixControl_OpeningFcn, ...
                   'gui_OutputFcn',  @MicronixControl_OutputFcn, ...
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

% --- Executes just before MicronixControl is made visible.
function MicronixControl_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to MicronixControl (see VARARGIN)

% Choose default command line output for MicronixControl
handles.output = hObject;

handles.test_guiHandles = varargin{1}; % handles passed from afm figures: test_gui

% crude way to update handles in test_gui
% handles.test_guiHandles.hmic_ypos = handles.mic_ypos;
% handles.test_guiHandles.hmic_zpos = handles.mic_zpos;
% handles.test_guiHandles.hmic_xpos = handles.mic_zpos;
% handles.test_guiHandles.hmic_mic_port_status = handles.mic_port_status;

handles.xyStepLimit = 2000; % in um
handles.zStepLimit = 500; % should have two limits for when engaged and not

handles.prev_feedback_x=1;
handles.prev_feedback_y=1;
handles.prev_feedback_z=1;

% Update handles structure
guidata(hObject, handles);
end
% UIWAIT makes MicronixControl wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = MicronixControl_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end


function mic_xstep_Callback(hObject, eventdata, handles)
% hObject    handle to mic_xstep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of mic_xstep as text
%        str2double(get(hObject,'String')) returns contents of mic_xstep as a double

% allow positive inputs less than limit of step um 
input = str2double(get(hObject,'String'));
if (input<0)
    input=abs(input);
end
if isnan(input)
    input=0;
end
if (input>handles.xyStepLimit)
    input=handles.xyStepLimit;
end
set(hObject,'String',num2str(input));
end

% --- Executes during object creation, after setting all properties.
function mic_xstep_CreateFcn(hObject, eventdata, handles)
% hObject    handle to mic_xstep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function mic_ystep_Callback(hObject, eventdata, handles)
% hObject    handle to mic_ystep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of mic_ystep as text
%        str2double(get(hObject,'String')) returns contents of mic_ystep as a double

% allow positive inputs less than limit of step um 
input = str2double(get(hObject,'String'));
if (input<0)
    input=abs(input);
end
if isnan(input)
    input=0;
end
if (input>handles.xyStepLimit)
    input=handles.xyStepLimit;
end
set(hObject,'String',num2str(input));
end

% --- Executes during object creation, after setting all properties.
function mic_ystep_CreateFcn(hObject, eventdata, handles)
% hObject    handle to mic_ystep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function mic_zstep_Callback(hObject, eventdata, handles)
% hObject    handle to mic_zstep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of mic_zstep as text
%        str2double(get(hObject,'String')) returns contents of mic_zstep as a double

% allow positive inputs less than limit of step um 
input = str2double(get(hObject,'String'));
if (input<0)
    input=abs(input);
end
if isnan(input)
    input=0;
end
if (input>handles.zStepLimit)
    input=handles.zStepLimit;
end
set(hObject,'String',num2str(input));
end

% --- Executes during object creation, after setting all properties.
function mic_zstep_CreateFcn(hObject, eventdata, handles)
% hObject    handle to mic_zstep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on button press in button_micxplus.
function button_micxplus_Callback(hObject, eventdata, handles)
% hObject    handle to button_micxplus (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% checking the value range is done on input beforehand
xstep = str2double(get(handles.mic_xstep,'String')); % in um
mDAC('micronix_x_mvr',xstep);
end

% --- Executes on button press in button_micxminus.
function button_micxminus_Callback(hObject, eventdata, handles)
% hObject    handle to button_micxminus (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% checking the value range is done on input beforehand
xstep = str2double(get(handles.mic_xstep,'String')); % in um
mDAC('micronix_x_mvr',-xstep);
end
% --- Executes on button press in button_micyplus.
function button_micyplus_Callback(hObject, eventdata, handles)
% hObject    handle to button_micyplus (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% checking the value range is done on input beforehand
ystep = str2double(get(handles.mic_ystep,'String')); % in um
mDAC('micronix_y_mvr',ystep);
end

% --- Executes on button press in button_micyminus.
function button_micyminus_Callback(hObject, eventdata, handles)
% hObject    handle to button_micyminus (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% checking the value range is done on input beforehand
ystep = str2double(get(handles.mic_ystep,'String')); % in um
mDAC('micronix_y_mvr',-ystep);
end

% --- Executes on button press in button_miczplus.
function button_miczplus_Callback(hObject, eventdata, handles)
% hObject    handle to button_miczplus (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
zstep = str2double(get(handles.mic_zstep,'String')); % in um
mDAC('micronix_z_mvr',zstep);
end

% --- Executes on button press in button_miczminus.
function button_miczminus_Callback(hObject, eventdata, handles)
% hObject    handle to button_miczminus (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
zstep = str2double(get(handles.mic_zstep,'String')); % in um
mDAC('micronix_z_mvr',-zstep);
end

% --- Executes on button press in buttonOpenPort.
function buttonOpenPort_Callback(hObject, eventdata, handles)
% hObject    handle to buttonOpenPort (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
mDAC('set_Micronix_handles',hObject,handles.mic_port_status,...
            handles.mic_xpos,handles.mic_ypos,handles.mic_zpos,...
            handles.mic_debug1,handles.mic_debug2,handles.mic_debug3,...
            handles.mic_radio_x,handles.mic_radio_y,handles.mic_radio_z,...
            handles.mic_n_steps,handles.mic_feedback_type_x,...
            handles.mic_feedback_type_y,handles.mic_feedback_type_z,...
            handles.mic_command_window);
        
micronixPort = 5;
micronixBaud = 38400;
mDAC('set_Micronix_port',micronixPort,micronixBaud);
end

% --- Executes on button press in mic_radio_x.
function mic_radio_x_Callback(hObject, eventdata, handles)
% hObject    handle to mic_radio_x (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of mic_radio_x

% arg = axis number
set(handles.mic_radio_x,'Value',1);
set(handles.mic_radio_y,'Value',0);
set(handles.mic_radio_z,'Value',0);
mDAC('change_Micronix_read_axis',1); 
end

% --- Executes on button press in mic_radio_y.
function mic_radio_y_Callback(hObject, eventdata, handles)
% hObject    handle to mic_radio_y (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of mic_radio_y

% arg = axis number
set(handles.mic_radio_x,'Value',0);
set(handles.mic_radio_y,'Value',1);
set(handles.mic_radio_z,'Value',0);
mDAC('change_Micronix_read_axis',2); 
end

% --- Executes on button press in mic_radio_z.
function mic_radio_z_Callback(hObject, eventdata, handles)
% hObject    handle to mic_radio_z (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of mic_radio_z

% arg = axis number
set(handles.mic_radio_x,'Value',0);
set(handles.mic_radio_y,'Value',0);
set(handles.mic_radio_z,'Value',1);
mDAC('change_Micronix_read_axis',3); 
end

% --- Executes on button press in checkbox_mic_lockmanual.
function checkbox_mic_lockmanual_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_mic_lockmanual (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_mic_lockmanual
is_locked = get(hObject,'Value');
if (is_locked==1)
   set(handles.button_micxplus,'Enable','off');
   set(handles.button_micxminus,'Enable','off');
   set(handles.button_micyplus,'Enable','off');
   set(handles.button_micyminus,'Enable','off');
   set(handles.button_miczplus,'Enable','off');
   set(handles.button_miczminus,'Enable','off');
   set(handles.mic_feedback_type_x,'Enable','off');
   set(handles.mic_feedback_type_y,'Enable','off');
   set(handles.mic_feedback_type_z,'Enable','off');
else 
   set(handles.button_micxplus,'Enable','on');
   set(handles.button_micxminus,'Enable','on');
   set(handles.button_micyplus,'Enable','on');
   set(handles.button_micyminus,'Enable','on');
   set(handles.button_miczplus,'Enable','on');
   set(handles.button_miczminus,'Enable','on');
   set(handles.mic_feedback_type_x,'Enable','on');
   set(handles.mic_feedback_type_y,'Enable','on');
   set(handles.mic_feedback_type_z,'Enable','on');
end
end

% --- Executes on selection change in mic_feedback_type_x.
function mic_feedback_type_x_Callback(hObject, eventdata, handles)
% hObject    handle to mic_feedback_type_x (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns mic_feedback_type_x contents as cell array
%        contents{get(hObject,'Value')} returns selected item from mic_feedback_type_x
newVal = get(hObject,'Value');
newVal
if (newVal~=handles.prev_feedback_x)
    mDAC('change_Micronix_feedback',1,newVal);
end
end

% --- Executes during object creation, after setting all properties.
function mic_feedback_type_x_CreateFcn(hObject, eventdata, handles)
% hObject    handle to mic_feedback_type_x (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

set(hObject,'Value',4);
end

% --- Executes on selection change in mic_feedback_type_y.
function mic_feedback_type_y_Callback(hObject, eventdata, handles)
% hObject    handle to mic_feedback_type_y (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns mic_feedback_type_y contents as cell array
%        contents{get(hObject,'Value')} returns selected item from mic_feedback_type_y
newVal = get(hObject,'Value');
if (newVal~=handles.prev_feedback_y)
    mDAC('change_Micronix_feedback',2,newVal);
end
end

% --- Executes during object creation, after setting all properties.
function mic_feedback_type_y_CreateFcn(hObject, eventdata, handles)
% hObject    handle to mic_feedback_type_y (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

set(hObject,'Value',4);
end

% --- Executes on selection change in mic_feedback_type_z.
function mic_feedback_type_z_Callback(hObject, eventdata, handles)
% hObject    handle to mic_feedback_type_z (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns mic_feedback_type_z contents as cell array
%        contents{get(hObject,'Value')} returns selected item from mic_feedback_type_z
newVal = get(hObject,'Value');
if (newVal~=handles.prev_feedback_z)
    mDAC('change_Micronix_feedback',3,newVal); % args = axis#,fbk val
end
end

% --- Executes during object creation, after setting all properties.
function mic_feedback_type_z_CreateFcn(hObject, eventdata, handles)
% hObject    handle to mic_feedback_type_z (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

set(hObject,'Value',4);
end

% --- Executes on button press in mic_zero_x.
function mic_zero_x_Callback(hObject, eventdata, handles)
% hObject    handle to mic_zero_x (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
mDAC('zero_Micronix_position',1); % arg = axis#
end

% --- Executes on button press in mic_zero_y.
function mic_zero_y_Callback(hObject, eventdata, handles)
% hObject    handle to mic_zero_y (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
mDAC('zero_Micronix_position',2); % arg = axis#
end

% --- Executes on button press in mic_zero_z.
function mic_zero_z_Callback(hObject, eventdata, handles)
% hObject    handle to mic_zero_z (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
mDAC('zero_Micronix_position',3); % arg = axis#
end


function mic_command_window_Callback(hObject, eventdata, handles)
% hObject    handle to mic_command_window (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of mic_command_window as text
%        str2double(get(hObject,'String')) returns contents of mic_command_window as a double
end

% --- Executes during object creation, after setting all properties.
function mic_command_window_CreateFcn(hObject, eventdata, handles)
% hObject    handle to mic_command_window (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on button press in mic_command_send.
function mic_command_send_Callback(hObject, eventdata, handles)
% hObject    handle to mic_command_send (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
toSend = get(handles.mic_command_window,'String');
if ~isempty(toSend)
    mDAC('send_Micronix_command');
end
end

% --- Executes on button press in buttonClosePort.
function buttonClosePort_Callback(hObject, eventdata, handles)
% hObject    handle to buttonClosePort (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
mDAC('close_Micronix_port');
end
