function readout_optimization()
%we want to measure number of photons from 0 for a given readout
%time, then repeat the process immediately for the -1 state. 

%SNR = (Number measured from 0 - Number measured from -1) / sqrt(Number
%measured from 0 + Number measured from 1)
%This yields the biggest measurable difference between the 0 and -1 state,
%which correponds to the best measurement we can make.

%Make GUI where you can set range of readout times and number of points in
%the curve, and then have it plot the curve realtime.

firstTauCmd = 'divideBy2';
secondTauCmd = 'yMinusFirst';

global Scan_Finished_Flag
global Img_handles;
global esr_handles;

global laser_x_handle;
global laser_y_handle;

global ESR_pulsed_handles;

readoutStart = 240; %ns
readoutEnd = 1200; %ns
numb_repeats = 220;

readout = readoutStart:20:readoutEnd;
ii = 0;
for r = readout

ii = ii+1;   

set(esr_handles.readoutTime,'String',num2str(r));
ESRControl('buttonStartSequence_Callback',0,0,esr_handles); %Start current ESR sequence


        % be sure this is not skipped
        while ( get(esr_handles.writeDataFreq,'UserData') == 1)
                    'while loop for not skipping esrcontrol'
            pause(0.5); 
        end
        'ended past ESRControl and while loop enable'
        
                % extract the pulse sequence data at this height
        path1 = get(esr_handles.esrSavePath,'String');
        path2 = get(esr_handles.esrSaveFilePrefix,'String');
        path3 = get(esr_handles.esrSaveFileNum,'String');
      
        % for every signal channel of the sequence, there is 1 file to read in
        % containing a sig and ref.
        % '_a_b.txt' where a=1,2 for channel and b=0,1,2... for tau points
        pathPrefix = [path1 path2 path3 '\' path2 path3]; 
        
        sweep = 0;
        numc = 2;
        numTauPoints = 2;
        
        firstNum = '';
secondNum='';
useNum='';
        
        for sweep = 0:(numb_repeats -1)

        filepath1 = [pathPrefix '_1_',num2str(sweep),'.txt'];
        filepath2 = [pathPrefix '_2_',num2str(sweep),'.txt'];
        d1 = importdata(filepath1);
        d2 = importdata(filepath2);
        celld = {d1,d2};
        signalArray = zeros(numc,numTauPoints*3);
        for c=1:numc 
            for nt=1:numTauPoints
                signalArray(c,3*nt-2) = celld{c}.data(nt,1); % gets 2 tau
                signalArray(c,3*nt-1) = celld{c}.data(nt,2); % gets signal
                signalArray(c,3*nt) = celld{c}.data(nt,3);  % gets reference
            end
        end
        % how to handle 2tau data, which is column index 1,4,7,10,...
        switch(firstTauCmd)
            case 'divideBy2'
                % for getting tau
                signalArray(1,1:3:end) = signalArray(1,1:3:end)./2; % get tau
        end
        switch(secondTauCmd)
            case 'yMinusFirst'
                % for getting y-tau,or y-2tau, etc...
                tauEndVal = str2double(get(esr_handles.tauEnd,'String'));
                tauStartVal = str2double(get(esr_handles.tauStart,'String'));
                signalArray(2,1:3:end) = tauEndVal +tauStartVal - signalArray(1,1:3:end); % get tau
        end
        
        % put all data for single x point into a matrix with 1 row
        % transpose first to take all of row 1, then all row 2, ...
        scanTauPLTriplets = reshape(signalArray',1,numTauPoints*3*numc);
                
                scanTauPLTriplets = reshape(signalArray',1,numTauPoints*3*numc);
       
        if sweep ==0
            scanTauPLTriplets_all = scanTauPLTriplets;
        else
            scanTauPLTriplets_all = [scanTauPLTriplets_all; scanTauPLTriplets];
        end
        
        
        
        end
        
        
        %----------------------------------------------
      
%         % write the .info file on the first cycle
%         if (AFM_galvo_track==1)
%             % ---------write a .info file----------------
%             infoFilename   = [path1,'\',path2,useNum,'.dat'];
%             dlmwrite(infoFilename, datestr(date),'-append','delimiter','');
%             dlmwrite(infoFilename, 'Size: 0.0 V x 0.0 V','-append','delimiter','');
%             dlmwrite(infoFilename, 'Center: (0.0 V, 0.0 V)','-append','delimiter','');
%             dlmwrite(infoFilename, ['Resolution: 1 x 1 x ',num2str(1)],'-append','delimiter','');  % should change this later to give the correct resolution
%             dlmwrite(infoFilename, 'Scan Speed: 0 Hz','-append','delimiter','');
%             dlmwrite(infoFilename, 'Rotation: 0 deg','-append','delimiter','');
%             dlmwrite(infoFilename, ' ','-append','delimiter','');
%             dlmwrite(infoFilename, 'Column Headings:','-append','delimiter','');
%             chanPosLabels = 'X / Y / Z nm from surf / Z - surf nm';
%             chanMeasLabels = ' / tau / sig / ref';
%             chanMeasLabels = repmat(chanMeasLabels,1,(numTauPoints*numc));
%             dlmwrite(infoFilename, [chanPosLabels,chanMeasLabels],'-append','delimiter','');
%             %------------------------------------------------
%         end
        
        counts_0 = r*1e-9*1000*(sum(scanTauPLTriplets_all(:,3)) + sum(scanTauPLTriplets_all(:,6)));%
        counts_neg1 = r*1e-9*1000*(sum(scanTauPLTriplets_all(:,2)) + sum(scanTauPLTriplets_all(:,5)));%
        SNR(ii) = (counts_0 - counts_neg1) ./ (sqrt(counts_0 + counts_neg1))
        
     if (mod(ii,1)==0)
        ESR_pulsed_handles.gesr.RunSingleTrackPulsedESR(ESR_pulsed_handles.imageScanHandles);
     end 
end

figure
plot(readout, SNR)
xlabel('Readout Time (ns)')
ylabel('Signal-to-Noise ratio')

set(gcf, 'color', 'w')
set(gca, 'fontsize', 20)
end