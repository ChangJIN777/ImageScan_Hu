z_points = [1,5,10,25,35,50,80,100,150,200,400,600,1000];

T1_intrinsic = 6082 ;% 6.6ms need to find these values experimentally and put here.
T1_engaged = 3237 ; %0.48ms
T1_250nm_away = 5000;

% generate a set of tau max values based on the two T1s and the z value

T1_metal_1 = 1/( (1/T1_engaged) -(1/T1_intrinsic) );
T1_metal_2 = 1/( (1/T1_250nm_away) -(1/T1_intrinsic) );

A = (1 - 250)/ (T1_metal_1 - T1_metal_2);
z_0 = A*T1_metal_1 - 1;

T1_z_metal = (z_points + z_0)/ A; 

T1_z_total = 1./( (1/T1_intrinsic) + (1./T1_z_metal)  )