% Zhiran, 2/12/2020. A GUI used for control Z piezo, while writing down the Zurich's input data

function varargout = zSetMeasure(varargin)
% ZSETMEASURE MATLAB code for zSetMeasure.fig
%      ZSETMEASURE, by itself, creates a new ZSETMEASURE or raises the existing
%      singleton*.
%
%      H = ZSETMEASURE returns the handle to a new ZSETMEASURE or the handle to
%      the existing singleton*.
%
%      ZSETMEASURE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ZSETMEASURE.M with the given input arguments.
%
%      ZSETMEASURE('Property','Value',...) creates a new ZSETMEASURE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before zSetMeasure_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to zSetMeasure_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help zSetMeasure

% Last Modified by GUIDE v2.5 19-Feb-2020 12:01:16

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @zSetMeasure_OpeningFcn, ...
                   'gui_OutputFcn',  @zSetMeasure_OutputFcn, ...
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


% --- Executes just before zSetMeasure is made visible.
function zSetMeasure_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to zSetMeasure (see VARARGIN)

% Choose default command line output for zSetMeasure
handles.output = hObject;

% Start USER code
handles.timer = timer(...
    'ExecutionMode', 'fixedRate', ...       % Run timer repeatedly.
    'Period', 0.05, ...                        % Initial period is 0.05 sec.
    'TimerFcn', {@update_display,hObject}); % Specify callback function.
handles.fid=fopen('C:\Users\lab\Desktop\zSetMeasure1.txt','a+');
clear ziDAQ
ziDAQ('connect', 'localhost', 8005);
handles.zdevice = ziAutoDetect();
handles.Zshift_struct=ziDAQ('get',['/',handles.zdevice,'/PIDS/0/SHIFT']);
handles.Zshift=handles.Zshift_struct.dev531.pids.shift;
% End of USER code
% Update handles structure
guidata(hObject,handles);

% UIWAIT makes zSetMeasure wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% START USER CODE
function update_display(hObject,eventdata,handles)
% Timer timer1 callback, called each time timer iterates.
% Gets surface Z data, adds noise, and writes it back to surface object.
handles = guidata(handles);
handles.bufferdata=ziDAQ('get',['/',handles.zdevice,'/DEMODS/0/SAMPLE']);
fprintf(handles.fid,'%1$10s %2$8s \r\n',num2str(1000*((handles.bufferdata.dev531.demods.sample.x)^2+(handles.bufferdata.dev531.demods.sample.y)^2)^0.5),num2str(handles.Zshift));
% END USER CODE

% --- Outputs from this function are returned to the command line.
function varargout = zSetMeasure_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in pushbutton4.
function pushbutton4_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if strcmp(get(handles.timer, 'Running'), 'off')
    start(handles.timer);
end

% --- Executes on button press in pushbutton6.
function pushbutton6_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if strcmp(get(handles.timer, 'Running'), 'on')
    stop(handles.timer);
    fclose('all');
end

% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ziDAQ('setDouble',['/',handles.zdevice,'/PIDS/0/OUTPUTDEFAULT'],handles.Zshift-0.001);
handles.Zshift=handles.Zshift-0.001;
% Update handles structure
guidata(hObject,handles);

% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ziDAQ('setDouble',['/',handles.zdevice,'/PIDS/0/OUTPUTDEFAULT'],handles.Zshift+0.001);
handles.Zshift=handles.Zshift+0.001;
% Update handles structure
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function figure1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called



function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% START USER CODE
% Necessary to provide this function to prevent timer callback
% from causing an error after GUI code stops executing.
% Before exiting, if the timer is running, stop it.
if strcmp(get(handles.timer, 'Running'), 'on')
    stop(handles.timer);
end
% Destroy timer
delete(handles.timer)
% END USER CODE

% Hint: delete(hObject) closes the figure
delete(hObject);


% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton7.
function pushbutton7_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.Zshift_struct=ziDAQ('get',['/',handles.zdevice,'/PIDS/0/SHIFT']);
handles.Zshift=handles.Zshift_struct.dev531.pids.shift;
guidata(hObject,handles);
