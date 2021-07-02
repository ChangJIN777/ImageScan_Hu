function varargout = Si_PD_ImageScan(varargin)
% SI_PD_IMAGESCAN MATLAB code for Si_PD_ImageScan.fig
%      SI_PD_IMAGESCAN, by itself, creates a new SI_PD_IMAGESCAN or raises the existing
%      singleton*.
%
%      H = SI_PD_IMAGESCAN returns the handle to a new SI_PD_IMAGESCAN or the handle to
%      the existing singleton*.
%
%      SI_PD_IMAGESCAN('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SI_PD_IMAGESCAN.M with the given input arguments.
%
%      SI_PD_IMAGESCAN('Property','Value',...) creates a new SI_PD_IMAGESCAN or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Si_PD_ImageScan_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Si_PD_ImageScan_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Si_PD_ImageScan

% Last Modified by GUIDE v2.5 25-Sep-2016 17:05:33

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Si_PD_ImageScan_OpeningFcn, ...
                   'gui_OutputFcn',  @Si_PD_ImageScan_OutputFcn, ...
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


% --- Executes just before Si_PD_ImageScan is made visible.
function Si_PD_ImageScan_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Si_PD_ImageScan (see VARARGIN)

% Choose default command line output for Si_PD_ImageScan
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Si_PD_ImageScan wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Si_PD_ImageScan_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Img_handles;
global esr_handles;

global laser_x_handle;
global laser_y_handle;
 global is_center;
 is_center = 0;


 %Xlimits= get(Img_handles. confocalAxes,'XLim');
 %Ylimits= get(Img_handles. confocalAxes,'YLim');
 
 Xlimits = [-100,100];
 Ylimits = [-100,100];
 
 
 
 
 points_X=20;
 points_Y=20;
 
                   
            
% generate xy coordinate list

x_microns= linspace(Xlimits(1), Xlimits(2), points_X);
y_microns=linspace(Ylimits(1),Ylimits(2), points_Y);

%Img_handles.ScanControl.ScanParameters.micronsPerVoltX
%Img_handles.ScanControl.ScanParameters.micronsPerVoltY

% copnvert to volta
%Xvolts = x_microns/Img_handles.ScanControl.ScanParameters.micronsPerVoltX;
%Yvolts = y_microns/Img_handles.ScanControl.ScanParameters.micronsPerVoltY;

Xvolts = x_microns / 140;
Yvolts = y_microns / 139;

 Va = Xvolts;
                Vb = Yvolts;             
                VoltageMatrix = zeros(length(Va),length(Vb),2);             
                VoltageMatrix(:,:,1) = Va(:) * ones(1,length(Vb));           
                VoltageMatrix(:,:,2) = ones(length(Va),1)*Vb;            
                VoltageMatrix(:,2:2:end,1)=flipdim(VoltageMatrix(:,2:2:end,1),1);              
                VoltageTuples = reshape(VoltageMatrix,[],2,1);
                VoltageTuples=flipud(VoltageTuples);
clockFreq = 200; %Hz
Nsamples = points_X*points_Y;

mNIDAQ('CreateTask','PulseTrain2')
mNIDAQ('CreateTask','ScanVoltageOut')
mNIDAQ('CreateTask','ReadPhotodiode')

devices1 = ['PXI1Slot2/ao0',',','PXI1Slot2/ao1'];

    mNIDAQ('ConfigureClockOut','PulseTrain2','PXI1Slot2/ctr1',clockFreq,.5,Nsamples)
 
   
  mNIDAQ('ConfigureVoltageOut','ScanVoltageOut',devices1,2,points_X*points_Y,'/PXI1Slot2/PFI13',200,-5,10,VoltageTuples);
   
  devices2 ='PXI1Slot2/ai0'  ;
  
  mNIDAQ('ConfigureVoltageIn','ReadPhotodiode',devices2,1,points_X*points_Y,'/PXI1Slot2/PFI13',200,-10,...
                 10,points_X*points_Y);
             
             
             
   mNIDAQ('StartTask','ScanVoltageOut');
   mNIDAQ('StartTask','ReadPhotodiode');
mNIDAQ('StartTask','PulseTrain2')
   
%set(handles.pushbutton1, 'String', 'Scanning');

  
    %wait till counts are aquired
    while (~mNIDAQ('IsTaskDone', 'ReadPhotodiode'))        
       pause(0.1); 
    end
     
  %  set(handles.pushbutton1, 'String', 'Scan Image');
    %%read the samples from the Counter buffer
    Ncounts = mNIDAQ('GetAvailableSamples','ReadPhotodiode')
    photo_diode_V = mNIDAQ('ReadVoltageIn','ReadPhotodiode',Ncounts);
   
    reflected_Img1=   reshape (photo_diode_V , points_X, points_Y);
   reflected_Img1(:,2:2:end) = flipdim(reflected_Img1(:,2:2:end),1);
   reflected_Img1 = rot90(reflected_Img1,1);
  global final_Img 
  
  final_Img = reflected_Img1;
   imshow(reflected_Img1*8);
  
   'donee'
   
 mNIDAQ ('StopTask','PulseTrain2')
 mNIDAQ ('StopTask','ScanVoltageOut')
 mNIDAQ ('StopTask','ReadPhotodiode')
 mNIDAQ('ClearAllTasks')
 


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
circle_x = str2num(get(handles.edit2,'String'));
circle_y = str2num(get(handles.edit3,'String'));
circle_rad= str2num(get(handles.edit1,'String'));

cla
global final_Img

imshow(final_Img*8)
viscircles([circle_x,circle_y],circle_rad)

% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

circle_x = str2num(get(handles.edit2,'String'));
circle_y = str2num(get(handles.edit3,'String'));
circle_rad= str2num(get(handles.edit1,'String'));
i=0;

for x=(circle_x- circle_rad):(circle_x+circle_rad)
    
    for y = (circle_y - circle_rad):(circle_y+circle_rad)
     
        distance = sqrt((circle_x-x)^2  + (circle_y-y)^2);
        
        if distance <= circle_rad
            i = i+1;
            points_inside_circle(i,1)=x;
            points_inside_circle(i,2)=y;            
        end
        
        
        
    end
end

%calculate the mean light intensity inside the circle
global final_Img
intensity = 0;

for j=1:i
    final_Img (points_inside_circle(j,2),points_inside_circle(j,1))
    intensity   = final_Img (points_inside_circle(j,2),points_inside_circle(j,1)) + intensity;
end

intensity = intensity/i;
set(handles.text4, 'String', intensity);







function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double


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



function edit2_Callback(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit2 as text
%        str2double(get(hObject,'String')) returns contents of edit2 as a double


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



function edit3_Callback(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit3 as text
%        str2double(get(hObject,'String')) returns contents of edit3 as a double


% --- Executes during object creation, after setting all properties.
function edit3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
