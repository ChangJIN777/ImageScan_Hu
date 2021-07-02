function varargout = ConfigureTracking(varargin)
% CONFIGURETRACKING MATLAB code for ConfigureTracking.fig
%      CONFIGURETRACKING, by itself, creates a new CONFIGURETRACKING or raises the existing
%      singleton*.
%
%      H = CONFIGURETRACKING returns the handle to a new CONFIGURETRACKING or the handle to
%      the existing singleton*.
%
%      CONFIGURETRACKING('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CONFIGURETRACKING.M with the given input arguments.
%
%      CONFIGURETRACKING('Property','Value',...) creates a new CONFIGURETRACKING or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ConfigureTracking_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ConfigureTracking_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ConfigureTracking

% Last Modified by GUIDE v2.5 31-May-2012 15:49:07

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ConfigureTracking_OpeningFcn, ...
                   'gui_OutputFcn',  @ConfigureTracking_OutputFcn, ...
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


% --- Executes just before ConfigureTracking is made visible.
function ConfigureTracking_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ConfigureTracking (see VARARGIN)

% Choose default command line output for ConfigureTracking
handles.output = hObject;

if nargin > 3
    handles.ConfocalScan = varargin{1}.TrackingParameters;
    handles.configS = varargin{1}.configS;
else
    handles.ConfocalScan = ConfocalScanTrackingParameters();
    handles.configS = ConfigureImageScan();
end
set(handles.editThreshold, 'Tooltip', ...
    sprintf('After calculating the new location for the NV Center,\nthe number of counts received at the old location are\ncompared to the number of counts at the new location.\nIf the new location has this many times more counts\nthan the old, the tracking cursor will move\nto the new location.'));
ConfigureScanFunctions('Initialize',hObject,eventdata,handles);
%handles = ConfigureScanFunctions('InitMenu',hObject,eventdata,handles);



guidata(hObject, handles);

% UIWAIT makes ConfigureTracking wait for user response (see UIRESUME)
% uiwait(handles.figure1);
end

function [varargout] = ConfigureScanFunctions(varargin)

    task = varargin{1};
    hObject = varargin{2};
    eventdata = varargin{3};
    if nargin > 3
        handles = varargin{4};
    end

    switch task
        case 'Initialize'
            scan = handles.ConfocalScan; % actually instance of ConfocalScanTrackingParameters() class.

            set(handles.trackSize, 'String', num2str(max(scan.TrackingBoxSize)));
            set(handles.trackSizeZ, 'String',num2str(max(scan.TrackingBoxSizeZ)));
            set(handles.points, 'String', num2str(max(scan.NPoints)));
            set(handles.editScanDwellTime, 'String', num2str(scan.DwellTime));
            set(handles.editComparisonDwellTime, 'String', num2str(scan.CompDwellTime));
            set(handles.editPostTrackingDwellTime, 'String', num2str(scan.PostDwellTime));
            set(handles.editThreshold, 'String', num2str(scan.TrackingThreshold));

            varargout{1} = scan;


        case 'Save'
            
            TrackSize = str2double(get(handles.trackSize, 'String'));
            TrackSizeZ = str2double(get(handles.trackSizeZ, 'String'));

            MaxVal(1) = .5*TrackSize*1;
            MaxVal(2) = .5*TrackSize;
            MaxVal(3) = .5*TrackSizeZ;
            MinVal = -MaxVal;

            
            TrackingThreshold = str2double(get(handles.editThreshold, 'String'));
            
            DwellTime = str2double(get(handles.editScanDwellTime,'String'));
            CompDwellTime = str2double(get(handles.editComparisonDwellTime, 'String'));
            PostDwellTime = str2double(get(handles.editPostTrackingDwellTime, 'String'));

            bEnable = [1 1 1];
            
            NPoints = str2double(get(handles.points, 'String'))*[1 1 1];
            % ConfocalScan is
            % actually an instance of ConfocalScanTrackingParameters() class.
            handles.ConfocalScan.MinValues = MinVal;
            handles.ConfocalScan.MaxValues = MaxVal;
            handles.ConfocalScan.NPoints = NPoints;
            handles.ConfocalScan.DwellTime = DwellTime;
            handles.ConfocalScan.CompDwellTime = CompDwellTime;
            handles.ConfocalScan.PostDwellTime = PostDwellTime;
            handles.ConfocalScan.bEnable = bEnable;
            handles.ConfocalScan.TrackingThreshold = TrackingThreshold;
            handles.ConfocalScan.TrackingBoxSize = TrackSize;
            handles.ConfocalScan.TrackingBoxSizeZ = TrackSizeZ;

            guidata(hObject,handles);
    end
end


% --- Outputs from this function are returned to the command line.
function varargout = ConfigureTracking_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end



function editScanDwellTime_Callback(hObject, ~, ~)
% hObject    handle to editScanDwellTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editScanDwellTime as text
%        str2double(get(hObject,'String')) returns contents of editScanDwellTime as a double
input = abs(str2num(get(hObject, 'String')));
set(hObject, 'String', num2str(input));
end


% --- Executes during object creation, after setting all properties.
function editScanDwellTime_CreateFcn(hObject, ~, ~)
% hObject    handle to editScanDwellTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function editThreshold_Callback(hObject, ~, ~)
% hObject    handle to editThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editThreshold as text
%        str2double(get(hObject,'String')) returns contents of editThreshold as a double
input = abs(str2num(get(hObject, 'String')));
if input < 1
    input = 1;
end
set(hObject, 'String', num2str(input));
end


% --- Executes during object creation, after setting all properties.
function editThreshold_CreateFcn(hObject, ~, ~)
% hObject    handle to editThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in save.
function save_Callback(hObject, eventdata, handles)
% hObject    handle to save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    ConfigureScanFunctions('Save',hObject,eventdata,handles);
    handles.output = handles.ConfocalScan;
    % notify of a state change
    %notify(handles.ConfocalScan,'ScanStateChange');
    close();
end


function points_Callback(hObject, ~, ~)
% hObject    handle to points (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of points as text
%        str2double(get(hObject,'String')) returns contents of points as a double
input = round(abs(str2double(get(hObject, 'String'))));
if isempty(input)
    set(hObject, 'String', '0');
    input = 0;
end
set(hObject, 'String', num2str(abs(round(input))));
end

% --- Executes during object creation, after setting all properties.
function points_CreateFcn(hObject, ~, ~)
% hObject    handle to points (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function trackSize_Callback(hObject, ~, handles)
% hObject    handle to trackSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of trackSize as text
%        str2double(get(hObject,'String')) returns contents of trackSize as a double

mpvX = handles.configS.micronsPerVoltX;
mpvY = handles.configS.micronsPerVoltY;
XmaxV = handles.configS.xMaxVolts;
XminV = handles.configS.xMinVolts;
YmaxV = handles.configS.yMaxVolts;
YminV = handles.configS.yMinVolts;

input = abs(str2double(get(hObject, 'String')));
if input>min(XmaxV*mpvX - XminV*mpvX) || input>min(YmaxV*mpvY - YminV*mpvY)
    input = min((XmaxV*mpvX - XminV*mpvX), (YmaxV*mpvY - YminV*mpvY));
end
set(hObject, 'String', num2str(input));

clear mpvX mpvY XmaxV XminV YmaxV YminV
end

% --- Executes during object creation, after setting all properties.
function trackSize_CreateFcn(hObject, ~, ~)
% hObject    handle to trackSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on key press with focus on figure1 or any of its controls.
function figure1_WindowKeyPressFcn(~, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if strcmp(eventdata.Key, 's')
    if length(eventdata.Modifier) == 1 && ...
            strcmp(eventdata.Modifier{:},'control')
        import java.awt.*;
        import java.awt.event.*;
        rob = Robot;
        rob.keyPress(KeyEvent.VK_ENTER);
        rob.keyRelease(KeyEvent.VK_ENTER);
        pause(.1)
        save_Callback(handles.save, eventdata, handles);
    end
end
end



function trackSizeZ_Callback(hObject, ~, handles)
% hObject    handle to trackSizeZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of trackSizeZ as text
%        str2double(get(hObject,'String')) returns contents of trackSizeZ as a double

mpvZ = handles.configS.micronsPerVoltZ;
ZmaxV = handles.configS.zMaxVolts;
ZminV = handles.configS.zMinVolts;

    input = abs(str2double(get(hObject, 'String')));
    if input>min(ZmaxV*mpvZ - ZminV*mpvZ)
        input = min(ZmaxV*mpvZ - ZminV*mpvZ);
    end
    set(hObject, 'String', num2str(input));
clear mpvZ ZminV ZmaxV
end

% --- Executes during object creation, after setting all properties.
function trackSizeZ_CreateFcn(hObject, ~, ~)
% hObject    handle to trackSizeZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end



function editComparisonDwellTime_Callback(hObject, ~, ~)
% hObject    handle to editComparisonDwellTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editComparisonDwellTime as text
%        str2double(get(hObject,'String')) returns contents of editComparisonDwellTime as a double
input = abs(str2double(get(hObject, 'String')));
set(hObject, 'String', num2str(input));
end

% --- Executes during object creation, after setting all properties.
function editComparisonDwellTime_CreateFcn(hObject, ~, ~)
% hObject    handle to editComparisonDwellTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end



function editPostTrackingDwellTime_Callback(hObject, ~, ~)
% hObject    handle to editPostTrackingDwellTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPostTrackingDwellTime as text
%        str2double(get(hObject,'String')) returns contents of editPostTrackingDwellTime as a double
    input = abs(str2double(get(hObject, 'String')));
    set(hObject, 'String', num2str(input));
end

% --- Executes during object creation, after setting all properties.
function editPostTrackingDwellTime_CreateFcn(hObject, ~, ~)
% hObject    handle to editPostTrackingDwellTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
       set(hObject,'BackgroundColor','white');
    end
end
