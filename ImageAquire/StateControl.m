classdef StateControl < handle
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        state;
        externalStop = true;
    end
    
    properties (Constant)
        SCANNING = 1;
        CURSOR = 2;%state where running count is running
        IDLE = 3;%user is able to switch to other states 
        TRACKING = 4;%state where running count and tracking are running
        scanButtonStartText = 'Start Scan';
        scanButtonStopText = 'Stop Scan';
        runningCountButtonStartText = 'Start Running Count';
        runningCountButtonStopText = 'Stop Running Count';
    end
    
    methods
        function obj = StateControl()
            obj.state = StateControl.IDLE;
        end
        
        function changeToScanningState(obj,handles)
            %handles.CursorControl.deleteZoomBox(handles);
            handles.CursorControl.deleteManualCursor(handles);
            obj.state = StateControl.SCANNING;
            
            set(handles.buttonStartStopRunningCount,'String',StateControl.runningCountButtonStartText);
            set(handles.buttonStartStopScan,'String',StateControl.scanButtonStopText);
            set(handles.buttonStartStopRunningCount,'Enable','off');
            set(handles.buttonStartStopScan,'Enable','on');
            bTracking = false;
            handles.ScanControl.performScan(handles,bTracking);
            
            %create cursor here in case stopScan is pressed so it doesn't
            %interrupt performScan
            %handles.CursorControl.createZoomBox(handles);
            %handles.CursorControl.createManualCursor(handles); 
            
            %after finished go to idle state
            obj.changeToIdleState(handles);
        end
        
        function changeToCursorState(obj,handles)
            switch obj.state 
                case StateControl.IDLE
                    
                case StateControl.TRACKING
                    handles.CursorControl.endTrackingMode(handles);
                    %handles.CursorControl.createZoomBox(handles);
                    handles.ScanControl.stopScan();
                    handles.ScanControl.finishScan(handles);
            end
%             if get(handles.tabGroup, 'SelectedIndex') == length(get(handles.tabGroup, 'Children'))
%                 handles.ScanControl.fixTabs(handles);
%             end
            handles.CursorControl.deleteManualCursor(handles);
            %handles.ScanControl.currentTab = get(handles.tabGroup, 'SelectedTab');
            handles.CursorControl.createManualCursor(handles);
            set(handles.buttonStartStopRunningCount,'String',StateControl.runningCountButtonStopText);
            set(handles.buttonStartStopScan,'String',StateControl.scanButtonStartText);
            set(handles.buttonStartStopScan,'Enable','off');
            set(handles.buttonStartStopRunningCount,'Enable','on');
            
            obj.state = StateControl.CURSOR;

            handles.CursorControl.runCount(handles);
            if obj.state == StateControl.TRACKING
                %handles.CursorControl.startTrackingMode(handles);
            end
        end
                
        function changeToTrackingState(obj,handles, bSingleTrack)
            if ~exist('bSingleTrack', 'var')
                bSingleTrack = false;
            end
            switch obj.state 
                case StateControl.IDLE
                    %handles.CursorControl.runCount(handles);
                    %handles.CursorControl.deleteZoomBox(handles);
                    
                    set(handles.buttonStartStopRunningCount,'String',StateControl.runningCountButtonStopText);
                    set(handles.buttonStartStopScan,'String',StateControl.scanButtonStartText);
                    set(handles.buttonStartStopScan,'Enable','off');
                    set(handles.buttonStartStopRunningCount,'Enable','on');
                case StateControl.CURSOR
                    handles.CursorControl.deleteManualCursor(handles);
                    %handles.CursorControl.deleteZoomBox(handles);
                    handles.CursorControl.stopCount();
            end
            obj.state = StateControl.TRACKING;
            if ~isempty(handles.ScanControl.currentScanParameters)
                handles.ScanControl.stopScan();
                handles.ScanControl.finishScan(handles);
            end
            handles.CursorControl.startTrackingMode(handles, bSingleTrack);
        end
        
        function changeToIdleState(obj,handles)
            switch obj.state 
                case StateControl.SCANNING
                    %createManualCursor done in the end of
                    %changeToScanningState so it doesn't interrupt
                    %performScan.
                    handles.ScanControl.stopScan();
                    handles.ScanControl.finishScan(handles);
                    %handles.CursorControl.createZoomBox(handles);
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
            %handles.ScanControl.currentTab = get(handles.tabGroup, 'SelectedTab');
            handles.CursorControl.createManualCursor(handles);
            
            set(handles.buttonStartStopRunningCount,'String',StateControl.runningCountButtonStartText);
            set(handles.buttonStartStopScan,'String',StateControl.scanButtonStartText);
            set(handles.buttonStartStopRunningCount,'Enable','on');
            set(handles.buttonStartStopScan,'Enable','on');
            obj.state = StateControl.IDLE;
        end

        function initializeState(obj,handles)
            %handles.CursorControl.createZoomBox(handles);
            handles.CursorControl.createManualCursor(handles); 
            set(handles.buttonStartStopRunningCount,'String',StateControl.runningCountButtonStartText);
            set(handles.buttonStartStopScan,'String',StateControl.scanButtonStartText);
            set(handles.buttonStartStopRunningCount,'Enable','on');
            set(handles.buttonStartStopScan,'Enable','on');      
            obj.state = StateControl.IDLE;
        end
        
        function delete(obj)
        end
        
        function redrawNVLabels(obj,handles)
            
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

