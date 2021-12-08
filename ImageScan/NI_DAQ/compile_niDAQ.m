mex  -compatibleArrayDims -'IC:\Program Files (x86)\National Instruments\Shared\ExternalCompilerSupport\C\include' '-LC:\Program Files (x86)\National Instruments\Shared\ExternalCompilerSupport\C\lib64\msvc' -lNIDAQmx mNIDAQ.cpp
copyfile('mNIDAQ-test.mexw64','..\')

% Note: run this with VisualStudio 2017 compiler for C++ - it might not
% work properly if run with a differenct compiler