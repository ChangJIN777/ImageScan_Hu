%mex -lMadlib create_thread.cpp 
mex  -compatibleArrayDims -lNIDAQmx mNIDAQ.cpp

copyfile('mNIDAQ.mexw64','C:\Users\lab\Documents\MATLAB\ImageScan\ImageAquire\')