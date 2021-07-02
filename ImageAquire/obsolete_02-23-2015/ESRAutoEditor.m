function varargout = ESRAutoEditor(varargin)
% ESRAUTOEDITOR MATLAB code for ESRAutoEditor.fig
%      ESRAUTOEDITOR, by itself, creates a new ESRAUTOEDITOR or raises the existing
%      singleton*.
%
%      H = ESRAUTOEDITOR returns the handle to a new ESRAUTOEDITOR or the handle to
%      the existing singleton*.
%
%      ESRAUTOEDITOR('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ESRAUTOEDITOR.M with the given input arguments.
%
%      ESRAUTOEDITOR('Property','Value',...) creates a new ESRAUTOEDITOR or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ESRAutoEditor_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ESRAutoEditor_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ESRAutoEditor

% Last Modified by GUIDE v2.5 06-May-2013 13:38:42

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ESRAutoEditor_OpeningFcn, ...
                   'gui_OutputFcn',  @ESRAutoEditor_OutputFcn, ...
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


% --- Executes just before ESRAutoEditor is made visible.
function ESRAutoEditor_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ESRAutoEditor (see VARARGIN)

% Choose default command line output for ESRAutoEditor
handles.output = hObject;

handles.ESRControlHandles = varargin{1};

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ESRAutoEditor wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = ESRAutoEditor_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in buttonAddCommand_track.
function buttonAddCommand_track_Callback(hObject, eventdata, handles)
% hObject    handle to buttonAddCommand_track (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

process = get(handles.tableProcessCommands,'Data');
  
    nextLine = str2num(get(handles.nextLineToEdit,'String'));
    nextName = 'Track current NV';
    dataColumn = num2str(0);
    process(nextLine,:) = {nextName, dataColumn};
    
    set(handles.tableProcessCommands,'Data',process);
    
    % increment the next line to add
    set(handles.nextLineToEdit,'String',num2str(nextLine+1));

% --- Executes on button press in buttonAddCommand_cwesr.
function buttonAddCommand_cwesr_Callback(hObject, eventdata, handles)
% hObject    handle to buttonAddCommand_cwesr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
process = get(handles.tableProcessCommands,'Data');
  
    nextLine = str2num(get(handles.nextLineToEdit,'String'));
    nextName = 'CWESR measurement';
    dataColumn = num2str(0);
    process(nextLine,:) = {nextName, dataColumn};
    
    set(handles.tableProcessCommands,'Data',process);
    
    % increment the next line to add
    set(handles.nextLineToEdit,'String',num2str(nextLine+1));


% --- Executes on button press in buttonAddCommand_fit.
function buttonAddCommand_fit_Callback(hObject, eventdata, handles)
% hObject    handle to buttonAddCommand_fit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
process = get(handles.tableProcessCommands,'Data');
  
    nextLine = str2num(get(handles.nextLineToEdit,'String'));
    nextName = 'Fit to data';
    dataColumn = num2str(0);
    process(nextLine,:) = {nextName, dataColumn};
    
    set(handles.tableProcessCommands,'Data',process);
    
    % increment the next line to add
    set(handles.nextLineToEdit,'String',num2str(nextLine+1));


% --- Executes on button press in buttonAddCommand_pulse.
function buttonAddCommand_pulse_Callback(hObject, eventdata, handles)
% hObject    handle to buttonAddCommand_pulse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
process = get(handles.tableProcessCommands,'Data');
  
    nextLine = str2num(get(handles.nextLineToEdit,'String'));
    nextName = 'Pulsed measurement';
    dataColumn = num2str(0);
    process(nextLine,:) = {nextName, dataColumn};
    
    set(handles.tableProcessCommands,'Data',process);
    
    % increment the next line to add
    set(handles.nextLineToEdit,'String',num2str(nextLine+1));


% --- Executes on button press in buttonAddCommand_getresult.
function buttonAddCommand_getresult_Callback(hObject, eventdata, handles)
% hObject    handle to buttonAddCommand_getresult (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
process = get(handles.tableProcessCommands,'Data');
  
    nextLine = str2num(get(handles.nextLineToEdit,'String'));
    nextName = 'Meas. result -> params';
    dataColumn = num2str(0);
    process(nextLine,:) = {nextName, dataColumn};
    
    set(handles.tableProcessCommands,'Data',process);
    
    % increment the next line to add
    set(handles.nextLineToEdit,'String',num2str(nextLine+1));


% --- Executes on button press in buttonAddCommand_move.
function buttonAddCommand_move_Callback(hObject, eventdata, handles)
% hObject    handle to buttonAddCommand_move (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
process = get(handles.tableProcessCommands,'Data');
  
    nextLine = str2num(get(handles.nextLineToEdit,'String'));
    nextName = 'Move cursor to next NV';
    dataColumn = num2str(0);
    process(nextLine,:) = {nextName, dataColumn};
    
    set(handles.tableProcessCommands,'Data',process);
    
    % increment the next line to add
    set(handles.nextLineToEdit,'String',num2str(nextLine+1));


% --- Executes on button press in buttonAddCommand_confocal.
function buttonAddCommand_confocal_Callback(hObject, eventdata, handles)
% hObject    handle to buttonAddCommand_confocal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
process = get(handles.tableProcessCommands,'Data');
  
    nextLine = str2num(get(handles.nextLineToEdit,'String'));
    nextName = 'Confocal scan XY';
    dataColumn = num2str(0);
    process(nextLine,:) = {nextName, dataColumn};
    
    set(handles.tableProcessCommands,'Data',process);
    
    % increment the next line to add
    set(handles.nextLineToEdit,'String',num2str(nextLine+1));


% --- Executes on button press in buttonDeleteCommand.
function buttonDeleteCommand_Callback(hObject, eventdata, handles)
% hObject    handle to buttonDeleteCommand (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
process = get(handles.tableProcessCommands,'Data');
thisLine = str2num(get(handles.commandNumToDelete,'String'));
[ro,~] = size(process);
% as long as the matrix dimensions are not exceeded, delete the row
if ro>=thisLine
    process(thisLine,:) = [];
end
set(handles.tableProcessCommands,'Data',process);


function commandNumToDelete_Callback(hObject, eventdata, handles)
% hObject    handle to commandNumToDelete (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of commandNumToDelete as text
%        str2double(get(hObject,'String')) returns contents of commandNumToDelete as a double


% --- Executes during object creation, after setting all properties.
function commandNumToDelete_CreateFcn(hObject, eventdata, handles)
% hObject    handle to commandNumToDelete (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function nextLineToEdit_Callback(hObject, eventdata, handles)
% hObject    handle to nextLineToEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of nextLineToEdit as text
%        str2double(get(hObject,'String')) returns contents of nextLineToEdit as a double

% make the variable an integer greater than 0
set(hObject,'String',num2str(floor(str2double(get(hObject,'String')))));
if str2double(get(hObject,'String')) < 1
    set(hObject,'String',num2str(1));
end

% --- Executes during object creation, after setting all properties.
function nextLineToEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to nextLineToEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in buttonSaveCommandList.
function buttonSaveCommandList_Callback(hObject, eventdata, handles)
% hObject    handle to buttonSaveCommandList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton11.
function pushbutton11_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function nextSettingsToEdit_Callback(hObject, eventdata, handles)
% hObject    handle to nextSettingsToEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of nextSettingsToEdit as text
%        str2double(get(hObject,'String')) returns contents of nextSettingsToEdit as a double


% --- Executes during object creation, after setting all properties.
function nextSettingsToEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to nextSettingsToEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in buttonEditCurrentCommand.
function buttonEditCurrentCommand_Callback(hObject, eventdata, handles)
% hObject    handle to buttonEditCurrentCommand (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
