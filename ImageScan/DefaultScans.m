function scans = DefaultScans()
        % changed on 9-17-12, 9-18-12 to make the voltage values into
        % micron values
        % hardcoded the microns/volt values into the configuration
        
        %04-20-2013
        % use NaN to indicate that this scan setting should not be changed
        % from the current value. E.g., in a 'Local XY Scan' the MinValues
        % and MaxValues should not be changed from how they are, rather
        % just number of points and bEnable scan axes are changed.
        
        %To add a new type of scan copy one of these blocks and increment
        %the number to scans(8), scans(9), etc...
        
        scans = struct();
        
        scans(1).MinValues = [NaN NaN NaN]; % scan limit in [x y z] in µm
        scans(1).MaxValues = [NaN NaN NaN]; % scan limit in [x y z] in µm
        scans(1).NPoints = [80 80 NaN]; % [Nx Ny Nz]
        scans(1).OffsetValues = [NaN NaN NaN]; % beware, offsetValues may be a little obsolete
        scans(1).DwellTime = 0.004; % time per pixel in seconds
        scans(1).bEnable = [1 1 0]; % enable (1) or disable (0) axes [bx by bz]
        scans(1).MenuName = 'Local XY Scan'; % string name to identify
        
        scans(2).MinValues = [-50 -50 NaN];
        scans(2).MaxValues = [50 50 NaN];
        scans(2).NPoints = [80 80 NaN];
        scans(2).OffsetValues = [0 0 NaN];
        scans(2).DwellTime = 0.004;
        scans(2).bEnable = [1 1 0];
        scans(2).MenuName = 'Large XY Scan';
        
        scans(3).MinValues = [NaN NaN NaN];
        scans(3).MaxValues = [NaN NaN NaN];
        scans(3).NPoints = [NaN NaN 200];
        scans(3).OffsetValues = [NaN NaN NaN];
        scans(3).DwellTime = 0.1;
        scans(3).bEnable = [0 0 1];
        scans(3).MenuName = 'Local Z Scan';
        
        scans(4).MinValues = [NaN NaN -50];
        scans(4).MaxValues = [NaN NaN 50];
        scans(4).NPoints = [NaN NaN 200];
        scans(4).OffsetValues = [NaN NaN 0];
        scans(4).DwellTime = 0.1;
        scans(4).bEnable = [0 0 1];
        scans(4).MenuName = 'Large Z Scan';
        
        scans(5).MinValues = [NaN NaN NaN];
        scans(5).MaxValues = [NaN NaN NaN];
        scans(5).NPoints = [NaN NaN NaN];
        scans(5).OffsetValues = [NaN NaN NaN];
        scans(5).DwellTime = 0.004;
        scans(5).bEnable = [1 1 1];
        scans(5).MenuName = 'Local 3D Scan';
        
        scans(6).MinValues = [-125 -125 40];
        scans(6).MaxValues = [125 125 60];
        scans(6).NPoints = [80 80 10];
        scans(6).OffsetValues = [0 0 0];
        scans(6).DwellTime = 0.004;
        scans(6).bEnable = [1 1 1];
        scans(6).MenuName = 'Large 3D Scan';
        
        scans(7).MinValues = [NaN NaN NaN];
        scans(7).MaxValues = [NaN NaN NaN];
        scans(7).NPoints = [NaN NaN 80];
        scans(7).OffsetValues = [NaN NaN NaN];
        scans(7).DwellTime = 0.4;
        scans(7).bEnable = [0 0 1];
        scans(7).MenuName = 'Local Z Scan, Slow';

end    

