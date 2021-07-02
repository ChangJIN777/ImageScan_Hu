function varargout = AFMControl(varargin)
% AFMCONTROL MATLAB code for AFMControl.fig
%      AFMCONTROL, by itself, creates a new AFMCONTROL or raises the existing
%      singleton*.
%
%      H = AFMCONTROL returns the handle to a new AFMCONTROL or the handle to
%      the existing singleton*.
%
%      AFMCONTROL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in AFMCONTROL.M with the given input arguments.
%
%      AFMCONTROL('Property','Value',...) creates a new AFMCONTROL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before AFMControl_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to AFMControl_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help AFMControl

% Last Modified by GUIDE v2.5 28-Nov-2012 12:17:50

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @AFMControl_OpeningFcn, ...
                   'gui_OutputFcn',  @AFMControl_OutputFcn, ...
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

% --- Executes just before AFMControl is made visible.
function AFMControl_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to AFMControl (see VARARGIN)

% Choose default command line output for AFMControl
handles.output = hObject;

% varargin 
    % first argument passed in will be the handle to instance of
    % AFMScanPLImages class which is made in ImageScan.
    handles.AFMImageScan = varargin{1};

guidata(hObject, handles); 

    % if one plot axes has colorboar attached, make it wider in x direction  
    handles.currentScanSignalAxes = axes('parent',handles.panelData,'Units', 'Pixels', 'Position', [50 380 280 280],...
        'XLimMode', 'manual', 'YLimMode', 'manual', 'XLim', [-200 200], 'YLim', [-200 200]);
    handles.currentScanReferenceAxes = axes('parent',handles.panelData,'Units', 'Pixels', 'Position', [400 380 349 280],...
        'XLimMode', 'manual', 'YLimMode', 'manual', 'XLim', [-200 200], 'YLim', [-200 200]);
    handles.averageScanSignalAxes = axes('parent',handles.panelData,'Units', 'Pixels', 'Position', [50 40 280 280],...
        'XLimMode', 'manual', 'YLimMode', 'manual', 'XLim', [-200 200], 'YLim', [-200 200]);
    handles.averageScanReferenceAxes = axes('parent',handles.panelData,'Units', 'Pixels', 'Position', [400 40 280 280],...
        'XLimMode', 'manual', 'YLimMode', 'manual', 'XLim', [-200 200], 'YLim', [-200 200]);
    handles.averageScanNormAxes = axes('parent',handles.panelData,'Units', 'Pixels', 'Position', [750 40 280 280],...
        'XLimMode', 'manual', 'YLimMode', 'manual', 'XLim', [-200 200], 'YLim', [-200 200]);
    
    title(handles.currentScanSignalAxes,'Current Scan PL (signal)');
    title(handles.currentScanReferenceAxes,'Current Scan PL (ref)');
    title(handles.averageScanSignalAxes,'Averaged Scan PL (signal)');
    title(handles.averageScanReferenceAxes,'Averaged Scan PL (ref)');
    title(handles.averageScanNormAxes,'Normalized Scan PL');
    xlabel(handles.currentScanSignalAxes,'');
    xlabel(handles.currentScanReferenceAxes,'');
    xlabel(handles.averageScanSignalAxes,'Tip x (nm)');
    xlabel(handles.averageScanReferenceAxes,'Tip x (nm)');
    xlabel(handles.averageScanNormAxes,'Tip x (nm)');
    ylabel(handles.currentScanSignalAxes,'');
    ylabel(handles.currentScanReferenceAxes,'Tip y (nm)');
    ylabel(handles.averageScanSignalAxes,'');
    ylabel(handles.averageScanReferenceAxes,'Tip y (nm)');
    
    set(handles.currentScanSignalAxes,'YDir','normal');
    set(handles.currentScanReferenceAxes,'YDir','normal');
    set(handles.averageScanSignalAxes,'YDir','normal');
    set(handles.averageScanReferenceAxes,'YDir','normal');
    set(handles.averageScanNormAxes,'YDir','normal');
%     set(currentScanSignalAxes,'YLimMode','manual');
%     set(currentScanSignalAxes,'YDir','normal');
%     xlim(currentScanSignalAxes,[-50,50]);
%     ylim(currentScanSignalAxes,[-50,50]);
    
    colorm.cmap = pink(64);
    %set(handles.AFMControl, 'Colormap',colorm.cmap);
    colorm.cax = caxis(handles.currentScanReferenceAxes);
    colorm.auto = true;
    caxis auto
    set(handles.currentScanReferenceAxes, 'UserData', colorm);
    colorbar('peer', handles.currentScanReferenceAxes)
   % set(handles.AFMControl,'CurrentAxes',currentScanSignalAxes);

   %Add the standard figure toolbar and the standard menu bar
    set(hObject, 'Toolbar', 'figure');
    % Update handles structure
    guidata(hObject, handles);
    drawnow();
    
    % get the scanner offset values to update the this GUI on opening
   % handles.AFMImageScan.UpdateOnlyIndicatorsScannerOffsets(handles,...
                       % handles.AFMImageScan.imageScanHandles.NanoA);
   
  % Update handles structure
% it is important that defining of handles (like AFMImageScan) goes above
% this update to the handles structure, otherwise it will not be a
% recognized handle upon later calls.

% create a new directory name for the current date if needed:
mydate = date; %returns dd-mmm-yyyy
myyear = mydate(8:end); % returns yyyy
mymonth= mydate(4:6); % returns mm
myday = mydate(1:2); % returns dd
myFormattedDate = [myyear '_' mymonth '_' myday '\'];

set(handles.saveDataPath,'String',['C:\Users\lab\Documents\code\MATLAB\ImageAquire\data\' myFormattedDate]);

guidata(hObject, handles);  
   
end


% --- Outputs from this function are returned to the command line.
function varargout = AFMControl_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end


% --- Executes on button press in buttonTrackingParameters.
function buttonTrackingParameters_Callback(hObject, eventdata, handles)
% hObject    handle to buttonTrackingParameters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    ConfigureTracking(handles.AFMImageScan.trackParameters);
end




function scanSize_Callback(hObject, eventdata, handles)
% hObject    handle to scanSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of scanSize as text
%        str2double(get(hObject,'String')) returns contents of scanSize as a double

end

% --- Executes during object creation, after setting all properties.
function scanSize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to scanSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function ampChan1_Callback(hObject, eventdata, handles)
% hObject    handle to ampChan1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ampChan1 as text
%        str2double(get(hObject,'String')) returns contents of ampChan1 as a double
end

% --- Executes during object creation, after setting all properties.
function ampChan1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ampChan1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function ampChan2_Callback(hObject, eventdata, handles)
% hObject    handle to ampChan2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ampChan2 as text
%        str2double(get(hObject,'String')) returns contents of ampChan2 as a double
end

% --- Executes during object creation, after setting all properties.
function ampChan2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ampChan2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function freqDetuning1_Callback(hObject, eventdata, handles)
% hObject    handle to freqDetuning1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of freqDetuning1 as text
%        str2double(get(hObject,'String')) returns contents of freqDetuning1 as a double
end

% --- Executes during object creation, after setting all properties.
function freqDetuning1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to freqDetuning1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function freqDetuning2_Callback(hObject, eventdata, handles)
% hObject    handle to freqDetuning2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of freqDetuning2 as text
%        str2double(get(hObject,'String')) returns contents of freqDetuning2 as a double
end

% --- Executes during object creation, after setting all properties.
function freqDetuning2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to freqDetuning2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on button press in buttonStartGradientScan.
function buttonStartGradientScan_Callback(hObject, eventdata, handles)
% hObject    handle to buttonStartGradientScan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.AFMImageScan.PerformMagneticTipScan(handles);
end

% --- Executes on button press in buttonStopGradientScan.
function buttonStopGradientScan_Callback(hObject, eventdata, handles)
% hObject    handle to buttonStopGradientScan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.AFMImageScan.stopScan=true;
end


function saveDataPath_Callback(hObject, eventdata, handles)
% hObject    handle to saveDataPath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of saveDataPath as text
%        str2double(get(hObject,'String')) returns contents of saveDataPath as a double
end

% --- Executes during object creation, after setting all properties.
function saveDataPath_CreateFcn(hObject, eventdata, handles)
% hObject    handle to saveDataPath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function saveDataFilename_Callback(hObject, eventdata, handles)
% hObject    handle to saveDataFilename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of saveDataFilename as text
%        str2double(get(hObject,'String')) returns contents of saveDataFilename as a double
end

% --- Executes during object creation, after setting all properties.
function saveDataFilename_CreateFcn(hObject, eventdata, handles)
% hObject    handle to saveDataFilename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function samplesPerLine_Callback(hObject, eventdata, handles)
% hObject    handle to samplesPerLine (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of samplesPerLine as text
%        str2double(get(hObject,'String')) returns contents of samplesPerLine as a double
end

% --- Executes during object creation, after setting all properties.
function samplesPerLine_CreateFcn(hObject, eventdata, handles)
% hObject    handle to samplesPerLine (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function timePerPixel_Callback(hObject, eventdata, handles)
% hObject    handle to timePerPixel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of timePerPixel as text
%        str2double(get(hObject,'String')) returns contents of timePerPixel as a double
end

% --- Executes during object creation, after setting all properties.
function timePerPixel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to timePerPixel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function integralGain_Callback(hObject, eventdata, handles)
% hObject    handle to integralGain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of integralGain as text
%        str2double(get(hObject,'String')) returns contents of integralGain as a double
end

% --- Executes during object creation, after setting all properties.
function integralGain_CreateFcn(hObject, eventdata, handles)
% hObject    handle to integralGain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function proportionalGain_Callback(hObject, eventdata, handles)
% hObject    handle to proportionalGain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of proportionalGain as text
%        str2double(get(hObject,'String')) returns contents of proportionalGain as a double
end

% --- Executes during object creation, after setting all properties.
function proportionalGain_CreateFcn(hObject, eventdata, handles)
% hObject    handle to proportionalGain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function setpointAmplitude_Callback(hObject, eventdata, handles)
% hObject    handle to setpointAmplitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of setpointAmplitude as text
%        str2double(get(hObject,'String')) returns contents of setpointAmplitude as a double
end

% --- Executes during object creation, after setting all properties.
function setpointAmplitude_CreateFcn(hObject, eventdata, handles)
% hObject    handle to setpointAmplitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function piTime_Callback(hObject, eventdata, handles)
% hObject    handle to piTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of piTime as text
%        str2double(get(hObject,'String')) returns contents of piTime as a double
end

% --- Executes during object creation, after setting all properties.
function piTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to piTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function depopulationTime_Callback(hObject, eventdata, handles)
% hObject    handle to depopulationTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of depopulationTime as text
%        str2double(get(hObject,'String')) returns contents of depopulationTime as a double
end

% --- Executes during object creation, after setting all properties.
function depopulationTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to depopulationTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function preReadoutWait_Callback(hObject, eventdata, handles)
% hObject    handle to preReadoutWait (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of preReadoutWait as text
%        str2double(get(hObject,'String')) returns contents of preReadoutWait as a double
end

% --- Executes during object creation, after setting all properties.
function preReadoutWait_CreateFcn(hObject, eventdata, handles)
% hObject    handle to preReadoutWait (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function sampleWidth_Callback(hObject, eventdata, handles)
% hObject    handle to sampleWidth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of sampleWidth as text
%        str2double(get(hObject,'String')) returns contents of sampleWidth as a double
end

% --- Executes during object creation, after setting all properties.
function sampleWidth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sampleWidth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function delayTimeAOM_Callback(hObject, eventdata, handles)
% hObject    handle to delayTimeAOM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of delayTimeAOM as text
%        str2double(get(hObject,'String')) returns contents of delayTimeAOM as a double
end

% --- Executes during object creation, after setting all properties.
function delayTimeAOM_CreateFcn(hObject, eventdata, handles)
% hObject    handle to delayTimeAOM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function initTime_Callback(hObject, eventdata, handles)
% hObject    handle to initTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of initTime as text
%        str2double(get(hObject,'String')) returns contents of initTime as a double
end

% --- Executes during object creation, after setting all properties.
function initTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to initTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on button press in buttonBrowseSequences.
function buttonBrowseSequences_Callback(hObject, eventdata, handles)
% hObject    handle to buttonBrowseSequences (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[filename pathname] = uigetfile('*.esr', 'Select Pulse Sequence',...
                    'C:\Users\lab\Documents\code\MATLAB\NewPulseBlaster\SavedPulseSequences\');
        try
             file1 = [pathname filename];
        catch err %#ok
             file1 = [];
        end

        %return if no good file is available
        if isempty(file1) || ~ischar(file1)
            return;
        end
        %Check to see that the file is good
        fid = fopen(file1);
        if fid == -1
            return;
        end
        fclose(fid);
        % if the file looks fine set the path/file on GUI,
        % that is the string of handles.pulseFile, the edit box below 
        % this browse button
        set(handles.pulseFile, 'String', file1);

end



function pulseFile_Callback(hObject, eventdata, handles)
% hObject    handle to pulseFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of pulseFile as text
%        str2double(get(hObject,'String')) returns contents of pulseFile as a double
end

% --- Executes during object creation, after setting all properties.
function pulseFile_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pulseFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function readoutTime_Callback(hObject, eventdata, handles)
% hObject    handle to readoutTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of readoutTime as text
%        str2double(get(hObject,'String')) returns contents of readoutTime as a double
end

% --- Executes during object creation, after setting all properties.
function readoutTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to readoutTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function scanSizePerDim_Callback(hObject, eventdata, handles)
% hObject    handle to scanSizePerDim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% this value is to be in units of nanometers
% limit it based on the Catalyst's scanner limits
% 125 µm, but limit to lower since we never need a scanStartZ this large,
% 100000 nm = 100 µm
% also forbid negative or too small values
if str2double(get(hObject,'String')) >=100000
    set(hObject,'String',num2str(100000));
end
if str2double(get(hObject,'String')) <= 10
    set(hObject,'String',num2str(10));
end

% Hints: get(hObject,'String') returns contents of scanSizePerDim as text
%        str2double(get(hObject,'String')) returns contents of scanSizePerDim as a double
end

% --- Executes during object creation, after setting all properties.
function scanSizePerDim_CreateFcn(hObject, eventdata, handles)
% hObject    handle to scanSizePerDim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function numPixelsPerDim_Callback(hObject, eventdata, handles)
% hObject    handle to numPixelsPerDim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% make the variable an integer greater than 1
set(hObject,'String',num2str(floor(str2double(get(hObject,'String')))));
if str2double(get(hObject,'String')) <= 1
    set(hObject,'String',num2str(2));
end

% Hints: get(hObject,'String') returns contents of numPixelsPerDim as text
%        str2double(get(hObject,'String')) returns contents of numPixelsPerDim as a double
end

% --- Executes during object creation, after setting all properties.
function numPixelsPerDim_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numPixelsPerDim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function numRepsPerPixel_Callback(hObject, eventdata, handles)
% hObject    handle to numRepsPerPixel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(hObject,'String',num2str(floor(str2double(get(hObject,'String')))));
if str2double(get(hObject,'String')) <= 1
    set(hObject,'String',num2str(2));
end

% Hints: get(hObject,'String') returns contents of numRepsPerPixel as text
%        str2double(get(hObject,'String')) returns contents of numRepsPerPixel as a double
end

% --- Executes during object creation, after setting all properties.
function numRepsPerPixel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numRepsPerPixel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function numPlotAverages_Callback(hObject, eventdata, handles)
% hObject    handle to numPlotAverages (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(hObject,'String',num2str(floor(str2double(get(hObject,'String')))));
if str2double(get(hObject,'String')) <= 1
    set(hObject,'String',num2str(2));
end

% Hints: get(hObject,'String') returns contents of numPlotAverages as text
%        str2double(get(hObject,'String')) returns contents of numPlotAverages as a double
end


% --- Executes during object creation, after setting all properties.
function numPlotAverages_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numPlotAverages (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in checkboxLaserFollows.
function checkboxLaserFollows_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxLaserFollows (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxLaserFollows
end



function tipLiftHeight_nm_Callback(hObject, eventdata, handles)
% hObject    handle to tipLiftHeight_nm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tipLiftHeight_nm as text
%        str2double(get(hObject,'String')) returns contents of tipLiftHeight_nm as a double

% the tip lift height here is in nanometers. Max should be limited to 1 or
% 2 microns I think, based on my observation of LithoMoveZ running out of
% range
% minimum could probably be under a nanometer, say 0.1 nm. This is probably
% lower anyway than we would ever need to use.
%Note also that positive values are the correct ones for moving the tip
%away from the surface when input into LithoMoveZ.
if str2double(get(hObject,'String')) >=3000
    set(hObject,'String',num2str(3000));
end
if str2double(get(hObject,'String')) <= 0
    set(hObject,'String',num2str(0));
end

end

% --- Executes during object creation, after setting all properties.
function tipLiftHeight_nm_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tipLiftHeight_nm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function numReadBuffers_Callback(hObject, eventdata, handles)
% hObject    handle to numReadBuffers (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numReadBuffers as text
%        str2double(get(hObject,'String')) returns contents of numReadBuffers as a double
set(hObject,'String',num2str(floor(str2double(get(hObject,'String')))));
if str2double(get(hObject,'String')) <= 1
    set(hObject,'String',num2str(2));
end

end

% --- Executes during object creation, after setting all properties.
function numReadBuffers_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numReadBuffers (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in checkbox50nsSignalAOM_APD.
function checkbox50nsSignalAOM_APD_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox50nsSignalAOM_APD (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox50nsSignalAOM_APD
end

% --- Executes on button press in checkbox50nsReferenceAOM_APD.
function checkbox50nsReferenceAOM_APD_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox50nsReferenceAOM_APD (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox50nsReferenceAOM_APD
end



function freqCenterResonance_Callback(hObject, eventdata, handles)
% hObject    handle to freqCenterResonance (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of freqCenterResonance as text
%        str2double(get(hObject,'String')) returns contents of freqCenterResonance as a double
end

% --- Executes during object creation, after setting all properties.
function freqCenterResonance_CreateFcn(hObject, eventdata, handles)
% hObject    handle to freqCenterResonance (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in buttonStopLithoScan.
function buttonStopLithoScan_Callback(hObject, eventdata, handles)
% hObject    handle to buttonStopLithoScan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.AFMImageScan.imageScanHandles.NanoZ.LithoScan(0);

% update the Z position on the GUI
readoutZ = handles.AFMImageScan.imageScanHandles.NanoZ.LithoGetSoft(2);
set(handles.indicatorProbeZ,'String',num2str(readoutZ));

% feedback status
if handles.AFMImageScan.imageScanHandles.NanoZ.LithoIsFeedbackOn()
    set(handles.indicatorFeedbackOnOff,'String','Feedback is on');    
else
    set(handles.indicatorFeedbackOnOff,'String','Feedback is off');
end
end

% --- Executes on button press in buttonCenterXY.
function buttonCenterXY_Callback(hObject, eventdata, handles)
% hObject    handle to buttonCenterXY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.AFMImageScan.imageScanHandles.NanoZ.LithoCenterXY();
newX = handles.AFMImageScan.imageScanHandles.NanoZ.LithoGetXPosUM();
newY = handles.AFMImageScan.imageScanHandles.NanoZ.LithoGetYPosUM();
set(handles.scannerPosIndicatorX,'String',num2str(newX));
set(handles.scannerPosIndicatorY,'String',num2str(newY));
end

% --- Executes on button press in buttonLithoBegin.
function buttonLithoBegin_Callback(hObject, eventdata, handles)
% hObject    handle to buttonLithoBegin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.AFMImageScan.imageScanHandles.NanoZ.LithoBegin();

% feedback status
if handles.AFMImageScan.imageScanHandles.NanoZ.LithoIsFeedbackOn()
    set(handles.indicatorFeedbackOnOff,'String','Feedback is on');    
else
    set(handles.indicatorFeedbackOnOff,'String','Feedback is off');
end
end

% --- Executes on button press in buttonLithoEnd.
function buttonLithoEnd_Callback(hObject, eventdata, handles)
% hObject    handle to buttonLithoEnd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.AFMImageScan.imageScanHandles.NanoZ.LithoEnd();


end

% --- Executes on button press in buttonMoveScannerpX.
function buttonMoveScannerpX_Callback(hObject, eventdata, handles)
% hObject    handle to buttonMoveScannerpX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
dx_um = str2double(get(handles.scannerMoveDistance_nm,'String'))*10^-3;
handles.AFMImageScan.imageScanHandles.NanoZ.LithoTranslate(dx_um,0,2.0);
newX = handles.AFMImageScan.imageScanHandles.NanoZ.LithoGetXPosUM();
newY = handles.AFMImageScan.imageScanHandles.NanoZ.LithoGetYPosUM();
set(handles.scannerPosIndicatorX,'String',num2str(newX));
set(handles.scannerPosIndicatorY,'String',num2str(newY));
end

% --- Executes on button press in buttonMoveScannernX.
function buttonMoveScannernX_Callback(hObject, eventdata, handles)
% hObject    handle to buttonMoveScannernX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
dx_um = str2double(get(handles.scannerMoveDistance_nm,'String'))*10^-3;
handles.AFMImageScan.imageScanHandles.NanoZ.LithoTranslate(-dx_um,0,2.0);
newX = handles.AFMImageScan.imageScanHandles.NanoZ.LithoGetXPosUM();
newY = handles.AFMImageScan.imageScanHandles.NanoZ.LithoGetYPosUM();
set(handles.scannerPosIndicatorX,'String',num2str(newX));
set(handles.scannerPosIndicatorY,'String',num2str(newY));
end

% --- Executes on button press in buttonMoveScannerpY.
function buttonMoveScannerpY_Callback(hObject, eventdata, handles)
% hObject    handle to buttonMoveScannerpY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
dy_um = str2double(get(handles.scannerMoveDistance_nm,'String'))*10^-3;
handles.AFMImageScan.imageScanHandles.NanoZ.LithoTranslate(0,dy_um,2.0);
newX = handles.AFMImageScan.imageScanHandles.NanoZ.LithoGetXPosUM();
newY = handles.AFMImageScan.imageScanHandles.NanoZ.LithoGetYPosUM();
set(handles.scannerPosIndicatorX,'String',num2str(newX));
set(handles.scannerPosIndicatorY,'String',num2str(newY));
end

% --- Executes on button press in buttonMoveScannernY.
function buttonMoveScannernY_Callback(hObject, eventdata, handles)
% hObject    handle to buttonMoveScannernY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
dy_um = str2double(get(handles.scannerMoveDistance_nm,'String'))*10^-3;
handles.AFMImageScan.imageScanHandles.NanoZ.LithoTranslate(0,-dy_um,2.0);
newX = handles.AFMImageScan.imageScanHandles.NanoZ.LithoGetXPosUM();
newY = handles.AFMImageScan.imageScanHandles.NanoZ.LithoGetYPosUM();
set(handles.scannerPosIndicatorX,'String',num2str(newX));
set(handles.scannerPosIndicatorY,'String',num2str(newY));
end

% --- Executes on button press in checkboxUseTracking.
function checkboxUseTracking_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxUseTracking (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxUseTracking
end



function scannerMoveDistance_nm_Callback(hObject, eventdata, handles)
% hObject    handle to scannerMoveDistance_nm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of scannerMoveDistance_nm as text
%        str2double(get(hObject,'String')) returns contents of scannerMoveDistance_nm as a double
end

% --- Executes during object creation, after setting all properties.
function scannerMoveDistance_nm_CreateFcn(hObject, eventdata, handles)
% hObject    handle to scannerMoveDistance_nm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in buttonStartLithoScan.
function buttonStartLithoScan_Callback(hObject, eventdata, handles)
% hObject    handle to buttonStartLithoScan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.AFMImageScan.imageScanHandles.NanoZ.LithoScan(1);

% feedback status
if handles.AFMImageScan.imageScanHandles.NanoZ.LithoIsFeedbackOn()
    set(handles.indicatorFeedbackOnOff,'String','Feedback is on');    
else
    set(handles.indicatorFeedbackOnOff,'String','Feedback is off');
end
end



function probeMoveZDistance_nm_Callback(hObject, eventdata, handles)
% hObject    handle to probeMoveZDistance_nm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of probeMoveZDistance_nm as text
%        str2double(get(hObject,'String')) returns contents of probeMoveZDistance_nm as a double
end

% --- Executes during object creation, after setting all properties.
function probeMoveZDistance_nm_CreateFcn(hObject, eventdata, handles)
% hObject    handle to probeMoveZDistance_nm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in buttonLithoMoveZPositive.
function buttonLithoMoveZPositive_Callback(hObject, eventdata, handles)
% hObject    handle to buttonLithoMoveZPositive (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
rateZ = 1.0; % microns/sec
distZ_um = 0.001*str2double(get(handles.probeMoveZDistance_nm,'String'));
handles.AFMImageScan.imageScanHandles.NanoZ.LithoMoveZ(distZ_um,rateZ);

% read the soft value (nm) from the AFM to check:
readoutZ = handles.AFMImageScan.imageScanHandles.NanoZ.LithoGetSoft(2);
set(handles.indicatorProbeZ,'String',num2str(readoutZ));

% feedback status
if handles.AFMImageScan.imageScanHandles.NanoZ.LithoIsFeedbackOn()
    set(handles.indicatorFeedbackOnOff,'String','Feedback is on');    
else
    set(handles.indicatorFeedbackOnOff,'String','Feedback is off');
end
end

% --- Executes on button press in buttonLithoMoveZNegative.
function buttonLithoMoveZNegative_Callback(hObject, eventdata, handles)
% hObject    handle to buttonLithoMoveZNegative (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
rateZ = 1.0; % microns/sec
distZ_um = 0.001*str2double(get(handles.probeMoveZDistance_nm,'String'));

% since moving the tip down to the surface is dangerous, throw a warning
% whenever it is tried to be sure it is not a mistake

choiceZ = questdlg('Warning: moving the tip down can cause damage to the probe. Are you sure you want to do it?',...
    'TIP TO SURFACE WARNING','Yes','No');
switch choiceZ,
    case 'Yes'
        handles.AFMImageScan.imageScanHandles.NanoZ.LithoMoveZ(-distZ_um,rateZ);

        % read the soft value (nm) from the AFM to check:
        readoutZ = handles.AFMImageScan.imageScanHandles.NanoZ.LithoGetSoft(2);
        set(handles.indicatorProbeZ,'String',num2str(readoutZ));
    case 'No'   
end %switch

% feedback status
if handles.AFMImageScan.imageScanHandles.NanoZ.LithoIsFeedbackOn()
    set(handles.indicatorFeedbackOnOff,'String','Feedback is on');    
else
    set(handles.indicatorFeedbackOnOff,'String','Feedback is off');
end

end



function scannerOffsetX_nm_Callback(hObject, eventdata, handles)
% hObject    handle to scannerOffsetX_nm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

input = str2double(get(hObject,'String'));
if isempty(get(hObject,'String'))
    input = 0;
end
if isnan(input)
    input = 0;
end
if input >30000
    input=12000;
end
if input<-30000
    input=-30000;
end
set(hObject,'String',num2str(input));

% Hints: get(hObject,'String') returns contents of scannerOffsetX_nm as text
%        str2double(get(hObject,'String')) returns contents of scannerOffsetX_nm as a double
end

% --- Executes during object creation, after setting all properties.
function scannerOffsetX_nm_CreateFcn(hObject, eventdata, handles)
% hObject    handle to scannerOffsetX_nm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

str = 'Set in nanometers how much +/- the scanner will move in its own hardware x direction to define a center of the scan region.';
set(hObject,'tooltipString',str);

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function scannerOffsetY_nm_Callback(hObject, eventdata, handles)
% hObject    handle to scannerOffsetY_nm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

input = str2double(get(hObject,'String'));
if isempty(get(hObject,'String'))
    input = 0;
end
if isnan(input)
    input = 0;
end
if input >30000
    input=30000;
end
if input<-30000
    input=-30000;
end
set(hObject,'String',num2str(input));
% Hints: get(hObject,'String') returns contents of scannerOffsetY_nm as text
%        str2double(get(hObject,'String')) returns contents of scannerOffsetY_nm as a double
end

% --- Executes during object creation, after setting all properties.
function scannerOffsetY_nm_CreateFcn(hObject, eventdata, handles)
% hObject    handle to scannerOffsetY_nm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

str = 'Set in nanometers how much +/- the scanner will move in its own hardware y direction to define a center of the scan region.';
set(hObject,'tooltipString',str);

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on button press in buttonSetOffsetsToCurrentPosition.
% function buttonSetOffsetsToCurrentPosition_Callback(hObject, eventdata, handles)
% % hObject    handle to buttonSetOffsetsToCurrentPosition (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % current scanner position in microns
% offX = handles.AFMImageScan.imageScanHandles.NanoZ.LithoGetXPosUM();
% offY = handles.AFMImageScan.imageScanHandles.NanoZ.LithoGetYPosUM();
% 
% % set the value to be set upon Start scanstartz for the scanner offset.
% set(handles.scannerOffsetX_nm,'String',num2str(offX*1000));
% set(handles.scannerOffsetY_nm,'String',num2str(offY*1000));

% end


% --- Executes on button press in buttonSetOffsetFromEdit.
function buttonSetOffsetFromEdit_Callback(hObject, eventdata, handles)
% hObject    handle to buttonSetOffsetFromEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% the offset X,Y edit buttons don't do anything to the AFM until you press
% this button. This will set the offset of the scanner hardware. This
% change can be seen on the Nanoscope Bruker GUI (scanStartZ parameter list) as
% well as the AFMControl.fig GUI in the top of the window.
offX_nm = str2double(get(handles.scannerOffsetX_nm,'String'));
offY_nm = str2double(get(handles.scannerOffsetY_nm,'String'));

% the function is contained in AFMScanPLImages.m
% UpdateScannerOffsets(obj, nanoScopeOA, xOff_nm, yOff_nm, bEndMeasure,bIncrement)
handles.AFMImageScan.UpdateScannerOffsets(handles,...
    handles.AFMImageScan.imageScanHandles.NanoA,offX_nm,offY_nm,0,0);

% the Update... function also sets the GUI to show the new offset values as
% read out from the Nanoscope.
% the last argument bIncrement==0 so the given offsets are absolute not
% relative

end



function stepwiseTracking_Callback(hObject, eventdata, handles)
% hObject    handle to stepwiseTracking (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(hObject,'String',num2str(floor(str2double(get(hObject,'String')))));
if str2double(get(hObject,'String')) <= 1
    set(hObject,'String',num2str(2));
end

% Hints: get(hObject,'String') returns contents of stepwiseTracking as text
%        str2double(get(hObject,'String')) returns contents of stepwiseTracking as a double
end

% --- Executes during object creation, after setting all properties.
function stepwiseTracking_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stepwiseTracking (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function trackingCompareThreshold_Callback(hObject, eventdata, handles)
% hObject    handle to trackingCompareThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% this should only ever be a narrow range between 0 to 1.0, a fraction
% pretty much anything below 0.70 makes no sense at all
% let it go higher just in case of special things like always track every x
% # steps "hack"
if str2double(get(hObject,'String')) >= 1.5
    set(hObject,'String',num2str(1));
end
if str2double(get(hObject,'String')) <= 0.5
    set(hObject,'String',num2str(0.5));
end

% Hints: get(hObject,'String') returns contents of trackingCompareThreshold as text
%        str2double(get(hObject,'String')) returns contents of trackingCompareThreshold as a double
end

% --- Executes during object creation, after setting all properties.
function trackingCompareThreshold_CreateFcn(hObject, eventdata, handles)
% hObject    handle to trackingCompareThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in buttonFeedbackOff.
function buttonFeedbackOff_Callback(hObject, eventdata, handles)
% hObject    handle to buttonFeedbackOff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.AFMImageScan.imageScanHandles.NanoZ.LithoFeedback(0);
if handles.AFMImageScan.imageScanHandles.NanoZ.LithoIsFeedbackOn()
    set(handles.indicatorFeedbackOnOff,'String','Feedback is on');    
else
    set(handles.indicatorFeedbackOnOff,'String','Feedback is off');
    
    % test turning off laser for "dark" lift
    
    handles.AFMImageScan.imageScanHandles.NanoA.LaserOnOff(0)
end

% read the soft value (nm) from the AFM to check:
readoutZ = handles.AFMImageScan.imageScanHandles.NanoZ.LithoGetSoft(2);
set(handles.indicatorProbeZ,'String',num2str(readoutZ));

% Hint: get(hObject,'Value') returns toggle state of buttonFeedbackOff
end

% --- Executes on button press in buttonFeedbackOn.
function buttonFeedbackOn_Callback(hObject, eventdata, handles)
% hObject    handle to buttonFeedbackOn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.AFMImageScan.imageScanHandles.NanoA.LaserOnOff(1)

handles.AFMImageScan.imageScanHandles.NanoZ.LithoFeedback(1);
if handles.AFMImageScan.imageScanHandles.NanoZ.LithoIsFeedbackOn()
    set(handles.indicatorFeedbackOnOff,'String','Feedback is on');    
else
    set(handles.indicatorFeedbackOnOff,'String','Feedback is off');
    
    
end

% read the soft value (nm) from the AFM to check:
readoutZ = handles.AFMImageScan.imageScanHandles.NanoZ.LithoGetSoft(2);
set(handles.indicatorProbeZ,'String',num2str(readoutZ));


% Hint: get(hObject,'Value') returns toggle state of buttonFeedbackOn
end


% --- Executes on button press in buttonOpenConfigureImageRegistration.
function buttonOpenConfigureImageRegistration_Callback(hObject, eventdata, handles)
% hObject    handle to buttonOpenConfigureImageRegistration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ConfigureImageRegistration(handles.AFMImageScan); % pass in "obj" of AFMScanPLImages
end



function scanAngle_deg_Callback(hObject, eventdata, handles)
% hObject    handle to scanAngle_deg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
inputStr = get(hObject,'String');
if str2double(inputStr) > 90
    set(hObject,'String',num2str(90));
end
if str2double(inputStr) <-90
    set(hObject,'String',num2str(-90));
end
if ~isnan(str2double(inputStr)) && ~isempty(str2double(inputStr))
    handles.AFMImageScan.imageScanHandles.NanoA.set('ScanAngle',degtorad(str2double(inputStr)));
end
% entering this value will most likely start the scanner on scanstartz mode again
% if it was LithoScanning=Off.

% Hints: get(hObject,'String') returns contents of scanAngle_deg as text
%        str2double(get(hObject,'String')) returns contents of scanAngle_deg as a double
end

% --- Executes during object creation, after setting all properties.
function scanAngle_deg_CreateFcn(hObject, eventdata, handles)
% hObject    handle to scanAngle_deg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on slider movement.
function sliderPulseRepsMultiplier_Callback(hObject, eventdata, handles)
% hObject    handle to sliderPulseRepsMultiplier (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

slideValue = get(hObject,'Value');
set(handles.sliderIndicator,'String',num2str(slideValue));

end

% --- Executes during object creation, after setting all properties.
function sliderPulseRepsMultiplier_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderPulseRepsMultiplier (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
end


% --- Executes on button press in checkboxUseImageReg.
function checkboxUseImageReg_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxUseImageReg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% Hint: get(hObject,'Value') returns toggle state of checkboxUseImageReg
end



function edit42_Callback(hObject, eventdata, handles)
% hObject    handle to edit42 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit42 as text
%        str2double(get(hObject,'String')) returns contents of edit42 as a double
end

% --- Executes during object creation, after setting all properties.
function edit42_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit42 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function seriesZValues_Callback(hObject, eventdata, handles)
% hObject    handle to seriesZValues (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of seriesZValues as text
%        str2double(get(hObject,'String')) returns contents of seriesZValues as a double
end

% --- Executes during object creation, after setting all properties.
function seriesZValues_CreateFcn(hObject, eventdata, handles)
% hObject    handle to seriesZValues (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function seriesDetuningValues_Callback(hObject, eventdata, handles)
% hObject    handle to seriesDetuningValues (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of seriesDetuningValues as text
%        str2double(get(hObject,'String')) returns contents of seriesDetuningValues as a double
end

% --- Executes during object creation, after setting all properties.
function seriesDetuningValues_CreateFcn(hObject, eventdata, handles)
% hObject    handle to seriesDetuningValues (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function scanStartZ_Callback(hObject, eventdata, handles)
% hObject    handle to scanStartZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of scanStartZ as text
%        str2double(get(hObject,'String')) returns contents of scanStartZ as a double
end

% --- Executes during object creation, after setting all properties.
function scanStartZ_CreateFcn(hObject, eventdata, handles)
% hObject    handle to scanStartZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function scanEndZ_Callback(hObject, eventdata, handles)
% hObject    handle to scanEndZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of scanEndZ as text
%        str2double(get(hObject,'String')) returns contents of scanEndZ as a double
end

% --- Executes during object creation, after setting all properties.
function scanEndZ_CreateFcn(hObject, eventdata, handles)
% hObject    handle to scanEndZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function nonScanFixedPosition_Callback(hObject, eventdata, handles)
% hObject    handle to nonScanFixedPosition (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of nonScanFixedPosition as text
%        str2double(get(hObject,'String')) returns contents of nonScanFixedPosition as a double
end

% --- Executes during object creation, after setting all properties.
function nonScanFixedPosition_CreateFcn(hObject, eventdata, handles)
% hObject    handle to nonScanFixedPosition (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
