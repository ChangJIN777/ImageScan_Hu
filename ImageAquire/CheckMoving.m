function ismoving = CheckMoving(handles)

% Checks to see if the actuators are moving in X, Y, or Z
%   by comparing positions every 70 ms. Output is 1 if
%   any axis is moving, and 0 if all are idle.

ismoving = 1;
tols = 0.005; % demand 5 micron precision
counter = 0; % demand conditions met multiple times

% delay during initial acceleration
pause(.4)

% get initial positions and time
t1=clock;
xposb = handles.APThandleX.GetPosition_Position(0);
yposb = handles.APThandleY.GetPosition_Position(0);
zposb = handles.APThandleZ.GetPosition_Position(0);
pause(.07)

% loop
while(etime(clock,t1)<handles.timeout)
    xposa = handles.APThandleX.GetPosition_Position(0);
    yposa = handles.APThandleY.GetPosition_Position(0);
    zposa = handles.APThandleZ.GetPosition_Position(0);
    
    xdiff = abs(xposa-xposb);
    ydiff = abs(yposa-yposb);
    zdiff = abs(zposa-zposb);
    
    if xdiff<tols&&ydiff<tols&&zdiff<tols
        counter = counter + 1;
    end
    
    if counter >= 2
        ismoving = 0;
        pause(0.05) %50 ms settle pause
        break
    end
    
    xposb = xposa;
    yposb = yposa;
    zposb = zposa;
    
    pause(0.07)
end
end