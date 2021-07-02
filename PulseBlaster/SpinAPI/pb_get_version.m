function [version] = pb_get_version()
%[neg_on_err] = pb_stop_programming()
%DESCRIPTION: Get the version of this library. The version is a string in
%the form YYYYMMDD. 
%INPUTS:
%
%OUTPUTS:
% version - A string indicating the version of this library is returned.  

version = calllib('spinapi','pb_get_version');