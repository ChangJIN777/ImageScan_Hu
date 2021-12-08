function varargout = MagnetPLScan(varargin)
% MAGNETPLSCAN MATLAB code for MagnetPLScan.fig
%      MAGNETPLSCAN, by itself, creates a new MAGNETPLSCAN or raises the existing
%      singleton*.
%
%      H = MAGNETPLSCAN returns the handle to a new MAGNETPLSCAN or the handle to
%      the existing singleton*.
%
%      MagnetPLScan('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MagnetPLScan.M with the given input arguments.
%
%      MagnetPLScan('Property','Value',...) creates a new MagnetPLScan or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before MagnetPLScan_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to MagnetPLScan_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help MagnetPLScan

% Last Modified by GUIDE v2.5 12-Feb-2015 16:26:47

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @MagnetPLScan_OpeningFcn, ...
                   'gui_OutputFcn',  @MagnetPLScan_OutputFcn, ...
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


% --- Executes just before MagnetPLScan is made visible.
function MagnetPLScan_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to MagnetPLScan (see VARARGIN)

% Choose default command line output for MagnetPLScan
handles.output = hObject;
handles.ImageScanhandles = varargin{1};

handles.MagnetCursor=MagnetCursor;
handles.MagnetScanningTools=MagnetScanningTools(handles.ImageScanhandles);

% Setup Colormap
    magcolorm.cmap = jet(64);
    %set(handles.MagnetPLScan, 'Colormap',colorm.cmap);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    magcolorm.cax = caxis(handles.axesMagnet);
    magcolorm.auto = true;
    caxis auto
    set(handles.axesMagnet, 'UserData', magcolorm);
    set(handles.axesMagnet, 'YDir','normal');
    colorbar('peer', handles.axesMagnet);

% Initialize handle to track scan state
% 0 OFF; 1 BUSY
global state
state = 0;

% Initialize global variable for scanning
global scanning 
scanning = 0;

% Initialize Scan Properties
handles.points = 50; %number of points per dimension
set(handles.editScanPoints,'String',handles.points);
handles.range = 4; %range of scan is twice this number
set(handles.editScanRange,'String',handles.range);
handles.scanmode = 1; %Mode 1: XY; Mode2: XZ; Mode3: XYZ (implemented later)
%Set appropriate scanmode
    if handles.scanmode==1
    set(handles.radiobuttonScanTypeXY,'Value',1);
    elseif handles.scanmode==2
    set(handles.radiobuttonScanTypeXZ,'Value',1);
    elseif handles.scanmode==3
    set(handles.radiobuttonScanType3D,'Value',1);
    else error('Unidentified ScanMode')
    end
    
% Open ActiveX controls for the Thorlabs stages
handles.APThandleX=ConnectToAPT(83854799);
handles.APThandleY=ConnectToAPT(83852593);
handles.APThandleZ=ConnectToAPT(83854797);

% Set Thorlabs to desired velocity and acceleration
%the DC servo motors can only attain a max velocity of 2.3 mm/s before
% distortion of the movement profile comes into effect
% The max acceleration is 4 mm/s^2. 50 um is min acheivable increment
% so do not attempt to step by amounts less than 50 um. for example, for a
% 2mm range, 40 points.
% velocity stability is +/- 0.125 mm/s.
handles.APThandleX.SetJogVelParams(0,0,3,2.3); 
handles.APThandleX.SetVelParams(0,0,3,2.3);
handles.APThandleY.SetJogVelParams(0,0,3,2.3);
handles.APThandleY.SetVelParams(0,0,3,2.3);
handles.APThandleZ.SetJogVelParams(0,0,3,2.3);
handles.APThandleZ.SetVelParams(0,0,3,2.3);

% Get Thorlabs position
handles.scancenter = [0 0 0]; % Allocate
handles.scancenter(1) = handles.APThandleX.GetPosition_Position(0);
handles.scancenter(2) = handles.APThandleY.GetPosition_Position(0);
handles.scancenter(3) = handles.APThandleZ.GetPosition_Position(0);
% Set ScanCenter in GUI based on thorlabs position
set(handles.editScanCenterX,'String',handles.scancenter(1));
set(handles.editScanCenterY,'String',handles.scancenter(2));
set(handles.editScanCenterZ,'String',handles.scancenter(3));
    
% Pass scanrange to main plot (text box and axes)
xlim(handles.axesMagnet,[-1*handles.range+handles.scancenter(1),handles.range+handles.scancenter(1)]);
ylim(handles.axesMagnet,[-1*handles.range+handles.scancenter(2),handles.range+handles.scancenter(2)]);
xlabel(handles.axesMagnet,'X (mm)')
ylabel(handles.axesMagnet,'Y (mm)')

% Initialize Cursor at present thorlabs position
handles.magcurspos = handles.scancenter;
set(handles.editCursorX,'String',handles.magcurspos(1));
set(handles.editCursorY,'String',handles.magcurspos(2));
set(handles.editCursorZ,'String',handles.magcurspos(3));
% Draw Cursor
handles.MagnetCursor.drawCursor(handles)

% Initizlize Scan Bounds
handles.scanbounds(1) = str2double(get(handles.editScanBoundsX,'String'));
handles.scanbounds(2) = str2double(get(handles.editScanBoundsY,'String'));
handles.scanbounds(3) = str2double(get(handles.editScanBoundsZ,'String'));

% Initialize Tracking parameters
handles.tracknum = str2double(get(handles.editTrackNum,'String'));
handles.tracken = get(handles.checkboxTrackEn,'Value');
handles.dwelltime = str2double(get(handles.editDwellTime,'String'))/1000;

% Set Timeout
handles.timeout=10; %Note: 15 seconds is slightly longer than Max travel with vel=2 mm/s

% Get Date

    mydate = date; %returns dd-mmm-yyyy
    myyear = mydate(8:end); % returns yyyy
    mymonth= mydate(4:6); % returns mm
    myday = mydate(1:2); % returns dd
    myFormattedDate = [myyear '_' mymonth '_' myday '\'];

% Pass date to save info
    set(handles.editFilePath,'String',['C:\Users\lab\Documents\Data\'...
        myFormattedDate]);

disp('To ensure proper operation, the actuators should be homed before opening this program.')
    
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes MagnetPLScan wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = MagnetPLScan_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbuttonStartStop.
function pushbuttonStartStop_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonStartStop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global state
global scanning

    if state == 0
        % setup axes on main plot
            handles.MagnetCursor.deleteCursor(handles)
            if handles.scanmode == 1
                xlabel(handles.axesMagnet,'X (mm)')
                ylabel(handles.axesMagnet,'Y (mm)')
                xlim(handles.axesMagnet,[-1*handles.range+handles.scancenter(1),handles.range+handles.scancenter(1)]);
                ylim(handles.axesMagnet,[-1*handles.range+handles.scancenter(2),handles.range+handles.scancenter(2)]);
            elseif handles.scanmode == 2
                xlabel(handles.axesMagnet,'X (mm)')
                ylabel(handles.axesMagnet,'Z (mm)')
                xlim(handles.axesMagnet,[-1*handles.range+handles.scancenter(1),handles.range+handles.scancenter(1)]);
                ylim(handles.axesMagnet,[-1*handles.range+handles.scancenter(3),handles.range+handles.scancenter(3)]);
            elseif handles.scanmode == 3
                % XXX
                disp('XYZ scanning not yet implemented')
            end
        % flip state
            state = 1;
            set(hObject,'String','Stop Scan')
            set(hObject,'ForegroundColor','r')
        % start scan
            handles.MagnetScanningTools.MagnetScanFnct(handles)
        % flip state
            set(hObject,'String','Start Scan')
            set(hObject,'ForegroundColor','b')
    elseif scanning == 1
        % stop scan
            scanning = 0;
            state = 1;
            pause(1)
        % return to ScanCenter
            handles.APThandleX.SetAbsMovePos(0,handles.scancenter(1));
            handles.APThandleY.SetAbsMovePos(0,handles.scancenter(2));
            handles.APThandleZ.SetAbsMovePos(0,handles.scancenter(3));
            handles.APThandleX.MoveAbsolute(0,1==0);
            handles.APThandleY.MoveAbsolute(0,1==0);
            handles.APThandleZ.MoveAbsolute(0,1==0);
        % wait for movement
            CheckMoving(handles);
        % flip state
            state = 0;
            set(hObject,'String','Start Scan')
            set(hObject,'ForegroundColor','b')
    end
if scanning == 0 && state==0
    set(hObject,'String','Start Scan')
    set(hObject,'ForegroundColor','b')
    handles.MagnetCursor.drawCursor(handles)
end
    
guidata(hObject, handles);



function editScanCenterX_Callback(hObject, eventdata, handles)
% hObject    handle to editScanCenterX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editScanCenterX as text
%        str2double(get(hObject,'String')) returns contents of editScanCenterX as a double
val1=str2double(get(hObject,'String'));
% enforce bounds
if val1 < 0
    val1 = 0;
elseif val1 > handles.scanbounds(1)
    val1 = handles.scanbounds(1);
end
set(hObject,'String',val1);
handles.scancenter(1)=val1;
guidata(hObject, handles); %Updates handles structure


% --- Executes during object creation, after setting all properties.
function editScanCenterX_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editScanCenterX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editScanCenterY_Callback(hObject, eventdata, handles)
% hObject    handle to editScanCenterY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editScanCenterY as text
%        str2double(get(hObject,'String')) returns contents of editScanCenterY as a double
val1=str2double(get(hObject,'String'));
% enforce bounds
if val1 < 0
    val1 = 0;
elseif val1 > handles.scanbounds(2)
    val1 = handles.scanbounds(2);
end
set(hObject,'String',val1);
handles.scancenter(2)=val1;
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function editScanCenterY_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editScanCenterY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editScanCenterZ_Callback(hObject, eventdata, handles)
% hObject    handle to editScanCenterZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editScanCenterZ as text
%        str2double(get(hObject,'String')) returns contents of editScanCenterZ as a double
val1=str2double(get(hObject,'String'));
% enforce bounds
if val1 < 0
    val1 = 0;
elseif val1 > handles.scanbounds(3)
    val1 = handles.scanbounds(3);
end
set(hObject,'String',val1);
handles.scancenter(3)=val1;
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function editScanCenterZ_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editScanCenterZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonCursorToScanCenter.
function pushbuttonCursorToScanCenter_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonCursorToScanCenter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Sets cursor position as scan center upon buttonpress
set(handles.editScanCenterX,'String',handles.magcurspos(1));
set(handles.editScanCenterY,'String',handles.magcurspos(2));
set(handles.editScanCenterZ,'String',handles.magcurspos(3));
handles.scancenter = [handles.magcurspos(1) handles.magcurspos(2) handles.magcurspos(3)];
guidata(hObject, handles);



function editScanRange_Callback(hObject, eventdata, handles)
% hObject    handle to editScanRange (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editScanRange as text
%        str2double(get(hObject,'String')) returns contents of editScanRange as a double
val1=str2double(get(hObject,'String'));
% enforce bounds
if val1 < 0.25
    val1 = 0.25;
elseif val1 > 12
    val1 = 12;
end
set(hObject,'String',val1);
handles.range=val1;
guidata(hObject, handles);



% --- Executes during object creation, after setting all properties.
function editScanRange_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editScanRange (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editScanPoints_Callback(hObject, eventdata, handles)
% hObject    handle to editScanPoints (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editScanPoints as text
%        str2double(get(hObject,'String')) returns contents of editScanPoints as a double

val1=str2double(get(hObject,'String'));
val1 = round(val1);
% enforce bounds
if val1 < 5
    val1 = 5;
elseif val1 > 200
    val1 = 200;
end
set(hObject,'String',val1);
handles.points=val1;
guidata(hObject, handles);



% --- Executes during object creation, after setting all properties.
function editScanPoints_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editScanPoints (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editCursorX_Callback(hObject, eventdata, handles)
% hObject    handle to editCursorX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editCursorX as text
%        str2double(get(hObject,'String')) returns contents of editCursorX as a double
val1=str2double(get(hObject,'String'));
% enforce bounds
if val1 < 0
    val1 = 0;
elseif val1 > handles.scanbounds(1)
    val1 = handles.scanbounds(1);
end
set(hObject,'String',val1);
handles.magcurspos(1)=val1;
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function editCursorX_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editCursorX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editCursorY_Callback(hObject, eventdata, handles)
% hObject    handle to editCursorY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editCursorY as text
%        str2double(get(hObject,'String')) returns contents of editCursorY as a double
val1=str2double(get(hObject,'String'));
% enforce bounds
if val1 < 0
    val1 = 0;
elseif val1 > handles.scanbounds(2)
    val1 = handles.scanbounds(2);
end
set(hObject,'String',val1);
handles.magcurspos(2)=val1;
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function editCursorY_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editCursorY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editCursorZ_Callback(hObject, eventdata, handles)
% hObject    handle to editCursorZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editCursorZ as text
%        str2double(get(hObject,'String')) returns contents of editCursorZ as a double
val1=str2double(get(hObject,'String'));
% enforce bounds
if val1 < 0
    val1 = 0;
elseif val1 > handles.scanbounds(3)
    val1 = handles.scanbounds(3);
end
set(hObject,'String',val1);
handles.magcurspos(3)=val1;
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function editCursorZ_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editCursorZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonAdjustCursor.
function pushbuttonAdjustCursor_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonAdjustCursor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% call cursor updating function
handles.MagnetCursor.updateCursor(handles)

% update handles structure with new data
    val1=str2double(get(handles.editCursorX,'String'));
    val2=str2double(get(handles.editCursorY,'String'));
    val3=str2double(get(handles.editCursorZ,'String'));
    handles.magcurspos(1)=val1;
    handles.magcurspos(2)=val2;
    handles.magcurspos(3)=val3;

% update handles structure an extra time so drawCursor can get magcurspos
guidata(hObject, handles);
    
% draw cursor
handles.MagnetCursor.drawCursor(handles)

guidata(hObject, handles); %update handles structure


% --- Executes on button press in pushbuttonMoveToCursor.
function pushbuttonMoveToCursor_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonMoveToCursor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Check that cursor is in range and it is not busy
global state
if handles.magcurspos(1)<=handles.scanbounds(1)&&handles.magcurspos(1)>=0&&...
        handles.magcurspos(2)<=handles.scanbounds(2)&&handles.magcurspos(2)>=0&&...
        handles.magcurspos(3)<=handles.scanbounds(3)&&handles.magcurspos(3)>=0&&...
        state == 0
    % Switch to busy state
    state = 1;
    % Move
    handles.APThandleX.SetAbsMovePos(0,handles.magcurspos(1));
    handles.APThandleX.MoveAbsolute(0,1==0);
    handles.APThandleY.SetAbsMovePos(0,handles.magcurspos(2));
    handles.APThandleY.MoveAbsolute(0,1==0);
    handles.APThandleZ.SetAbsMovePos(0,handles.magcurspos(3));
    handles.APThandleZ.MoveAbsolute(0,1==0);
    % Wait until move is finished
    CheckMoving(handles);
    % Switch to not busy state
    disp('Move Completed')
    state = 0;
elseif state
    disp('Error: Busy')
else
    disp('Error: Cursor out of Range')
end

% --- Executes on button press in editFilePath.
function editFilePath_Callback(hObject, eventdata, handles)
% hObject    handle to editFilePath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function editFilePath_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editFilePath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called



function editAutosaveString_Callback(hObject, eventdata, handles)
% hObject    handle to editAutosaveString (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editAutosaveString as text
%        str2double(get(hObject,'String')) returns contents of editAutosaveString as a double


% --- Executes during object creation, after setting all properties.
function editAutosaveString_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editAutosaveString (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editAutosaveNumber_Callback(hObject, eventdata, handles)
% hObject    handle to editAutosaveNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editAutosaveNumber as text
%        str2double(get(hObject,'String')) returns contents of editAutosaveNumber as a double


% --- Executes during object creation, after setting all properties.
function editAutosaveNumber_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editAutosaveNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function axesMagnet_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axesMagnet (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axesMagnet


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over editScanRange.
function editScanRange_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to editScanRange (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% Callback for changing the ScanMode radio button
% --- Executes when selected object is changed in uipanel5.
function uipanel5_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel5 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

% Get the name of which value was selected
val1=get(eventdata.NewValue,'Tag');
% Change scanmode to proper value
if strcmp(val1,'radiobuttonScanTypeXY')
    handles.scanmode = 1;
elseif strcmp(val1,'radiobuttonScanTypeXZ')
    handles.scanmode = 2;
elseif strcmp(val1,'radiobuttonScanType3D')
    handles.scanmode = 3;
else
    error('Invalid Scan Mode')
end

% delete cursor
handles.MagnetCursor.deleteCursor(handles)

% reset the scan axes to the right orientation/range
if handles.scanmode == 1
    xlabel(handles.axesMagnet,'X (mm)')
    ylabel(handles.axesMagnet,'Y (mm)')
    xlim(handles.axesMagnet,[-1*handles.range+handles.scancenter(1),handles.range+handles.scancenter(1)]);
    ylim(handles.axesMagnet,[-1*handles.range+handles.scancenter(2),handles.range+handles.scancenter(2)]);
elseif handles.scanmode == 2
    xlabel(handles.axesMagnet,'X (mm)')
    ylabel(handles.axesMagnet,'Z (mm)')
    xlim(handles.axesMagnet,[-1*handles.range+handles.scancenter(1),handles.range+handles.scancenter(1)]);
    ylim(handles.axesMagnet,[-1*handles.range+handles.scancenter(3),handles.range+handles.scancenter(3)]);
elseif handles.scanmode == 3
    % XXX
    disp('XYZ scanning not yet implemented')
end

% draw cursor
handles.MagnetCursor.drawCursor(handles)

guidata(hObject, handles);


% --- Executes on button press in checkboxTrackEn.
function checkboxTrackEn_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxTrackEn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxTrackEn
handles.tracken = get(handles.checkboxTrackEn,'Value');
guidata(hObject, handles);


function editTrackNum_Callback(hObject, eventdata, handles)
% hObject    handle to editTrackNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editTrackNum as text
%        str2double(get(hObject,'String')) returns contents of editTrackNum as a double
val1 = str2double(get(handles.editTrackNum,'String'));
val1 = round(val1);
% enforce bounds
if val1 < 3
    val1 = 3;
    set(hObject,'String',val1);
elseif val1 > 200
    val1 = 200;
    set(hObject,'String',val1);
end
handles.tracknum = val1;
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function editTrackNum_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editTrackNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editDwellTime_Callback(hObject, eventdata, handles)
% hObject    handle to editDwellTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editDwellTime as text
%        str2double(get(hObject,'String')) returns contents of editDwellTime as a double
val1 = str2double(get(hObject,'String'));
val1 = round(val1);
% enforce bounds
if val1 < 10
    val1 = 10;
    set(hObject,'String',val1);
elseif val1 > 3000
    val1 = 3000;
    set(hObject,'String',val1);
end
handles.dwelltime = val1/1000;
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function editDwellTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editDwellTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editScanBoundsX_Callback(hObject, eventdata, handles)
% hObject    handle to editScanBoundsX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editScanBoundsX as text
%        str2double(get(hObject,'String')) returns contents of editScanBoundsX as a double
val1 = str2double(get(hObject,'String'));
if val1>0&&val1<=25
    handles.scanbounds(1) = val1;
else
    set(hObject,'String',handles.scanbounds(1));
end
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function editScanBoundsX_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editScanBoundsX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editScanBoundsY_Callback(hObject, eventdata, handles)
% hObject    handle to editScanBoundsY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editScanBoundsY as text
%        str2double(get(hObject,'String')) returns contents of editScanBoundsY as a double
val1 = str2double(get(hObject,'String'));
if val1>0&&val1<=25
    handles.scanbounds(2) = val1;
else
    set(hObject,'String',handles.scanbounds(2));
end
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function editScanBoundsY_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editScanBoundsY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editScanBoundsZ_Callback(hObject, eventdata, handles)
% hObject    handle to editScanBoundsZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editScanBoundsZ as text
%        str2double(get(hObject,'String')) returns contents of editScanBoundsZ as a double
val1 = str2double(get(hObject,'String'));
if val1>0&&val1<=12
    handles.scanbounds(3) = val1;
else
    set(hObject,'String',handles.scanbounds(3));
end
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function editScanBoundsZ_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editScanBoundsZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox_doPulseSequence.
function checkbox_doPulseSequence_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_doPulseSequence (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_doPulseSequence


guidata(hObject, handles);



function editPulseReps_Callback(hObject, eventdata, handles)
% hObject    handle to editPulseReps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPulseReps as text
%        str2double(get(hObject,'String')) returns contents of editPulseReps as a double
input=str2double(get(hObject,'String'));
input = floor(input); % round 
if input<10
    input=10;
end
set(hObject,'String',num2str(input));
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function editPulseReps_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPulseReps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in radio_plotChannel1.
function radio_plotChannel1_Callback(hObject, eventdata, handles)
% hObject    handle to radio_plotChannel1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radio_plotChannel1
guidata(hObject, handles);

% --- Executes on button press in radio_plotChannel2.
function radio_plotChannel2_Callback(hObject, eventdata, handles)
% hObject    handle to radio_plotChannel2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radio_plotChannel2
guidata(hObject, handles);

% Callback for changing the Channel radio button
% --- Executes when selected object is changed in uipanel5.
function uipanel8_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel5 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
% Get the name of which value was selected
guidata(hObject, handles);