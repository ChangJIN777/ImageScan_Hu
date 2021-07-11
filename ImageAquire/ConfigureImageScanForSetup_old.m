function varargout = ConfigureImageScanForSetup(varargin)
% CONFIGUREIMAGESCANFORSETUP MATLAB code for ConfigureImageScanForSetup.fig
%      CONFIGUREIMAGESCANFORSETUP, by itself, creates a new CONFIGUREIMAGESCANFORSETUP or raises the existing
%      singleton*.
%
%      H = CONFIGUREIMAGESCANFORSETUP returns the handle to a new CONFIGUREIMAGESCANFORSETUP or the handle to
%      the existing singleton*.
%
%      CONFIGUREIMAGESCANFORSETUP('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CONFIGUREIMAGESCANFORSETUP.M with the given input arguments.
%
%      CONFIGUREIMAGESCANFORSETUP('Property','Value',...) creates a new CONFIGUREIMAGESCANFORSETUP or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ConfigureImageScanForSetup_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ConfigureImageScanForSetup_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ConfigureImageScanForSetup

% Last Modified by GUIDE v2.5 31-Oct-2014 10:21:10

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ConfigureImageScanForSetup_OpeningFcn, ...
                   'gui_OutputFcn',  @ConfigureImageScanForSetup_OutputFcn, ...
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


% --- Executes just before ConfigureImageScanForSetup is made visible.
function ConfigureImageScanForSetup_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ConfigureImageScanForSetup (see VARARGIN)

% Choose default command line output for ConfigureImageScanForSetup
handles.output = hObject;

handles.configurationFile = 'C:\Users\lab\Documents\MATLAB\ImageScan\ImageAquire\ConfigurationImageScan.txt';

% structure
if exist(handles.configurationFile, 'file') == 2
    
    handles.configS = tdfread(handles.configurationFile);

    set(handles.bHaveInverterBoard,'Value',handles.configS.bHaveInverterBoard);
    set(handles.bHaveNanoscopeAFM,'Value',handles.configS.bHaveNanoscopeAFM);
    set(handles.numUSBFilterWheels,'String',handles.configS.numUSBFilterWheels);
    set(handles.bHaveZurichInstr,'Value',handles.configS.bHaveZurichInstr);
    set(handles.bHaveMCLXYZScanner,'Value',handles.configS.bHaveMCLXYZScanner);
    set(handles.dataFolder,'String',handles.configS.dataFolder);
    set(handles.sequenceFolder,'String',handles.configS.sequenceFolder);
    set(handles.bMagnetGui,'Value',handles.configS.bMagnetGui);
    set(handles.xScanMicronsPerVolt,'String',handles.configS.xScanMicronsPerVolt);
    set(handles.yScanMicronsPerVolt,'String',handles.configS.yScanMicronsPerVolt);
    set(handles.zScanMicronsPerVolt,'String',handles.configS.zScanMicronsPerVolt);
    set(handles.xMinVolts,'String',handles.configS.xMinVolts);
    set(handles.xMaxVolts,'String',handles.configS.xMaxVolts);
    set(handles.yMinVolts,'String',handles.configS.yMinVolts);
    set(handles.yMaxVolts,'String',handles.configS.yMaxVolts);
    set(handles.zMinVolts,'String',handles.configS.zMinVolts);
    set(handles.zMaxVolts,'String',handles.configS.zMaxVolts);
    set(handles.bHaveMicronixSerial,'Value',handles.configS.bHaveMicronixSerial);
    handles.imageScanBGColorR=num2str(handles.configS.imageScanBGColorR);
    handles.imageScanBGColorG=num2str(handles.configS.imageScanBGColorG);
    handles.imageScanBGColorB=num2str(handles.configS.imageScanBGColorB);
    
    R = handles.imageScanBGColorR;
    G = handles.imageScanBGColorG;
    B = handles.imageScanBGColorB;
    if strcmp([R G B],'228240230')==1
        set(handles.radiobutton1,'Value',1);
    end
    if strcmp([R G B],'205224247')==1
        set(handles.radiobutton2,'Value',1);
    end
    if strcmp([R G B],'231231231')==1
        set(handles.radiobutton3,'Value',1);
    end
    if strcmp([R G B],'252201150')==1
        set(handles.radiobutton4,'Value',1);
    end
    if strcmp([R G B],'190158190')==1
        set(handles.radiobutton5,'Value',1);
    end
    if strcmp([R G B],'239221221')==1
        set(handles.radiobutton6,'Value',1);
    end
    if strcmp([R G B],'205205176')==1
        set(handles.radiobutton7,'Value',1);
    end
    if strcmp([R G B],'191235235')==1
        set(handles.radiobutton8,'Value',1);
    end
    if strcmp([R G B],'255255255')==1
        set(handles.radiobutton9,'Value',1);
    end

else
    handles.imageScanBGColorR = '231';
    handles.imageScanBGColorG = '231';
    handles.imageScanBGColorB = '231';
    % the configuration file doesn't exist yet so just fill out the GUI
    % 'form' and save to create one.
    handles.configS.bHaveInverterBoard = get(handles.bHaveInverterBoard,'Value');
    handles.configS.bHaveNanoscopeAFM = get(handles.bHaveNanoscopeAFM,'Value');
    handles.configS.numUSBFilterWheels = str2double(get(handles.numUSBFilterWheels,'String'));
    handles.configS.bHaveZurichInstr = get(handles.bHaveZurichInstr,'Value');
    handles.configS.bHaveMCLXYZScanner = get(handles.bHaveMCLXYZScanner,'Value');
    handles.configS.dataFolder = get(handles.dataFolder,'String');
    handles.configS.sequenceFolder = get(handles.sequenceFolder,'String');
    handles.configS.bMagnetGui = get(handles.bMagnetGui,'Value');
    handles.configS.xScanMicronsPerVolt = str2double(get(handles.xScanMicronsPerVolt,'String'));
    handles.configS.yScanMicronsPerVolt = str2double(get(handles.yScanMicronsPerVolt,'String'));
    handles.configS.zScanMicronsPerVolt = str2double(get(handles.zScanMicronsPerVolt,'String'));
    handles.configS.xMinVolts = str2double(get(handles.xMinVolts,'String'));
    handles.configS.xMaxVolts = str2double(get(handles.xMaxVolts,'String'));
    handles.configS.yMinVolts = str2double(get(handles.yMinVolts,'String'));
    handles.configS.yMaxVolts = str2double(get(handles.yMaxVolts,'String'));
    handles.configS.zMinVolts = str2double(get(handles.zMinVolts,'String'));
    handles.configS.zMaxVolts = str2double(get(handles.zMaxVolts,'String'));
    handles.configS.imageScanBGColorR = str2double(handles.imageScanBGColorR);
    handles.configS.imageScanBGColorG = str2double(handles.imageScanBGColorG);
    handles.configS.imageScanBGColorB = str2double(handles.imageScanBGColorB);
    set(handles.radiobutton3,'Value',1);
    handles.configS.bHaveMicronixSerial = get(handles.bHaveMicronixSerial,'Value');
end

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ConfigureImageScanForSetup wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = ConfigureImageScanForSetup_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function numUSBFilterWheels_Callback(hObject, eventdata, handles)
% hObject    handle to numUSBFilterWheels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numUSBFilterWheels as text
%        str2double(get(hObject,'String')) returns contents of numUSBFilterWheels as a double


% --- Executes during object creation, after setting all properties.
function numUSBFilterWheels_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numUSBFilterWheels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function dataFolder_Callback(hObject, eventdata, handles)
% hObject    handle to dataFolder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dataFolder as text
%        str2double(get(hObject,'String')) returns contents of dataFolder as a double


% --- Executes during object creation, after setting all properties.
function dataFolder_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dataFolder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function sequenceFolder_Callback(hObject, eventdata, handles)
% hObject    handle to sequenceFolder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of sequenceFolder as text
%        str2double(get(hObject,'String')) returns contents of sequenceFolder as a double


% --- Executes during object creation, after setting all properties.
function sequenceFolder_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sequenceFolder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function xScanMicronsPerVolt_Callback(hObject, eventdata, handles)
% hObject    handle to xScanMicronsPerVolt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of xScanMicronsPerVolt as text
%        str2double(get(hObject,'String')) returns contents of xScanMicronsPerVolt as a double


% --- Executes during object creation, after setting all properties.
function xScanMicronsPerVolt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to xScanMicronsPerVolt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function yScanMicronsPerVolt_Callback(hObject, eventdata, handles)
% hObject    handle to yScanMicronsPerVolt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of yScanMicronsPerVolt as text
%        str2double(get(hObject,'String')) returns contents of yScanMicronsPerVolt as a double


% --- Executes during object creation, after setting all properties.
function yScanMicronsPerVolt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to yScanMicronsPerVolt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function xMinVolts_Callback(hObject, eventdata, handles)
% hObject    handle to xMinVolts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of xMinVolts as text
%        str2double(get(hObject,'String')) returns contents of xMinVolts as a double


% --- Executes during object creation, after setting all properties.
function xMinVolts_CreateFcn(hObject, eventdata, handles)
% hObject    handle to xMinVolts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function xMaxVolts_Callback(hObject, eventdata, handles)
% hObject    handle to xMaxVolts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of xMaxVolts as text
%        str2double(get(hObject,'String')) returns contents of xMaxVolts as a double


% --- Executes during object creation, after setting all properties.
function xMaxVolts_CreateFcn(hObject, eventdata, handles)
% hObject    handle to xMaxVolts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit9_Callback(hObject, eventdata, handles)
% hObject    handle to edit9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit9 as text
%        str2double(get(hObject,'String')) returns contents of edit9 as a double


% --- Executes during object creation, after setting all properties.
function edit9_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit10_Callback(hObject, eventdata, handles)
% hObject    handle to edit10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit10 as text
%        str2double(get(hObject,'String')) returns contents of edit10 as a double


% --- Executes during object creation, after setting all properties.
function edit10_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function yMaxVolts_Callback(hObject, eventdata, handles)
% hObject    handle to yMaxVolts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of yMaxVolts as text
%        str2double(get(hObject,'String')) returns contents of yMaxVolts as a double


% --- Executes during object creation, after setting all properties.
function yMaxVolts_CreateFcn(hObject, eventdata, handles)
% hObject    handle to yMaxVolts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function yMinVolts_Callback(hObject, eventdata, handles)
% hObject    handle to yMinVolts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of yMinVolts as text
%        str2double(get(hObject,'String')) returns contents of yMinVolts as a double


% --- Executes during object creation, after setting all properties.
function yMinVolts_CreateFcn(hObject, eventdata, handles)
% hObject    handle to yMinVolts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function zScanMicronsPerVolt_Callback(hObject, eventdata, handles)
% hObject    handle to zScanMicronsPerVolt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of zScanMicronsPerVolt as text
%        str2double(get(hObject,'String')) returns contents of zScanMicronsPerVolt as a double


% --- Executes during object creation, after setting all properties.
function zScanMicronsPerVolt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to zScanMicronsPerVolt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in buttonSaveConfig.
function buttonSaveConfig_Callback(hObject, eventdata, handles)
% hObject    handle to buttonSaveConfig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    handles.configS.bHaveInverterBoard = get(handles.bHaveInverterBoard,'Value');
    handles.configS.bHaveNanoscopeAFM = get(handles.bHaveNanoscopeAFM,'Value');
    handles.configS.numUSBFilterWheels = str2double(get(handles.numUSBFilterWheels,'String'));
    handles.configS.bHaveZurichInstr = get(handles.bHaveZurichInstr,'Value');
    handles.configS.bHaveMCLXYZScanner = get(handles.bHaveMCLXYZScanner,'Value');
    handles.configS.dataFolder = get(handles.dataFolder,'String');
    handles.configS.sequenceFolder = get(handles.sequenceFolder,'String');
    handles.configS.bMagnetGui = get(handles.bMagnetGui,'Value');
    handles.configS.xScanMicronsPerVolt = str2double(get(handles.xScanMicronsPerVolt,'String'));
    handles.configS.yScanMicronsPerVolt = str2double(get(handles.yScanMicronsPerVolt,'String'));
    handles.configS.zScanMicronsPerVolt = str2double(get(handles.zScanMicronsPerVolt,'String'));
    handles.configS.xMinVolts = str2double(get(handles.xMinVolts,'String'));
    handles.configS.xMaxVolts = str2double(get(handles.xMaxVolts,'String'));
    handles.configS.yMinVolts = str2double(get(handles.yMinVolts,'String'));
    handles.configS.yMaxVolts = str2double(get(handles.yMaxVolts,'String'));
    handles.configS.zMinVolts = str2double(get(handles.zMinVolts,'String'));
    handles.configS.zMaxVolts = str2double(get(handles.zMaxVolts,'String'));
    handles.configS.imageScanBGColorR = str2double(handles.imageScanBGColorR);
    handles.configS.imageScanBGColorG = str2double(handles.imageScanBGColorG);
    handles.configS.imageScanBGColorB = str2double(handles.imageScanBGColorB);
    handles.configS.bHaveMicronixSerial = get(handles.bHaveMicronixSerial,'Value');

tdfwrite(handles.configurationFile,handles.configS);
close();


function zMinVolts_Callback(hObject, eventdata, handles)
% hObject    handle to zMinVolts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of zMinVolts as text
%        str2double(get(hObject,'String')) returns contents of zMinVolts as a double


% --- Executes during object creation, after setting all properties.
function zMinVolts_CreateFcn(hObject, eventdata, handles)
% hObject    handle to zMinVolts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function zMaxVolts_Callback(hObject, eventdata, handles)
% hObject    handle to zMaxVolts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of zMaxVolts as text
%        str2double(get(hObject,'String')) returns contents of zMaxVolts as a double


% --- Executes during object creation, after setting all properties.
function zMaxVolts_CreateFcn(hObject, eventdata, handles)
% hObject    handle to zMaxVolts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in bMagnetGui.
function bMagnetGui_Callback(hObject, eventdata, handles)
% hObject    handle to bMagnetGui (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of bMagnetGui

function tdfwrite(filename,st)
%
% function tdfwrite(filename,st)
%
% Saves structure st into filename
% st is a structure created with st=tdfread('file.tab');
%
% st is a structure with several fields.  Each field is a vector of numbers
% or a matrix of char. Field names are used as headers of each column.
%
% Warning: General format %.20g is used for numerical values. It works fine most
% of the time. Some applications may need to change the output format.
%
% Rafael Palacios, Oct 2009
%

%%Error checking
error(nargchk(2, 2, nargin));  %2 arguments required, 2 maximum
if (~ischar(filename))
    error('First argument must be the name of the file');
end
if (~isstruct(st))
    error('Second argument must be a strcuture');
end
%Field names
names=fieldnames(st);
rows=size(getfield(st,names{1}),1);
for j=2:length(names)
    if (rows~=size(getfield(st,names{j}),1))
        error('Field $s has a different length than first field (%s)',names{j},names{1});
    end
end


[fp,message]=fopen(filename,'w');
if (fp==-1)
    error('Error opening file: %s',message);
end
%header
fprintf(fp,'%s',names{1});
fprintf(fp,'\t%s',names{2:end});
fprintf(fp,'\n');
%values
for i=1:rows
    for j=1:length(names)
        if (j~=1)
            fprintf(fp,'\t');
        end
        v=getfield(st,names{j});
        if (ischar(v(1,1)))
            fprintf(fp,'%s',v(i,:));
        else
            fprintf(fp,'%.20g',v(i));  %general format
        end
    end
    fprintf(fp,'\n');
end
fclose(fp);


% --- Executes when selected object is changed in panelColor.
function panelColor_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in panelColor 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
switch(eventdata.NewValue)
    case handles.radiobutton1
        RGB='228240230';
    case handles.radiobutton2
        RGB='205224247';
    case handles.radiobutton3
        RGB='231231231';
    case handles.radiobutton4
        RGB='252201150';
    case handles.radiobutton5
        RGB='190158190';
    case handles.radiobutton6
        RGB='239221221';
    case handles.radiobutton7
        RGB='205205176';
    case handles.radiobutton8
        RGB='191235235';
    case handles.radiobutton9
        RGB='255255255';
end
handles.imageScanBGColorR = RGB(1:3);
handles.imageScanBGColorG = RGB(4:6);
handles.imageScanBGColorB = RGB(7:9);
% Update handles structure
% important, otherwise the new color won't be saved
guidata(hObject, handles);


% --- Executes on button press in buttonOpenDefaultScans.
function buttonOpenDefaultScans_Callback(hObject, eventdata, handles)
% hObject    handle to buttonOpenDefaultScans (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
open('DefaultScans.m');


% --- Executes on button press in bHaveMicronixSerial.
function bHaveMicronixSerial_Callback(hObject, eventdata, handles)
% hObject    handle to bHaveMicronixSerial (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of bHaveMicronixSerial

