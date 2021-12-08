classdef MagnetCursor <handle
    %Controls the cursor for the PL magnet scan program

    properties
        hCursor = [];
    end
    
    methods
        
        function obj=MagnetCursor
        end
        
        function updateCursor(obj,handles)%,position)
            % First, reset the scan axes to the right orientation/range
            if handles.scanmode == 1
                xlabel(handles.axesMagnet,'X (mm)')
                ylabel(handles.axesMagnet,'Y (mm)')
                xlim(handles.axesMagnet,[-1*handles.range+handles.scancenter(1),handles.range+handles.scancenter(1)]);
                ylim(handles.axesMagnet,[-1*handles.range+handles.scancenter(2),handles.range+handles.scancenter(2)]);
            elseif handles.scanmode == 2
                xlabel(handles.axesMagnet,'X (mm)')
                ylabel(handles.axesMagnet,'Z (mm)')
                xlim(handles.axesMagnet,[-1*handles.range+handles.scancenter(1),handles.range+handles.scancenter(1)]);
                ylim(handles.axesMagnet,[-1*handles.range+handles.scancenter(3),handles.range+handles.scancenter(3)]);
            elseif handles.scanmode == 3
                % XXX
                disp('XYZ scanning not yet implemented')
            end
            
            % Get mouse click values in local variables
            [val1,val2] = ginput(1);
            
            % Set cursor values for the right axes
            if handles.scanmode == 1
                set(handles.editCursorX,'String',val1);
                set(handles.editCursorY,'String',val2);
            elseif handles.scanmode == 2
                set(handles.editCursorX,'String',val1);
                set(handles.editCursorZ,'String',val2);
            elseif handles.scanmode == 3
                disp('XYZ scanning not yet implemented')
                % XXX
            end
            
        end
        
        function drawCursor(obj,handles)
            
            currentAxes = handles.axesMagnet;
            hold(currentAxes,'on');
            
            % delete old cursor
            obj.deleteCursor(handles)
            
            % draw new cursor
            switch handles.scanmode
                case 1
                    obj.hCursor = plot(currentAxes,handles.magcurspos(1),...
                        handles.magcurspos(2),'+k','MarkerSize',15);
                case 2
                    obj.hCursor = plot(currentAxes,handles.magcurspos(1),...
                        handles.magcurspos(3),'+k','MarkerSize',15);
            end
            
            hold(currentAxes,'off');
        end
        
        function deleteCursor(obj,handles)
                if ~isempty(obj.hCursor);
                    delete(obj.hCursor);
                    obj.hCursor = [];
                end
        end
        
    end
end