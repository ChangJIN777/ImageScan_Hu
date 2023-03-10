classdef StateControl < handle
    % class that controls the confocal state (= scanning, tracking, idle)
    % it also changes the buttons in the GUI and makes sure the changes of
    % state run smoothly - this class does no execute any scans or anything else
    % 
    
    properties
        state;
        externalStop = true;
    end
    
    properties (Constant)
        SCANNING = 1;
        CURSOR = 2;         %state where running count is running
        IDLE = 3;           %user is able to switch to other states 
        TRACKING = 4;       %state where running count and tracking are running
        
        scanButtonStartText = 'Start Scan';
        scanButtonStopText = 'Stop Scan';
        runningCountButtonStartText = 'Start Running Count';
        runningCountButtonStopText = 'Stop Running Count';
        trackingButtonStartText = 'Start Tracking';
    end
    
    methods
        function obj = StateControl()
            obj.state = StateControl.IDLE;
        end
        
        function changeToScanningState(obj,handles,usedButtonNr)
            handles.CursorControl.deleteManualCursor(handles);
            obj.state = StateControl.SCANNING;
            
            % disable all scanning buttonsb ==========================
            p = {'buttonStartStopScan' 'buttonStartStopLargeXYScan' 'buttonStartStopLocalXYScan' 'buttonStartStopZScan' 'buttonStartStopRunningCount' 'buttonStartTracking'}; % array with scanning buttons
            for k = 1:max(size(p))
                handles.(p{k}).Enable = 'off';   
            end    
            % ========================================================
            % reanable the currently used button =====================         
            handles.(p{usedButtonNr}).Enable = 'on';
            if usedButtonNr < 5
                handles.(p{usedButtonNr}).String = StateControl.scanButtonStopText;
            elseif usedButtonNr > 4
                handles.(p{usedButtonNr}).String = StateControl.runningCountButtonStartText;
            end
            % ========================================================
            
            bTracking = false;
            handles.ScanControl.performScan(handles,bTracking);
            
            %after finished go to idle state
            obj.changeToIdleState(handles,usedButtonNr);
            clear k usedButtonNr p
        end
        
        function changeToCursorState(obj,handles,usedButtonNr)
            switch obj.state 
                case StateControl.IDLE
                    
                case StateControl.TRACKING
                    handles.CursorControl.endTrackingMode(handles);
                    handles.ScanControl.stopScan();
                    handles.ScanControl.finishScan(handles);
            end
            
            handles.CursorControl.deleteManualCursor(handles);
            handles.CursorControl.createManualCursor(handles);
            
            % disable all scanning buttons
            p = {'buttonStartStopScan' 'buttonStartStopLargeXYScan' 'buttonStartStopLocalXYScan' 'buttonStartStopZScan' 'buttonStartStopRunningCount' 'buttonStartTracking'}; % array with scanning buttons
            for k = 1:max(size(p))
                handles.(p{k}).Enable = 'off';   
            end    
            % reanable the currently used button          
            handles.(p{usedButtonNr}).Enable = 'on';
            if usedButtonNr < 5
                handles.(p{usedButtonNr}).String = StateControl.scanButtonStopText;
            elseif usedButtonNr > 4
                handles.(p{usedButtonNr}).String = StateControl.runningCountButtonStopText;
            end
            clear p k usedButtonNr
            
            obj.state = StateControl.CURSOR;

            handles.CursorControl.runCount(handles);
            if obj.state == StateControl.TRACKING
            end
        end
                
        function changeToTrackingState(obj,handles,usedButtonNr, bSingleTrack)
            if ~exist('bSingleTrack', 'var')
                bSingleTrack = false;
            end
            switch obj.state 
                case StateControl.IDLE
                    % disable all scanning buttons
                    if usedButtonNr ~=0
                        p = {'buttonStartStopScan' 'buttonStartStopLargeXYScan' 'buttonStartStopLocalXYScan' 'buttonStartStopZScan' 'buttonStartStopRunningCount' 'buttonStartTracking'}; % array with scanning buttons
                        for k = 1:max(size(p))
                            handles.(p{k}).Enable = 'off';   
                        end    
                        % reanable the currently used button          
                        handles.(p{usedButtonNr}).Enable = 'on';
                        if usedButtonNr < 5
                            handles.(p{usedButtonNr}).String = StateControl.scanButtonStopText; % displays "Stop Scanning"
                        elseif usedButtonNr > 4
                            handles.(p{usedButtonNr}).String = StateControl.runningCountButtonStopText; % displays "Stop Running Counts"
                        end

                        clear p k usedButtonNr
                    end
                case StateControl.CURSOR
                    handles.CursorControl.deleteManualCursor(handles);
                    handles.CursorControl.stopCount();
            end
            obj.state = StateControl.TRACKING;
            if ~isempty(handles.ScanControl.currentScanParameters)
                handles.ScanControl.stopScan();
                handles.ScanControl.finishScan(handles);
            end
            handles.CursorControl.startTrackingMode(handles, bSingleTrack);
        end
        
        function changeToIdleState(obj,handles,usedButtonNr)
            switch obj.state 
                case StateControl.SCANNING
                    %createManualCursor done in the end of 
                    %changeToScanningState so it doesn't interrupt performScan.
                    handles.ScanControl.stopScan();
                    handles.ScanControl.finishScan(handles);
                    handles.CursorControl.createManualCursor(handles);
                    obj.redrawNVLabels(handles);
                                        
                case StateControl.CURSOR               
                    handles.CursorControl.stopCount();
                
                case StateControl.TRACKING
                    % currently 4/19/13 this tracking stop code is very
                    % disruptive as it stops the tracking in the middle of
                    % wherever it is scanning, counting etc.
 
                    handles.CursorControl.endTrackingMode(handles);
                    handles.CursorControl.stopCount();
                    handles.ScanControl.stopScan();
                    handles.ScanControl.finishScan(handles);
            end
            handles.CursorControl.deleteManualCursor(handles);
            handles.CursorControl.createManualCursor(handles);
            
            % enable all scanning buttons
            p = {'buttonStartStopScan' 'buttonStartStopLargeXYScan' 'buttonStartStopLocalXYScan' 'buttonStartStopZScan' 'buttonStartStopRunningCount' 'buttonStartTracking'}; % array with scanning buttons
            for k = 1:max(size(p))
                handles.(p{k}).Enable = 'on';   
            end    
            if usedButtonNr < 5
                handles.(p{usedButtonNr}).String = StateControl.scanButtonStartText;
            elseif usedButtonNr == 5
                handles.(p{usedButtonNr}).String = StateControl.runningCountButtonStartText;
            elseif usedButtonNr == 6
                handles.(p{usedButtonNr}).String = StateControl.trackingButtonStartText;
            end
            
            obj.state = StateControl.IDLE;
            
            clear p k usedButtonNr
        end

        function initializeState(obj,handles)
           
            handles.CursorControl.createManualCursor(handles); 
            set(handles.buttonStartStopRunningCount,'String',StateControl.runningCountButtonStartText);
            set(handles.buttonStartStopScan,'String',StateControl.scanButtonStartText);
            set(handles.buttonStartStopRunningCount,'Enable','on');
            set(handles.buttonStartStopScan,'Enable','on');      
            obj.state = StateControl.IDLE;
            
        end
        
        function delete(~)
        end
        
        function redrawNVLabels(~,handles)
            
            % delete the old text handles but not the data of position,type
            ind = find(handles.listNVMarkers(:));
            handles.listNVMarkers = zeros(1,handles.maxLabel);
            if ~isempty(ind)
                for jb=1:length(ind)
                    handles.listNVMarkerType(1,ind(jb));
                    mtype = handles.listNVMarkerType(1,ind(jb));
                    colorM='none';
                    %switch isn't working
                        if mtype== 15
                            colorM='red';
                        elseif mtype== 14
                            colorM='green';
                        elseif mtype== -1
                            colorM='none';
                        end
                    pointX = handles.listNVMarkerPos(1,ind(jb));
                    pointY = handles.listNVMarkerPos(2,ind(jb));
                    newMark = text(pointX,pointY,['\color{cyan}' get(handles.NVmarkerLetter,'String') num2str(ind(jb))],'FontSize',10,'HorizontalAlignment','center','EdgeColor',colorM,'LineStyle',':');
                    handles.listNVMarkers(jb) = newMark;
                end
            end
            
            guidata(handles.output, handles);
        end
        
        
    end
    
end

