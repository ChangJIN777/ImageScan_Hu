function APThandle=ConnectToAPT(TCubeSN)
% Opens the Thorlabs ActiveX APT controller

%Build Figure Window
APTFigPos    = get(0,'DefaultFigurePosition'); % figure default position
APTFigPos(3) = 500; % figure window size;Width
APTFigPos(4) = 300; % Height
 
APTFig = figure('Position', APTFigPos,'Menu','None','Name','APT GUI');

% Create ActiveX control
APThandle = actxcontrol('MGMOTOR.MGMotorCtrl.1',[0 0 500 300 ], APTFig);

% Start Control, set serial number, and identify the device
APThandle.StartCtrl;
set(APThandle,'HWSerialNum',TCubeSN);
APThandle.Identify;
pause(2);
disp('Initialization Pause End')

% Event Handling - Wei Wang's code; goes with function movecompletehandler
APThandle.registerevent({'MoveComplete' 'MoveCompleteHandler'});