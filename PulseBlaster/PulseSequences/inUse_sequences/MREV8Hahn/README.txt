Doing Hahn Echo to measure T2, while doing n MREV-8 between
the pi/2 and pi pulses.
v: surface spin's pi time


SRS1: pi/2    2q+v/2+n*(12*z+4*v)+q+v/2+q+t+q    pi   2q+v/2+n*(12*z+4*v)+q+v/2+q+t+q    pi/2
SRS2:         2q+MREV-8*n                             2q+MREV-8*n


where MREV-8 is:
v/2(X) {z X z Y 2z -Y z -X 2z -X z Y 2z -Y z X z}*n -X

given q=20ns, z should be at least 50ns. Also p>50ns.


bit 3:SRS2
bit 4:SRS1
bit 5:SRS1's +Y
6,10,8,9: SRS2's +X -X +Y -Y.

