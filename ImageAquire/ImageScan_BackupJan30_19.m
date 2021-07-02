function varargout = ImageScan(varargin)
    % IMAGESCAN MATLAB code for ImageScan.fig
    %      IMAGESCAN, by itself, creates a new IMAGESCAN or raises the existing
    %      singleton*.
    %
    %      H = IMAGESCAN returns the handle to a new IMAGESCAN or the handle to
    %      the existing singleton*.
    %
    %      IMAGESCAN('CALLBACK',hObject,eventData,handles,...) calls the local
    %      function named CALLBACK in IMAGESCAN.M with the given input arguments.
    %
    %      IMAGESCAN('Property','Value',...) creates a new IMAGESCAN or raises the
    %      existing singleton*.  Starting from the left, property value pairs are
    %      applied to the GUI before ImageScan_OpeningFcn gets called.  An
    %      unrecognized property name or invalid value makes property application
    %      stop.  All inputs are passed to ImageScan_OpeningFcn via varargin.
    %
    %      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
    %      instance to run (singleton)".
    %
    % See also: GUIDE, GUIDATA, GUIHANDLES

    % Edit the above text to modify the response to help ImageScan

    % Last Modified by GUIDE v2.5 23-Feb-2015 16:20:30

    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @ImageScan_OpeningFcn, ...
                       'gui_OutputFcn',  @ImageScan_OutputFcn, ...
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

% --- Executes just before ImageScan is made visible.
function ImageScan_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to ImageScan (see VARARGIN)

    % Choose default command line output for ImageScan
    handles.output = hObject;
    
    handles.bSimulatedData = false;
    
    handles.version = 2013.04; % the version is in YYYY.MM
    %feature accel off;
    global laser_x_handle;
    laser_x_handle = handles.editPositionX;
    global laser_y_handle;
    laser_y_handle = handles.editPositionY;
    global laser_z_handle;
    laser_z_handle = handles.editPositionZ;
    %-----loading the configuration file------------------
    %-----------------------------------------------------
    handles.configurationFile = 'ConfigurationImageScan.txt';

    % structure
    if exist(handles.configurationFile, 'file') == 2

        handles.configS = tdfread(handles.configurationFile);
       

    else
        % the configuration file doesn't exist which is bad, but in this
        % case just set some defaults
        handles.configS.bHaveInverterBoard = 1;
        handles.configS.bHaveNanoscopeAFM = 1;
        handles.configS.numUSBFilterWheels = 2;
        handles.configS.bHaveZurichInstr = 0;
        handles.configS.bHaveMCLXYZScanner = 0;
        handles.configS.dataFolder = 'C:\Users\lab\Documents\code\MATLAB\ImageAquire\data\';
        handles.configS.sequenceFolder = 'C:\Users\lab\Documents\code\MATLAB\NewPulseBlaster\SavedPulseSequences\';
        handles.configS.bMagnetGui = 1;
        handles.configS.xScanMicronsPerVolt = 25.508796;
        handles.configS.yScanMicronsPerVolt = 25.508796;
        handles.configS.zScanMicronsPerVolt = 10;
        handles.configS.xMinVolts = -4.90027;
        handles.configS.xMaxVolts = 4.90027;
        handles.configS.yMinVolts = -4.90027;
        handles.configS.yMaxVolts = 4.90027;
        handles.configS.zMinVolts = 0;
        handles.configS.zMaxVolts = 10;
        handles.configS.imageScanBGColorR = 231;
        handles.configS.imageScanBGColorG = 231;
        handles.configS.imageScanBGColorB = 231;
    end
    %-----------------------------------------------------
    %-----------------------------------------------------
    
%back = axes;
%set(back, 'Position', [.186 .4298 .4773 .543], 'Box', 'on', 'XTick', [],...
%    'YTick', [], 'HitTest', 'off')

    % Create the one instance of pulseBlaster to send to all GUIs using
    % the card. Also use it in the Image Scan GUI for AOM on/off
    
    handles.PulseInterpreter = PulseInterpreter();
    handles.PulseInterpreter.setCurrentPulse([handles.configS.sequenceFolder 'bit1_on.txt']);
    handles.PulseInterpreter.loadToPulseblaster();
    
    if handles.configS.bHaveInverterBoard == 0
        % no inverter board, so start the laser on
        handles.PulseInterpreter.runPulse();
    end

    handles.DAQManager = DAQManager(handles,handles.configS);
    handles.csp = ConfocalScanParameters(handles.configS);
    handles.cstp = ConfocalScanTrackingParameters(handles.configS);
    handles.ScanControl = ScanControl(handles.DAQManager.DAQ,handles.csp,handles.cstp);
    handles.CursorControl = CursorControl(handles.DAQManager.DAQ);
    handles.StateControl = StateControl();
    handles.MagnetPLScan = [];
    % sweep/pulse ESR measurements require DAQ, Pulseblaster, and the SRS
    % is established inside SweepControl itself
    
    % uncomment these two lines for old sweep control GUI
    %handles.SweepControl_standalone = SweepControl_standalone(handles.DAQManager.DAQ,...
     %   handles.PulseInterpreter,handles);
    
    % new on 3/29/2013%%%%%%%%%
    % I've decided to start up the SRS when ImageScan opens now, instead of
    % doing it inside Sweep Control, which causes occasional problems anyway
    
    % 04/20/2016: add a second SRS for things like phase noise
    handles.bUseSRS2=1;
    handles.srs = gpib('ni', 0, 24);
    if handles.bUseSRS2
        handles.srs2 = gpib('ni',0,16);
    else
        handles.srs2 = [];
    end
    handles.lake = gpib('ni',0,2);
    handles.ESRControl = [];
    handles.EsrGlobalMethods = EsrGlobalMethods(handles.DAQManager.DAQ,...
        handles.PulseInterpreter,handles.srs,handles);
    handles.EsrCWSweep = EsrCWSweep(handles,handles.DAQManager.DAQ,...
        handles.PulseInterpreter,handles.srs,handles.EsrGlobalMethods);
    handles.EsrPulsedSweep = EsrPulsedSweep(handles,handles.DAQManager.DAQ,...
        handles.PulseInterpreter,handles.srs,handles.EsrGlobalMethods);
    handles.EsrAutomation = EsrAutomation(handles);
    
    global ESR_pulsed_handles;
    ESR_pulsed_handles = handles.EsrPulsedSweep;
    %%%%%%%%%
    
    %if handles.configS.bMagnetGui == 1
    %    handles.GonioGUI = GonioGUI(handles.DAQManager.DAQ,handles);
    %    set(handles.buttonOpenMagnet,'Enable','on');
    %else
    %    handles.GonioGUI = [];
    %    set(handles.buttonOpenMagnet,'Enable','off');
    %end
    
%     % depending on the AFM type used change the buttons.
%     if handles.configS.bHaveNanoscopeAFM == 1
%         set(handles.buttonOpenAFMControl,'String','Open NanoScope AFM');
%         set(handles.buttonOpenNanoscopeCOM,'Enable','on');
%         set(handles.buttonOpenAFMControl,'Enable','on');
%         
%     elseif handles.configS.bHaveZurichInstr == 1
%         set(handles.buttonOpenAFMControl,'String','Open HF2LI AFM Gui');
%         set(handles.buttonOpenNanoscopeCOM,'Enable','off');
%         set(handles.buttonOpenAFMControl,'Enable','on');
%     else
%         % if there is no AFM then disable the button
%         set(handles.buttonOpenAFMControl,'Enable','off');
%         set(handles.buttonOpenNanoscopeCOM,'Enable','off');
%     end
    
    handles.NanoZ = []; % nanoscope zApi. wait to initialize
    handles.NanoA = []; % nanoscope open arch. wait in initialize
    handles.AFMControl = []; % for the Bruker AFM Gui
    handles.AFM_gui = []; % for the Zurich Instr AFM GUi
    handles.bInitNanoscope = 0; % bool
    % the AFM measurements require accss to DAQ, pulseBlaster and SRS
    if handles.configS.bHaveNanoscopeAFM == 1
        
        handles.AFMImageScan = AFMScanPLImages(handles.DAQManager.DAQ,...
            handles.PulseInterpreter,handles.srs,handles);
    end
    
    handles.sIgor = actxserver('IgorPro.Application');
    handles.sIGor.Visible = 1; % show the Igor if not already
    
    % two dialog boxes will pop up, one for initialization of each filter
    % wheel connection. COM3, COM4
    
    switch(handles.configS.numUSBFilterWheels)
        case 0
            set(handles.buttonNDpos1,'Enable','off');
            set(handles.buttonNDpos2,'Enable','off');
            set(handles.buttonNDpos3,'Enable','off');
            set(handles.buttonNDpos4,'Enable','off');
            set(handles.buttonNDpos5,'Enable','off');
            set(handles.buttonNDpos6,'Enable','off');
            set(handles.buttonDetectionFilterPos1,'Enable','off');
            set(handles.buttonDetectionFilterPos2,'Enable','off');
            set(handles.buttonDetectionFilterPos3,'Enable','off');
            set(handles.buttonDetectionFilterPos4,'Enable','off');
            set(handles.buttonDetectionFilterPos5,'Enable','off');
            set(handles.buttonDetectionFilterPos6,'Enable','off');
            set(handles.outputMotorNDFilter,'String','0');
            set(handles.outputCombinedOD,'String',get(handles.inputStationaryNDFilter,'String'));
            handles.FilterWheel = [];
            handles.FilterWheel2 = [];
        case 1
            handles.FilterWheel = FilterWheel(handles,1); % COM7 for excitation
            set(handles.buttonDetectionFilterPos1,'Enable','off');
            set(handles.buttonDetectionFilterPos2,'Enable','off');
            set(handles.buttonDetectionFilterPos3,'Enable','off');
            set(handles.buttonDetectionFilterPos4,'Enable','off');
            set(handles.buttonDetectionFilterPos5,'Enable','off');
            set(handles.buttonDetectionFilterPos6,'Enable','off');
            handles.FilterWheel2 = [];
        case 2
            handles.FilterWheel = FilterWheel(handles,1); % COM7 for excitation
            handles.FilterWheel2 = FilterWheel(handles,2); % COMX for detection
    end
    
    %Initialize a bunch of the variables to calm Matlab
    %handles.shiftOn = false;
    %handles.tabGroup = [];
    %handles.checkboxAutoColorScale = [];
    handles.buttonColorMapEditor = [];
    handles.buttonZoomToBox = [];
    handles.scanMenu = [];
    handles.buttonSetupScan = [];
    %handles.checkboxContinuousScan = [];
    handles.buttonSetupTracking = [];
    handles.useSimulatedData = [];
    
    handles.maxLabel = 200;
    handles.listNVMarkers = zeros(1,handles.maxLabel);
    handles.listNVMarkerPos = zeros(3,handles.maxLabel); %x,y,z
    handles.listNVMarkerType = zeros(1,handles.maxLabel);
    
    set(handles.checkUseZoomboxLimits,'Value',true);
    guidata(hObject, handles);
    

    %Add the standard figure toolbar and the standard menu bar
    % 4/18/2013 get rid of the standard figure menu and toolbar. In GUIDE
    % we have set all the tools we actually need. The colorbar, setup scan,
    % and other checkboxes are now all located on the front panel for
    % easier access.
    set(hObject, 'Toolbar', 'none');
    set(hObject, 'MenuBar', 'none');

    bgcolor = [handles.configS.imageScanBGColorR/255 handles.configS.imageScanBGColorG/255 handles.configS.imageScanBGColorB/255];
    set(hObject, 'Color', bgcolor);
    %set(findobj(hObject,'-property', 'BackgroundColor'), 'BackgroundColor', bgcolor);
    % take any "blue-screened" color and turn it to the new color
    set(findobj(hObject,'BackgroundColor',[0 1 1]),'BackgroundColor',bgcolor);
    guidata(hObject, handles);
    %drawnow();
    
    %We don't like the look of the tabs in the normal L&F, so we change it
    %just for the tabs
   % originalLnF = javax.swing.UIManager.getLookAndFeel;  %class
    %newLnF = 'com.sun.java.swing.plaf.motif.MotifLookAndFeel';  %string
    %javax.swing.UIManager.setLookAndFeel(newLnF);
   % warning off MATLAB:uitabgroup:OldVersion
    %Start the tab group
    %handles.tabGroup = uitabgroup(hObject, 'Position', [.1873 .4298 .476 .5751]);
    %drawnow();
    %javax.swing.UIManager.setLookAndFeel(originalLnF); %Reset original L&F
    
    %Create the first tab. This works exactly like the NewTab function
    %tab = uitab('Parent', handles.tabGroup, 'title', '');
    %Create the axes on the tab
    %currentAxes = axes('Parent', tab, 'Units', 'Pixels', 'Position', [56 42 393 307],... % formerly [47 42 393 307]
    %    'XLimMode', 'manual', 'YLimMode', 'manual', 'XLim', [-2 2], 'YLim', [-2 2]);
    
    % decided to put axses defined in GUIDE, otherwise uncomment this:
    %handles.confocalAxes = axes('Units', 'Pixels', 'Position', [235 335 393 307],... 
    %    'XLimMode', 'manual', 'YLimMode', 'manual', 'XLim', [-2 2], 'YLim', [-2 2]);
    
    %set(tab, 'UserData', currentAxes);
    %Prepare the colormap for this tab and store it as UserData in the axes
    %colorm.cmap = get(handles.ImageScan, 'Colormap'); %12-16-11
    colorm.cmap = pink(64);
    set(handles.ImageScan, 'Colormap',colorm.cmap);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    colorm.cax = caxis(handles.confocalAxes);
    colorm.auto = true;
    caxis auto
    set(handles.confocalAxes, 'UserData', colorm);
    colorbar('peer', handles.confocalAxes);
    %uitab(handles.tabGroup, 'title', '+');%Add the 'new tab' tab
    %jTabGroup = getappdata(handle(handles.tabGroup),'JTabbedPane');
    %set(handles.tabGroup, 'SelectionChangeCallback', @tabGroup_callback);
    % First let's load the close icon
    %jarFile = fullfile(matlabroot,'/java/jar/mwt.jar');
    %iconsFolder = '/com/mathworks/mwt/resources/';
    %iconURI = ['jar:file:/' jarFile '!' iconsFolder 'closebox.gif'];
    %icon = javax.swing.ImageIcon(java.net.URL(iconURI));
        % Now let's prepare the close button: icon, size and callback
    %jCloseButton = handle(javax.swing.JButton,'CallbackProperties');
    %jCloseButton.setIcon(icon);
    %jCloseButton.setPreferredSize(java.awt.Dimension(15,15));
    %jCloseButton.setMaximumSize(java.awt.Dimension(15,15));
    %jCloseButton.setSize(java.awt.Dimension(15,15));
    %jCloseButton.Border = [];
    %set(jCloseButton, 'ActionPerformedCallback',{@tabDelete, tab});
    %set(jCloseButton, 'Visible', false)

    % Now let's prepare a tab panel with our label and close button
    %jPanel = javax.swing.JPanel;	% default layout = FlowLayout
    %set(jPanel.getLayout, 'Hgap',0, 'Vgap',0);  % default gap = 5px
    %jLabel = javax.swing.JLabel('Tab #1  ');
    %jPanel.add(jLabel);
    %jPanel.add(jCloseButton);
    %import java.awt.*
    %jPanel.setBackground(java.awt.Color(1, 1, 1, 0))
    % Now attach this tab panel as the tab-group's 2nd component
    %jTabGroup.setTabComponentAt(0,jPanel);	% Tab #1 = second tab
    %handles.ScanControl.currentTab = tab; %set the currentTab property - VERY IMPORTANT
    
    
    
    %Set up the axes in the first tab
    set(handles.ImageScan,'CurrentAxes',handles.confocalAxes);
    set(handles.confocalAxes,'XLimMode','manual');
    set(handles.confocalAxes,'YLimMode','manual');
    set(handles.confocalAxes,'YDir','normal');
    xlim(handles.confocalAxes,[-125,125]);
    ylim(handles.confocalAxes,[-125,125]);
    xlabel(handles.confocalAxes,'X (µm)');
    ylabel(handles.confocalAxes,'Y (µm)');
    
    guidata(hObject, handles);
    
    handles.StateControl.initializeState(handles); % initialize the state machine
    
    %Set up the toolbar - get rid of a lot of the buttons, and change the
    %callbacks and tooltips for a few of them
%     tool = findall(hObject, 'Type', 'uitoolbar');
%     pushtools = findall(tool, 'Type', 'uipushtool');
%     toggletools = findall(tool, 'Type', 'uitoggletool');
%     set(toggletools(1:5), 'Visible', 'off');
%     set(pushtools(1:2), 'Visible', 'off');
%     set(pushtools(6), 'Visible', 'off');
%     set(pushtools(5), 'Tooltip', 'Load saved image', 'ClickedCallback', {@loadFile_Callback,...
%         handles});
%     set(pushtools(4), 'ClickedCallback', @buttonSaveScan_Callback,...
%         'Tooltip', 'Save Scan');
%     set(toggletools(7), 'OnCallback', {@zoomOutCallback, handles},...
%         'Tooltip', 'Zoom out to voltage limits');
    
    %Set up the menu bar - clear out a couple of menu items, change some,
    %andthen add a bunch, including the entire 'Scan & Track' menu
    %menu = findall(hObject, 'Type', 'uimenu');
    %uimenu(menu(1), 'Label', 'ImageScan Help', 'Position', 1, 'Callback', @helpCallback);
    %handles.checkboxAutoColorScale = uimenu(menu(6), 'Label', 'Auto Color Scale', 'Callback',...
    %    @checkboxAutoColorScale_Callback, 'Separator', 'on', 'Checked', 'on');
    %handles.buttonColorMapEditor = uimenu(menu(6), 'Label', 'Colormap Editor',...
    %    'Callback', @buttonColorMapEditor_Callback);
    %set(menu(111), 'Callback', @buttonSaveScan_Callback, 'Label', 'Save Data');
    %set(menu(110), 'Visible', 'off');
    %set(menu(113), 'Visible', 'off');
    %set(menu(91), 'Visible', 'off');
    %handles.scanMenu = uimenu(hObject, 'Label', 'Scan & Track', 'Position', 4);
    %handles.buttonSetupScan = uimenu(handles.scanMenu, 'Label', 'Setup Scan',...
    %    'Callback', @buttonSetupScan_Callback);
    %handles.checkboxContinuousScan = uimenu(handles.scanMenu, 'Label', 'Continuous Scan',...
    %    'Callback', @checkboxContinuousScan_Callback, 'Checked', 'off');
    %handles.buttonSetupTracking = uimenu(handles.scanMenu, 'Label', 'Setup Tracking',...
    %    'Callback', @buttonSetupTracking_Callback, 'Separator', 'on');
    %handles.useSimulatedData = uimenu(handles.scanMenu, 'Label', 'Use Simulated Data',...
    %    'Callback', @menuToggleFcn, 'Separator', 'on', 'Enable', 'off');
    %handles.aomMenu = uimenu(handles.scanMenu, 'Label', 'AOM Port', 'Position', 1, 'Separator', 'off');
    %uimenu(handles.aomMenu, 'Label', 'BNC 1', 'Position', 1, 'Callback', {@setAOMCallback, 1}, 'Checked', 'on');
    %uimenu(handles.aomMenu, 'Label', 'BNC 2', 'Position', 2, 'Callback', {@setAOMCallback, 2});
    %uimenu(handles.aomMenu, 'Label', 'BNC 3', 'Position', 3, 'Callback', {@setAOMCallback, 3});
    %uimenu(handles.aomMenu, 'Label', 'BNC 4', 'Position', 4, 'Callback', {@setAOMCallback, 4});

    guidata(hObject, handles);
    
    % set the z position to be 50 microns (half way) at the start.
    set(handles.editPositionZ,'String','50');
    increment = 0;
    handles.CursorControl.updatePositionFromEdit(handles,handles.editPositionZ,DAQManager.Z,increment);
    
    mydate = date; %returns dd-mmm-yyyy
    myyear = mydate(8:end); % returns yyyy
    mymonth= mydate(4:6); % returns mm
    myday = mydate(1:2); % returns dd
    myFormattedDate = [myyear '_' mymonth '_' myday '\'];
    set(handles.inputSaveImagePath,'String',[handles.configS.dataFolder myFormattedDate]);
    
    global Img_handles;
    Img_handles = handles;
end

% --- Outputs from this function are returned to the command line.
function varargout = ImageScan_OutputFcn(hObject, eventdata, handles) 
    % varargout  cell array for returning output args (see VARARGOUT);
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    %handles.StateControl.state = StateControl.SCANNING;
    %handles.CursorControl.createZoomBox(handles);
    %handles.CursorControl.createManualCursor(handles); 
    %handles.StateControl.changeToIdleState(handles);
    % Get default command line output from handles structure
    varargout{1} = handles.output;
end


% --- Executes on button press in buttonSetupScan.
function buttonSetupScan_Callback(hObject, eventdata)
    % hObject    handle to buttonSetupScan (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    handles = guidata(hObject);
%     ConfigureScan(handles.ScanControl.ScanParameters(find(get(...
%         handles.tabGroup, 'Children')==handles.ScanControl.currentTab)),...
%         str2double(get(handles.editPositionX,'String')),...
%         str2double(get(handles.editPositionY,'String')));
ConfigureScan(handles.ScanControl.ScanParameters(1),...
        str2double(get(handles.editPositionX,'String')),...
        str2double(get(handles.editPositionY,'String')),handles);
end

% --- Executes on button press in buttonStartStopScan.
function buttonStartStopScan_Callback(hObject, eventdata, handles)
    % hObject    handle to buttonStartStopScan (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
%this will notify
    %CountFinished event which will trigger ScanControl to perform the scan
    handles = guidata(hObject);
    if handles.StateControl.state == StateControl.SCANNING
        handles.StateControl.changeToIdleState(handles);
    else
        if get(handles.checkUseZoomboxLimits, 'Value');

            %index = find(get(handles.tabGroup, 'Children')'==handles.ScanControl.currentTab);

        end
        handles.StateControl.changeToScanningState(handles);
    end
end
 
% --- Executes on button press in buttonStopScan.
function buttonStopScan_Callback(hObject, eventdata, handles) %#ok<DEFNU>
    % hObject    handle to buttonStopScan (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

end



% % --- Executes on button press in buttonSaveScan.
% function buttonSaveScan_Callback(hObject, eventdata)
% % hObject    handle to buttonSaveScan (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % some of these may not currently work, except txt
%     handles = guidata(hObject);
%     imageToSave = uint16(handles.ScanControl.imageData);
%     imageInfo = handles.ScanControl.scanImageInfo(handles,false, false); % last argument is bTracking
%     if isempty(imageInfo) == true
%         return
%     end
%     [~, ~, ext] = fileparts(imageInfo.file);
%     switch ext
%         case '.txt'
%             fid = fopen(imageInfo.file, 'wt');
%             fprintf(fid, imageInfo.description);
%             fprintf(fid, '\n\n');
%             fclose(fid);
%             dlmwrite(imageInfo.file, imageToSave, '-append', 'delimiter', '\t');
%         case '.csv'
%             fid = fopen(imageInfo.file, 'wt');
%             fprintf(fid, imageInfo.description);
%             fprintf(fid, '\n\n');
%             fclose(fid);
%             dlmwrite(imageInfo.file, imageToSave, '-append', 'delimiter', ',');
%         case '.xls'
%             xlswrite(imageInfo.file, imageToSave);
%         case {'.tif', '.tiff'}
%             imwrite(imageToSave,file,'Description',imageInfo);
%     end
% end



% % --- Executes on button press in remove.
% function checkboxAutoColorScale_Callback(hObject, eventdata)
% % hObject    handle to remove (see GCBO)
%     % eventdata  reserved - to be defined in a future version of MATLAB
%     % handles    structure with handles and user data (see GUIDATA)
% 
%     % Hint: get(hObject,'Value') returns toggle state of remove
%     handles = guidata(hObject); %Get 'handles'
%     if strcmp(get(hObject, 'Checked'), 'off')==true
%         %If the auto color scale button is being checked on
%         set(handles.ImageScan, 'Colormap', pink(64));
%         caxis auto;
%         set(hObject, 'Checked', 'on');
%         %Note this in the userdata for the axes
%         currentAxes = get(get(handles.tabGroup, 'SelectedTab'), 'UserData');
%         colorm = get(currentAxes, 'UserData');
%         colorm.auto = true;
%         set(currentAxes, 'UserData', colorm);
%     else
%         %If the auto color scale button is being checked off
%         set(hObject, 'Checked', 'off');
%         currentAxes = get(get(handles.tabGroup, 'SelectedTab'), 'UserData');
%         colorm = get(currentAxes, 'UserData');
%         colorm.auto = false;
%         set(handles.ImageScan, 'Colormap', colorm.cmap);
%         caxis(currentAxes, colorm.cax);
%         set(currentAxes, 'UserData', colorm);
%     end
% end


% --- Executes on button press in buttonColorMapEditor.
function buttonColorMapEditor_Callback(hObject, eventdata)
% hObject    handle to buttonColorMapEditor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    handles = guidata(hObject);
    set(handles.checkboxAutoColorScale, 'Value', 1);
    colormapeditor;
end


function editPositionX_Callback(hObject, eventdata, handles)
% hObject    handle to editPositionX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    handles.CursorControl.updatePositionFromEdit(handles,handles.editPositionX,1,0.0);
end

% --- Executes on button press in buttonIncrementX.
function buttonIncrementX_Callback(hObject, eventdata, handles)
% hObject    handle to buttonIncrementX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    increment = str2double(get(handles.editStepSizeXY,'String'));
    handles.CursorControl.updatePositionFromEdit(handles,handles.editPositionX,1,increment);
end

% --- Executes on button press in buttonDecrmentX.
function buttonDecrmentX_Callback(hObject, eventdata, handles)
% hObject    handle to buttonDecrmentX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    decrement = -str2double(get(handles.editStepSizeXY,'String'));
    handles.CursorControl.updatePositionFromEdit(handles,handles.editPositionX,1,decrement);
end

function editPositionY_Callback(hObject, eventdata, handles)
% hObject    handle to editPositionY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    handles.CursorControl.updatePositionFromEdit(handles,handles.editPositionY,2,0.0);
end


% --- Executes on button press in buttonIncrementY.
function buttonIncrementY_Callback(hObject, eventdata, handles)
% hObject    handle to buttonIncrementY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    increment = str2double(get(handles.editStepSizeXY,'String'));
    handles.CursorControl.updatePositionFromEdit(handles,handles.editPositionY,2,increment);
end

% --- Executes on button press in buttonDecrmentY.
function buttonDecrmentY_Callback(hObject, eventdata, handles)
% hObject    handle to buttonDecrmentY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    decrement = -str2double(get(handles.editStepSizeXY,'String'));
    handles.CursorControl.updatePositionFromEdit(handles,handles.editPositionY,2,decrement);
end

function editPositionZ_Callback(hObject, eventdata, handles)
% hObject    handle to editPositionZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    handles.CursorControl.updatePositionFromEdit(handles,handles.editPositionZ,3,0.0);
end

% --- Executes on button press in buttonIncrementZ.
function buttonIncrementZ_Callback(hObject, eventdata, handles)
% hObject    handle to buttonIncrementZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    increment = str2double(get(handles.editStepSizeZ,'String'));
    handles.CursorControl.updatePositionFromEdit(handles,handles.editPositionZ,3,increment);
end

% --- Executes on button press in buttonDecrementZ.
function buttonDecrementZ_Callback(hObject, eventdata, handles)
% hObject    handle to buttonDecrementZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    decrement = -str2double(get(handles.editStepSizeZ,'String'));
    handles.CursorControl.updatePositionFromEdit(handles,handles.editPositionZ,3,decrement);
end

% --- Executes on button press in buttonResetCountHistory.
function buttonResetCountHistory_Callback(hObject, eventdata, handles)
% hObject    handle to buttonResetCountHistory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    handles.CursorControl.resetCountHistory();
end
%===========================HELPERS========================================





%===========================DEFAULTS=======================================


% --- Executes during object creation, after setting all properties.
function editPositionX_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPositionX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes during object creation, after setting all properties.
function editPositionY_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPositionY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function editStepSizeXY_Callback(hObject, eventdata, handles)
% hObject    handle to editStepSizeXY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editStepSizeXY as text
%        str2double(get(hObject,'String')) returns contents of editStepSizeXY as a double
end

% --- Executes during object creation, after setting all properties.
function editStepSizeXY_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editStepSizeXY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function editRunningCount_Callback(hObject, eventdata, handles)
% hObject    handle to editRunningCount (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editRunningCount as text
%        str2double(get(hObject,'String')) returns contents of editRunningCount as a double
end

% --- Executes during object creation, after setting all properties.
function editRunningCount_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editRunningCount (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end





% --- Executes during object creation, after setting all properties.
function editPositionZ_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPositionZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function editStepSizeZ_Callback(hObject, eventdata, handles)
% hObject    handle to editStepSizeZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editStepSizeZ as text
%        str2double(get(hObject,'String')) returns contents of editStepSizeZ as a double
end

% --- Executes during object creation, after setting all properties.
function editStepSizeZ_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editStepSizeZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



% --- Executes during object creation, after setting all properties.
function axesCurrentImage_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axesCurrentImage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axesCurrentImage
end


% % --- Executes on button press in checkboxContinuousScan.
% function checkboxContinuousScan_Callback(hObject, eventdata)
% % hObject    handle to checkboxContinuousScan (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hint: get(hObject,'Value') returns toggle state of checkboxContinuousScan
% %Standard function emulating a toggle switch in the menu
% if strcmp(get(hObject, 'Checked'), 'off')
%     set(hObject, 'Checked', 'on');
% else
%     set(hObject, 'Checked', 'off');
% end
% end



function editCountsToShow_Callback(hObject, eventdata, handles)
% hObject    handle to editCountsToShow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editCountsToShow as text
%        str2double(get(hObject,'String')) returns contents of editCountsToShow as a double
end

% --- Executes during object creation, after setting all properties.
function editCountsToShow_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editCountsToShow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function editCountDwellTime_Callback(hObject, eventdata, handles)
% hObject    handle to editCountDwellTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editCountDwellTime as text
%        str2double(get(hObject,'String')) returns contents of editCountDwellTime as a double
    if handles.StateControl.state == StateControl.CURSOR ...
            || handles.StateControl.state == StateControl.TRACKING
        handles.CursorControl.changeDwell();
        handles.CursorControl.runCount(handles);
    end
end

% --- Executes during object creation, after setting all properties.
function editCountDwellTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editCountDwellTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes when user attempts to close ImageScan.
% function ImageScan_CloseRequestFcn(hObject, eventdata, handles)
% % hObject    handle to ImageScan (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hint: delete(hObject) closes the figure
%     if handles.bSimulatedData == false
%         handles.PulseInterpreter.clearPulseblaster();
%     end
%     b=1
%     handles.StateControl.changeToIdleState(handles);
%     b=2
%     handles.ScanControl.currentTab = [];
% %     if ~isempty(handles.SweepControl_standalone.sweepFig)&&get(handles.checkCloseWithScan, 'Value')
% %         handles.SweepControl_standalone.sweepCloseFcn(hObject, eventdata)
% %         handles.SweepControl_standalone.delete();
% %     elseif ~isempty(handles.SweepControl_standalone.sweepFig)&&~get(handles.checkCloseWithScan, 'Value')
% %         set(handles.SweepControl_standalone.useTracking, 'Checked', 'off', 'Enable', 'off', 'Checked', 'off');
% %         set(handles.SweepControl_standalone.setupTracking, 'Enable', 'off');
% %         set(handles.SweepControl_standalone.trackFreqMainMenu, 'Enable', 'off');
% %         set(handles.SweepControl_standalone.checkboxUseTracking, 'Enable', 'off', 'Value', 0);
% %         set(handles.SweepControl_standalone.listboxTrackFreq, 'Enable', 'off');
% %         set(handles.SweepControl_standalone.buttonTrackingParameters, 'Enable', 'off');
% %         set(handles.SweepControl_standalone.textTrack, 'Enable', 'off');
% %     end
% b=3
%     if ~isempty(handles.GonioGUI.gonioFig)
%         handles.GonioGUI.gonioCloseFcn(hObject, eventdata)
%         handles.GonioGUI.delete();
%     end
%     b=4
%     handles.ScanControl.delete();
%     b=5
%     delete(findobj('type', 'figure', 'name', 'ConfigureScan'));
%     delete(findobj('type', 'figure', 'name', 'ConfigureTracking'));
%     b=6
%     handles.StateControl.delete();
%     handles.CursorControl.delete();
%     b=7
%     
%     handles.DAQManager.delete();
%     b=8
%     %delete(hObject)
% end


% --- Executes on button press in checkboxUseTracking.
function checkboxUseTracking_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxUseTracking (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxUseTracking
    if get(handles.checkboxUseTracking,'Value') == true...
            && handles.StateControl.state == StateControl.CURSOR
        handles.StateControl.changeToTrackingState(handles);
    elseif get(handles.checkboxUseTracking,'Value') == false...
            && handles.StateControl.state == StateControl.TRACKING
        %handles.ScanControl.finishScan(handles);
        handles.StateControl.changeToCursorState(handles);
    end
end


% --- Executes on button press in buttonStartStopRunningCount.
function buttonStartStopRunningCount_Callback(hObject, eventdata, handles)
% hObject    handle to buttonStartStopRunningCount (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if handles.StateControl.state == StateControl.CURSOR ...
        || handles.StateControl.state == StateControl.TRACKING
        %handles.ScanControl.finishScan();
        handles.StateControl.changeToIdleState(handles);
    else
        if get(handles.checkboxUseTracking,'Value') == true
            handles.StateControl.changeToTrackingState(handles);
        else
            handles.StateControl.changeToCursorState(handles);
        end
    end
end

% --- Executes on button press in buttonStopRunningCount.
function buttonStopRunningCount_Callback(hObject, eventdata, handles)
% hObject    handle to buttonStopRunningCount (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

end

function editTrackingBoxSize_Callback(hObject, eventdata, handles)
% hObject    handle to editTrackingBoxSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editTrackingBoxSize as text
%        str2double(get(hObject,'String')) returns contents of editTrackingBoxSize as a double
end

% --- Executes during object creation, after setting all properties.
function editTrackingBoxSize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editTrackingBoxSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in buttonOpenFreqSweep.
function buttonOpenFreqSweep_Callback(hObject, eventdata, handles)
% hObject    handle to buttonOpenFreqSweep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% uncomment these 5 lines for old GUI
%if isempty(handles.SweepControl_standalone.sweepFig)
%    handles.SweepControl_standalone.CreateFigure('large', handles);
%else
%    figure(handles.SweepControl_standalone.sweepFig);
%end

% new ESR control GUI (March 2013)
    handles = guidata(hObject);
    handles.ESRControl = ESRControl(handles.EsrGlobalMethods,...
                                    handles.EsrCWSweep,...
                                    handles.EsrPulsedSweep,...
                                    handles.EsrAutomation);
    guidata(handles.output, handles);
    
    handles.EsrCWSweep.UpdateHandles(handles);
    handles.EsrPulsedSweep.UpdateHandles(handles);
    handles.EsrGlobalMethods.UpdateHandles(handles);
    handles.EsrAutomation.UpdateHandles(handles);
end


% --- Executes during object creation, after setting all properties.
function buttonOpenFreqSweep_CreateFcn(hObject, eventdata, handles)
% hObject    handle to buttonOpenFreqSweep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
end





% --- Executes on button press in buttonSetupTracking.
function buttonSetupTracking_Callback(hObject, eventdata)
% hObject    handle to buttonSetupTracking (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);
%     ConfigureTracking(handles.ScanControl.TrackingParameters(find(get(...
%         handles.tabGroup, 'Children')==handles.ScanControl.currentTab)));
    ConfigureTracking(handles.ScanControl.TrackingParameters(1));
    guidata(handles.output, handles);
end


% --- Executes on button press in buttonZoomToBox.
function buttonZoomToBox_Callback(hObject, eventdata)
% hObject    handle to buttonZoomToBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);
%     if handles.StateControl.state == StateControl.IDLE
%         if isempty(handles.CursorControl.hZoomBox) == false
%             
%             tab = get(handles.tabGroup, 'SelectedTab');
%             index = find(get(handles.tabGroup, 'Children')' == tab);
%             %bounds = getPosition(handles.CursorControl.hZoomBox(index));
%             %[xmin ymin width height]
%             currentAxes = get(tab, 'UserData');
%             set(currentAxes, 'YLim', [bounds(2), (bounds(2)+bounds(4))],...
%                 'XLim', [bounds(1), (bounds(1)+bounds(3))]);
%             
%             if ~isempty(hObject)
%             set(hObject, 'State', 'off');
%             end
%             axis equal
%         end
%     end
end

% --- Executes on button press in checkUseZoomboxLimits.
function checkUseZoomboxLimits_Callback(hObject, eventdata, handles)
% hObject    handle to checkUseZoomboxLimits (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkUseZoomboxLimits
end

function zoomOutCallback(hObject, ~, handles)
%Zooms back out to the maximum size allowed. Double-clicking this button resets the
%scan parameters to the maximum size allowed also.
%tab = get(handles.tabGroup, 'SelectedTab');
set(hObject, 'State', 'off');

% xlim and ylim will now be in µm, so translate from voltages on DAQ props.
% the accessed index of ScanParameters will not matter since microns to
% volts conversion will be the same for all tabs, so just use "1"
mpvx = handles.ScanControl.ScanParameters(1).micronsPerVoltX;
mpvy = handles.ScanControl.ScanParameters(1).micronsPerVoltY;
xlim = [handles.DAQManager.DAQ.AnalogOutMinVoltages(1)*mpvx, handles.DAQManager.DAQ.AnalogOutMaxVoltages(1)*mpvx];
ylim = [handles.DAQManager.DAQ.AnalogOutMinVoltages(2)*mpvy, handles.DAQManager.DAQ.AnalogOutMaxVoltages(2)*mpvy];
% if all(get(get(tab, 'UserData'), 'XLim') == xlim) &&...
%         all(get(get(tab, 'UserData'), 'YLim')==ylim)
%     index = get(handles.tabGroup, 'SelectedIndex');
%     handles.ScanControl.ScanParameters(index).MinValues(1:2) = [xlim(1) ylim(1)];
%     handles.ScanControl.ScanParameters(index).MaxValues(1:2) = [xlim(2) ylim(2)];
% else
%     set(get(tab, 'UserData'), 'XLim', xlim);
%     set(get(tab, 'UserData'), 'YLim', ylim);
% end
%handles.ScanControl.ScanParameters(1).MinValues(1:2) = [xlim(1) ylim(1)];
%handles.ScanControl.ScanParameters(1).MaxValues(1:2) = [xlim(2) ylim(2)];
set(handles.confocalAxes, 'XLim', xlim);
set(handles.confocalAxes, 'YLim', ylim);

end

function helpCallback(~, ~)
%Load the help documentation (which hasn't been started yet).
    helpview('ImageScanHelp.htm');
end

function menuToggleFcn(hObject, ~)
%Standard menu-item callback that emulates a toggle-style button
if strcmp(get(hObject, 'Checked'), 'on')
    set(hObject, 'Checked', 'off');
else
    set(hObject, 'Checked', 'on');
end
end

% function loadFile_Callback(~, ~, handles)
% %Loads a file and then draws it in the open tab.
% 
% [filename pathname] = uigetfile({'*.txt', 'Tab-delimited Text File (*.txt)';...
%     '*.csv', 'CSV File (*.csv)'; '*.xsl', 'Microsoft Excel Spreadsheet (*.xls)';...
%     '*.tiff', 'TIFF Image (*.tiff)'; '*.*', 'All Files (*.*)'}, 'Select image to load');
% if isempty(filename)
%     return
% end
% if isnumeric(filename)
%     return
% end
% fid = fopen([pathname filename]);
% if fid == -1
%     fclose(fid);
%     return
% end
% [~, ~, ext] = fileparts(filename);
%     switch ext
%         case {'.txt', 'csv'}
%             outString = fileread(filename);
%             q = find(arrayfun(@(x)strcmp(x, sprintf('\n')), outString), 20, 'first');
%             if isempty(q)
%                 q = 1;
%             end
%             dat = str2num(outString(q(end):end));
%             temp1 = find(arrayfun(@(x)strcmp(x, ':'), outString(q(6):q(7))), 1, 'first')+1;
%             temp2 = find(arrayfun(@(x)strcmp(x, '$'), outString(q(6):q(7))), 1, 'first')+1;
%             xlim(1) = str2num(outString(q(6)+temp1-1:q(6)+temp2-4));
%             temp1 = find(arrayfun(@(x)strcmp(x, ':'), outString(q(7):q(8))), 1, 'first')+1;
%             temp2 = find(arrayfun(@(x)strcmp(x, '$'), outString(q(7):q(8))), 1, 'first')+1;
%             xlim(2) = str2num(outString(q(7)+temp1-1:q(7)+temp2-4));
%             temp1 = find(arrayfun(@(x)strcmp(x, ':'), outString(q(10):q(11))), 1, 'first')+1;
%             temp2 = find(arrayfun(@(x)strcmp(x, '$'), outString(q(10):q(11))), 1, 'first')+1;
%             ylim(1) = str2num(outString(q(10)+temp1-1:q(10)+temp2-4));
%             temp1 = find(arrayfun(@(x)strcmp(x, ':'), outString(q(11):q(12))), 1, 'first')+1;
%             temp2 = find(arrayfun(@(x)strcmp(x, '$'), outString(q(11):q(12))), 1, 'first')+1;
%             ylim(2) = str2num(outString(q(11)+temp1-1:q(11)+temp2-4));
%             currentAxes = get(get(handles.tabGroup, 'SelectedTab'), 'UserData');
%             imagesc(xlim, ylim, dat, 'Parent', currentAxes);
%             set(currentAxes, 'XLim', xlim, 'YLim', ylim);
%         case '.xls'
%             [num text raw] = xlsread(filename);
%             currentAxes = get(get(handles.tabGroup, 'SelectedTab'), 'UserData');
%             xlim = get(currentAxes, 'XLim');
%             ylim = get(currentAxes, 'YLim');
%             imagesc(xlim, ylim, num);
%         case {'.tif', '.tiff'}
%             dat = imread([pathname filename], 'tiff');
%             info = imfinfo(filename)
%             outString = info(1).ImageDescription
%             q = find(arrayfun(@(x)strcmp(x, sprintf('\n')), outString), 20, 'first');
%             if isempty(q)
%                 q = 1;
%             end
%             temp1 = find(arrayfun(@(x)strcmp(x, ':'), outString(q(6):q(7))), 1, 'first')+1;
%             temp2 = find(arrayfun(@(x)strcmp(x, '$'), outString(q(6):q(7))), 1, 'first')+1;
%             xlim(1) = str2num(outString(q(6)+temp1-1:q(6)+temp2-4));
%             temp1 = find(arrayfun(@(x)strcmp(x, ':'), outString(q(7):q(8))), 1, 'first')+1;
%             temp2 = find(arrayfun(@(x)strcmp(x, '$'), outString(q(7):q(8))), 1, 'first')+1;
%             xlim(2) = str2num(outString(q(7)+temp1-1:q(7)+temp2-4));
%             temp1 = find(arrayfun(@(x)strcmp(x, ':'), outString(q(10):q(11))), 1, 'first')+1;
%             temp2 = find(arrayfun(@(x)strcmp(x, '$'), outString(q(10):q(11))), 1, 'first')+1;
%             ylim(1) = str2num(outString(q(10)+temp1-1:q(10)+temp2-4));
%             temp1 = find(arrayfun(@(x)strcmp(x, ':'), outString(q(11):q(12))), 1, 'first')+1;
%             temp2 = find(arrayfun(@(x)strcmp(x, '$'), outString(q(11):q(12))), 1, 'first')+1;
%             ylim(2) = str2num(outString(q(11)+temp1-1:q(11)+temp2-4));
%             currentAxes = get(get(handles.tabGroup, 'SelectedTab'), 'UserData');
%             imagesc(xlim, ylim, dat, 'Parent', currentAxes);
%             set(currentAxes, 'XLim', xlim, 'YLim', ylim);
%     end
% end

% function tab = newTab(handles, oldTab, bSaveParam)
% %Creates a new tab, complete with axes and its own color scheme.
% %
% %This program works by turning the existing 'new tab' tab into a standard
% %tab with its own axes, color scheme, and scanning parameters, and then
% %creating a new 'new tab' tab.
% 
% %Check for input arguments
% if ~exist('bSaveParam', 'var')
%     bSaveParam = false;
% end
% if ~exist('oldTab', 'var')
%     bSaveParam = false;
%     oldTab = [];
% end
% 
% tabs = get(handles.tabGroup, 'Children'); %get all tabs
% len = length(tabs); %len = number of tabs
% jTabGroup = getappdata(handle(handles.tabGroup),'JTabbedPane');
% 
% %If there is only one normal tab (2 tabs including the 'new tab' tab), then
% %the close button on that tab is hidden, so we make it visible again
% if len == 2
%     jPanel = jTabGroup.getTabComponentAt(0);
%     jcoms = jPanel.getComponents();
%     if ~isempty(jcoms)
%         for i = 0:(size(jcoms, 1)-1)
%             if strcmp(class(jcoms(i+1)), 'javax.swing.JButton')
%                 try
%                     set(jcoms(i+1), 'Visible', true);
%                 catch err
%                     set(jcoms(i+1), 'Visible', 'on');
%                 end
%             end
%         end
%     end
% end
% 
%     %Add the close button to the new tab
%     % First let's load the close icon
% jarFile = fullfile(matlabroot,'/java/jar/mwt.jar');
% iconsFolder = '/com/mathworks/mwt/resources/';
% iconURI = ['jar:file:/' jarFile '!' iconsFolder 'closebox.gif'];
% icon = javax.swing.ImageIcon(java.net.URL(iconURI));
%     % Now let's prepare the close button: icon, size and callback
% jCloseButton = handle(javax.swing.JButton,'CallbackProperties');
% jCloseButton.setIcon(icon);
% jCloseButton.setPreferredSize(java.awt.Dimension(15,15));
% jCloseButton.setMaximumSize(java.awt.Dimension(15,15));
% jCloseButton.setSize(java.awt.Dimension(15,15));
% jCloseButton.Border = [];
% set(jCloseButton, 'ActionPerformedCallback',{@tabDelete, tabs(len)});
%  
%     % Now let's prepare a tab panel with our label and close button
% jPanel = javax.swing.JPanel;	% default layout = FlowLayout
% set(jPanel.getLayout, 'Hgap',0, 'Vgap',0);  % default gap = 5px
% jLabel = javax.swing.JLabel(sprintf('Tab #%i  ', len));
% jPanel.add(jLabel);
% jPanel.add(jCloseButton);
% import java.awt.*
% jPanel.setBackground(java.awt.Color(1, 1, 1, 0))
%     % Now attach this tab panel as the tab-group's 2nd component
% jTabGroup.setTabComponentAt(len-1,jPanel);	% Tab #1 = second tab
% tab = tabs(end);
% 
% %Initialize the scan and tracking parameters for the new tab
% handles.ScanControl.ScanParameters(len) = ConfocalScanParameters();
% handles.ScanControl.TrackingParameters(len) = ConfocalScanTrackingParameters();
% 
% %add the axes with a colorbar
% currentAxes = axes('Parent', tab, 'Units', 'pixels', 'Position', [47 42 393 307],...
%     'XLimMode', 'manual', 'YLimMode', 'manual');
% set(tab, 'UserData', currentAxes)
% set(handles.ImageScan, 'CurrentAxes', currentAxes);
% colorbar('peer', currentAxes)
% 
% %If bSaveParam is true, then the settings on the previously selected tab
% %are carried over to the new tab. This include scan and tracking
% %parameters, axes limits, and the colormap.
% if bSaveParam
%     oldAxes = get(oldTab, 'UserData');
%     set(currentAxes, 'XLim', get(oldAxes, 'XLim'), 'YLim', get(oldAxes, 'YLim'));
%     ind = find(tabs == oldTab);
%     handles.ScanControl.ScanParameters(len).ImportScan(handles.ScanControl.ScanParameters(ind));
%     if get(handles.checkUseZoomboxLimits, 'Value')
%         xdata = get(oldAxes, 'XLim');
%         ydata = get(oldAxes, 'YLim');
%         handles.ScanControl.ScanParameters(len).MinValues(1:2) = [xdata(1), ydata(1)];
%         handles.ScanControl.ScanParameters(len).MaxValues(1:2) = [xdata(2), ydata(2)];
%     end
%     handles.ScanControl.TrackingParameters(len).ImportScan(handles.ScanControl.TrackingParameters(ind));
%     colorm = get(oldAxes, 'UserData');
%     set(currentAxes, 'UserData', colorm);
%     if colorm.auto
%         set(handles.ImageScan, 'ColorMap', 'default');
%         caxis(currentAxes, 'auto')
%         set(handles.checkboxAutoColorScale, 'Value', 1);
%     else
%         set(handles.ImageScan, 'ColorMap', colorm.cmap);
%         caxis(currentAxes, colorm.cax);
%         set(handles.checkboxAutoColorScale, 'Value', 0);
%     end
% else %If bSaveParam == false
%     set(currentAxes, 'XLim', [-2 2], 'YLim', [-2 2]);
%     set(handles.ImageScan, 'Colormap', 'default');
%     colorm.cmap = get(handles.ImageScan, 'ColorMap');
%     caxis(currentAxes, 'auto')
%     colorm.cax = caxis(currentAxes);
%     colorm.auto = true;
%     set(handles.checkboxAutoColorScale, 'Value', 1);
%     set(currentAxes, 'UserData', colorm);
% end
% tab = tabs(end); %output tab
% uitab(handles.tabGroup, 'title', '+'); %recreate the 'new tab' tab
% end

% function tabGroup_callback(hObject, eventdata)
% %SelectionChangeCallback for the tab group - runs whenever the currently
% %selected tab is changed, either programmatically or manually
% drawnow();
% handles = guidata(hObject); %retrieve the handles structure
% %Store the current colormap as the UserData in the axes of the old tab
% colorm.cmap = get(handles.ImageScan, 'Colormap');
% oldAxes = get(eventdata.OldValue, 'UserData');
% colorm.cax = caxis(oldAxes);
% colorm.auto = get(handles.checkboxAutoColorScale, 'Value');
% set(oldAxes, 'UserData', colorm);
% tabs = get(handles.tabGroup, 'Children');
% 
% if eventdata.NewValue == tabs(end)
%     %If the tab selected was the 'new tab' tab
%     newTab(handles, eventdata.OldValue, handles.shiftOn);
% else %If we selected a normal tab
%     %Set the colormap to what is specified in the UserData for the axes in
%     %this tab
%     currentAxes = get(eventdata.NewValue, 'UserData');
%     colorm = get(currentAxes, 'UserData');
%     if colorm.auto == true
%         set(handles.ImageScan, 'Colormap', 'default')
%         caxis(currentAxes, 'auto');
%         set(handles.checkboxAutoColorScale, 'Value', 1);
%     else
%         set(handles.ImageScan, 'Colormap', colorm.cmap);
%         caxis(currentAxes, colorm.cax);
%         set(handles.checkboxAutoColorScale, 'Value', 0);
%     end
% end
% if (handles.StateControl.state == handles.StateControl.CURSOR) ||...
%         (handles.StateControl.state == handles.StateControl.IDLE)
%     %If we aren't scanning or tracking, then we can change the currentTab
%     %property to the newly-selected tab, and move the cursor to it
%     handles.CursorControl.deleteManualCursor(handles);
%     handles.ScanControl.currentTab = eventdata.NewValue;
%     handles.CursorControl.createManualCursor(handles);
% end
% end

% function tabDelete(~, ~, tabHandle)
% %Deletes the tab that the button is placed on.
% 
% handles = guidata(get(tabHandle, 'Parent')); %retrieve the handles structure
% set(handles.tabGroup, 'SelectionChangeCallback', []);%Deleting a tab can run the SelectionChangeCallback fcn, which we don't want
% if (handles.StateControl.state == handles.StateControl.TRACKING ||...
%         handles.StateControl.state == handles.StateControl.SCANNING)
%     %Problems happen when we try to delete a tab during a scan, so I'm not
%     %going to let that happen.
%     set(handles.tabGroup, 'SelectionChangeCallback', @tabGroup_callback);
%     return
% end
% jTabGroup = getappdata(handle(handles.tabGroup),'JTabbedPane');
% tabs = get(handles.tabGroup, 'Children'); %get all the tabs
% 
% %If we deleted the tab that was set as the currentTab, then we need to not
% %that the currentTab property has to be changed after we've deleted this
% %tab
% bChangeScanTab = false;
% if tabHandle == handles.ScanControl.currentTab
%     bChangeScanTab = true;
% end
% 
% index = find(tabs == tabHandle);%Get the number of the tab being deleted
% 
% %If for some reason there are only 2 tabs and this function got called on
% %one of them, then we need to just return
% if length(tabs) <= 2
%     set(handles.tabGroup, 'SelectionChangeCallback', {@tabGroup_callback, handles});
%     return
% end
% 
% %This should only happen in extreme cases where things go really wrong
% if length(index) ~= 1
%     error('Something went wrong with the tabs, but I dont know where it could have happened')
% end
% 
% %I included this chunk to try to fix the bug with the color scale where
% %deleting tab you are on causes the color scale for the tab 2 after this
% %one to get messed up. This did not fix the problem, but I just left it in
% %because I don't know how to fix the issue.
% %
% %If the user deletes a tab that would cause this problem, then we save the
% %color data for the tab that will get messed up, and try to re-apply it
% %later.
% %
% %Some of this needs to stay though. This bit of code also controls which
% %tab is the next to be selected when the user deletes the tab he is on.
% bWorkAround = false;
% if tabHandle == get(handles.tabGroup, 'SelectedTab')
%     switch index
%         case length(tabs)
%             set(handles.tabGroup, 'SelectedTab', tabs(1));
%         case (length(tabs)-1)
%             set(handles.tabGroup, 'SelectedTab', tabs(index-1));
%         otherwise
%             if get(handles.tabGroup, 'SelectedIndex') == index && (index < (length(tabs)-2))
%                 bWorkAround = true;
%                 tabcm = tabs(index+2);
%                 axcm = get(tabcm, 'UserData');
%                 colorcm = get(axcm, 'UserData');
%             end
%             set(handles.tabGroup, 'SelectedTab', tabs(index+1));
%     end
% end
% 
% %handles.CursorControl.deleteZoomBox(handles,tabHandle);
% delete(get(tabHandle, 'UserData'));                 %Delete the axes from the tab
% delete(tabHandle);                                  %Delete the tab itself
% handles.ScanControl.ScanParameters(index) = [];     %Clear the scan parameters for the tab
% handles.ScanControl.TrackingParameters(index) = []; %Clear the tracking parameters for the tab
% %handles.CursorControl.hZoomBox(index) = [];
% 
% %Set the color scheme to what is specified in the new tab
% currentAxes = get(get(handles.tabGroup, 'SelectedTab'), 'UserData');
% colorm = get(currentAxes, 'UserData');
% if colorm.auto
%     set(handles.ImageScan, 'Colormap', 'default');
%     caxis(currentAxes, 'auto')
%     set(handles.checkboxAutoColorScale, 'Value', 1);
% else
%     set(handles.ImageScan, 'Colormap', colorm.cmap);
%     caxis(currentAxes, colorm.cax);
%     set(handles.checkboxAutoColorScale, 'Value', 0)
% end
% drawnow();
% 
% %Now, I remake all the close buttons for each tab. I'm not sure if I have
% %to do this anymore, as this is from a time when this function worked a bit
% %differently, but it doesn't really hurt to have, and I might still need
% %it.
% %
% %Anyways, this is exactly the same as the normal creation of a close
% %button, but performed on each individual tab.
% tabs = get(handles.tabGroup, 'Children');
% len = length(tabs);
% jarFile = fullfile(matlabroot,'/java/jar/mwt.jar');
% iconsFolder = '/com/mathworks/mwt/resources/';
% iconURI = ['jar:file:/' jarFile '!' iconsFolder 'closebox.gif'];
% icon = javax.swing.ImageIcon(java.net.URL(iconURI));
% import java.awt.*
% for i = 0:len-1
%     jPanel = jTabGroup.getTabComponentAt(i);
%     if ~isempty(jPanel)
%         jPanel.setVisible(false);
%         jCloseButton = handle(javax.swing.JButton,'CallbackProperties');
%         jCloseButton.setIcon(icon);
%         jCloseButton.setPreferredSize(java.awt.Dimension(15,15));
%         jCloseButton.setMaximumSize(java.awt.Dimension(15,15));
%         jCloseButton.setSize(java.awt.Dimension(15,15));
%         jCloseButton.Border = [];
%         set(jCloseButton, 'ActionPerformedCallback',{@tabDelete, tabs(i+1)});
% 
%             % Now let's prepare a tab panel with our label and close button
%         jPanel = javax.swing.JPanel;	% default layout = FlowLayout
%         set(jPanel.getLayout, 'Hgap',0, 'Vgap',0);  % default gap = 5px
%         jLabel = javax.swing.JLabel(sprintf('Tab #%i  ', i+1));
%         jPanel.add(jLabel);
%         jPanel.add(jCloseButton);
%         jPanel.setBackground(java.awt.Color(1, 1, 1, 0))
%             % Now attach this tab panel as the tab-group's 2nd component
%         jTabGroup.setTabComponentAt(i,jPanel);	% Tab #1 = second tab
%     end
% end
% %If we now only have 1 standard tab (2 with the 'new tab' tab), then we
% %need to hide the close button on that tab
% if len == 2
%     jPanel = jTabGroup.getTabComponentAt(0);
%     jcoms = jPanel.getComponents();
%     if ~isempty(jcoms)
%         for i = 0:(size(jcoms, 1)-1)
%             if strcmp(class(jcoms(i+1)), 'javax.swing.JButton')
%                 try
%                     set(jcoms(i+1), 'Visible', false);
%                 catch err
%                     set(jcoms(i+1), 'Visible', 'off');
%                 end
%             end
%         end
%     end
% end
% %Make sure we don't have the 'new tab' tab selected, just incase
% if get(handles.tabGroup, 'SelectedIndex') == len
%     set(handles.tabGroup, 'SelectedIndex', len-1);
% end
% if bChangeScanTab %Change the currentTab property to reflect the new selected tab
%     if (handles.StateControl.state == handles.StateControl.CURSOR) ||...
%             (handles.StateControl.state == handles.StateControl.IDLE)
%         %only change if we are not scanning or tracking
%         handles.ScanControl.currentTab = get(handles.tabGroup, 'SelectedTab');
%         handles.CursorControl.createManualCursor(handles);
%     end
% end
% if bWorkAround %Try the work-around that didn't work
%     set(axcm, 'UserData', colorcm);
% end
% %reset the SelectionChangeCallback function for the tab group, and end
% set(handles.tabGroup, 'SelectionChangeCallback', @tabGroup_callback);
% end




% --- Executes on button press in buttonAOMOn.
function buttonAOMOn_Callback(hObject, ~, handles)
% hObject    handle to buttonAOMOn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of buttonAOMOn
handles.listNVMarkerPos(1,:);
handles.listNVMarkerPos(2,:);

if handles.configS.bHaveInverterBoard == 1
    
   
    
    if get(hObject, 'Value') == false
        %handles.PulseInterpreter.setCurrentPulse('C:\Users\lab\Documents\code\MATLAB\NewPulseBlaster\SavedPulseSequences\bit1_on.txt');
        handles.PulseInterpreter.setCurrentPulse([handles.configS.sequenceFolder 'bit1_on.txt']);
        handles.PulseInterpreter.loadToPulseblaster();
        handles.PulseInterpreter.runPulse();
        set(hObject, 'String', 'Turn AOM On');
    else
        handles.PulseInterpreter.stopPulse();
        set(hObject, 'String', 'Turn AOM Off');
    end
    
else
    if get(hObject, 'Value') == true
        %handles.PulseInterpreter.setCurrentPulse('C:\Users\lab\Documents\code\MATLAB\NewPulseBlaster\SavedPulseSequences\bit1_on.txt');
        handles.PulseInterpreter.setCurrentPulse([handles.configS.sequenceFolder 'bit1_on.txt']);
        handles.PulseInterpreter.loadToPulseblaster();
        handles.PulseInterpreter.runPulse();
        set(hObject, 'String', 'Turn AOM Off');
    else
        handles.PulseInterpreter.stopPulse();
        set(hObject, 'String', 'Turn AOM On');
    end
end

end





function setAOMCallback(hObject, ~, whichPort)
%Sets the output port of the AOM to what the user specifies. Causes the AOM
%menu to work like a standard selection menu.
    handles = guidata(hObject);
    handles.PulseInterpreter.stopPulse();
    handles.PulseInterpreter.resetPulseblaster();
    children = get(handles.aomMenu, 'Children')';
    arrayfun(@(hand)set(hand, 'Checked', 'off'), children);
    switch whichPort
        case 1
            handles.PulseInterpreter.setCurrentPulse('C:\Users\lab\Documents\code\MATLAB\NewPulseBlaster\SavedPulseSequences\bit1_on.txt')
            set(children(4), 'Checked', 'on');
        case 2
            handles.PulseInterpreter.setCurrentPulse('C:\Users\lab\Documents\code\MATLAB\NewPulseBlaster\SavedPulseSequences\bit2_on.txt')
            set(children(3), 'Checked', 'on');
        case 3
            handles.PulseInterpreter.setCurrentPulse('C:\Users\lab\Documents\code\MATLAB\NewPulseBlaster\SavedPulseSequences\bit3_on.txt')
            set(children(2), 'Checked', 'on');
        case 4
            handles.PulseInterpreter.setCurrentPulse('C:\Users\lab\Documents\code\MATLAB\NewPulseBlaster\SavedPulseSequences\bit4_on.txt')
            set(children(1), 'Checked', 'on');
    end
    handles.PulseInterpreter.loadToPulseblaster();
    if get(handles.buttonAOMOn, 'Value')
        handles.PulseInterpreter.runPulse();
    end
end

function cancelZoom(hObject, ~)
    handles = guidata(hObject);
    set(zoom(handles.ImageScan), 'Enable', 'off');
end


% --- Executes on button press in buttonSaveHistory.
function buttonSaveHistory_Callback(hObject, eventdata, handles)
% hObject    handle to buttonSaveHistory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    handles.CursorControl.saveCountHistory(handles);
end


% --- Executes on button press in buttonOpenMagnet.
function buttonOpenMagnet_Callback(hObject, eventdata, handles)
% hObject    handle to buttonOpenMagnet (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%if isempty(handles.MagnetPLScan)
handles.MagnetPLScan = MagnetPLScan(handles);
    handles = guidata(hObject);
    guidata(handles.output, handles);
%else
%    figure(handles.GonioGUI.gonioFig);
%end
end


% --- Executes on button press in buttonTrackingParameters.
function buttonTrackingParameters_Callback(hObject, eventdata, handles)
% hObject    handle to buttonTrackingParameters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);
%     ConfigureTracking(handles.ScanControl.TrackingParameters(find(get(...
%         handles.tabGroup, 'Children')==handles.ScanControl.currentTab)));
    ConfigureTracking(handles.ScanControl.TrackingParameters(1), handles.DAQManager.DAQ);
    guidata(handles.output, handles);
end


% --- Executes on button press in buttonOpenAFMControl.
function buttonOpenAFMControl_Callback(hObject, eventdata, handles)
% hObject    handle to buttonOpenAFMControl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);
    % pass in the handle to the AFMScanPLImages instance
    
    if handles.configS.bHaveNanoscopeAFM == 1
        
        if handles.bInitNanoscope == 1
            handles.AFMControl = AFMControl(handles.AFMImageScan);
        else
            warndlg('Please initialize the Nanoscope COM connection via the ImageScan button.');
        end
        guidata(handles.output, handles);
    
        handles.AFMImageScan.updateHandles(handles);
        
    elseif handles.configS.bHaveZurichInstr == 1
        handles.AFM_gui = AFM_gui(handles,handles.PulseInterpreter,handles.DAQManager.DAQ,...
                           handles.srs);
                       
        guidata(handles.output, handles);
    end
end


% --- Executes on button press in buttonMoveStageToCursor.
% function buttonMoveStageToCursor_Callback(hObject, eventdata, handles)
% % hObject    handle to buttonMoveStageToCursor (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% moveCheck = questdlg('(THIS BUTTON IS NOT DOING ANYTHING AT THE MOMENT. THE STAGE MOTORS ARE NOT THAT REPEATABLE WITH THE CONFOCAL SCAN BUT THE SCANNER IS) Are you sure you want to move the stage to the cursor position? Check that the objective will not be damaged.', ...
% 	'Yes','No');
% 
% % switch moveCheck
% %     case 'Yes'
% %         % stuff
% %         % this should move to a new 'nanoscope' class
% %         dsx = handles.editPositionX;
% %         dsy = handles.editPositionY;
% %         % transform the coordinates from confocal cursor to stage
% %         % positioning
% %         [csx csy csz] = StageGetXYZ; % this actually does return the coordinates in microns
% %         NanoZ.StageMoveXYZ(dsx, dsy, 0, 50); % (x,y,z, percent speed)
% %     case 'No'
% %         % do nothing
% %end
% 
% end

% --- Executes on button press in buttonOpenNanoscopeCOM.
function buttonOpenNanoscopeCOM_Callback(hObject, eventdata, handles)
% hObject    handle to buttonOpenNanoscopeCOM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.NanoZ = actxserver('NanoScope.zApi','\\AFMPC');
handles.NanoZ.methods
handles.NanoZ.get

handles.NanoA = actxserver('NanoScope.OpenArchitecture','\\AFMPC');
handles.NanoA.methods
handles.NanoA.get

% check if it gave an error. If so, no handle will be returned to the
% variable NanoZ, in which case we don't want to enable AFM-related buttons

% change visible status on ImageScan GUI, disable button
handles.bInitNanoscope = 1;
set(handles.textNanoscopeInit,'String','Initialized');
set(hObject,'Enable','Off'); 
guidata(handles.output, handles);

end



function inputStationaryNDFilter_Callback(hObject, eventdata, handles)
% hObject    handle to inputStationaryNDFilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

statND = str2double(get(handles.inputStationaryNDFilter,'String'));
if isnan(statND)
    statND=0;
end
set(hObject,'String',num2str(statND));
if ~isempty(handles.FilterWheel)
    handles.FilterWheel.changeODIndicator(handles);
else
    set(handles.outputCombinedOD,'String',get(handles.inputStationaryNDFilter,'String'));
end
    
% Hints: get(hObject,'String') returns contents of inputStationaryNDFilter as text
%        str2double(get(hObject,'String')) returns contents of inputStationaryNDFilter as a double
end

% --- Executes during object creation, after setting all properties.
function inputStationaryNDFilter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to inputStationaryNDFilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in buttonNDpos1.
function buttonNDpos1_Callback(hObject, eventdata, handles)
% hObject    handle to buttonNDpos1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.FilterWheel.goToFilter(handles, 1);

end


% --- Executes on button press in buttonNDpos2.
function buttonNDpos2_Callback(hObject, eventdata, handles)
% hObject    handle to buttonNDpos2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.FilterWheel.goToFilter(handles, 2);
end

% --- Executes on button press in buttonNDpos3.
function buttonNDpos3_Callback(hObject, eventdata, handles)
% hObject    handle to buttonNDpos3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.FilterWheel.goToFilter(handles, 3);
end

% --- Executes on button press in buttonNDpos4.
function buttonNDpos4_Callback(hObject, eventdata, handles)
% hObject    handle to buttonNDpos4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.FilterWheel.goToFilter(handles, 4);
end

% --- Executes on button press in buttonNDpos5.
function buttonNDpos5_Callback(hObject, eventdata, handles)
% hObject    handle to buttonNDpos5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.FilterWheel.goToFilter(handles, 5);
end

% --- Executes on button press in buttonNDpos6.
function buttonNDpos6_Callback(hObject, eventdata, handles)
% hObject    handle to buttonNDpos6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.FilterWheel.goToFilter(handles, 6);
end


% --- Executes on button press in buttonDetectionFilterPos1.
function buttonDetectionFilterPos1_Callback(hObject, eventdata, handles)
% hObject    handle to buttonDetectionFilterPos1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.FilterWheel2.goToFilter(handles, 1);
end

% --- Executes on button press in buttonDetectionFilterPos2.
function buttonDetectionFilterPos2_Callback(hObject, eventdata, handles)
% hObject    handle to buttonDetectionFilterPos2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.FilterWheel2.goToFilter(handles, 2);
end


% --- Executes on button press in buttonDetectionFilterPos3.
function buttonDetectionFilterPos3_Callback(hObject, eventdata, handles)
% hObject    handle to buttonDetectionFilterPos3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.FilterWheel2.goToFilter(handles, 3);
end

% --- Executes on button press in buttonDetectionFilterPos4.
function buttonDetectionFilterPos4_Callback(hObject, eventdata, handles)
% hObject    handle to buttonDetectionFilterPos4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.FilterWheel2.goToFilter(handles, 4);
end

% --- Executes on button press in buttonDetectionFilterPos5.
function buttonDetectionFilterPos5_Callback(hObject, eventdata, handles)
% hObject    handle to buttonDetectionFilterPos5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.FilterWheel2.goToFilter(handles, 5);
end

% --- Executes on button press in buttonDetectionFilterPos6.
function buttonDetectionFilterPos6_Callback(hObject, eventdata, handles)
% hObject    handle to buttonDetectionFilterPos6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.FilterWheel2.goToFilter(handles, 6);
end



function inputSaveImagePath_Callback(hObject, eventdata, handles)
% hObject    handle to inputSaveImagePath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of inputSaveImagePath as text
%        str2double(get(hObject,'String')) returns contents of inputSaveImagePath as a double
end

% --- Executes during object creation, after setting all properties.
function inputSaveImagePath_CreateFcn(hObject, eventdata, handles)
% hObject    handle to inputSaveImagePath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function inputSaveImageFilePrefix_Callback(hObject, eventdata, handles)
% hObject    handle to inputSaveImageFilePrefix (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of inputSaveImageFilePrefix as text
%        str2double(get(hObject,'String')) returns contents of inputSaveImageFilePrefix as a double
end

% --- Executes during object creation, after setting all properties.
function inputSaveImageFilePrefix_CreateFcn(hObject, eventdata, handles)
% hObject    handle to inputSaveImageFilePrefix (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function inputSaveImageFileNum_Callback(hObject, eventdata, handles)
% hObject    handle to inputSaveImageFileNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

input = floor(str2num(get(hObject,'String')));
if input>9999
    input=9999;
end
output = sprintf('%04d', input);
set(hObject,'String',output);
% also set the counter to be this number
handles.ScanControl.imageSaveCounter = input;

% Hints: get(hObject,'String') returns contents of inputSaveImageFileNum as text
%        str2double(get(hObject,'String')) returns contents of inputSaveImageFileNum as a double
end

% --- Executes during object creation, after setting all properties.
function inputSaveImageFileNum_CreateFcn(hObject, eventdata, handles)
% hObject    handle to inputSaveImageFileNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in buttonSetupScanFromGUI.
function buttonSetupScanFromGUI_Callback(hObject, eventdata, handles)
% hObject    handle to buttonSetupScanFromGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    handles = guidata(hObject);
%     ConfigureScan(handles.ScanControl.ScanParameters(find(get(...
%         handles.tabGroup, 'Children')==handles.ScanControl.currentTab)),...
%         str2double(get(handles.editPositionX,'String')),...
%         str2double(get(handles.editPositionY,'String')));
    ConfigureScan(handles.ScanControl.ScanParameters(1),...
        str2double(get(handles.editPositionX,'String')),...
        str2double(get(handles.editPositionY,'String')),handles);
end


% --- Executes on button press in buttonOpenColormapEditor.
function buttonOpenColormapEditor_Callback(hObject, eventdata, handles)
% hObject    handle to buttonOpenColormapEditor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = guidata(hObject);
    set(handles.checkboxAutoColorScale, 'Value', 0);
    colormapeditor;
end


% --- Executes on button press in checkboxScanContinuous.
function checkboxScanContinuous_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxScanContinuous (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxScanContinuous
end


% --- Executes on button press in checkboxAutoColorScale.
function checkboxAutoColorScale_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxAutoColorScale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxAutoColorScale

handles = guidata(hObject); %Get 'handles'
    if get(hObject, 'Value')==true
        %If the auto color scale button is being checked on
        set(handles.ImageScan, 'Colormap', pink(64));
        caxis auto;
        %set(hObject, 'Value', 1);
        %Note this in the userdata for the axes
        currentAxes = handles.confocalAxes;
        colorm = get(currentAxes, 'UserData');
        colorm.auto = true;
        set(currentAxes, 'UserData', colorm);
    else
        %If the auto color scale button is being checked off
        %set(hObject, 'Value', 0);
        currentAxes = handles.confocalAxes;
        colorm = get(currentAxes, 'UserData');
        colorm.auto = false;
        %set(handles.ImageScan, 'Colormap', colorm.cmap);
        %caxis(currentAxes, colorm.cax);
        set(currentAxes, 'UserData', colorm);
    end
end


% --- Executes on button press in buttonStartLaserCursor.
function buttonStartLaserCursor_Callback(hObject, eventdata, handles)
% hObject    handle to buttonStartLaserCursor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);
% We would like to only access this tool if not scanning or tracking
% it is okay to use it if we are doing a running count, however.
if handles.StateControl.state ~= handles.StateControl.SCANNING && handles.StateControl.state~=handles.StateControl.TRACKING
    
    [pointX,pointY] = ginput(1);

    % check if these are within the current limits of the axes. If they are not
    % we interpret this out of bounds click as the user "cancelling" the use of
    % the Laser Cursor ginput.
    xlim = get(handles.confocalAxes,'XLim');
    ylim = get(handles.confocalAxes,'YLim');

    if (pointX>xlim(1) && pointX<xlim(2) && pointY>ylim(1) && pointY<ylim(2))
        set(handles.editPositionX,'String',num2str(pointX));
        set(handles.editPositionY,'String',num2str(pointY));

        % need to update the graphical cursor:
        handles.CursorControl.deleteManualCursor(handles);
        handles.CursorControl.createManualCursor(handles);
        handles.CursorControl.updatePositionFromCursor(handles,[pointX,pointY]);
    end
end

end


% --- Executes on button press in buttonMakeNVMarker.
function buttonMakeNVMarker_Callback(hObject, eventdata, handles)
% hObject    handle to buttonMakeNVMarker (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);
if handles.StateControl.state ~= handles.StateControl.SCANNING && handles.StateControl.state~=handles.StateControl.TRACKING
    [pointX,pointY] = ginput(1);

    % check if these are within the current limits of the axes. If they are not
    % we interpret this out of bounds click as the user "cancelling" the use of
    % the Laser Cursor ginput.
    xlim = get(handles.confocalAxes,'XLim');
    ylim = get(handles.confocalAxes,'YLim');

    if (pointX>xlim(1) && pointX<xlim(2) && pointY>ylim(1) && pointY<ylim(2))

        currentAxes = handles.confocalAxes;
        numM = str2double(get(handles.NVmarkerNumber,'String'));
        % check if there is already a label for this number
        colorM = 'none';
        if get(handles.checkboxMarker15N,'Value')==1
            colorM='red';
            handles.listNVMarkerType(numM) = 15;

        elseif get(handles.checkboxMarker14N,'Value')==1
            colorM='green';
            handles.listNVMarkerType(numM) = 14;
        else
            colorM='none';
            handles.listNVMarkerType(numM) = -1;
        end
        handles.listNVMarkerPos(1,numM) = pointX;
        handles.listNVMarkerPos(2,numM) = pointY;
        if handles.listNVMarkers(numM) ==0

            hold(currentAxes,'on');
            newMark = text(pointX,pointY,['\color{cyan}' get(handles.NVmarkerLetter,'String') get(handles.NVmarkerNumber,'String')],'FontSize',10,'HorizontalAlignment','center','EdgeColor',colorM,'LineStyle',':');
            handles.listNVMarkers(numM) = newMark;
            hold(currentAxes,'off');
        else
           % overwrite the marker.
           delete(handles.listNVMarkers(numM));
           handles.listNVMarkers(numM) = 0;

           hold(currentAxes,'on');
           newMark = text(pointX,pointY,['\color{cyan}' get(handles.NVmarkerLetter,'String') get(handles.NVmarkerNumber,'String')],'FontSize',10,'HorizontalAlignment','center','EdgeColor',colorM,'LineStyle',':');
           handles.listNVMarkers(numM) = newMark;
           hold(currentAxes,'off');
        end
        
        % increase counter
        set(handles.NVmarkerNumber,'String',num2str(numM+1));
    end
end
guidata(handles.output, handles);
end


function NVmarkerLetter_Callback(hObject, eventdata, handles)
% hObject    handle to NVmarkerLetter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of NVmarkerLetter as text
%        str2double(get(hObject,'String')) returns contents of NVmarkerLetter as a double
end

% --- Executes during object creation, after setting all properties.
function NVmarkerLetter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NVmarkerLetter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function NVmarkerNumber_Callback(hObject, eventdata, handles)
% hObject    handle to NVmarkerNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);
input = floor(str2double(get(hObject,'String')));
if input > handles.maxLabel
    input = handles.maxLabel;
end
set(hObject,'String',num2str(input));
guidata(handles.output, handles);
% Hints: get(hObject,'String') returns contents of NVmarkerNumber as text
%        str2double(get(hObject,'String')) returns contents of NVmarkerNumber as a double
end

% --- Executes during object creation, after setting all properties.
function NVmarkerNumber_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NVmarkerNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on button press in buttonDeleteNVMarkers.
function buttonDeleteNVMarkers_Callback(hObject, eventdata, handles)
% hObject    handle to buttonDeleteNVMarkers (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

askME = questdlg('Are you sure you want to delete all the markers?','Marker deleteion','Yes','No','No');
switch(askME)
    case 'Yes'
        currentAxes = handles.confocalAxes;
                ind = find(handles.listNVMarkers(:)); % get all nonzero elements
                delete(handles.listNVMarkers(ind));
                handles.listNVMarkers = [];
                handles.listNVMarkers = zeros(1,handles.maxLabel);
                handles.listNVMarkerType = zeros(1,handles.maxLabel);
                handles.listNVMarkerPos = zeros(3,handles.maxLabel);
                set(handles.NVmarkerNumber,'String',num2str(1));
            %end
            if ~isempty(currentAxes)
                hold(currentAxes,'off');
            end
            guidata(handles.output, handles);
end
end


% --- Executes on button press in checkboxMarker15N.
function checkboxMarker15N_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxMarker15N (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);
if get(handles.checkboxMarker14N,'Value')==1
    set(handles.checkboxMarker14N,'Value',0);
end
guidata(handles.output, handles);
% Hint: get(hObject,'Value') returns toggle state of checkboxMarker15N
end

% --- Executes on button press in checkboxMarker14N.
function checkboxMarker14N_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxMarker14N (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);
if get(handles.checkboxMarker15N,'Value')==1
    set(handles.checkboxMarker15N,'Value',0);
end
guidata(handles.output, handles);
% Hint: get(hObject,'Value') returns toggle state of checkboxMarker14N

end


% --- Executes on button press in buttonSaveLoadNVMarkers.
function buttonSaveLoadNVMarkers_Callback(hObject, eventdata, handles)
% hObject    handle to buttonSaveLoadNVMarkers (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);
% save markers to file or load from file
selectAction = questdlg('Save markers or load from file onto image?','NV Markers','Save','Load','Cancel','Cancel');

switch(selectAction)
    case 'Save'
        
        markersOutput.numMarks = handles.maxLabel;
        for knv = 1:markersOutput.numMarks
           mystr = get(handles.NVmarkerLetter,'String');
           eval(['markersOutput.nvType' num2str(knv) '=' num2str(handles.listNVMarkerType(knv)) ';']);
           eval(['markersOutput.markerLetter' num2str(knv) '= mystr;']);
           eval(['markersOutput.pointX' num2str(knv) '=' num2str(handles.listNVMarkerPos(1,knv)) ';']);
           eval(['markersOutput.pointY' num2str(knv) '=' num2str(handles.listNVMarkerPos(2,knv)) ';']);
        end
        
        defaultPath = [handles.configS.sequenceFolder 'NVMarkerMaps\'];
        if exist(defaultPath,'dir') ==0 %path does not exist?
            mkdir(defaultPath);
        end
        [filename fpath ~] = uiputfile('*.nvm','Save NV Markers Map As...',defaultPath);

        tdfwrite([fpath filename],markersOutput);
        
    case 'Load'
        [filename pathname] = uigetfile('*.nvm', 'Select NV Markers Map to Load',...
                    [handles.configS.sequenceFolder 'NVMarkerMaps\']);
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

        markersOutput = tdfread([pathname filename]);
        numMarks = markersOutput.numMarks;
        for jnv = 1:numMarks
            currentAxes = handles.confocalAxes;
            numM = jnv;
            nvType = eval(['markersOutput.nvType' num2str(numM)]);
            % check if there is already a label for this number
            colorM = 'none';
            if nvType==15
                colorM='red';
            elseif nvType==14
                colorM='green';
            else
                colorM='none';
            end
            pointX = eval(['markersOutput.pointX' num2str(numM)]);
            pointY = eval(['markersOutput.pointY' num2str(numM)]);
            markerLetter = eval(['markersOutput.markerLetter' num2str(numM)]);
            set(handles.NVmarkerLetter,'String',markerLetter); % only needs to be set once, but whatever
            handles.listNVMarkerType(1,numM) = nvType;
            if nvType ~= 0 % if 0 then marker is unused and don't create it!!
                handles.listNVMarkerPos(1,numM) = pointX;
                handles.listNVMarkerPos(2,numM) = pointY;
                
                if handles.listNVMarkers(numM) ==0

                    hold(currentAxes,'on');
                    newMark = text(pointX,pointY,['\color{cyan}' markerLetter num2str(numM)],'FontSize',10,'HorizontalAlignment','center','EdgeColor',colorM,'LineStyle',':');
                    handles.listNVMarkers(numM) = newMark;
                    hold(currentAxes,'off');
                else
                   % overwrite the marker.
                   %delete(handles.listNVMarkers(numM));
                   handles.listNVMarkers(numM) = 0;

                   hold(currentAxes,'on');
                   newMark = text(pointX,pointY,['\color{cyan}' markerLetter num2str(numM)],'FontSize',10,'HorizontalAlignment','center','EdgeColor',colorM,'LineStyle',':');
                   handles.listNVMarkers(numM) = newMark;
                   hold(currentAxes,'off');
                end
                % increase counter
                set(handles.NVmarkerNumber,'String',num2str(numM+1));
            end

        end
        
    case 'Cancel' % do nothing
end
guidata(handles.output, handles);
end

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
end


% --- Executes on button press in buttonShiftAllMarkerPosToCurrentNumberPos.
function buttonShiftAllMarkerPosToCurrentNumberPos_Callback(hObject, eventdata, handles)
% hObject    handle to buttonShiftAllMarkerPosToCurrentNumberPos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% this begins the same as if you are creating a new marker specified by the
% letter and number edit boxes.
% first set this letter and number to be the same as the NV to recreate a
% position for, e.g., if you want to move NV k3 then enter 'k' and'3' in
% those boxes.
% click this button to 'Recreate and Shift'. This makes a ginput. Once you
% choose the new position all the other NV markers will be shifted such
% that the relative distances to NV k3 remain the same as before.
handles = guidata(hObject);
if handles.StateControl.state ~= handles.StateControl.SCANNING && handles.StateControl.state~=handles.StateControl.TRACKING
   
    % before setting new position save old position
    numM = str2double(get(handles.NVmarkerNumber,'String'));
    
    if handles.listNVMarkers(numM) == 0 % doesn't exist on image! user cannot shift based on it
        warndlg(['NV marker # ' num2str(numM) ' is non-existent on the image, so it cannot be used as a position reference.'],'Invalid marker operation');
    else
        prevX = handles.listNVMarkerPos(1,numM);
        prevY = handles.listNVMarkerPos(2,numM);

        [pointX,pointY] = ginput(1);
        shiftX = pointX - prevX;
        shiftY = pointY - prevY;

        % check if these are within the current limits of the axes. If they are not
        % we interpret this out of bounds click as the user "cancelling" the use of
        % the Laser Cursor ginput.
        xlim = get(handles.confocalAxes,'XLim');
        ylim = get(handles.confocalAxes,'YLim');

        if (pointX>xlim(1) && pointX<xlim(2) && pointY>ylim(1) && pointY<ylim(2))

            currentAxes = handles.confocalAxes;

            % check if there is already a label for this number
            colorM = 'none';
            if get(handles.checkboxMarker15N,'Value')==1
                colorM='red';
                handles.listNVMarkerType(numM) = 15;

            elseif get(handles.checkboxMarker14N,'Value')==1
                colorM='green';
                handles.listNVMarkerType(numM) = 14;
            else
                colorM='none';
                handles.listNVMarkerType(numM) = -1;
            end
            handles.listNVMarkerPos(1,numM) = pointX;
            handles.listNVMarkerPos(2,numM) = pointY;
            if handles.listNVMarkers(numM) ==0

                hold(currentAxes,'on');
                newMark = text(pointX,pointY,['\color{cyan}' get(handles.NVmarkerLetter,'String') get(handles.NVmarkerNumber,'String')],'FontSize',10,'HorizontalAlignment','center','EdgeColor',colorM,'LineStyle',':');
                handles.listNVMarkers(numM) = newMark;
                hold(currentAxes,'off');
            else
               % overwrite the marker.
               delete(handles.listNVMarkers(numM));
               handles.listNVMarkers(numM) = 0;

               hold(currentAxes,'on');
               newMark = text(pointX,pointY,['\color{cyan}' get(handles.NVmarkerLetter,'String') get(handles.NVmarkerNumber,'String')],'FontSize',10,'HorizontalAlignment','center','EdgeColor',colorM,'LineStyle',':');
               handles.listNVMarkers(numM) = newMark;
               hold(currentAxes,'off');
            end

            % don't increase counter
            %set(handles.NVmarkerNumber,'String',num2str(numM+1));


            % now go through all the NV markers to update positions
            % first retrieve list of indices for "active" markers (nonzero)
            rInd = find(handles.listNVMarkers);


            for pnv = rInd
                if pnv ~= numM% do not include the current index for this
                    colorM = 'none';
                    if handles.listNVMarkerType(pnv) == 15
                        colorM='red';
                    elseif handles.listNVMarkerType(pnv) == 14
                        colorM='green';
                    else
                        colorM='none';
                    end
                    % overwrite the marker.
                    delete(handles.listNVMarkers(pnv));
                    handles.listNVMarkers(pnv) = 0;

                    newX = handles.listNVMarkerPos(1,pnv) + shiftX;
                    newY = handles.listNVMarkerPos(2,pnv) + shiftY;
                    hold(currentAxes,'on');
                    newMark = text(newX,newY,['\color{cyan}' get(handles.NVmarkerLetter,'String') num2str(pnv)],'FontSize',10,'HorizontalAlignment','center','EdgeColor',colorM,'LineStyle',':');
                    handles.listNVMarkers(pnv) = newMark;
                    hold(currentAxes,'off');
                    % replace old position values in the array
                    handles.listNVMarkerPos(1,pnv) = newX;
                    handles.listNVMarkerPos(2,pnv) = newY;
                end
            end
        end
    end
end



guidata(handles.output, handles);
end



function displacementNVB_Callback(hObject, eventdata, handles)
% hObject    handle to displacementNVB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of displacementNVB as text
%        str2double(get(hObject,'String')) returns contents of displacementNVB as a double
if get(handles.radiobuttonDisplacementUnits_um,'Value')==1
    unitFactor = 1;
elseif get(handles.radiobuttonDisplacementUnits_nm,'Value')==1
    unitFactor = 1000;
end

inputOther = str2num(get(handles.displacementNVA,'String'));
input = floor(str2num(get(hObject,'String')));
if input<1 % only input allowed that is <1 is -1, for laser cursor 
    if input ~= -1
        input=1;
    end
end
if input > handles.maxLabel
    input=handles.maxLabel;
end
set(hObject,'String',num2str(input));

% whenever one of these is changed, automatically recalculate the outputs
if input == -1
    NVBx = str2double(get(handles.editPositionX,'String'));
    NVBy = str2double(get(handles.editPositionY,'String'));
else
    NVBx = handles.listNVMarkerPos(1,input);
    NVBy = handles.listNVMarkerPos(2,input);
end
if inputOther ==-1
    NVAx = str2double(get(handles.editPositionX,'String'));
    NVAy = str2double(get(handles.editPositionY,'String'));
else
    NVAx = handles.listNVMarkerPos(1,inputOther);
    NVAy = handles.listNVMarkerPos(2,inputOther);
end
set(handles.dxMarkers,'String',num2str((NVBx - NVAx)*unitFactor));
set(handles.dyMarkers,'String',num2str((NVBy - NVAy)*unitFactor));
end

% --- Executes during object creation, after setting all properties.
function displacementNVB_CreateFcn(hObject, eventdata, handles)
% hObject    handle to displacementNVB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function displacementNVA_Callback(hObject, eventdata, handles)
% hObject    handle to displacementNVA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of displacementNVA as text
%        str2double(get(hObject,'String')) returns contents of displacementNVA as a double
if get(handles.radiobuttonDisplacementUnits_um,'Value')==1
    unitFactor = 1;
elseif get(handles.radiobuttonDisplacementUnits_nm,'Value')==1
    unitFactor = 1000;
end

inputOther = str2num(get(handles.displacementNVB,'String'));
input = floor(str2num(get(hObject,'String')));
if input<1 % only input allowed that is <1 is -1, for laser cursor 
    if input ~= -1
        input=1;
    end
end
if input > handles.maxLabel
    input=handles.maxLabel;
end
set(hObject,'String',num2str(input));

% whenever one of these is changed, automatically recalculate the outputs
if input == -1
    NVAx = str2double(get(handles.editPositionX,'String'));
    NVAy = str2double(get(handles.editPositionY,'String'));
else
    NVAx = handles.listNVMarkerPos(1,input);
    NVAy = handles.listNVMarkerPos(2,input);
end
if inputOther ==-1
    NVBx = str2double(get(handles.editPositionX,'String'));
    NVBy = str2double(get(handles.editPositionY,'String'));
else
    NVBx = handles.listNVMarkerPos(1,inputOther);
    NVBy = handles.listNVMarkerPos(2,inputOther);
end
set(handles.dxMarkers,'String',num2str((NVBx - NVAx)*unitFactor));
set(handles.dyMarkers,'String',num2str((NVBy - NVAy)*unitFactor));
end

% --- Executes during object creation, after setting all properties.
function displacementNVA_CreateFcn(hObject, eventdata, handles)
% hObject    handle to displacementNVA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on button press in buttondxToClipboard.
function buttondxToClipboard_Callback(hObject, eventdata, handles)
% hObject    handle to buttondxToClipboard (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
clipboard('copy', get(handles.dxMarkers,'String'));
end

% --- Executes on button press in buttondyToClipboard.
function buttondyToClipboard_Callback(hObject, eventdata, handles)
% hObject    handle to buttondyToClipboard (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
clipboard('copy', get(handles.dyMarkers,'String'));
end


% --- Executes on button press in buttonBothDxyToClipboard.
function buttonBothDxyToClipboard_Callback(hObject, eventdata, handles)
% hObject    handle to buttonBothDxyToClipboard (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
clipboard('copy', [get(handles.dxMarkers,'String') ' ' get(handles.dyMarkers,'String')]);
end


% --- Executes on button press in checkbox14.
function checkbox14_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(handles.checkbox14,'Value') == true
           
        handles.CursorControl.bMCLTracking = true;
    elseif get(handles.checkbox14,'Value') == false
           
        %handles.ScanControl.finishScan(handles);
        handles.CursorControl.bMCLTracking = false;
end
end
% Hint: get(hObject,'Value') returns toggle state of checkbox14


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over checkbox14.


% --- Executes on button press in checkbox_analogInputScan.
function checkbox_analogInputScan_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_analogInputScan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_analogInputScan


end



function AOMfreq_kHz_Callback(hObject, eventdata, handles)
% hObject    handle to AOMfreq_kHz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AOMfreq_kHz as text
%        str2double(get(hObject,'String')) returns contents of AOMfreq_kHz as a double

% AOM repetition in kHz
% 0 is allowed, negative is not allowed
% maximum allowed AOM frequency will be 10000 kHz (10MHz), but this is arbitrary
% minimum allowed AOM rep other than 0 will be subject to the limits of the
% long delay feature, let's just make it 2 kHz for now which is only
% about a factor of 8 faster than the scan pixel dwell time (~250 Hz)
input = str2double(get(hObject,'String'));
if input<2 && input>0
    input=2; % no < 2000 Hz except 0
elseif input<0
    input=0.5; % no negatives
elseif input>10000
    input=10000; % max 10 MHz
end
set(hObject,'String',num2str(input));
guidata(hObject, handles);
end

% --- Executes during object creation, after setting all properties.
function AOMfreq_kHz_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AOMfreq_kHz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in button_openESRLock.
function button_openESRLock_Callback(hObject, eventdata, handles)
% hObject    handle to button_openESRLock (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);
handles.ESRControl = EsrResonanceLock(handles);
% do not pass the DAQ handle to ESRlock because the DAQ tasks will be taken
% care of by the mDAC.cpp code 
guidata(handles.output, handles);

end


% --- Executes on button press in buttonNewIgorExperiment.
function buttonNewIgorExperiment_Callback(hObject, eventdata, handles)
% hObject    handle to buttonNewIgorExperiment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.sIgor = actxserver('IgorPro.Application');
    handles.sIGor.Visible = 1; % show the Igor if not already

sel = questdlg('First save the currently open Igor experiment?','Save Igor pxp?','Yes','No','No');
switch(sel)
    case 'Yes'
        handles.sIgor.SaveExperiment(0,1,-1,'',''); % last argument unused for Save w/o Save As
        
    case 'No'
        
end
handles.sIgor.Visible = 1;
handles.sIgor.NewExperiment(0);
handles.sIgor.OpenFile(0, 12, '', 'C:\Users\lab\Documents\WaveMetrics\Igor Pro 6 User Files\User Procedures\NVAnalysis.ipfT3');
end

% --- Executes on button press in buttonLoadIgorExperiment.
function buttonLoadIgorExperiment_Callback(hObject, eventdata, handles)
% hObject    handle to buttonLoadIgorExperiment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
sel = questdlg('First save the currently open Igor experiment?','Save Igor pxp?','Yes','No','No');
switch(sel)
    case 'Yes'
        handles.sIgor.SaveExperiment(0,1,-1,'',''); % last argument unused for Save w/o Save As
    case 'No'
        
end
    defaultPath = 'Z:\Bryan\CVD diamond\';
        [filename pathname] = uigetfile('*.pxp', 'Select Igor Experiment to Load',defaultPath);
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
            % if the file looks fine set the path/file on GUI:
            expPath =  file1;
            handles.sIgor.Visible = 1;
            handles.sIgor.LoadExperiment(0,2,'',expPath);
end
