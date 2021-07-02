function scan_tracking( )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

%mNIDAQ('StopDifference');

    global Img_handles;
    
   Img_handles.StateControl.changeToTrackingState(Img_handles,true);
    Img_handles.StateControl.changeToIdleState(Img_handles);
    
  % mNIDAQ('GetDifference');
end

