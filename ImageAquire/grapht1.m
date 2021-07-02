figure(500);
errorbar(t1long(:,1)+0.5,t1long(:,2)/10.429,t1long(:,3)/10.429,'-r');

hold on;
errorbar(t1short(:,1)+0.5,t1short(:,2)/1.19,t1short(:,3)/1.19);
