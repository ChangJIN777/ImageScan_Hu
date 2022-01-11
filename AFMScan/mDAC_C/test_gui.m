function varargout = test_gui(varargin)
% TEST_GUI MATLAB code for test_gui.fig
%      TEST_GUI, by itself, creates a new TEST_GUI or raises the existing
%      singleton*.
%
%      H = TEST_GUI returns the handle to a new TEST_GUI or the handle to
%      the existing singleton*.
%
%      TEST_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TEST_GUI.M with the given input arguments.
%
%      TEST_GUI('Property','Value',...) creates a new TEST_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before test_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to test_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help test_gui

% Last Modified by GUIDE v2.5 15-Oct-2020 13:31:14

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @test_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @test_gui_OutputFcn, ...
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
% --- Executes just before test_gui is made visible.
function test_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to test_gui (see VARARGIN)

% Choose default command line output for test_gui
handles.output = hObject;
%handles.output = handles; 
%clear mex; %Clear all variables from previous MEX iterations
%Create ThorLabs APT DC Servo Motor figure

 %fpos(1) = 1310;
 %    fpos(2) = 50;
 %    fpos(3) = 600; % figure window size;Width
 %    fpos(4) = 400; % Height
%      
%  ThorFigure = figure('Position', fpos,...
%            'Menu','None',...
%            'Name','APT GUI');
%        set(ThorFigure,'CloseRequestFcn',@close_callback);
%      % Create ActiveX Controller
%     global ThorStage;
%     ThorStage = actxcontrol('MGMOTOR.MGMotorCtrl.1',[0 0 600 400 ], ThorFigure);
% 
%      ThorStage.StartCtrl;
%      
%      % Set the Serial Number
%      SN = 83838133; % put in the serial number of the hardware
%      set(ThorStage,'HWSerialNum', SN);
%      
%      ThorStage.Identify;
%      SetJogStepSize(ThorStage, 0, 0.06);
% 
%      DisableHWChannel(ThorStage,1);
%  
%      handles.Thor = ThorStage;
%      handles.Thorfig = ThorFigure;
%    
system('start ThorLabsAPT.exe'); % starting the program named ThorLabsAPT.exe (make sure that this exists in the current path)
%Create tip signal graph figure
f = figure('WindowButtonDownFcn',@button_down,'WindowButtonMotionFcn',@button_drag,'WindowButtonUpFcn',@button_up,'menubar','none');
set(f,'OuterPosition',[1308 485 600 600]);
set(f,'Resize','off');
set(f,'CloseRequestFcn',@close_callback);
colordef white;


handles.tip_figure = f;

TextBox_tip_label = uicontrol('style','text');
set(TextBox_tip_label,'Position',[20 120 100 30]);
set(TextBox_tip_label,'String','Tip Signal:','BackgroundColor',[0.8 0.8 0.8],'FontSize',16,'HorizontalAlignment','right');

TextBox_tip_volt = uicontrol('style','text');
set(TextBox_tip_volt,'Position',[150 117 150 30],'FontName','Courier New','HorizontalAlignment','right');
set(TextBox_tip_volt,'String',' ','BackgroundColor',[0.8 0.8 0.8],'FontSize',16);

TextBox_min_label = uicontrol('style','text');
set(TextBox_min_label,'Position',[20 40 100 30]);
set(TextBox_min_label,'String','Min Flag:','BackgroundColor',[0.8 0.8 0.8],'FontSize',16,'HorizontalAlignment','right');

TextBox_min_volt = uicontrol('style','text');
set(TextBox_min_volt,'Position',[150 37 150 30],'FontName','Courier New','HorizontalAlignment','right');
set(TextBox_min_volt,'String',' ','BackgroundColor',[0.8 0.8 0.8],'FontSize',16);

TextBox_max_label = uicontrol('style','text');
set(TextBox_max_label,'Position',[20 80 100 30]);
set(TextBox_max_label,'String','Max Flag:','BackgroundColor',[0.8 0.8 0.8],'FontSize',16,'HorizontalAlignment','right');

TextBox_max_volt = uicontrol('style','text');
set(TextBox_max_volt,'Position',[150 77 150 30],'FontName','Courier New','HorizontalAlignment','right');
set(TextBox_max_volt,'String',' ','BackgroundColor',[0.8 0.8 0.8],'FontSize',16);

TextBox_inc_range = uicontrol('style','pushbutton');
set(TextBox_inc_range,'Position',[10 510 30 25],'BackgroundColor',[0.8 0.8 0.8],'FontSize',16,'String','+','Callback',@inc_range_callback);

TextBox_dec_range = uicontrol('style','pushbutton');
set(TextBox_dec_range,'Position',[50 510 30 25],'BackgroundColor',[0.8 0.8 0.8],'FontSize',16,'String','-','Callback',@dec_range_callback);

PushButton_start_app = uicontrol('style','pushbutton');
set(PushButton_start_app,'Position',[350 110 175 35],'BackgroundColor',[0.8 0.8 0.8],'FontSize',16,'String','Start Approach','Callback',@start_app_callback);

PushButton_stop_app = uicontrol('style','pushbutton');
set(PushButton_stop_app,'Position',[350 50 175 35],'BackgroundColor',[0.8 0.8 0.8],'FontSize',16,'String','Stop Approach','Callback',@stop_app_callback);

PushButton_stop_graph = uicontrol('style','pushbutton');
set(PushButton_stop_graph,'Position',[250 510 150 35],'BackgroundColor',[0.8 0.8 0.8],'FontSize',16,'String','Stop Graph','Callback',@stop_graph_callback);

PushButton_start_graph = uicontrol('style','pushbutton');
set(PushButton_start_graph,'Position',[425 510 150 35],'BackgroundColor',[0.8 0.8 0.8],'FontSize',16,'String','Start Graph','Callback',@start_graph_callback);


buffer = 2500;
x = linspace(-10,0,buffer);
y= 0.*x;
set(gca,'XLim',[-10,0],'YLim',[-1 1]);
set(gca,'Units','pixels','DrawMode','fast','XTickLabel','');
set(gca,'Position',[50 200 500 300]);
%set(gcf,'Renderer','painter');
h = line('XData',x,'YData',y);
%set(h,'EraseMode','background');
x2 = [-10 0];
y_max = [0.5 0.5];
y_min = [-0.5 -0.5];

h_max_line = line('XData',x2,'YData',y_max,'Color','r');
h_min_line = line('XData',x2,'YData',y_min,'Color','r');

%Create scan window
scan_figure = figure('WindowButtonDownFcn',@scan_button_down,'WindowButtonMotionFcn',@scan_button_motion,'WindowButtonUpFcn',@scan_button_up);
set(scan_figure,'OuterPosition',[495 288 800 800]);
set(scan_figure,'Resize','off');
set(scan_figure,'CloseRequestFcn',@close_callback);

hcmenu = uimenu('Label','Scan Options','Callback',@scan_menu_callback);
    view_channel_item = uimenu(hcmenu, 'Label', 'View Channel');
       h_channel_submenu = uicontextmenu;
        
        channel_item(1) = uimenu(h_channel_submenu, 'Label', strcat('ai',num2str(0)),'Parent',view_channel_item,'Callback',@view_channel0_callback);
        channel_item(2) = uimenu(h_channel_submenu, 'Label', strcat('ai',num2str(1)),'Parent',view_channel_item,'Callback',@view_channel1_callback);
        channel_item(3) = uimenu(h_channel_submenu, 'Label', strcat('ai',num2str(2)),'Parent',view_channel_item,'Callback',@view_channel2_callback);
        channel_item(4) = uimenu(h_channel_submenu, 'Label', strcat('ai',num2str(3)),'Parent',view_channel_item,'Callback',@view_channel3_callback);
        channel_item(5) = uimenu(h_channel_submenu, 'Label', strcat('ai',num2str(4)),'Parent',view_channel_item,'Callback',@view_channel4_callback);
        channel_item(6) = uimenu(h_channel_submenu, 'Label', strcat('ai',num2str(5)),'Parent',view_channel_item,'Callback',@view_channel5_callback);
        channel_item(7) = uimenu(h_channel_submenu, 'Label', strcat('ai',num2str(6)),'Parent',view_channel_item,'Callback',@view_channel6_callback);
        channel_item(8) = uimenu(h_channel_submenu, 'Label', strcat('ai',num2str(7)),'Parent',view_channel_item,'Callback',@view_channel7_callback);
        
        input_channel_item = uimenu(hcmenu, 'Label', 'Input Channels...','Callback',@input_channels_callback);
        forward_item = uimenu(hcmenu, 'Label', 'Forward','separator','on','Callback',@forward_callback);
        reverse_item = uimenu(hcmenu, 'Label', 'Reverse','Callback',@reverse_callback);
         filtered_item = uimenu(hcmenu, 'Label', 'Filtered','separator','on','Callback',@filtered_callback);
        unfiltered_item = uimenu(hcmenu, 'Label', 'Unfiltered','Callback',@unfiltered_callback);
         tip_position_item = uimenu(hcmenu, 'Label', 'Tip Position','separator','on','Callback',@tip_position_callback);
         % grid_line_item = uimenu(hcmenu, 'Label', 'Grid Lines','Callback',@grid_lines_callback);
          %crosshairs_item = uimenu(hcmenu, 'Label', 'Crosshairs');
          %item8 = uimenu(hcmenu, 'Label', 'Data Selector');
          % vary_colorbar_item = uimenu(hcmenu, 'Label', 'Vary Colorbar','Callback',@vary_colorbar_callback);
            invert_colorbar_item = uimenu(hcmenu, 'Label', 'Invert Colorbar','Callback',@invert_colorbar_callback);
             %save_data_item = uimenu(hcmenu, 'Label', 'Save Data...','separator','on');
             %item12 = uimenu(hcmenu, 'Label', 'Save Image...');    
             
              function scan_menu_callback(src,evnt)
                 % added by Chang 01/05/22 (create c++ mex function out of process)
                  mh = mexhost; 
                  feval(mh,"mDAC",'set_scan_menu');
%                   mDAC('set_scan_menu');
                  
              end
          
         
   tip_position_x_handle = line('Visible','off','color','blue','LineWidth',1);
tip_position_y_handle = line('Visible','off','color','blue','LineWidth',1);
          
               
handles.scan_figure = scan_figure;
scan_axes_handle = surface('Visible','off');
handles.scan_axes_handle = scan_axes_handle;
%set(gcf,'WindowButtonDownFcn',@scan_button_down);
set(scan_axes_handle,'LineStyle','none','FaceColor','interp');
scan_grid_handle = gca;
handles.scan_grid_handle = scan_grid_handle;
set(gca,'TickDir','out','YDir','reverse','XAxisLocation','top');
colorbar;
colormap bone;
caxis auto;
box on;
xlim manual;
ylim manual;

cur_line_handle = line('Visible','off','color','red','LineWidth',2);

 function scan_button_down(src,evnt)
      
    if strcmp(get(src,'SelectionType'),'alt')
    %Right-click in scan window, move tip if enabled
     cp =  get(scan_grid_handle,'CurrentPoint');
     % added by Chang 01/05/22 (create c++ mex function out of process)
                  mh = mexhost; 
                  feval(mh,"mDAC",'enable_tip_motion',cp(1,1),cp(1,2));
%            mDAC('enable_tip_motion',cp(1,1),cp(1,2));
    end
 end

 function scan_button_motion(src,evnt)
      
    if strcmp(get(src,'SelectionType'),'alt')
       
    %Right-click in scan window, move tip if enabled
            cp =  get(scan_grid_handle,'CurrentPoint');
            % added by Chang 01/05/22 (create c++ mex function out of process)
            mh = mexhost; 
            feval(mh,"mDAC",'tip_motion',cp(1,1),cp(1,2));
%             mDAC('tip_motion',cp(1,1),cp(1,2));
    end
 end

 function scan_button_up(src,evnt)
   % added by Chang 01/05/22 (create c++ mex function out of process)
   mh = mexhost; 
   feval(mh,"mDAC",'disable_tip_motion');
%    mDAC('disable_tip_motion');
 end


scan_info_figure = figure('OuterPosition',[88 290 400 800],'menubar','none');
handles.scan_info_figure = scan_info_figure;

TextBox_tip_pos = uicontrol('style','text');
set(TextBox_tip_pos,'Position',[15 705 150 30]);
set(TextBox_tip_pos,'String','Tip Position','BackgroundColor',[0.8 0.8 0.8],'FontSize',16,'HorizontalAlignment','left');

TextBox_tip_pos_x = uicontrol('style','text');
set(TextBox_tip_pos_x,'Position',[30 670 50 30]);
set(TextBox_tip_pos_x,'String','X:','BackgroundColor',[0.8 0.8 0.8],'FontSize',16,'HorizontalAlignment','left');

TextBox_tip_pos_x_value = uicontrol('style','text');
set(TextBox_tip_pos_x_value,'Position',[60 667 120 30],'FontName','Courier New');
set(TextBox_tip_pos_x_value,'String','','BackgroundColor',[0.8 0.8 0.8],'FontSize',16,'HorizontalAlignment','right');

%handles.xtippos =TextBox_tip_pos_x_value; 

Edit_tip_pos_x = uicontrol('style','edit','KeyPressFcn',@tip_pos_x_keypress);
set(Edit_tip_pos_x,'Position',[220 670 120 30],'FontSize',16,'FontName','Courier New','HorizontalAlignment','right');

TextBox_tip_pos_y = uicontrol('style','text');
set(TextBox_tip_pos_y,'Position',[30 635 50 30]);
set(TextBox_tip_pos_y,'String','Y:','BackgroundColor',[0.8 0.8 0.8],'FontSize',16,'HorizontalAlignment','left');

TextBox_tip_pos_y_value = uicontrol('style','text');
set(TextBox_tip_pos_y_value,'Position',[60 632 120 30],'FontName','Courier New');
set(TextBox_tip_pos_y_value,'String','','BackgroundColor',[0.8 0.8 0.8],'FontSize',16,'HorizontalAlignment','right');

Edit_tip_pos_y = uicontrol('style','edit','KeyPressFcn',@tip_pos_y_keypress);
set(Edit_tip_pos_y,'Position',[220 635 120 30],'FontSize',16,'FontName','Courier New','HorizontalAlignment','right');

TextBox_scan_size = uicontrol('style','text');
set(TextBox_scan_size,'Position',[15 600 150 30]);
set(TextBox_scan_size,'String','Scan Size','BackgroundColor',[0.8 0.8 0.8],'FontSize',16,'HorizontalAlignment','left');

TextBox_scan_size_x = uicontrol('style','text');
set(TextBox_scan_size_x,'Position',[30 565 50 30]);
set(TextBox_scan_size_x,'String','X:','BackgroundColor',[0.8 0.8 0.8],'FontSize',16,'HorizontalAlignment','left');

TextBox_scan_size_x_value = uicontrol('style','text');
set(TextBox_scan_size_x_value,'Position',[60 562 120 30],'FontName','Courier New');
set(TextBox_scan_size_x_value,'String','','BackgroundColor',[0.8 0.8 0.8],'FontSize',16,'HorizontalAlignment','right');

Edit_scan_size_x = uicontrol('style','edit','KeyPressFcn',@scan_size_x_keypress);
set(Edit_scan_size_x,'Position',[220 565 120 30],'FontSize',16,'FontName','Courier New','HorizontalAlignment','right');

TextBox_scan_size_y = uicontrol('style','text');
set(TextBox_scan_size_y,'Position',[30 530 50 30]);
set(TextBox_scan_size_y,'String','Y:','BackgroundColor',[0.8 0.8 0.8],'FontSize',16,'HorizontalAlignment','left');

TextBox_scan_size_y_value = uicontrol('style','text');
set(TextBox_scan_size_y_value,'Position',[60 527 120 30],'FontName','Courier New');
set(TextBox_scan_size_y_value,'String','','BackgroundColor',[0.8 0.8 0.8],'FontSize',16,'HorizontalAlignment','right');

Edit_scan_size_y = uicontrol('style','edit','KeyPressFcn',@scan_size_y_keypress);
set(Edit_scan_size_y,'Position',[220 530 120 30],'FontSize',16,'FontName','Courier New','HorizontalAlignment','right');

TextBox_scan_center = uicontrol('style','text');
set(TextBox_scan_center,'Position',[15 495 150 30]);
set(TextBox_scan_center,'String','Scan Center','BackgroundColor',[0.8 0.8 0.8],'FontSize',16,'HorizontalAlignment','left');

TextBox_scan_center_x = uicontrol('style','text');
set(TextBox_scan_center_x,'Position',[30 460 50 30]);
set(TextBox_scan_center_x,'String','X:','BackgroundColor',[0.8 0.8 0.8],'FontSize',16,'HorizontalAlignment','left');

TextBox_scan_center_x_value = uicontrol('style','text');
set(TextBox_scan_center_x_value,'Position',[60 457 120 30],'FontName','Courier New');
set(TextBox_scan_center_x_value,'String','','BackgroundColor',[0.8 0.8 0.8],'FontSize',16,'HorizontalAlignment','right');

Edit_scan_center_x = uicontrol('style','edit','KeyPressFcn',@scan_center_x_keypress);
set(Edit_scan_center_x,'Position',[220 460 120 30],'FontSize',16,'FontName','Courier New','HorizontalAlignment','right');

TextBox_scan_center_y = uicontrol('style','text');
set(TextBox_scan_center_y,'Position',[30 425 50 30]);
set(TextBox_scan_center_y,'String','Y:','BackgroundColor',[0.8 0.8 0.8],'FontSize',16,'HorizontalAlignment','left');

TextBox_scan_center_y_value = uicontrol('style','text');
set(TextBox_scan_center_y_value,'Position',[60 422 120 30],'FontName','Courier New');
set(TextBox_scan_center_y_value,'String','','BackgroundColor',[0.8 0.8 0.8],'FontSize',16,'HorizontalAlignment','right');

Edit_scan_center_y = uicontrol('style','edit','KeyPressFcn',@scan_center_y_keypress);
set(Edit_scan_center_y,'Position',[220 425 120 30],'FontSize',16,'FontName','Courier New','HorizontalAlignment','right');

TextBox_scan_speed = uicontrol('style','text');
set(TextBox_scan_speed,'Position',[15 390 150 30]);
set(TextBox_scan_speed,'String','Scan Speed','BackgroundColor',[0.8 0.8 0.8],'FontSize',16,'HorizontalAlignment','left');

TextBox_scan_speed_value = uicontrol('style','text');
set(TextBox_scan_speed_value,'Position',[30 352 120 30],'FontName','Courier New');
set(TextBox_scan_speed_value,'String','','BackgroundColor',[0.8 0.8 0.8],'FontSize',16,'HorizontalAlignment','left');

Edit_scan_speed = uicontrol('style','edit','KeyPressFcn',@scan_speed_keypress);
set(Edit_scan_speed,'Position',[220 355 120 30],'FontSize',16,'FontName','Courier New','HorizontalAlignment','right');

TextBox_scan_points = uicontrol('style','text');
set(TextBox_scan_points,'Position',[15 320 150 30]);
set(TextBox_scan_points,'String','Points','BackgroundColor',[0.8 0.8 0.8],'FontSize',16,'HorizontalAlignment','left');

TextBox_scan_points_x = uicontrol('style','text');
set(TextBox_scan_points_x,'Position',[30 285 50 30]);
set(TextBox_scan_points_x,'String','X:','BackgroundColor',[0.8 0.8 0.8],'FontSize',16,'HorizontalAlignment','left');

TextBox_scan_points_x_value = uicontrol('style','text');
set(TextBox_scan_points_x_value,'Position',[60 282 55 30],'FontName','Courier New');
set(TextBox_scan_points_x_value,'String','','BackgroundColor',[0.8 0.8 0.8],'FontSize',16,'HorizontalAlignment','right');

Edit_points_x = uicontrol('style','edit','KeyPressFcn',@scan_points_x_keypress);
set(Edit_points_x,'Position',[220 285 120 30],'FontSize',16,'FontName','Courier New','HorizontalAlignment','right');

TextBox_scan_points_y = uicontrol('style','text');
set(TextBox_scan_points_y,'Position',[30 250 50 30]);
set(TextBox_scan_points_y,'String','Y:','BackgroundColor',[0.8 0.8 0.8],'FontSize',16,'HorizontalAlignment','left');

TextBox_scan_points_y_value = uicontrol('style','text');
set(TextBox_scan_points_y_value,'Position',[60 247 55 30],'FontName','Courier New');
set(TextBox_scan_points_y_value,'String','','BackgroundColor',[0.8 0.8 0.8],'FontSize',16,'HorizontalAlignment','right');

Edit_points_y = uicontrol('style','edit','KeyPressFcn',@scan_points_y_keypress);
set(Edit_points_y,'Position',[220 250 120 30],'FontSize',16,'FontName','Courier New','HorizontalAlignment','right');

PushButton_calibrate = uicontrol('style','pushbutton');
set(PushButton_calibrate,'Position',[15 180 150 35],'BackgroundColor',[0.8 0.8 0.8],'String','Calibrate...','FontSize',16,'Callback',@calibrate_callback);

% 
% TextBox_rotation = uicontrol('style','text');
% set(TextBox_rotation,'Position',[15 215 150 30]);
% set(TextBox_rotation,'String','Rotation','BackgroundColor',[0.8 0.8 0.8],'FontSize',16,'HorizontalAlignment','left');
% 
% TextBox_rotation_value = uicontrol('style','text');
% set(TextBox_rotation_value,'Position',[30 180 120 30],'FontName','Courier New');
% set(TextBox_rotation_value,'String','0.0 deg','BackgroundColor',[0.8 0.8 0.8],'FontSize',16,'HorizontalAlignment','left');
% 
% Edit_rotation = uicontrol('style','edit');
% set(Edit_rotation,'Position',[220 180 120 30],'FontSize',16,'FontName','Courier New','HorizontalAlignment','right');


PushButton_set_plane = uicontrol('style','pushbutton');
set(PushButton_set_plane,'Position',[15 135 150 35],'BackgroundColor',[0.8 0.8 0.8],'String','Set Plane...','FontSize',16,'Callback',@set_plane_callback);

CheckBox_snap_plane = uicontrol('style','checkbox');
set(CheckBox_snap_plane,'Position',[200 135 150 35],'BackgroundColor',[0.8 0.8 0.8],'String','Snap to Plane','FontSize',16,'Callback',@snap_plane_callback);

CheckBox_pulse_seq = uicontrol('style','checkbox');
set(CheckBox_pulse_seq,'Position',[200 180 175 35],'BackgroundColor',[0.8 0.8 0.8],'String','Pulse Sequence','FontSize',16,'Callback',@pulse_seq_callback);

PushButton_start_scan = uicontrol('style','pushbutton');
set(PushButton_start_scan,'Position',[80 80 175 35],'BackgroundColor',[0.8 0.8 0.8],'FontSize',16,'String','Start Scan','Callback',@start_scan_callback);

PushButton_stop_scan = uicontrol('style','pushbutton');
set(PushButton_stop_scan,'Position',[80 30 175 35],'BackgroundColor',[0.8 0.8 0.8],'FontSize',16,'String','Stop Scan','Callback',@stop_scan_callback);

    function snap_plane_callback(src,evnt)
       val = get(CheckBox_snap_plane,'Value');
       % added by Chang 01/05/22 (create c++ mex function out of process)
       mh = mexhost; 
       feval(mh,"mDAC",'snap_plane',val);
%        mDAC('snap_plane',val);
    end

    function pulse_seq_callback(src,evnt)
       val = get(CheckBox_pulse_seq,'Value');
       % added by Chang 01/05/22 (create c++ mex function out of process)
       mh = mexhost; 
       feval(mh,"mDAC",'pulse_seq',val);
%        mDAC('pulse_seq',val);
    end

    function calibrate_callback(src,evnt)
        % added by Chang 01/05/22 (create c++ mex function out of process)
        mh = mexhost; 
        feval(mh,"mDAC",'calibrate');
%         mDAC('calibrate');
    end


    
% Update handles structure
guidata(hObject, handles);
 % added by Chang 01/05/22 (create c++ mex function out of process)
mh = mexhost; 
mDAC('button_up',0,0);
% feval(mh,"mDAC",'set_scan_menu_items',channel_item(1),channel_item(2),channel_item(3),channel_item(4),channel_item(5),channel_item(6),channel_item(7),channel_item(8),input_channel_item,...
%     forward_item,reverse_item,filtered_item,unfiltered_item,tip_position_item,invert_colorbar_item);
% feval(mh,"mDAC",'set_scan_handles',TextBox_tip_pos_x_value,TextBox_tip_pos_y_value,TextBox_scan_size_x_value,TextBox_scan_size_y_value,TextBox_scan_center_x_value,TextBox_scan_center_y_value,...
%     TextBox_scan_speed_value, TextBox_scan_points_x_value, TextBox_scan_points_y_value,scan_axes_handle,scan_grid_handle,cur_line_handle,...
%     tip_position_x_handle,tip_position_y_handle,PushButton_start_scan,PushButton_stop_scan,PushButton_start_app,PushButton_stop_app,CheckBox_snap_plane,PushButton_stop_graph,PushButton_start_graph);
% feval(mh,"mDAC",'set_MCL_handles',handles.text1,handles.text2,handles.text3);
mDAC('set_scan_menu_items',channel_item(1),channel_item(2),channel_item(3),channel_item(4),channel_item(5),channel_item(6),channel_item(7),channel_item(8),input_channel_item,...
    forward_item,reverse_item,filtered_item,unfiltered_item,tip_position_item,invert_colorbar_item);
mDAC('set_scan_handles',TextBox_tip_pos_x_value,TextBox_tip_pos_y_value,TextBox_scan_size_x_value,TextBox_scan_size_y_value,TextBox_scan_center_x_value,TextBox_scan_center_y_value,...
    TextBox_scan_speed_value, TextBox_scan_points_x_value, TextBox_scan_points_y_value,scan_axes_handle,scan_grid_handle,cur_line_handle,...
    tip_position_x_handle,tip_position_y_handle,PushButton_start_scan,PushButton_stop_scan,PushButton_start_app,PushButton_stop_app,CheckBox_snap_plane,PushButton_stop_graph,PushButton_start_graph);
mDAC('set_MCL_handles',handles.text1,handles.text2,handles.text3);


% feval(mh,"mDAC",'init',h,h_min_line,h_max_line,TextBox_tip_volt,TextBox_min_volt,TextBox_max_volt,handles.text17,buffer);
mDAC('init',h,h_min_line,h_max_line,TextBox_tip_volt,TextBox_min_volt,TextBox_max_volt,handles.text17,buffer);
%read laser calibrations from the ini file

 configurationFile = 'ConfigurationImageScan.txt';
 global laser_x_handle;
  global laser_y_handle;

    % structure
    if exist(configurationFile, 'file') == 2
        configS = tdfread(configurationFile);
        % added by Chang 01/05/22 (create c++ mex function out of process)
        mh = mexhost; 
        feval(mh,"mDAC",'set_cal', configS.xScanMicronsPerVolt,configS.yScanMicronsPerVolt,10.000,10.000,laser_x_handle,laser_y_handle);
%         mDAC('set_cal', configS.xScanMicronsPerVolt,configS.yScanMicronsPerVolt,10.000,10.000,laser_x_handle,laser_y_handle);
    end

    % micronix addtion:
    if configS.bHaveMicronixSerial
        % pass the handles from test_gui to new figure
        handles.micronix_figure = MicronixControl(handles);
    end
    
    %phase readout gui
    handles.phase_figure = PhaseGUI(handles);
    
    % Update handles structure
    guidata(hObject, handles);
end
% UIWAIT makes test_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);
function button_down(src,evnt)
    if strcmp(get(src,'SelectionType'),'normal')
        cp = get(findobj(src,'type','axes'),'CurrentPoint');
        % added by Chang 01/05/22 (create c++ mex function out of process)
        mh = mexhost; 
        feval(mh,"mDAC",'button_down',cp(1,1),cp(1,2));
        % mDAC('button_down',cp(1,1),cp(1,2));
    end
end

function button_drag(src,evnt)
 if strcmp(get(src,'SelectionType'),'normal')
        cp = get(findobj(src,'type','axes'),'CurrentPoint');
        % added by Chang 01/05/22 (create c++ mex function out of process)
        mh = mexhost; 
        feval(mh,"mDAC",'button_drag',cp(1,1),cp(1,2));
%         mDAC('button_drag',cp(1,1),cp(1,2));
 end
end
 function button_up(src,evnt)
 if strcmp(get(src,'SelectionType'),'normal')
        cp = get(findobj(src,'type','axes'),'CurrentPoint');
        % added by Chang 01/05/22 (create c++ mex function out of process)
        mh = mexhost; 
        feval(mh,"mDAC",'button_up',cp(1,1),cp(1,2));
%         mDAC('button_up',cp(1,1),cp(1,2));
 end
 end   
 
     function inc_range_callback(src,evnt)
         
          cp = ylim;
          if cp(2) < 0.95
              set(gca,'YLim',[-(cp(2)+0.1) cp(2)+0.1]);
          end
     end
         function dec_range_callback(src,evnt)
            cp = ylim;
          if cp(2) > 0.15
              set(gca,'YLim',[-(cp(2)-0.1) cp(2)-0.1]);
          end
         end
             function start_app_callback(src,evnt)
                % added by Chang 01/05/22 (create c++ mex function out of process)
                mh = mexhost; 
                feval(mh,"mDAC",'start_approach');
%                 mDAC('start_approach');
             end
                 
                 function stop_app_callback(src,evnt)
                    % added by Chang 01/05/22 (create c++ mex function out of process)
                    mh = mexhost; 
                    feval(mh,"mDAC",'stop_approach');
%                     mDAC('stop_approach');
                 end
                 function stop_graph_callback(src,evnt)
                    % added by Chang 01/05/22 (create c++ mex function out of process)
                    mh = mexhost; 
                    feval(mh,"mDAC",'stop_graph');
%                     mDAC('stop_graph');
                 end
                  function start_graph_callback(src,evnt)
                   % added by Chang 01/05/22 (create c++ mex function out of process)
                   mh = mexhost; 
                   feval(mh,"mDAC",'start_graph');
%                    mDAC('start_graph');
                 end
                     function close_callback(src,evnt)
                     end
                         
                             
                             
                                 function stop_scan_callback(src,evnt)
                                     % added by Chang 01/05/22 (create c++ mex function out of process)
                                     mh = mexhost; 
                                     feval(mh,"mDAC",'stop_scan');
                                 end
                                     function start_scan_callback(src,evnt)
                                     %Get laser position
                                      global laser_x_handle;
                                        global laser_y_handle;
                                        
                                         laser_x = str2double(get(laser_x_handle,'String'));
                                         laser_y = str2double(get(laser_y_handle,'String'));
                                         % added by Chang 01/05/22 (create c++ mex function out of process)
                                         mh = mexhost; 
                                         feval(mh,"mDAC",'start_scan',laser_x,laser_y);
%                                          mDAC('start_scan',laser_x,laser_y);
                                     end

  
function view_channel0_callback(src,~)
% added by Chang 01/05/22 (create c++ mex function out of process)
mh = mexhost; 
feval(mh,"mDAC",'set_view_channel',0);
% mDAC('set_view_channel',0);
end
function view_channel1_callback(src,evnt)
% added by Chang 01/05/22 (create c++ mex function out of process)
mh = mexhost; 
feval(mh,"mDAC",'set_view_channel',1);
% mDAC('set_view_channel',1);
end
function view_channel2_callback(src,evnt)
% added by Chang 01/05/22 (create c++ mex function out of process)
mh = mexhost; 
feval(mh,"mDAC",'set_view_channel',2);
% mDAC('set_view_channel',2);
end
function view_channel3_callback(src,evnt)
% added by Chang 01/05/22 (create c++ mex function out of process)
mh = mexhost; 
feval(mh,"mDAC",'set_view_channel',3);
% mDAC('set_view_channel',3);
end
function view_channel4_callback(src,evnt)
% added by Chang 01/05/22 (create c++ mex function out of process)
mh = mexhost; 
feval(mh,"mDAC",'set_view_channel',4);
% mDAC('set_view_channel',4);
end
function view_channel5_callback(src,evnt)
% added by Chang 01/05/22 (create c++ mex function out of process)
mh = mexhost; 
feval(mh,"mDAC",'set_view_channel',5);
% mDAC('set_view_channel',5);
end
function view_channel6_callback(src,evnt)
% added by Chang 01/05/22 (create c++ mex function out of process)
mh = mexhost; 
feval(mh,"mDAC",'set_view_channel',6);
% mDAC('set_view_channel',6);
end
function view_channel7_callback(src,evnt)
% added by Chang 01/05/22 (create c++ mex function out of process)
mh = mexhost; 
feval(mh,"mDAC",'set_view_channel',7);
% mDAC('set_view_channel',7);
end
function forward_callback(src,evnt)
% added by Chang 01/05/22 (create c++ mex function out of process)
mh = mexhost; 
feval(mh,"mDAC",'set_forward');
% mDAC('set_forward');
end
function reverse_callback(src,evnt)
% added by Chang 01/05/22 (create c++ mex function out of process)
mh = mexhost; 
feval(mh,"mDAC",'set_reverse');
% mDAC('set_reverse');
end
function filtered_callback(src,evnt)
% added by Chang 01/05/22 (create c++ mex function out of process)
mh = mexhost; 
feval(mh,"mDAC",'set_filtered');
% mDAC('set_filtered');
end
function unfiltered_callback(src,evnt)
% added by Chang 01/05/22 (create c++ mex function out of process)
mh = mexhost; 
feval(mh,"mDAC",'set_unfiltered');
% mDAC('set_unfiltered');
end
function tip_position_callback(src,evnt)
% added by Chang 01/05/22 (create c++ mex function out of process)
mh = mexhost; 
feval(mh,"mDAC",'draw_tip_position');
% mDAC('draw_tip_position');
end
function invert_colorbar_callback(src,evnt)
  colormap(flipud(colormap));
end

 function input_channels_callback(src,evnt)
       dbox = dialog('Position',[600 500 280 400],'Name','Input Channels'); 
       for k=0:7
           ch_checkbox(k+1) = uicontrol('style','checkbox','Position',[20 357-40*k 20 20]);
           ch_text(k+1) = uicontrol('style','text','String',strcat('Ch',num2str(k)),'Position',[40 350-40*k 50 30],'FontSize',16);
           ch_edit(k+1) = uicontrol('style','edit','Position',[110 350-40*k 150 30],'BackgroundColor',[1 1 1],'FontSize',16,'HorizontalAlignment','left');
       end
       ch_ok = uicontrol('style','pushbutton','String','OK','Position',[30 20 100 30],'FontSize',12,'Callback',@input_channel_ok_callback);
        ch_cancel = uicontrol('style','pushbutton','String','Cancel','Position',[160 20 100 30],'FontSize',12,'Callback','close');
        
        %Populate fields in dialog box with current state
        % added by Chang 01/05/22 (create c++ mex function out of process)
        mh = mexhost; 
        feval(mh,"mDAC",'input_channel_dialog_set',dbox,ch_checkbox(1),ch_checkbox(2),ch_checkbox(3),ch_checkbox(4),ch_checkbox(5),ch_checkbox(6),ch_checkbox(7),ch_checkbox(8),...
                                        ch_edit(1),ch_edit(2),ch_edit(3),ch_edit(4),ch_edit(5),ch_edit(6),ch_edit(7),ch_edit(8));
%         mDAC('input_channel_dialog_set',dbox,ch_checkbox(1),ch_checkbox(2),ch_checkbox(3),ch_checkbox(4),ch_checkbox(5),ch_checkbox(6),ch_checkbox(7),ch_checkbox(8),...
%                                         ch_edit(1),ch_edit(2),ch_edit(3),ch_edit(4),ch_edit(5),ch_edit(6),ch_edit(7),ch_edit(8));
 
     function input_channel_ok_callback(src,evnt)
        % added by Chang 01/05/22 (create c++ mex function out of process)
        mh = mexhost; 
        feval(mh,"mDAC",'input_channel_dialog_ok');
%         mDAC('input_channel_dialog_ok');
        close(dbox);
     end
 end
       function tip_pos_x_keypress(src,evnt)  
           if isequal(evnt.Key,'return')
              drawnow;
              % added by Chang 01/05/22 (create c++ mex function out of process)
              mh = mexhost; 
              feval(mh,"mDAC",'set_tip_x',str2num(get(src,'String')));
%               mDAC('set_tip_x',str2num(get(src,'String')));
              set(src,'String','');
           end
       end
           function tip_pos_y_keypress(src,evnt)  
           if isequal(evnt.Key,'return')
              drawnow;
              % added by Chang 01/05/22 (create c++ mex function out of process)
              mh = mexhost; 
              feval(mh,"mDAC",'set_tip_y',str2num(get(src,'String')));
%               mDAC('set_tip_y',str2num(get(src,'String')));
              set(src,'String','');
           end
           end
       
           function scan_size_x_keypress(src,evnt)  
           if isequal(evnt.Key,'return')
              drawnow;
              % added by Chang 01/05/22 (create c++ mex function out of process)
              mh = mexhost; 
              feval(mh,"mDAC",'set_scan_size_x',str2num(get(src,'String')));
%               mDAC('set_scan_size_x',str2num(get(src,'String')));
              set(src,'String','');
           end
           end
       
           function scan_size_y_keypress(src,evnt)  
           if isequal(evnt.Key,'return')
              drawnow;
              % added by Chang 01/05/22 (create c++ mex function out of process)
              mh = mexhost; 
              feval(mh,"mDAC",'set_scan_size_y',str2num(get(src,'String')));
%               mDAC('set_scan_size_y',str2num(get(src,'String')));
              set(src,'String','');
           end
           end
       
           function scan_center_x_keypress(src,evnt)  
           if isequal(evnt.Key,'return')
              drawnow;
              % added by Chang 01/05/22 (create c++ mex function out of process)
              mh = mexhost; 
              feval(mh,"mDAC",'set_scan_center_x',str2num(get(src,'String')));
%               mDAC('set_scan_center_x',str2num(get(src,'String')));
              set(src,'String','');
           end
           end
       
           function scan_center_y_keypress(src,evnt)  
           if isequal(evnt.Key,'return')
              drawnow;
              % added by Chang 01/05/22 (create c++ mex function out of process)
              mh = mexhost; 
              feval(mh,"mDAC",'set_scan_center_y',str2num(get(src,'String')));
%               mDAC('set_scan_center_y',str2num(get(src,'String')));
              set(src,'String','');
           end
           end
       
           function scan_speed_keypress(src,evnt)  
           if isequal(evnt.Key,'return')
              drawnow;
              % added by Chang 01/05/22 (create c++ mex function out of process)
              mh = mexhost; 
              feval(mh,"mDAC",'set_scan_speed',str2num(get(src,'String')));
%               mDAC('set_scan_speed',str2num(get(src,'String')));
              set(src,'String','');
           end
           end
       
           function scan_points_x_keypress(src,evnt)  
           if isequal(evnt.Key,'return')
              drawnow;
              % added by Chang 01/05/22 (create c++ mex function out of process)
              mh = mexhost; 
              feval(mh,"mDAC",'set_scan_points_x',str2num(get(src,'String')));
%               mDAC('set_scan_points_x',str2num(get(src,'String')));
              set(src,'String','');
           end
           end
       
           function scan_points_y_keypress(src,evnt)  
           if isequal(evnt.Key,'return')
              drawnow;
              % added by Chang 01/05/22 (create c++ mex function out of process)
              mh = mexhost; 
              feval(mh,"mDAC",'set_scan_points_y',str2num(get(src,'String')));
%               mDAC('set_scan_points_y',str2num(get(src,'String')));
              set(src,'String','');
           end
           end
       
              
function set_plane_callback(src,evnt)
 pbox = figure('Position',[600 500 600 300],'Name','Set Plane','menubar','none'); 
 %x,y,z edit boxes
 uicontrol('style','text','String','X:','Position',[15 260 30 30],'FontSize',16,'BackgroundColor',[0.8 0.8 0.8],'HorizontalAlignment','left');
 plane_x_edit = uicontrol('style','edit','BackgroundColor',[1 1 1],'FontSize',16,'HorizontalAlignment','right','Position',[45 260 70 30],'FontSize',16);
 uicontrol('style','text','String','V','Position',[120 260 30 30],'FontSize',16,'BackgroundColor',[0.8 0.8 0.8],'HorizontalAlignment','left');
 
 uicontrol('style','text','String','Y:','Position',[150 260 30 30],'FontSize',16,'BackgroundColor',[0.8 0.8 0.8],'HorizontalAlignment','left');
 plane_y_edit = uicontrol('style','edit','BackgroundColor',[1 1 1],'FontSize',16,'HorizontalAlignment','right','Position',[180 260 70 30],'FontSize',16);
 uicontrol('style','text','String','V','Position',[255 260 30 30],'FontSize',16,'BackgroundColor',[0.8 0.8 0.8],'HorizontalAlignment','left');
 
 uicontrol('style','text','String','Z:','Position',[285 260 30 30],'FontSize',16,'BackgroundColor',[0.8 0.8 0.8],'HorizontalAlignment','left');
 plane_z_edit = uicontrol('style','edit','BackgroundColor',[1 1 1],'FontSize',16,'HorizontalAlignment','right','Position',[315 260 70 30],'FontSize',16);
  uicontrol('style','text','String','V','Position',[390 260 30 30],'FontSize',16,'BackgroundColor',[0.8 0.8 0.8],'HorizontalAlignment','left');
  
 plane_current_pushbutton = uicontrol('style','pushbutton','Position',[55 220 200 30],'String','Get Current Position','FontSize',12,'BackgroundColor',[0.8 0.8 0.8],'Callback',@get_current_pos_callback);
 plane_add_pushbutton = uicontrol('style','pushbutton','Position',[275 220 75 30],'String','Add','FontSize',12,'BackgroundColor',[0.8 0.8 0.8],'Callback',@plane_add_callback);
 
 plane_listbox = uicontrol('style','listbox','Position',[30 110 360 100],'FontSize',12);
 
 plane_delete_all_pushbutton = uicontrol('style','pushbutton','Position',[50 70 150 30],'String','Delete All','FontSize',12,'BackgroundColor',[0.8 0.8 0.8],'Callback',@delete_all_callback);
 plane_delete_selected_pushbutton = uicontrol('style','pushbutton','Position',[215 70 150 30],'String','Delete Selected','FontSize',12,'BackgroundColor',[0.8 0.8 0.8],'Callback',@delete_selected_callback);
 
  uicontrol('style','text','String','Offset:','Position',[85 25 80 30],'FontSize',16,'BackgroundColor',[0.8 0.8 0.8]);
  plane_offset_edit = uicontrol('style','edit','BackgroundColor',[1 1 1],'FontSize',16,'HorizontalAlignment','right','Position',[175 25 80 30],'FontSize',16);
  uicontrol('style','text','String','mV','Position',[265 25 80 30],'FontSize',16,'BackgroundColor',[0.8 0.8 0.8],'HorizontalAlignment','left');
  
  plane_ok_pushbutton = uicontrol('style','pushbutton','Position',[400 30 75 30],'String','OK','FontSize',12,'BackgroundColor',[0.8 0.8 0.8],'Callback',@plane_ok_callback);
  plane_cancel_pushbutton = uicontrol('style','pushbutton','Position',[500 30 75 30],'String','Cancel','FontSize',12,'BackgroundColor',[0.8 0.8 0.8],'Callback','close');
  
  uicontrol('style','text','String','aX+bY=Z-c','Position',[430 235 150 30],'FontSize',16,'BackgroundColor',[0.8 0.8 0.8],'HorizontalAlignment','left','FontName','Courier New');
  
  uicontrol('style','text','String','a:','Position',[430 190 150 30],'FontSize',12,'BackgroundColor',[0.8 0.8 0.8],'HorizontalAlignment','left','FontName','Courier New');
   uicontrol('style','text','String','b:','Position',[430 160 150 30],'FontSize',12,'BackgroundColor',[0.8 0.8 0.8],'HorizontalAlignment','left','FontName','Courier New');
    uicontrol('style','text','String','c:','Position',[430 130 150 30],'FontSize',12,'BackgroundColor',[0.8 0.8 0.8],'HorizontalAlignment','left','FontName','Courier New');
     uicontrol('style','text','String','R^2:','Position',[430 100 150 30],'FontSize',12,'BackgroundColor',[0.8 0.8 0.8],'HorizontalAlignment','left','FontName','Courier New');
     
     plane_a_text = uicontrol('style','text','String','','Position',[470 190 80 30],'FontSize',12,'BackgroundColor',[0.8 0.8 0.8],'HorizontalAlignment','right','FontName','Courier New');
plane_b_text = uicontrol('style','text','String','','Position',[470 160 80 30],'FontSize',12,'BackgroundColor',[0.8 0.8 0.8],'HorizontalAlignment','right','FontName','Courier New');
plane_c_text = uicontrol('style','text','String','','Position',[470 130 80 30],'FontSize',12,'BackgroundColor',[0.8 0.8 0.8],'HorizontalAlignment','right','FontName','Courier New');
plane_r2_text = uicontrol('style','text','String','','Position',[470 100 80 30],'FontSize',12,'BackgroundColor',[0.8 0.8 0.8],'HorizontalAlignment','right','FontName','Courier New');

% added by Chang 01/05/22 (create c++ mex function out of process)
mh = mexhost; 
feval(mh,"mDAC",'set_plane_dialog_items',plane_x_edit,plane_y_edit,plane_z_edit,plane_listbox,plane_offset_edit,plane_a_text,plane_b_text,plane_c_text,plane_r2_text);
% mDAC('set_plane_dialog_items',plane_x_edit,plane_y_edit,plane_z_edit,plane_listbox,plane_offset_edit,plane_a_text,plane_b_text,plane_c_text,plane_r2_text);


    function plane_add_callback(src,evnt)
        x_val = get(plane_x_edit,'string');
        y_val = get(plane_y_edit,'string');
        z_val = get(plane_z_edit,'string');
        % added by Chang 01/05/22 (create c++ mex function out of process)
        mh = mexhost; 
        feval(mh,"mDAC",'add_plane_point',str2num(x_val),str2num(y_val),str2num(z_val));
%         mDAC('add_plane_point',str2num(x_val),str2num(y_val),str2num(z_val));
    end

    function delete_all_callback(src,evnt)
        % added by Chang 01/05/22 (create c++ mex function out of process)
        mh = mexhost; 
        feval(mh,"mDAC",'delete_all_position');
%         mDAC('delete_all_position');
    end

    function delete_selected_callback(src,evnt)
       num_sel = get(plane_listbox,'Value');
       % added by Chang 01/05/22 (create c++ mex function out of process)
       mh = mexhost; 
       feval(mh,"mDAC",'delete_selected_position',num_sel);
%        mDAC('delete_selected_position',num_sel);
    end

    function get_current_pos_callback(src,evnt)
        % added by Chang 01/05/22 (create c++ mex function out of process)
        mh = mexhost; 
        feval(mh,"mDAC",'get_current_position');
%         mDAC('get_current_position');
    end

    function plane_ok_callback(src,envt)
       % added by Chang 01/05/22 (create c++ mex function out of process)
        mh = mexhost; 
        feval(mh,"mDAC",'plane_ok');
%        mDAC('plane_ok');
       close(pbox);
    end

end   
% --- Outputs from this function are returned to the command line.
function varargout = test_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
%
varargout{1} = handles.output;
%varargout(2) =get(TextBox_tip_pos_y_value,'String')
end

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% added by Chang 01/05/22 (create c++ mex function out of process)
mh = mexhost; 
% feval(mh,"mDAC",'close');
mDAC('close');
clear mDAC;
%delete(handles.Thorfig);
%set(handles.tip_figure,'CloseRequestFcn','closereq');
delete(handles.tip_figure);
delete(handles.scan_figure);
delete(handles.scan_info_figure);
% try
%     delete(handles.micronix_figure);
% catch
%     xx='micronix close failed'
% end
% Hint: delete(hObject) closes the figure
delete(hObject);
%pause(5);
%clear mex;
end


function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double
end

% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function edit2_Callback(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit2 as text
%        str2double(get(hObject,'String')) returns contents of edit2 as a double
end

% --- Executes during object creation, after setting all properties.
function edit2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function edit3_Callback(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit2 as text
%        str2double(get(hObject,'String')) returns contents of edit2 as a double
end

% --- Executes during object creation, after setting all properties.
function edit3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
x_edit = get(handles.edit1,'String');
mDAC('move_MCL',1,str2num(x_edit));
end



% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
x_edit = get(handles.edit1,'String');
mDAC('move_MCL',1,-str2num(x_edit));
end

% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
y_edit = get(handles.edit2,'String');
% added by Chang 01/05/22 (create c++ mex function out of process)
mh = mexhost; 
feval(mh,"mDAC",'move_MCL',2,str2num(y_edit));
% mDAC('move_MCL',2,str2num(y_edit));
end

% --- Executes on button press in pushbutton4.
function pushbutton4_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
y_edit = get(handles.edit2,'String');
% added by Chang 01/05/22 (create c++ mex function out of process)
mh = mexhost; 
feval(mh,"mDAC",'move_MCL',2,-str2num(y_edit));
% mDAC('move_MCL',2,-str2num(y_edit));
end

% --- Executes on button press in pushbutton5.
function pushbutton5_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
z_edit = get(handles.edit3,'String');
% added by Chang 01/05/22 (create c++ mex function out of process)
mh = mexhost; 
feval(mh,"mDAC",'move_MCL',3,str2num(z_edit));
% mDAC('move_MCL',3,str2num(z_edit));
end

% --- Executes on button press in pushbutton6.
function pushbutton6_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
z_edit = get(handles.edit3,'String');
% added by Chang 01/05/22 (create c++ mex function out of process)
mh = mexhost; 
feval(mh,"mDAC",'move_MCL',3,-str2num(z_edit));
% mDAC('move_MCL',3,-str2num(z_edit));
end


function edit4_Callback(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit4 as text
%        str2double(get(hObject,'String')) returns contents of edit4 as a double
end

% --- Executes during object creation, after setting all properties.
function edit4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on button press in pushbutton9.
function pushbutton9_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%x = [0:0.01:6];
%y = sin(x);
%plot(handles.approach_plot,x,y);
z_in = get(handles.edit4,'String');
% added by Chang 01/05/22 (create c++ mex function out of process)
mh = mexhost; 
feval(mh,"mDAC",'z_in',str2num(z_in));
% mDAC('z_in',str2num(z_in));
end

% --- Executes on button press in pushbutton11.
function pushbutton11_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%mDAC('start_approach');
end


% --- Executes on button press in pushbutton12.
function pushbutton12_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end
%mDAC('stop_approach');
