function varargout = PhaseGUI(varargin)
% PHASEGUI MATLAB code for PhaseGUI.fig
%      PHASEGUI, by itself, creates a new PHASEGUI or raises the existing
%      singleton*.
%
%      H = PHASEGUI returns the handle to a new PHASEGUI or the handle to
%      the existing singleton*.
%
%      PHASEGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PHASEGUI.M with the given input arguments.
%
%      PHASEGUI('Property','Value',...) creates a new PHASEGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before PhaseGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to PhaseGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help PhaseGUI

% Last Modified by GUIDE v2.5 14-Jul-2015 17:29:16

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @PhaseGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @PhaseGUI_OutputFcn, ...
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


% --- Executes just before PhaseGUI is made visible.
function PhaseGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to PhaseGUI (see VARARGIN)

% Choose default command line output for PhaseGUI
handles.output = hObject;

handles.test_guiHandles = varargin{1}; % handles passed from afm figures: test_gui



% Update handles structure
guidata(hObject, handles);

buffer = 2500;
x = linspace(-10,0,buffer);
y= 0.*x;
set(handles.axes_phase,'XLim',[-10,0],'YLim',[-1 1]);
set(handles.axes_phase,'Units','pixels','DrawMode','fast','XTickLabel','');
%set(gcf,'Renderer','painter');
handles.phase_h = line('XData',x,'YData',y);

% Update handles structure
guidata(hObject, handles);
mDAC('set_phase_handles',handles.TextBox_phase_volt,...
    handles.TextBox_phase_deg,...
    handles.phase_h);

% UIWAIT makes PhaseGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = PhaseGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton_set_mVoltsPerDeg.
function pushbutton_set_mVoltsPerDeg_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_set_mVoltsPerDeg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

mDAC('set_phase_handles',handles.TextBox_phase_volt,...
    handles.TextBox_phase_deg,...
    handles.phase_h);

input = str2double(get(handles.edit_mVoltsPerDeg,'String'));
if input <0
    input = abs(input);
end
if input>36 
    input=36;
end
if isnan(input)==1
    input=28;
end
set(handles.TextBox_mVoltsPerDeg,'String',num2str(input));
mDAC('set_phase_conversion',input);
