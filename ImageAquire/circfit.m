function [x,y,r]=circfit(points)


X=points(:,1);
Y=points(:,2);
mx=mean(X);
my=mean(Y);
U=X-mx;
V=Y-my;

Suu=U'*U;
Svv=V'*V;

Suv=U'*V;

Suuu=sum(U.^3);
Svvv=sum(V.^3);

Suvv=sum(U.*V.*V);
Svuu=sum(U.*U.*V);

M=[Suu Suv; Suv Svv];

c=M\(1/2*[Suuu+Suvv;Svvv+Svuu]);

x=c(1)+mx;
y=c(2)+my;
r=sqrt(c'*c+(Suu+Svv)/length(U));

