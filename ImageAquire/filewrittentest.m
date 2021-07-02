fileID = fopen('driftingdata.txt','a');
fprintf(fileID,'%7.2f %7.2f %7.2f %7.2f %7.2f %7.2f %7.2f %7.2f %7.2f %7.2f\n',driftingdata(1,:));
fclose(fileID);