% COM stuff

nanoA = actxserver('NanoScope.OpenArchitecture','\\AFMPC');
nanoZ = actxserver('NanoScope.zApi','\\AFMPC');

% using nano.properties doesn't give any, instead use
nanoA.get
nanoZ.get
% these will list all the parameters with values given when no specific
% parameter is asked for.

nanoZ.IsWithdrawn

% for the measurement sequence
% 0) begin with the tip centered close to confocal 0,0 position, as possible
% 1) confocal scan the area, find an NV candidate
% 2) Test whether this is an NV using ESR and photostability
% 3) Be sure the cursor is exactly on the NV x,y position
% 4) Click button on GUI to use the cursor as an input and make the AFM stage move automatically to a new
% position such that the NV of interest 
%the x direction of the AFM is east-west and the x direction of confocal is
%north south


% use the following to release only one interface + resources
nanoA.release;
nanoZ.release;

% use to delete ALL interfaces with COM object. delete object itself
% this is probably best as I don't think I will have multiple interfaces
nanoA.delete; 
nanoZ.delete; 