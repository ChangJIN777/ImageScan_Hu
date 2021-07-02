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

% Last Modified by GUIDE v2.5 22-Feb-2014 18:09:23

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
handles.maxCommand = 38;
handles.maxSettingParameters=38; % maximum number of settings for a type of command

handles.SettingValues = cell(handles.maxCommand,handles.maxSettingParameters); % all the data values
[handles.SettingValues{:,:}] = deal(0);
handles.lineToEdit = 1;

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
    dataColumn = '';
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
    % first column is non-editable name, second is editable value
    set(handles.tableProcessCommands,'ColumnEditable',[false,true]);


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
    nextName = 'Meas result to params';
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
handles = guidata(hObject);
input = floor(str2double(get(hObject,'String')));
if input > handles.maxCommand
    input = handles.maxCommand;
end
set(hObject,'String',num2str(input));
guidata(handles.output, handles);

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
handles = guidata(hObject);
input = floor(str2double(get(hObject,'String')));
if input > handles.maxCommand
    input = handles.maxCommand;
end
set(hObject,'String',num2str(input));
guidata(handles.output, handles);

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
defaultPath = [handles.ESRControlHandles.EsrGlobalMethods.imageScanHandles.configS.sequenceFolder '\AutomationSequenceSettings\'];
if exist(defaultPath,'dir') ==0 %path does not exist?
    mkdir(defaultPath);
end

%first this saves the nva file to the selected name
[filename fpath ~] = uiputfile('*.nva','Save automation sequence as...',defaultPath);

cdata = get(handles.tableProcessCommands,'Data');
txtformat=sprintf([repmat('%s\t',1,size(cdata,1)),'\n'],cdata{:});
dlmwrite([fpath filename],txtformat,'');

% then it also saves the nvcs file automatically using the same filename
% and file path and just a different file extension
filename2 = regexprep(filename,'.nva','.nvcs');
settingsdata = handles.SettingValues;
% turn all data into strings
for i=1:handles.maxCommand
    for j=1:handles.maxSettingParameters
        % no point to judge if it is already string or number because
        % num2str still returns a string for a string input
        settingsdata{i,j} = num2str(settingsdata{i,j});
    end
end
txtformat=sprintf([repmat('%s\t',1,size(settingsdata,1)),'\n'],settingsdata{:});
dlmwrite([fpath filename2],txtformat,'');


% --- Executes on button press in buttonLoadNVAsequence.
function buttonLoadNVAsequence_Callback(hObject, eventdata, handles)
% hObject    handle to buttonLoadNVAsequence (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function nextSettingsToEdit_Callback(hObject, eventdata, handles)
% hObject    handle to nextSettingsToEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of nextSettingsToEdit as text
%        str2double(get(hObject,'String')) returns contents of nextSettingsToEdit as a double
handles = guidata(hObject);
input = floor(str2double(get(hObject,'String')));
if input > handles.maxCommand
    input = handles.maxCommand;
end
set(hObject,'String',num2str(input));
guidata(handles.output, handles);

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

process = get(handles.tableProcessCommands,'Data');
handles.lineToEdit = str2num(get(handles.nextSettingsToEdit,'String'));
currentCommand = process{handles.lineToEdit,1};

% make sure it is a valid command and not empty line
if ischar(class(currentCommand))
    set(handles.indicateSettingsForWhat,'String',...
                ['line ' num2str(handles.lineToEdit) ': ' currentCommand]);
    switch(currentCommand)
        case 'Track current NV'
            set(handles.tableCommandSettings,'ColumnName',{'Parameter','Value','Units'});
            set(handles.tableCommandSettings,'Data',...
                {'# times to track',handles.SettingValues{handles.lineToEdit,1}, 'cycles';...
                'Filter Wheel pos.',handles.SettingValues{handles.lineToEdit,2}, 'postion'});
            % first column is non-editable name, second is editable value
            set(handles.tableCommandSettings,'ColumnEditable',[false,true,false]);
            
        case 'CWESR measurement'   
            set(handles.tableCommandSettings,'ColumnName',{'Parameter','Value','Units'});
            set(handles.tableCommandSettings,'Data',...
                {'RF Amplitude',handles.SettingValues{handles.lineToEdit,1}, 'dBm';...
                'Center Frequency',handles.SettingValues{handles.lineToEdit,2}, 'MHz';...
                'Freq. Deviation +/-',handles.SettingValues{handles.lineToEdit,3}, 'MHz';...
                'Num. Steps',handles.SettingValues{handles.lineToEdit,4},'points';...
                'Dwell time',handles.SettingValues{handles.lineToEdit,5},'µs';...
                'Filter Wheel pos.', handles.SettingValues{handles.lineToEdit,6}, 'position';...
                'Tracking period',handles.SettingValues{handles.lineToEdit,7},'sweeps';...
                'Num. sweeps to do',handles.SettingValues{handles.lineToEdit,8},'sweeps';...
                'Use tracking?',handles.SettingValues{handles.lineToEdit,9},'0=no,1=yes';...
                'Do peak fit?',handles.SettingValues{handles.lineToEdit,10},'0=no,1=yes';...
                'Expect hyperfine?',handles.SettingValues{handles.lineToEdit,11},'0=no,1=yes';...
                'Guess D splitting',handles.SettingValues{handles.lineToEdit,12},'MHz'});
            % first column is non-editable name, second is editable value
            set(handles.tableCommandSettings,'ColumnEditable',[false,true,false]);
        case 'Fit to data'
            '3'
        case 'Pulsed measurement'
            set(handles.tableCommandSettings,'ColumnName',{'Parameter','Value','Units'});
            set(handles.tableCommandSettings,'Data',...
                {'RF Amplitude',handles.SettingValues{handles.lineToEdit,1}, 'dBm';...
                'Center Frequency',handles.SettingValues{handles.lineToEdit,2}, 'MHz';...
                'Sweep type',handles.SettingValues{handles.lineToEdit,3}, '0=tau,1=freq.,3=ampl.';...
                'Num points',handles.SettingValues{handles.lineToEdit,4}, 'tau/freq/ampl points';...
                'Reps per point',handles.SettingValues{handles.lineToEdit,5},'reps';...
                'Tracking period',handles.SettingValues{handles.lineToEdit,6},'points';...
                'Tracking garbage',handles.SettingValues{handles.lineToEdit,7},'points';...
                'Use tracking?',handles.SettingValues{handles.lineToEdit,8},'0=no,1=yes';...
                'Tau (t) start',handles.SettingValues{handles.lineToEdit,9},'ns';...
                'Tau (y) end',handles.SettingValues{handles.lineToEdit,10},'ns';...
                'Extra tau pts.',handles.SettingValues{handles.lineToEdit,11},'ns';...
                'Use extra tau?',handles.SettingValues{handles.lineToEdit,12},'0=no,1=yes';...
                'Freq sweep dev+/-',handles.SettingValues{handles.lineToEdit,13},'MHz';...
                'Ampl sweep dev+/-',handles.SettingValues{handles.lineToEdit,14},'dBm';...
                'Num pi cycles',handles.SettingValues{handles.lineToEdit,15},'cycles';...
                'Pre-measure pause',handles.SettingValues{handles.lineToEdit,16},'s';...
                '(u)Depopulation time',handles.SettingValues{handles.lineToEdit,17},'ns';...
                '(w)Pre Readout wait time',handles.SettingValues{handles.lineToEdit,18},'ns';...
                '(p)Pi pulse time',handles.SettingValues{handles.lineToEdit,19},'ns';...
                '(s)Sample trigger width',handles.SettingValues{handles.lineToEdit,20},'ns';...
                '(a)Aom delay time',handles.SettingValues{handles.lineToEdit,21},'ns';...
                '(i)Init time',handles.SettingValues{handles.lineToEdit,22},'ns';...
                '(r)Readout time',handles.SettingValues{handles.lineToEdit,23},'ns';...
                '(q)IQ time',handles.SettingValues{handles.lineToEdit,24},'ns';...
                'IQ mod on?',handles.SettingValues{handles.lineToEdit,25},'0=no,1=yes';...
                'Daq counter/trigger',handles.SettingValues{handles.lineToEdit,26},'1,2,3,4';...
                '50 ns pre-trigger sig?',handles.SettingValues{handles.lineToEdit,27},'0=no,1=yes';...
                '50 ns pre-trigger ref?',handles.SettingValues{handles.lineToEdit,28},'0=no,1=yes';...
                'Differential y-t?',handles.SettingValues{handles.lineToEdit,29},'0=no,1=yes';...
                'Sequence filename',handles.SettingValues{handles.lineToEdit,30},'';...
                'Num. sweeps to do',handles.SettingValues{handles.lineToEdit,31},'sweeps'});
                
            set(handles.tableCommandSettings,'ColumnEditable',[false,true,false]);
        case 'Meas result to params'
            
            set(handles.tableCommandSettings,'ColumnName',{'Parameter','Value','Units'});
            set(handles.tableCommandSettings,'Data',...
                {'Get center frequency',handles.SettingValues{handles.lineToEdit,1}, '0=no,1=yes';...
                'Get freq. deviation',handles.SettingValues{handles.lineToEdit,2}, '0=no,1=yes'
                'Get RF amplitude',handles.SettingValues{handles.lineToEdit,3}, '0=no,1=yes';...
                'Get pi pulse time',handles.SettingValues{handles.lineToEdit,4}, '0=no,1=yes'});
            % first column is non-editable name, second is editable value
            set(handles.tableCommandSettings,'ColumnEditable',[false,true,false]);
            
        case 'Confocal scan XY'
            '6'
        case 'Move cursor to next NV'
            set(handles.tableCommandSettings,'ColumnName',{'Parameter','Value','Units'});
            set(handles.tableCommandSettings,'Data',...
                {'1st NV Move rel or abs?',handles.SettingValues{handles.lineToEdit,1}, '0=rel,1=abs';...
                'other NVs Move rel or abs?',handles.SettingValues{handles.lineToEdit,2}, '0=rel,1=abs'});
            % editability
            set(handles.tableCommandSettings,'ColumnEditable',[false,true,false]);
            
    end
    guidata(hObject, handles);
end


% --- Executes on button press in buttonSetCommandDefaults.
function buttonSetCommandDefaults_Callback(hObject, eventdata, handles)
% hObject    handle to buttonSetCommandDefaults (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
process = get(handles.tableProcessCommands,'Data');
handles.lineToEdit = str2num(get(handles.nextSettingsToEdit,'String'));
currentCommand = process{handles.lineToEdit,1};
% make sure it is a valid command and not empty line
if ischar(class(currentCommand))

    switch(currentCommand)
        case 'Track current NV'
             handles.SettingValues{handles.lineToEdit,1} = 2; % # of cycles
             handles.SettingValues{handles.lineToEdit,2} = 2; % filter pos.
             guidata(hObject, handles);
             
             buttonEditCurrentCommand_Callback(handles.buttonEditCurrentCommand,eventdata,handles);
        case 'CWESR measurement'
             handles.SettingValues{handles.lineToEdit,1} = -20;
             handles.SettingValues{handles.lineToEdit,2} = 2870;
             handles.SettingValues{handles.lineToEdit,3} = 140;
             handles.SettingValues{handles.lineToEdit,4} = 200;
             handles.SettingValues{handles.lineToEdit,5} = 20000;
             handles.SettingValues{handles.lineToEdit,6} = 3;
             handles.SettingValues{handles.lineToEdit,7} = 20;
             handles.SettingValues{handles.lineToEdit,8} = 10;
             handles.SettingValues{handles.lineToEdit,9} = 1;
             handles.SettingValues{handles.lineToEdit,10} = 1;
             handles.SettingValues{handles.lineToEdit,11} = 0;
             handles.SettingValues{handles.lineToEdit,12} = 2870;
             guidata(hObject, handles);
             
             buttonEditCurrentCommand_Callback(handles.buttonEditCurrentCommand,eventdata,handles);
        case 'Fit to data'
            '3'
        case 'Pulsed measurement'
            handles.SettingValues{handles.lineToEdit,1} = -20;
             handles.SettingValues{handles.lineToEdit,2} = 2800;
             handles.SettingValues{handles.lineToEdit,3} = 0;
             handles.SettingValues{handles.lineToEdit,4} = 31;
             handles.SettingValues{handles.lineToEdit,5} = 100000;
             handles.SettingValues{handles.lineToEdit,6} = 25;
             handles.SettingValues{handles.lineToEdit,7} = 2;
             handles.SettingValues{handles.lineToEdit,8} = 1;
             handles.SettingValues{handles.lineToEdit,9} = 0;
             handles.SettingValues{handles.lineToEdit,10} = 600;
             handles.SettingValues{handles.lineToEdit,11} = 50;
             handles.SettingValues{handles.lineToEdit,12} = 0;
             handles.SettingValues{handles.lineToEdit,13} = 20;
             handles.SettingValues{handles.lineToEdit,14} = 0.5;
             handles.SettingValues{handles.lineToEdit,15} = 9;
             handles.SettingValues{handles.lineToEdit,16} = 3;
             handles.SettingValues{handles.lineToEdit,17} = 500;
             handles.SettingValues{handles.lineToEdit,18} = 1000;
             handles.SettingValues{handles.lineToEdit,19} = 100;
             handles.SettingValues{handles.lineToEdit,20} = 50;
             handles.SettingValues{handles.lineToEdit,21} = 860;
             handles.SettingValues{handles.lineToEdit,22} = 1000;
             handles.SettingValues{handles.lineToEdit,23} = 400;
             handles.SettingValues{handles.lineToEdit,24} = 60;
             handles.SettingValues{handles.lineToEdit,25} = 0;
             handles.SettingValues{handles.lineToEdit,26} = 1;
             handles.SettingValues{handles.lineToEdit,27} = 1;
             handles.SettingValues{handles.lineToEdit,28} = 1;
             handles.SettingValues{handles.lineToEdit,29} = 0;
             handles.SettingValues{handles.lineToEdit,30} = 'C:\Users\lab\Documents\code_dev\NewPulseBlaster\SavedPulseSequences\inUseSequences\';
             handles.SettingValues{handles.lineToEdit,31} = 50;
             guidata(hObject, handles);
             
             buttonEditCurrentCommand_Callback(handles.buttonEditCurrentCommand,eventdata,handles);
        case 'Meas result to params'
             handles.SettingValues{handles.lineToEdit,1} = 0; % defaults are get no parameters
             handles.SettingValues{handles.lineToEdit,2} = 0;
             handles.SettingValues{handles.lineToEdit,3} = 0;
             handles.SettingValues{handles.lineToEdit,4} = 0;
             guidata(hObject, handles);
             
             buttonEditCurrentCommand_Callback(handles.buttonEditCurrentCommand,eventdata,handles);
        case 'Confocal scan XY'
            %edit here
        case 'Move cursor to next NV'
            handles.SettingValues{handles.lineToEdit,1} = 1; % default, absolute NV->NV move on first NV
            handles.SettingValues{handles.lineToEdit,2} = 0; %default, relative NV-NV move for all others
            guidata(hObject, handles);
            buttonEditCurrentCommand_Callback(handles.buttonEditCurrentCommand,eventdata,handles);  
    end
    guidata(hObject, handles);
end


% --- Executes when entered data in editable cell(s) in tableCommandSettings.
function tableCommandSettings_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to tableCommandSettings (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)

% save the settings whenever one is updated.
tableData = get(handles.tableCommandSettings,'Data');
[numrows ~] = size(tableData);
valueColumn = 2; % second column are values
% handles.lineToEdit had already been set in previous button call,
% to make sure that it is the settings visible in table which get saved
for i=1:numrows
    %tableData is a CELL so use {i,col} not [i,col] !
    handles.SettingValues{handles.lineToEdit,i} = tableData{i,valueColumn};
end
guidata(hObject, handles);
