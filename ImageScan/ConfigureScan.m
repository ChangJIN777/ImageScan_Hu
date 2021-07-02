function varargout = ConfigureScan(varargin)
% CONFIGURESCAN M-file for ConfigureScan.fig
%      CONFIGURESCAN, by itself, creates a new CONFIGURESCAN or raises the existing
%      singleton*.
%
%      H = CONFIGURESCAN returns the handle to a new CONFIGURESCAN or the handle to
%      the existing singleton*.
%
%      CONFIGURESCAN('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CONFIGURESCAN.M with the given input arguments.
%
%      CONFIGURESCAN('Property','Value',...) creates a new CONFIGURESCAN or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ConfigureScan_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ConfigureScan_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ConfigureScan

% Last Modified by GUIDE v2.5 18-Oct-2012 18:22:05

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ConfigureScan_OpeningFcn, ...
                   'gui_OutputFcn',  @ConfigureScan_OutputFcn, ...
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

% --- Executes just before ConfigureScan is made visible.
function ConfigureScan_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ConfigureScan (see VARARGIN)

% Choose default command line output for ConfigureScan
handles.output = hObject;

if nargin > 3
    % get the first varargin, which is current scan parameters
    handles.ConfocalScan = varargin{1};
else
    handles.ConfocalScan = ConfocalScanParameters();
end

if nargin > 4
    % added on 10/18/2012
    % get the next two varargin, which is current cursor position
    handles.currentCursorX = varargin{2};
    handles.currentCursorY = varargin{3};
    handles.imageScanHandles = varargin{4};
else
    % other wise set to zero, but any call should use these varargins
    handles.currentCursorX = 0;
    handles.currentCursorY = 0;
end

ConfigureScanFunctions('Initialize',hObject,eventdata,handles);
handles = ConfigureScanFunctions('InitMenu',hObject,eventdata,handles);

guidata(hObject, handles);

% UIWAIT makes ConfigureScan wait for user response (see UIRESUME)
%uiwait(handles.figure1);
end

% --- Outputs from this function are returned to the command line.
function varargout = ConfigureScan_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% Return Confocal Scan to command line on close
%varargout{1} = handles.ConfocalScan;
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
            scan = handles.ConfocalScan;

            % DAQManager.X,Y,Z are just integer indicies. As of 9-17-2012
            % the actual scan.Min/MaxValues are in microns as set in the
            % class ConfocalScan.
            set(handles.minX,'String',scan.MinValues(DAQManager.X));
            set(handles.minY,'String',scan.MinValues(DAQManager.Y));
            set(handles.minZ,'String',scan.MinValues(DAQManager.Z));

            set(handles.maxX,'String',scan.MaxValues(DAQManager.X));
            set(handles.maxY,'String',scan.MaxValues(DAQManager.Y));
            set(handles.maxZ,'String',scan.MaxValues(DAQManager.Z));

            set(handles.pointsX,'String',scan.NPoints(DAQManager.X));
            set(handles.pointsY,'String',scan.NPoints(DAQManager.Y));
            set(handles.pointsZ,'String',scan.NPoints(DAQManager.Z));

            set(handles.offsetX,'String',scan.OffsetValues(DAQManager.X));
            set(handles.offsetY,'String',scan.OffsetValues(DAQManager.Y));
            set(handles.offsetZ,'String',scan.OffsetValues(DAQManager.Z));

            set(handles.dwell,'String',scan.DwellTime);

            set(handles.enableX,'Value',scan.bEnable(DAQManager.X));
            set(handles.enableY,'Value',scan.bEnable(DAQManager.Y));
            set(handles.enableZ,'Value',scan.bEnable(DAQManager.Z));
            
            set(handles.checkboxSaveData,'Value',scan.bSaveData);

            varargout{1} = scan;
            
        case 'CenterScanOnCursor'
            scan = handles.ConfocalScan;
            
            % set all based on current scan, except x,y limits are based on
            % the cursor
            halfSizeX = 0.5*(scan.MaxValues(DAQManager.X)-scan.MinValues(DAQManager.X));
            halfSizeY = 0.5*(scan.MaxValues(DAQManager.X)-scan.MinValues(DAQManager.X));
            cX = handles.currentCursorX;
            cY = handles.currentCursorY;
            
            set(handles.minX,'String',cX-halfSizeX);
            set(handles.minY,'String',cY-halfSizeY);
            set(handles.minZ,'String',scan.MinValues(DAQManager.Z));

            set(handles.maxX,'String',cX+halfSizeX);
            set(handles.maxY,'String',cY+halfSizeY);
            set(handles.maxZ,'String',scan.MaxValues(DAQManager.Z));

            set(handles.pointsX,'String',scan.NPoints(DAQManager.X));
            set(handles.pointsY,'String',scan.NPoints(DAQManager.Y));
            set(handles.pointsZ,'String',scan.NPoints(DAQManager.Z));

            set(handles.offsetX,'String',scan.OffsetValues(DAQManager.X));
            set(handles.offsetY,'String',scan.OffsetValues(DAQManager.Y));
            set(handles.offsetZ,'String',scan.OffsetValues(DAQManager.Z));

            set(handles.dwell,'String',scan.DwellTime);

            set(handles.enableX,'Value',1);
            set(handles.enableY,'Value',1);
            set(handles.enableZ,'Value',0);
            
            set(handles.checkboxSaveData,'Value',scan.bSaveData);

            varargout{1} = scan;

        case 'InitMenu'

            % load in default scans from script
            %%%% add secret menu %%%%

            handles.DefaultScans = DefaultScans();
            for k=1:numel(handles.DefaultScans)
                uimenu(handles.menuDefaultScans,'Label',handles.DefaultScans(k).MenuName,...
                    'Callback',@(ho,eventdata)ConfigureScanFunctions('SetScanFromMenu',k,guidata(ho)));
            end
            
            
            varargout{1} = handles;

        case 'SetScanFromMenu'
            index = varargin{2};
            handles = varargin{3};
            scan = handles.DefaultScans(index);

            % these should also all still be fine as of 9-17-2012 as the
            % volts on front panel are changed to microns.
            % Again, DAQManager.X,Y,Z are just integers 1,2,3 and there is no
            % implication that they have to do with voltages.
            if ~isnan(scan.MinValues(DAQManager.X))
                set(handles.minX,'String',scan.MinValues(DAQManager.X));
            end
            if ~isnan(scan.MinValues(DAQManager.Y))
                set(handles.minY,'String',scan.MinValues(DAQManager.Y));
            end
            if ~isnan(scan.MinValues(DAQManager.Z))
                set(handles.minZ,'String',scan.MinValues(DAQManager.Z));
            end

            if ~isnan(scan.MinValues(DAQManager.X))
                set(handles.maxX,'String',scan.MaxValues(DAQManager.X));
            end
            if ~isnan(scan.MaxValues(DAQManager.Y))
                set(handles.maxY,'String',scan.MaxValues(DAQManager.Y));
            end
            if ~isnan(scan.MaxValues(DAQManager.Z))
                set(handles.maxZ,'String',scan.MaxValues(DAQManager.Z));
            end

            if ~isnan(scan.NPoints(DAQManager.X))
                set(handles.pointsX,'String',scan.NPoints(DAQManager.X));
            end
            if ~isnan(scan.NPoints(DAQManager.Y))
                set(handles.pointsY,'String',scan.NPoints(DAQManager.Y));
            end
            if ~isnan(scan.NPoints(DAQManager.Z))
                set(handles.pointsZ,'String',scan.NPoints(DAQManager.Z));
            end

            if ~isnan(scan.OffsetValues(DAQManager.X))
                set(handles.offsetX,'String',scan.OffsetValues(DAQManager.X));
            end
            if ~isnan(scan.OffsetValues(DAQManager.Y))
                set(handles.offsetY,'String',scan.OffsetValues(DAQManager.Y));
            end
            if ~isnan(scan.OffsetValues(DAQManager.Z))
                set(handles.offsetZ,'String',scan.OffsetValues(DAQManager.Z));
            end

            if ~isnan(scan.DwellTime)
                set(handles.dwell,'String',scan.DwellTime);
            end

            if ~isnan(scan.bEnable(DAQManager.X))
                set(handles.enableX,'Value',scan.bEnable(DAQManager.X));
            end
            if ~isnan(scan.bEnable(DAQManager.Y))
                set(handles.enableY,'Value',scan.bEnable(DAQManager.Y));
            end
            if ~isnan(scan.bEnable(DAQManager.Z))
                set(handles.enableZ,'Value',scan.bEnable(DAQManager.Z));
            end

            varargout{1} = scan;

        case 'Save'

            % 3-element arrays called MinVal, MaxVal, Offset, etc.
            % again, as of 9-17-2012 these numbers are in microns!
            MinVal(DAQManager.X) = str2num(get(handles.minX,'String')); %#ok<*ST2NM>
            MinVal(DAQManager.Y) = str2num(get(handles.minY,'String'));
            MinVal(DAQManager.Z) = str2num(get(handles.minZ,'String'));

            MaxVal(DAQManager.X) = str2num(get(handles.maxX,'String'));
            MaxVal(DAQManager.Y) = str2num(get(handles.maxY,'String'));
            MaxVal(DAQManager.Z) = str2num(get(handles.maxZ,'String'));

            Offset(DAQManager.X) = str2num(get(handles.offsetX,'String'));
            Offset(DAQManager.Y) = str2num(get(handles.offsetY,'String'));
            Offset(DAQManager.Z) = str2num(get(handles.offsetZ,'String'));

            DwellTime = str2num(get(handles.dwell,'String'));

            bEnable(DAQManager.X) = get(handles.enableX,'Value');
            bEnable(DAQManager.Y) = get(handles.enableY,'Value');
            bEnable(DAQManager.Z) = get(handles.enableZ,'Value');
            
            bSaveData = get(handles.checkboxSaveData,'Value');
            
            NPoints(DAQManager.X) = str2num(get(handles.pointsX,'String'));
            NPoints(DAQManager.Y) = str2num(get(handles.pointsY,'String'));
            NPoints(DAQManager.Z) = str2num(get(handles.pointsZ,'String'));


            handles.ConfocalScan.MinValues = MinVal;
            handles.ConfocalScan.MaxValues = MaxVal;
            handles.ConfocalScan.NPoints = NPoints;
            handles.ConfocalScan.OffsetValues = Offset;
            handles.ConfocalScan.DwellTime = DwellTime;
            handles.ConfocalScan.bEnable = bEnable;
            handles.ConfocalScan.bSaveData = bSaveData;

            guidata(hObject,handles);
    end
end

function minX_Callback(hObject, eventdata, handles)
% hObject    handle to minX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of minX as text
%        str2double(get(hObject,'String')) returns contents of minX as a double

end

function [hMax hMin hPoints hOffset hEnable dimStr] = dimLists(handles)
    hMax(DAQManager.X) = handles.maxX;
    hMax(DAQManager.Y) = handles.maxY;
    hMax(DAQManager.Z) = handles.maxZ;
    hMin(DAQManager.X) = handles.minX;
    hMin(DAQManager.Y) = handles.minY;
    hMin(DAQManager.Z) = handles.minZ;    
    hPoints(DAQManager.X) = handles.pointsX;
    hPoints(DAQManager.Y) = handles.pointsY;
    hPoints(DAQManager.Z) = handles.pointsZ;

    hOffset(DAQManager.X) = handles.offsetX;
    hOffset(DAQManager.Y) = handles.offsetY;
    hOffset(DAQManager.Z) = handles.offsetZ;
    
    hEnable(DAQManager.X) = handles.enableX;
    hEnable(DAQManager.Y) = handles.enableY;
    hEnable(DAQManager.Z) = handles.enableZ;
    dimStr(DAQManager.X) = 'X';
    dimStr(DAQManager.Y) = 'Y';
    dimStr(DAQManager.Z) = 'Z';
end

function bool = validate_offset(dim,handles)
    bool = true;
    [hMax hMin hPoints hOffset hEnable dimStr] = dimLists(handles);  
    input = str2num(get(hOffset(dim), 'String'));
    enable = get(hEnable(dim),'Value');
    if enable == true
        if isempty(input)
            errordlg(['Offset ' dimStr(dim) ' must be a numerical value'],'Input Error');
            bool = false;
        end
        maxVal = str2num(get(hMax(dim), 'String'));
        minVal = str2num(get(hMax(dim), 'String'));
        % 9-17-2012 microns to volts, this is where we have to change the
        % code to accept micron values based on voltage limits
        mpv(1) = handles.imageScanHandles.configS.micronsPerVoltX;
        mpv(2) = handles.imageScanHandles.configS.micronsPerVoltY;
        mpv(3) = handles.imageScanHandles.configS.voltsPerMicronX;
        if (input+maxVal) > round(handles.imageScanHandles.configS.AnalogOutMaxVoltages(dim)*mpv(dim)*1000)/1000
            errordlg(['Offset ' dimStr(dim) '+ Max ' dimStr(dim) ' cannot be greater than ' ...
                sprintf('%.2f',handles.imageScanHandles.configS.AnalogOutMaxVoltages(dim)*mpv(dim))],'Input Error');
            bool = false;
        elseif (input+minVal) < round(handles.imageScanHandles.configS.AnalogOutMinVoltages(dim)*mpv(dim)*1000)/1000
            errordlg(['Offset ' dimStr(dim) '+ Min ' dimStr(dim) ' cannot be less than ' ...
                sprintf('%.2f',handles.imageScanHandles.configS.AnalogOutMinVoltages(dim)*mpv(dim))],'Input Error');
            bool = false;
        end
    elseif isempty(input)
        set(hOffset(dim), 'String', '0');
    end
end

function bool = validate_min(dim,handles)
    bool = true;
    [hMax hMin hPoints hOffset hEnable dimStr] = dimLists(handles);
    input = str2num(get(hMin(dim), 'String'));
    enable = get(hEnable(dim),'Value');
    if enable == true
        if isempty(input)
            errordlg(['Min ' dimStr(dim) ' must be a numerical value'],'Input Error');
            bool = false;
            %set(hMin(dim), 'String', '0');
        end
        maxVal = str2num(get(hMax(dim),'String'));
        % 9-17-2012 microns to volts, this is where we have to change the
        % code to accept micron values based on voltage limits
        mpv(1) = handles.imageScanHandles.configS.micronsPerVoltX;
        mpv(2) = handles.imageScanHandles.configS.micronsPerVoltY;
        mpv(3) = handles.imageScanHandles.configS.micronsPerVoltZ;
        if isempty(maxVal) == false && input >= maxVal
            errordlg(['Min ' dimStr(dim) ' must be less than Max' dimStr(dim)],'Input Error');
            bool = false;
        elseif input < handles.imageScanHandles.configS.AnalogOutMinVoltages(dim)*mpv(dim)
            errordlg(['Min ' dimStr(dim) ' cannot be less than ' ...
                sprintf('%.2f',handles.imageScanHandles.configS.AnalogOutMinVoltages(dim)*mpv(dim))],'Input Error');
            bool = false;
        end
    elseif isempty(input)
        set(hMin(dim), 'String', '0');
    end
end

function bool = validate_max(dim,handles)
    bool = true;
    [hMax hMin hPoints hOffset hEnable dimStr] = dimLists(handles);
    input = str2num(get(hMax(dim), 'String'));
    enable = get(hEnable(dim),'Value');
    if enable == true
        if isempty(input)
            errordlg(['Max ' dimStr(dim) ' must be a numerical value'],'Input Error');
            bool = false;
        end
        minVal = str2num(get(hMin(dim), 'String'));
        % 9-17-2012 microns to volts, this is where we have to change the
        % code to accept micron values based on voltage limits
        mpv(1) = handles.imageScanHandles.configS.micronsPerVoltX;
        mpv(2) = handles.imageScanHandles.configS.micronsPerVoltY;
        mpv(3) = handles.imageScanHandles.configS.micronsPerVoltZ;
        if input > handles.imageScanHandles.configS.AnalogOutMaxVoltages(dim)*mpv(dim)
            errordlg(['Max ' dimStr(dim) ' cannot be more than ' ...
                sprintf('%.2f',handles.imageScanHandles.configS.AnalogOutMaxVoltages(dim)*mpv(dim))],'Input Error');
            bool = false;
        end
    elseif isempty(input)
        set(hMax(dim), 'String', '0');
    end
end

function bool = validate_points(dim,handles)
    bool = true;
    [hMax hMin hPoints hOffset hEnable dimStr] = dimLists(handles);
    input = str2num(get(hPoints(dim), 'String'));
    enable = get(hEnable(dim),'Value');
    if enable == true
        if isempty(input)
            errordlg(['Points ' dimStr(dim) ' must be an integer'],'Input Error');
            bool = false;
            input = 0;
        end
        if abs(round(input)) ~= input
            errordlg(['Points ' dimStr(dim) ' must be an integer'],'Input Error');
            bool = false;
        end
    elseif isempty(input)
        set(hPoints(dim), 'String', '0');
    end
    
end


function bool = validate_dwell(handles)
    bool = true;
    [hMax hMin hPoints hOffset hEnable dimStr] = dimLists(handles);
    input = str2num(get(handles.dwell, 'String'));

    if isempty(input)
        errordlg('Dwell time must be a positive numerical value','Input Error');
        bool = false;
    end
    if input <= 0
        errordlg('Dwell time must be positive','Input Error');
        bool = false;

    end

end

function bool = validate_enable(handles)
    bool = true;
    bEnableX = get(handles.enableX,'Value');
    bEnableY = get(handles.enableY,'Value');
    bEnableZ = get(handles.enableZ,'Value');

    if bEnableX + bEnableY + bEnableZ == 0
        errordlg('At least one dimension must be enabled','Input Error');
        bool = false;
    end
end

function bool = validate_all_inputs(handles)
    bool = validate_dwell(handles);
    for dim = 1:3
        bool = bool && validate_points(dim,handles) ...
            && validate_offset(dim,handles) ...
            && validate_min(dim,handles) ...
            && validate_max(dim,handles);
    end
end

% --- Executes during object creation, after setting all properties.
function minX_CreateFcn(hObject, eventdata, handles)
% hObject    handle to minX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function maxX_Callback(hObject, eventdata, handles)
% hObject    handle to maxX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxX as text
%        str2double(get(hObject,'String')) returns contents of maxX as a double

end



% --- Executes during object creation, after setting all properties.
function maxX_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function pointsX_Callback(hObject, eventdata, handles)
% hObject    handle to pointsX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of pointsX as text
%        str2double(get(hObject,'String')) returns contents of pointsX as a double

end



% --- Executes during object creation, after setting all properties.
function pointsX_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pointsX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on button press in enableX.
function enableX_Callback(hObject, eventdata, handles)
% hObject    handle to enableX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of enableX
end


function offsetX_Callback(hObject, eventdata, handles)
% hObject    handle to offsetX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of offsetX as text
%        str2double(get(hObject,'String')) returns contents of offsetX as a double
end


% --- Executes during object creation, after setting all properties.
function offsetX_CreateFcn(hObject, eventdata, handles)
% hObject    handle to offsetX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function minZ_Callback(hObject, eventdata, handles)
% hObject    handle to minZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of minZ as text
%        str2double(get(hObject,'String')) returns contents of minZ as a double
end


% --- Executes during object creation, after setting all properties.
function minZ_CreateFcn(hObject, eventdata, handles)
% hObject    handle to minZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function maxZ_Callback(hObject, eventdata, handles)
% hObject    handle to maxZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxZ as text
%        str2double(get(hObject,'String')) returns contents of maxZ as a double
end

% --- Executes during object creation, after setting all properties.
function maxZ_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function pointsZ_Callback(hObject, eventdata, handles)
% hObject    handle to pointsZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of pointsZ as text
%        str2double(get(hObject,'String')) returns contents of pointsZ as a double
end



% --- Executes during object creation, after setting all properties.
function pointsZ_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pointsZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on button press in enableZ.
function enableZ_Callback(hObject, eventdata, handles)
% hObject    handle to enableZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of enableZ
end


function offsetZ_Callback(hObject, eventdata, handles)
% hObject    handle to offsetZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of offsetZ as text
%        str2double(get(hObject,'String')) returns contents of offsetZ as a double
end


% --- Executes during object creation, after setting all properties.
function offsetZ_CreateFcn(hObject, eventdata, handles)
% hObject    handle to offsetZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function offsetY_Callback(hObject, eventdata, handles)
% hObject    handle to offsetY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of offsetY as text
%        str2double(get(hObject,'String')) returns contents of offsetY as a double
end



% --- Executes during object creation, after setting all properties.
function offsetY_CreateFcn(hObject, eventdata, handles)
% hObject    handle to offsetY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on button press in enableY.
function enableY_Callback(hObject, eventdata, handles)
% hObject    handle to enableY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of enableY
end


function pointsY_Callback(hObject, eventdata, handles)
% hObject    handle to pointsY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of pointsY as text
%        str2double(get(hObject,'String')) returns contents of pointsY as a double
end

% --- Executes during object creation, after setting all properties.
function pointsY_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pointsY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function maxY_Callback(hObject, eventdata, handles)
% hObject    handle to maxY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxY as text
%        str2double(get(hObject,'String')) returns contents of maxY as a double
end

% --- Executes during object creation, after setting all properties.
function maxY_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function minY_Callback(hObject, eventdata, handles)
% hObject    handle to minY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of minY as text
%        str2double(get(hObject,'String')) returns contents of minY as a double
end

% --- Executes during object creation, after setting all properties.
function minY_CreateFcn(hObject, eventdata, handles)
% hObject    handle to minY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function dwell_Callback(hObject, eventdata, handles)
% hObject    handle to dwell (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dwell as text
%        str2double(get(hObject,'String')) returns contents of dwell as a double
end


% --- Executes during object creation, after setting all properties.
function dwell_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dwell (see GCBO)
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
    if validate_all_inputs(handles) == true
        ConfigureScanFunctions('Save',hObject,eventdata,handles);
        handles.output = handles.ConfocalScan;
        % turn zoom-box usage off in order to use the newly saved values
        handles.imageScanHandles.checkUseZoomboxLimits.Value = 0;
        % notify of a state change
        close();
    end
end

% --------------------------------------------------------------------
function menuDefaultScans_Callback(hObject, eventdata, handles)
% hObject    handle to menuDefaultScans (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end

% --------------------------------------------------------------------
function menu2D_Callback(hObject, eventdata, handles)
% hObject    handle to menu2D (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ConfigureScanFunctions('2D',hObject,eventdata,handles);
end

% --------------------------------------------------------------------
function menuZ_Callback(hObject, eventdata, handles)
% hObject    handle to menuZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ConfigureScanFunctions('Z',hObject,eventdata,handles);
end

% --------------------------------------------------------------------
function menuP2DFS_Callback(hObject, eventdata, handles)
% hObject    handle to menuP2DFS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ConfigureScanFunctions('2D Thor Piezo',hObject,eventdata,handles);
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


% --- Executes on button press in checkboxSaveData.
function checkboxSaveData_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxSaveData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxSaveData
end


% --- Executes on button press in buttonCenterScanOnCursor.
function buttonCenterScanOnCursor_Callback(hObject, eventdata, handles)
% hObject    handle to buttonCenterScanOnCursor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ConfigureScanFunctions('CenterScanOnCursor',hObject,eventdata,handles);

end
