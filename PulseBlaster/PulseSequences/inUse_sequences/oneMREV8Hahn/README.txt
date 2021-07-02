Doing Hahn Echo to measure T2, while doing a MREV-8 between
the pi/2 and pi pulses.

v: surface spin's pi pulse time


SRS1:   pi/2  2q+12t+10v/2+2q  pi  2q+12t+10v/2+2q   pi/2
SRS2:         2q+ MREV-8  +2q      2q+ MREV-8  +2q


where MREV-8 is:
v/2(X) t X t Y 2t -Y t -X 2t -X t Y 2t -Y t X t -X

given q=20ns, t should be at least 50ns. Also p>50ns.


bit 3:SRS2
bit 4:SRS1
bit 5:SRS1's +X
bit 7:SRS1's +Y
6,10,8,9: SRS2's +X -X +Y -Y.


 