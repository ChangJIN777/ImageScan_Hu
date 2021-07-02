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

if nargin > 3,
    handles.ConfocalScan = varargin{1};
    handles.DAQ = varargin{2};
else
    handles.ConfocalScan = ConfocalScanTrackingParameters();
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
    if nargin > 3,
        handles = varargin{4};
    end

    switch task,
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

%        case 'InitMenu',
%
%            % load in default scans from script
%            %%%% add secret menu %%%%
%            if ispref('nv','DefaultScans'),
%                %addpath(fullfile(pwd,'config'));
%                fname = getpref('nv','DefaultScans');
%                handles.DefaultScans = feval(fname(1:end-2));
%                %rmpath(fullfile(pwd,'config'));
%                for k=1:numel(handles.DefaultScans),
%                    uimenu(handles.menuDefaultScans,'Label',handles.DefaultScans(k).MenuName,...
%                        'Callback',@(ho,eventdata)ConfigureScanFunctions('SetScanFromMenu',k,guidata(ho)));
%                end
%            end
%
%            varargout{1} = handles;
%
%        case 'SetScanFromMenu'
%            index = varargin{2};
%            handles = varargin{3};
%            scan = handles.DefaultScans(index);
%            scan = rmfield(scan,'MenuName');
%
%            set(handles.minX,'String',scan.MinValues(1));
%            set(handles.minY,'String',scan.MinValues(2));
%            set(handles.minZ,'String',scan.MinValues(3));
%
%            set(handles.maxX,'String',scan.MaxValues(1));
%            set(handles.maxY,'String',scan.MaxValues(2));
%            set(handles.maxZ,'String',scan.MaxValues(3));
%
%            set(handles.pointsX,'String',scan.NPoints(1));
%            set(handles.pointsY,'String',scan.NPoints(2));
%            set(handles.pointsZ,'String',scan.NPoints(3));
%
%            set(handles.offsetX,'String',scan.OffsetValues(1));
%            set(handles.offsetY,'String',scan.OffsetValues(2));
%            set(handles.offsetZ,'String',scan.OffsetValues(3));
%
%            set(handles.dwell,'String',scan.DwellTime);
%
%            set(handles.enableX,'Value',scan.bEnable(1));
%            set(handles.enableY,'Value',scan.bEnable(2));
%            set(handles.enableZ,'Value',scan.bEnable(3));
%
%            varargout{1} = scan;
%
        case 'Save'
            
            TrackSize = str2num(get(handles.trackSize, 'String'));
            TrackSizeZ = str2num(get(handles.trackSizeZ, 'String'));

            %MaxVal = .5*TrackSize*[1 handles.DAQ.ratioYtoX handles.DAQ.ratioZtoX];
            MaxVal(1) = .5*TrackSize*1;
            MaxVal(2) = .5*TrackSize*1;
            MaxVal(3) = .5*TrackSizeZ;
            MinVal = -MaxVal;
%             MaxVal = MaxVal + handles.ConfocalScan.OffsetValues;
%             MinVal = MinVal + handles.ConfocalScan.OffsetValues;
            
            TrackingThreshold = str2num(get(handles.editThreshold, 'String'));
            
            DwellTime = str2num(get(handles.editScanDwellTime,'String'));
            CompDwellTime = str2num(get(handles.editComparisonDwellTime, 'String'));
            PostDwellTime = str2num(get(handles.editPostTrackingDwellTime, 'String'));

            bEnable = [1 1 1];
            
            NPoints = str2num(get(handles.points, 'String'))*[1 1 1];
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
function varargout = ConfigureTracking_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end



function editScanDwellTime_Callback(hObject, eventdata, handles)
% hObject    handle to editScanDwellTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editScanDwellTime as text
%        str2double(get(hObject,'String')) returns contents of editScanDwellTime as a double
input = abs(str2num(get(hObject, 'String')));
set(hObject, 'String', num2str(input));
end


% --- Executes during object creation, after setting all properties.
function editScanDwellTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editScanDwellTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function editThreshold_Callback(hObject, eventdata, handles)
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
function editThreshold_CreateFcn(hObject, eventdata, handles)
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


function points_Callback(hObject, eventdata, handles)
% hObject    handle to points (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of points as text
%        str2double(get(hObject,'String')) returns contents of points as a double
input = round(abs(str2num(get(hObject, 'String'))));
if isempty(input)
    set(hObject, 'String', '0');
    input = 0;
end
set(hObject, 'String', num2str(abs(round(input))));
end

% --- Executes during object creation, after setting all properties.
function points_CreateFcn(hObject, eventdata, handles)
% hObject    handle to points (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function trackSize_Callback(hObject, eventdata, handles)
% hObject    handle to trackSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of trackSize as text
%        str2double(get(hObject,'String')) returns contents of trackSize as a double

% 9-17-12, 9-18-12 microns/volts conversion
mpv1 = handles.ConfocalScan.micronsPerVoltX;
mpv2 = handles.ConfocalScan.micronsPerVoltX;
mpv = min([mpv1,mpv2]);

temp00=handles.DAQ.AnalogOutMaxVoltages
temp11=handles.DAQ.AnalogOutMaxVoltages*mpv

input = abs(str2num(get(hObject, 'String')));
if input>min(handles.DAQ.AnalogOutMaxVoltages(1)*mpv-handles.DAQ.AnalogOutMinVoltages(1)*mpv)
    input = min(handles.DAQ.AnalogOutMaxVoltages(1)*mpv-handles.DAQ.AnalogOutMinVoltages(1)*mpv);
end
set(hObject, 'String', num2str(input));
end

% --- Executes during object creation, after setting all properties.
function trackSize_CreateFcn(hObject, eventdata, handles)
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
function figure1_WindowKeyPressFcn(hObject, eventdata, handles)
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



function trackSizeZ_Callback(hObject, eventdata, handles)
% hObject    handle to trackSizeZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of trackSizeZ as text
%        str2double(get(hObject,'String')) returns contents of trackSizeZ as a double

% 9-17-12, 9-18-12 microns/volts conversion
mpv = handles.ConfocalScan.micronsPerVoltZ;


    input = abs(str2num(get(hObject, 'String')));
    if input>min(handles.DAQ.AnalogOutMaxVoltages(3)*mpv-handles.DAQ.AnalogOutMinVoltages(3)*mpv)
        input = min(handles.DAQ.AnalogOutMaxVoltages(3)*mpv-handles.DAQ.AnalogOutMinVoltages(3)*mpv);
    end
    set(hObject, 'String', num2str(input));
end

% --- Executes during object creation, after setting all properties.
function trackSizeZ_CreateFcn(hObject, eventdata, handles)
% hObject    handle to trackSizeZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end



function editComparisonDwellTime_Callback(hObject, eventdata, handles)
% hObject    handle to editComparisonDwellTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editComparisonDwellTime as text
%        str2double(get(hObject,'String')) returns contents of editComparisonDwellTime as a double
input = abs(str2num(get(hObject, 'String')));
set(hObject, 'String', num2str(input));
end

% --- Executes during object creation, after setting all properties.
function editComparisonDwellTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editComparisonDwellTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end



function editPostTrackingDwellTime_Callback(hObject, eventdata, handles)
% hObject    handle to editPostTrackingDwellTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPostTrackingDwellTime as text
%        str2double(get(hObject,'String')) returns contents of editPostTrackingDwellTime as a double
    input = abs(str2num(get(hObject, 'String')));
    set(hObject, 'String', num2str(input));
end

% --- Executes during object creation, after setting all properties.
function editPostTrackingDwellTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPostTrackingDwellTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
       set(hObject,'BackgroundColor','white');
    end
end
