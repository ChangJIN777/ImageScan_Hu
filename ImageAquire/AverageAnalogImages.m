% averaging scripts for images

name = 'm_';
first = 1;
last = 16;

imAvg = 0;
loop1 = true;
for j=first:last
   zeros= '';
   if j < 10
       zeros = '000';
   elseif j<100
       zeros = '00';
   end
   stfile = ['C:\Users\lab\Documents\Data\2015_Jun_18\',name,zeros,num2str(j),'ai.txt'];
   st = importdata(stfile);
   
   if loop1
      imAvg = st.data;
      loop1=false;
   else
       imAvg = imAvg + st.data;
   end
end

numIm = last-first +1;
if numIm>0
    imAvg = imAvg/numIm;
end

figure;
imagesc([-80,-35],[4,49],imAvg);
