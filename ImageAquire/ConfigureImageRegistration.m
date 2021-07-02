function varargout = ConfigureImageRegistration(varargin)
% CONFIGUREIMAGEREGISTRATION MATLAB code for ConfigureImageRegistration.fig
%      CONFIGUREIMAGEREGISTRATION, by itself, creates a new CONFIGUREIMAGEREGISTRATION or raises the existing
%      singleton*.
%
%      H = CONFIGUREIMAGEREGISTRATION returns the handle to a new CONFIGUREIMAGEREGISTRATION or the handle to
%      the existing singleton*.
%
%      CONFIGUREIMAGEREGISTRATION('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CONFIGUREIMAGEREGISTRATION.M with the given input arguments.
%
%      CONFIGUREIMAGEREGISTRATION('Property','Value',...) creates a new CONFIGUREIMAGEREGISTRATION or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ConfigureImageRegistration_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ConfigureImageRegistration_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ConfigureImageRegistration

% Last Modified by GUIDE v2.5 10-Nov-2012 15:22:57

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ConfigureImageRegistration_OpeningFcn, ...
                   'gui_OutputFcn',  @ConfigureImageRegistration_OutputFcn, ...
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

% --- Executes just before ConfigureImageRegistration is made visible.
function ConfigureImageRegistration_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ConfigureImageRegistration (see VARARGIN)

% Choose default command line output for ConfigureImageRegistration
handles.output = hObject;

if nargin > 3,
    % get the first varargin, which is the AFM PL Scan "obj"
    handles.AFMImageScanObj = varargin{1};
else
    handles.AFMImageScanObj = [];
end
ConfigureRegScanFunctions('Initialize',hObject,eventdata,handles);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ConfigureImageRegistration wait for user response (see UIRESUME)
% uiwait(handles.figure1);
end

function [varargout] = ConfigureRegScanFunctions(varargin)
    task = varargin{1};
    hObject = varargin{2};
    eventdata = varargin{3};
    if nargin > 3,
        handles = varargin{4};
    end
    
    switch task,
        case 'Initialize'
            scan = handles.AFMImageScanObj; % shorthand
            
            set(handles.imageSizeReg,'String',num2str(scan.imageRegScanSize));
            set(handles.dwellTimeReg,'String',num2str(scan.imageRegDwellTime));
            set(handles.pointsPerLineReg,'String',num2str(scan.imageRegPointsPerLine));
            set(handles.usfacReg,'String',num2str(scan.imageRegSubPixelFactor));
            set(handles.checkboxNVPLImageReg,'Value',scan.imageRegCheckboxNVPL);
            set(handles.checkboxGreenImageReg,'Value',scan.imageRegCheckboxGreen);
            
            % compute indicators at startup
            inputNum=str2double(get(handles.pointsPerLineReg,'String'));
            inputSize=str2double(get(handles.imageSizeReg,'String'));
            inputPrec=str2double(get(handles.usfacReg,'String'));
            set(handles.indicatorPixelSize,'String',num2str(1000*inputSize/inputNum));
            set(handles.indicatorMaxPrecision,'String',num2str(1000*inputSize/(inputPrec*inputNum)));
            
            varargout{1} = scan;
            
        case 'Save'
            % basically do the reverse of initialize...
            scan = handles.AFMImageScanObj;
            
            scan.imageRegScanSize = str2double(get(handles.imageSizeReg,'String'));
            scan.imageRegDwellTime = str2double(get(handles.dwellTimeReg,'String'));
            scan.imageRegPointsPerLine = str2double(get(handles.pointsPerLineReg,'String'));
            scan.imageRegSubPixelFactor = str2double(get(handles.usfacReg,'String'));
            scan.imageRegCheckboxNVPL = get(handles.checkboxNVPLImageReg,'Value');
            scan.imageRegCheckboxGreen = get(handles.checkboxGreenImageReg,'Value');
            
            guidata(hObject,handles);
    end
end

% --- Outputs from this function are returned to the command line.
function varargout = ConfigureImageRegistration_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end


% --- Executes on button press in buttonSaveRegParameters.
function buttonSaveRegParameters_Callback(hObject, eventdata, handles)
% hObject    handle to buttonSaveRegParameters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ConfigureRegScanFunctions('Save',hObject,eventdata,handles);

close();
end


function imageSizeReg_Callback(hObject, eventdata, handles)
% hObject    handle to imageSizeReg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% don't get a scan size too small or negative, here 100 nm
inputSize=str2double(get(hObject,'String'));
if inputSize < 0.100
    set(hObject,'String',num2str(0.100));
end
inputNum=str2double(get(handles.pointsPerLineReg,'String'));
inputPrec=str2double(get(handles.usfacReg,'String'));
set(handles.indicatorPixelSize,'String',num2str(1000*inputSize/inputNum));
set(handles.indicatorMaxPrecision,'String',num2str(1000*inputSize/(inputPrec*inputNum)));

% Hints: get(hObject,'String') returns contents of imageSizeReg as text
%        str2double(get(hObject,'String')) returns contents of imageSizeReg as a double
end

% --- Executes during object creation, after setting all properties.
function imageSizeReg_CreateFcn(hObject, eventdata, handles)
% hObject    handle to imageSizeReg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function dwellTimeReg_Callback(hObject, eventdata, handles)
% hObject    handle to dwellTimeReg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% don't get a dwell time too small or negative, here 100µs
if str2double(get(hObject,'String')) < 0.0001
    set(hObject,'String',num2str(0.0001));
end

% Hints: get(hObject,'String') returns contents of dwellTimeReg as text
%        str2double(get(hObject,'String')) returns contents of dwellTimeReg as a double
end

% --- Executes during object creation, after setting all properties.
function dwellTimeReg_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dwellTimeReg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function pointsPerLineReg_Callback(hObject, eventdata, handles)
% hObject    handle to pointsPerLineReg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% integer number
set(hObject,'String',num2str(floor(str2double(get(hObject,'String')))));
inputNum=str2double(get(hObject,'String'));
if inputNum <= 1
    set(hObject,'String',num2str(2));
end
inputSize=str2double(get(handles.imageSizeReg,'String'));
inputPrec=str2double(get(handles.usfacReg,'String'));
set(handles.indicatorPixelSize,'String',num2str(1000*inputSize/inputNum));
set(handles.indicatorMaxPrecision,'String',num2str(1000*inputSize/(inputPrec*inputNum)));

% Hints: get(hObject,'String') returns contents of pointsPerLineReg as text
%        str2double(get(hObject,'String')) returns contents of pointsPerLineReg as a double
end

% --- Executes during object creation, after setting all properties.
function pointsPerLineReg_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pointsPerLineReg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function usfacReg_Callback(hObject, eventdata, handles)
% hObject    handle to usfacReg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% integer number no less than 1 (full pixel precision)
set(hObject,'String',num2str(floor(str2double(get(hObject,'String')))));
inputPrec = str2double(get(hObject,'String'));
if  inputPrec < 1
    set(hObject,'String',num2str(1));
end
inputSize=str2double(get(handles.imageSizeReg,'String'));
inputNum=str2double(get(handles.pointsPerLineReg,'String'));
set(handles.indicatorPixelSize,'String',num2str(1000*inputSize/inputNum));
set(handles.indicatorMaxPrecision,'String',num2str(1000*inputSize/(inputPrec*inputNum)));

% Hints: get(hObject,'String') returns contents of usfacReg as text
%        str2double(get(hObject,'String')) returns contents of usfacReg as a double
end

% --- Executes during object creation, after setting all properties.
function usfacReg_CreateFcn(hObject, eventdata, handles)
% hObject    handle to usfacReg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in checkboxNVPLImageReg.
function checkboxNVPLImageReg_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxNVPLImageReg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxNVPLImageReg
end

% --- Executes on button press in checkboxGreenImageReg.
function checkboxGreenImageReg_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxGreenImageReg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxGreenImageReg
end
