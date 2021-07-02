w = 2870e6 * 2 * pi ; %hz, level separation
h = 1.054571800e-34; %reduced plank
e_0 = 8.854e-12; %epsilon_0
c = 299792458; %speed of light 
T = 297;
theta = 54.7;
K_B = 1.38064852e-23;
mu_B = 9.274009994e-24;
mu_0 = 1.25663753e-6;
g = 2.0023;
m_e = 9.10938356e-31;
v_f = 1.4e6 ;
elec = 1.6e-19;
n = 5.8e28;

fraction = 0.0023;
n = 6e28; %electrons / m^3
m_e = 9.1e-31;
q = 1.6e-19;
sigma = 2.5e6;
%%
x_size =60e-9;
y_size =40e-9;
z_size =40e-9;
separation = 5e-9;
extra_dist = 250e-9;

flag_0 = 1;
total_steps = 1e7; %NOT seconds
tic
height_0 = 5e-9;

tau = m_e * sigma / (n * q^2);
n = n*0.0023;


%l = 53e-9; %nm, MFP of electron in silver
l = 10e-9; %aluminum
%v_f = 1.4e6; %m/s, fermi velocity in silver
%v_f = 2.03e6; %aluminum
v_th = sqrt(3*K_B * T / (m_e));
%v_th = (3/5) * 1.6e6;
%tau = l / v_th; %average time between collision in bulk
v_th = 2e6;
v_f = v_th;

%dt should be much less than Tau
mu_naught = 1.26e-6;
log_num = 1000; %just tells precision of S_v plot
dt = 1e-16; %time in between each "check up"
HA = round(100 *tau / dt);
t_c = round(-tau * log(rand(1)) / dt); %time until next collision

drude_sigma = n * q^2 * tau / m_e;

initial_position = [x_size*rand(1), y_size*rand(1), z_size*rand(1)];
initial_angle = 2 *pi * rand(1);
initial_theta = pi * rand(1);
initial_velocity = v_f * [sin(initial_theta)*cos(initial_angle), sin(initial_theta)*sin(initial_angle),cos(initial_theta)];

velocity = zeros(total_steps, 3);
position = zeros(total_steps, 3);

velocity(1, :) = initial_velocity;
position(1, :) = initial_position;
velocity_temp = initial_velocity;
t= 0;

for i = 2:total_steps
    position_temp = velocity_temp * dt + position(i-1,:);
    if position_temp(1) <= 1e-9
        t_c = ceil(-tau * log(rand(1)) / dt); %time until next collision
        %angle = pi * rand(1) - pi / 2;
        y = datasample([-1, 1],1);
        angle = acos(y*sqrt(rand(1))) - pi / 2;
        theta = pi * rand(1);
        velocity_temp = v_f * [sin(theta)*cos(angle), sin(theta)*sin(angle), cos(theta)];
        position_temp(1) = 1e-9;
        if position_temp(2) <= 1e-9
            position_temp(2) = 1e-9;
        elseif position_temp(2) >= y_size
            position_temp(2) = y_size;
        end
        if position_temp(3) <= 1e-9;
            position_temp(3) = 1e-9;
        elseif position_temp(3) >= z_size
            position_temp(3) = z_size;
        end
        t = 0;
    elseif position_temp(1) >= x_size
        t_c = ceil(-tau * log(rand(1)) / dt); %time until next collision
        %angle = pi * rand(1) + pi / 2;
        y = datasample([-1, 1],1);
        theta = pi * rand(1);
        angle = acos(y*sqrt(rand(1))) + pi / 2;
        velocity_temp = v_f * [sin(theta)*cos(angle), sin(theta)*sin(angle), cos(theta)];
        position_temp(1) = x_size;
        if position_temp(2) <= 1e-9
            position_temp(2) = 1e-9;
        elseif position_temp(2) >= y_size
            position_temp(2) = y_size;
        end
        if position_temp(3) <= 1e-9;
            position_temp(3) = 1e-9;
        elseif position_temp(3) >= z_size
            position_temp(3) = z_size;
        end
        t = 0;
    elseif position_temp(2) <= 1e-9
        t_c = ceil(-tau * log(rand(1)) / dt); %time until next collision
        %angle = pi * rand(1);
        y = datasample([-1, 1],1);
        theta = pi * rand(1);
        angle = acos(y*sqrt(rand(1))) ;
        velocity_temp = v_f * [sin(theta)*cos(angle), sin(theta)*sin(angle), cos(theta)];
        position_temp(2) = 1e-9;
        if position_temp(3) <= 1e-9;
            position_temp(3) = 1e-9;
        elseif position_temp(3) >= z_size
            position_temp(3) = z_size;
        end
        t = 0;
    elseif position_temp(2) >= y_size
        t_c = ceil(-tau * log(rand(1)) / dt); %time until next collision
        %angle = -pi * rand(1);
        y = datasample([-1, 1],1);
        theta = pi * rand(1);
        angle = -(acos(y*sqrt(rand(1))));
        velocity_temp = v_f * [sin(theta)*cos(angle), sin(theta)*sin(angle), cos(theta)];
        position_temp(2) = y_size;
        if position_temp(3) <= 1e-9;
            position_temp(3) = 1e-9;
        elseif position_temp(3) >= z_size
            position_temp(3) = z_size;
        end
        t = 0;
    elseif position_temp(3) <= 1e-9;
        t_c = ceil(-tau * log(rand(1)) / dt); %time until next collision
        %angle = -pi * rand(1);
        theta = (acos(sqrt(rand(1))));
        angle = 2 *pi * rand(1);
        velocity_temp = v_f * [sin(theta)*cos(angle), sin(theta)*sin(angle), cos(theta)];
        position_temp(3) = 1e-9;
        t = 0;
    elseif position_temp(3) >= z_size;
        t_c = ceil(-tau * log(rand(1)) / dt); %time until next collision
        %angle = -pi * rand(1);
        theta = (acos(sqrt(rand(1)))) + pi / 2;
        angle = 2 *pi * rand(1);
        velocity_temp = v_f * [sin(theta)*cos(angle), sin(theta)*sin(angle), cos(theta)];
        position_temp(3) = z_size;
        t = 0;
    elseif t == t_c;
        t_c = ceil(-tau * log(rand(1)) / dt); %time until next collision
        angle = 2 *pi * rand(1);
        theta = pi * rand(1);
        velocity_temp = v_f * [sin(theta)*cos(angle), sin(theta)*sin(angle), cos(theta)];
        t = 0;
    end
    velocity(i, :) = velocity_temp;
    position(i,:) = position_temp;
    t = t+1;
end

x_pos = position(:,1);
y_pos = position(:,2);
z_pos = position(:,3);
x_vel = velocity(:,1);
y_vel = velocity(:,2);
z_vel = velocity(:,3);

N = total_steps;

mean_velocity = mean(velocity);
mean_position = mean(position);

height = height_0 + z_size;

K = mu_naught * q / (4 * pi);

log_vec= logspace(9, 16, log_num);
% num = 67 + 92;


x_range = round((x_size + 2*extra_dist)*1e9);

Bx = zeros(x_range,1);
By = zeros(x_range,1);
Bz = zeros(x_range,1);
y_center = y_size / 2;
x_range
for ix = 1:x_range
        ix
        x_vec = ix * 1e-9 - extra_dist - x_pos;
        y_vec = y_center - y_pos;
        z_vec = height - z_pos;
        
%         if min(x_vec.^2) >= 150e-9
%             S_B_x = 0;
%             S_B_y = 0;
%             S_B_z = 0;
%         else
            
        pos_cubed = (x_vec.^2 + y_vec.^2 + z_vec.^2).^(3/2);
        Bx_temp = K * (y_vel .* z_vec - y_vec .* z_vel) ./ pos_cubed;
        By_temp = - K * (x_vel .* z_vec - x_vec .* z_vel) ./ pos_cubed;
        Bz_temp = K* (x_vel .* y_vec - y_vel .* x_vec) ./ pos_cubed;
        
        C_B_x = zeros(HA + 1,1);
        C_B_y = zeros(HA + 1,1);
        C_B_z = zeros(HA +1 ,1);
        
        for j = 0:(HA)
            C_B_x(j+1) = (1 / (N-j)) *sum(sum(Bx_temp(1:(N-j),:) .* Bx_temp((j+1):(N),:)));
            if C_B_x(j+1) < 0
                break
            end
        end
        
        for j = 0:(HA)
            C_B_y(j+1) = (1 / (N-j)) *sum(sum(By_temp(1:(N-j),:) .* By_temp((j+1):(N),:)));
            if C_B_y(j+1) < 0
                break
            end
        end
        
        for j = 0:(HA)
            C_B_z(j+1) = (1 / (N-j)) *sum(sum(Bz_temp(1:(N-j),:) .* Bz_temp((j+1):(N),:)));
            if C_B_z(j+1) < 0
                break
            end
        end
        
        C_B_x = C_B_x(C_B_x ~= 0);
        t_x = (0:(length(C_B_x) - 1)) * dt;
        t_x = t_x';
        
        C_B_y = C_B_y(C_B_y ~= 0);
        t_y = (0:(length(C_B_y) - 1)) * dt;
        t_y = t_y';
        
        C_B_z = C_B_z(C_B_z ~= 0);
        t_z = (0:(length(C_B_z) - 1)) * dt;
        t_z = t_z';
                        
        for w = log_vec(1);
            cos_mat=cos(w * t_x);
            S_B_x = 1*trapz(C_B_x .* cos_mat) * dt;
        end
                        
        for w = log_vec(1);
            cos_mat=cos(w * t_y);
            S_B_y = 1*trapz(C_B_y .* cos_mat) * dt;
        end
        
                
        for w = log_vec(1);
            cos_mat=cos(w * t_z);
            S_B_z = 1*trapz(C_B_z .* cos_mat) * dt;
        end
        Bx(ix, 1) = (n * x_size * y_size * z_size) * S_B_x/3;
        By(ix, 1) = (n * x_size * y_size * z_size) * S_B_y/3;
        Bz(ix ,1) = (n * x_size * y_size * z_size) * S_B_z;
end
%%
del_num = round((separation+x_size)*1e9);
Bx_1 = [Bx; zeros(del_num, 1)];
By_1 = [By; zeros(del_num,1)];
Bz_1 = [Bz; zeros(del_num,1)];

Bx_2 = [zeros(del_num,1); Bx];
By_2 = [zeros(del_num,1); By;];
Bz_2 = [zeros(del_num,1); Bz];

% Bx_1 = [Bx; zeros(150, 1)];
% By_1 = [By; zeros(150, 1)];
% Bz_1 = [Bz; zeros(150, 1)];
% 
% Bx_2 = [zeros(50, 1); Bx; zeros(100, 1)];
% By_2 = [zeros(50,1); By; zeros(100, 1)];
% Bz_2 = [zeros(50, 1); Bz; zeros(100, 1)];
% 
% Bx_3 = [zeros(100, 1); Bx; zeros(50, 1)];
% By_3 = [zeros(100,1); By; zeros(50, 1)];
% Bz_3 = [zeros(100, 1); Bz; zeros(50, 1)];
% 
% Bx_4 = [zeros(150, 1); Bx];
% By_4 = [zeros(150,1); By];
% Bz_4 = [zeros(150, 1); Bz];

const = 3 * g^2 * mu_B^2 / (h^2);% * K_B * T / (h^3 * omega);

Bx_full = (Bx_1 + Bx_2);
By_full = (By_1 + By_2);
Bz_full = Bz_1 + Bz_2;


% Bx_full((end-1):end) = [];
% By_full((end-1):end) = [];
% Bz_full((end-1):end) = [];

% Bx_full = [Bx_full(1:end-1); flipud(Bx_full)];
% By_full = [By_full(1:end-1); flipud(By_full)];
% Bz_full = [Bz_full(1:end-1); flipud(Bz_full)];

%gamma_Ag = const * (0.5*(cosd(54.7))^2 * Bx + 0.5 * By + 0.5 * (sind(54.7))^2 * Bz);
gamma_temp = const * (0.5*(cosd(54.7))^2 * Bx_1 + 0.5 * By_1 + 0.5 * (sind(54.7))^2 * Bz_1);



%clear variables before saving file
x_pos = 0;
y_pos = 0;
z_pos = 0;
x_vec = 0;
y_vec = 0;
z_vec = 0;
pos_cubed = 0;
x_vel = 0;
y_vel = 0;
z_vel = 0;
position = 0;
velocity = 0;
Bx_temp = 0;
By_temp = 0;
Bz_temp = 0;

w = 2870e6 * 2 * pi ; %hz, level separation
h = 1.054571800e-34; %reduced plank
e_0 = 8.854e-12; %epsilon_0
c = 299792458; %speed of light 
T = 297;
theta = 54.7;
K_B = 1.38064852e-23;
mu_B = 9.274009994e-24;
mu_0 = 1.25663753e-6;
g = 2.0023;
m_e = 9.10938356e-31;
v_f = 1.4e6 ;
elec = 1.6e-19;
n = 5.8e28;

fraction = 0.0023;
n = 6e28; %electrons / m^3
m_e = 9.1e-31;
q = 1.6e-19;
%%
x_size =500e-9;
y_size =500e-9;

flag_0 = 1;
total_steps = 6e6; %NOT seconds

tau = m_e * sigma / (n * q^2);
n = n*0.0023;


%l = 53e-9; %nm, MFP of electron in silver
l = 10e-9; %aluminum
%v_f = 1.4e6; %m/s, fermi velocity in silver
%v_f = 2.03e6; %aluminum
v_th = sqrt(3*K_B * T / (m_e));
%v_th = (3/5) * 1.6e6;
%tau = l / v_th; %average time between collision in bulk
v_th = 2e6;
v_f = v_th;

%dt should be much less than Tau
mu_naught = 1.26e-6;
log_num = 1000; %just tells precision of S_v plot
dt = 1e-16; %time in between each "check up"
HA = round(100 *tau / dt);
t_c = round(-tau * log(rand(1)) / dt); %time until next collision

drude_sigma = n * q^2 * tau / m_e;

initial_position = [x_size*rand(1), y_size*rand(1), z_size*rand(1)];
initial_angle = 2 *pi * rand(1);
initial_theta = pi * rand(1);
initial_velocity = v_f * [sin(initial_theta)*cos(initial_angle), sin(initial_theta)*sin(initial_angle),cos(initial_theta)];

velocity = zeros(total_steps, 3);
position = zeros(total_steps, 3);

velocity(1, :) = initial_velocity;
position(1, :) = initial_position;
velocity_temp = initial_velocity;
t= 0;

for i = 2:total_steps
    position_temp = velocity_temp * dt + position(i-1,:);
    if position_temp(1) <= 1e-9
        t_c = ceil(-tau * log(rand(1)) / dt); %time until next collision
        %angle = pi * rand(1) - pi / 2;
        y = datasample([-1, 1],1);
        angle = acos(y*sqrt(rand(1))) - pi / 2;
        theta = pi * rand(1);
        velocity_temp = v_f * [sin(theta)*cos(angle), sin(theta)*sin(angle), cos(theta)];
        position_temp(1) = 1e-9;
        if position_temp(2) <= 1e-9
            position_temp(2) = 1e-9;
        elseif position_temp(2) >= y_size
            position_temp(2) = y_size;
        end
        if position_temp(3) <= 1e-9;
            position_temp(3) = 1e-9;
        elseif position_temp(3) >= z_size
            position_temp(3) = z_size;
        end
        t = 0;
    elseif position_temp(1) >= x_size
        t_c = ceil(-tau * log(rand(1)) / dt); %time until next collision
        %angle = pi * rand(1) + pi / 2;
        y = datasample([-1, 1],1);
        theta = pi * rand(1);
        angle = acos(y*sqrt(rand(1))) + pi / 2;
        velocity_temp = v_f * [sin(theta)*cos(angle), sin(theta)*sin(angle), cos(theta)];
        position_temp(1) = x_size;
        if position_temp(2) <= 1e-9
            position_temp(2) = 1e-9;
        elseif position_temp(2) >= y_size
            position_temp(2) = y_size;
        end
        if position_temp(3) <= 1e-9;
            position_temp(3) = 1e-9;
        elseif position_temp(3) >= z_size
            position_temp(3) = z_size;
        end
        t = 0;
    elseif position_temp(2) <= 1e-9
        t_c = ceil(-tau * log(rand(1)) / dt); %time until next collision
        %angle = pi * rand(1);
        y = datasample([-1, 1],1);
        theta = pi * rand(1);
        angle = acos(y*sqrt(rand(1))) ;
        velocity_temp = v_f * [sin(theta)*cos(angle), sin(theta)*sin(angle), cos(theta)];
        position_temp(2) = 1e-9;
        if position_temp(3) <= 1e-9;
            position_temp(3) = 1e-9;
        elseif position_temp(3) >= z_size
            position_temp(3) = z_size;
        end
        t = 0;
    elseif position_temp(2) >= y_size
        t_c = ceil(-tau * log(rand(1)) / dt); %time until next collision
        %angle = -pi * rand(1);
        y = datasample([-1, 1],1);
        theta = pi * rand(1);
        angle = -(acos(y*sqrt(rand(1))));
        velocity_temp = v_f * [sin(theta)*cos(angle), sin(theta)*sin(angle), cos(theta)];
        position_temp(2) = y_size;
        if position_temp(3) <= 1e-9;
            position_temp(3) = 1e-9;
        elseif position_temp(3) >= z_size
            position_temp(3) = z_size;
        end
        t = 0;
    elseif position_temp(3) <= 1e-9;
        t_c = ceil(-tau * log(rand(1)) / dt); %time until next collision
        %angle = -pi * rand(1);
        theta = (acos(sqrt(rand(1))));
        angle = 2 *pi * rand(1);
        velocity_temp = v_f * [sin(theta)*cos(angle), sin(theta)*sin(angle), cos(theta)];
        position_temp(3) = 1e-9;
        t = 0;
    elseif position_temp(3) >= z_size;
        t_c = ceil(-tau * log(rand(1)) / dt); %time until next collision
        %angle = -pi * rand(1);
        theta = (acos(sqrt(rand(1)))) + pi / 2;
        angle = 2 *pi * rand(1);
        velocity_temp = v_f * [sin(theta)*cos(angle), sin(theta)*sin(angle), cos(theta)];
        position_temp(3) = z_size;
        t = 0;
    elseif t == t_c;
        t_c = ceil(-tau * log(rand(1)) / dt); %time until next collision
        angle = 2 *pi * rand(1);
        theta = pi * rand(1);
        velocity_temp = v_f * [sin(theta)*cos(angle), sin(theta)*sin(angle), cos(theta)];
        t = 0;
    end
    velocity(i, :) = velocity_temp;
    position(i,:) = position_temp;
    t = t+1;
end

x_pos = position(:,1);
y_pos = position(:,2);
z_pos = position(:,3);
x_vel = velocity(:,1);
y_vel = velocity(:,2);
z_vel = velocity(:,3);

N = total_steps;

mean_velocity = mean(velocity);
mean_position = mean(position);

height = height_0 + z_size;

K = mu_naught * q / (4 * pi);

log_vec= logspace(9, 16, log_num);
% num = 67 + 92;



y_center = y_size / 2;
x_center = x_size / 2;
        
        x_vec = x_center - x_pos;
        y_vec = y_center - y_pos;
        z_vec = height - z_pos;
        
%         if min(x_vec.^2) >= 150e-9
%             S_B_x = 0;
%             S_B_y = 0;
%             S_B_z = 0;
%         else
            
        pos_cubed = (x_vec.^2 + y_vec.^2 + z_vec.^2).^(3/2);
        Bx_temp = K * (y_vel .* z_vec - y_vec .* z_vel) ./ pos_cubed;
        By_temp = - K * (x_vel .* z_vec - x_vec .* z_vel) ./ pos_cubed;
        Bz_temp = K* (x_vel .* y_vec - y_vel .* x_vec) ./ pos_cubed;
        
        C_B_x = zeros(HA + 1,1);
        C_B_y = zeros(HA + 1,1);
        C_B_z = zeros(HA +1 ,1);
        
        for j = 0:(HA)
            C_B_x(j+1) = (1 / (N-j)) *sum(sum(Bx_temp(1:(N-j),:) .* Bx_temp((j+1):(N),:)));
            if C_B_x(j+1) < 0
                break
            end
        end
        
        for j = 0:(HA)
            C_B_y(j+1) = (1 / (N-j)) *sum(sum(By_temp(1:(N-j),:) .* By_temp((j+1):(N),:)));
            if C_B_y(j+1) < 0
                break
            end
        end
        
        for j = 0:(HA)
            C_B_z(j+1) = (1 / (N-j)) *sum(sum(Bz_temp(1:(N-j),:) .* Bz_temp((j+1):(N),:)));
            if C_B_z(j+1) < 0
                break
            end
        end
        
        C_B_x = C_B_x(C_B_x ~= 0);
        t_x = (0:(length(C_B_x) - 1)) * dt;
        t_x = t_x';
        
        C_B_y = C_B_y(C_B_y ~= 0);
        t_y = (0:(length(C_B_y) - 1)) * dt;
        t_y = t_y';
        
        C_B_z = C_B_z(C_B_z ~= 0);
        t_z = (0:(length(C_B_z) - 1)) * dt;
        t_z = t_z';
                        
        for w = log_vec(1);
            cos_mat=cos(w * t_x);
            S_B_x = 1*trapz(C_B_x .* cos_mat) * dt;
        end
                        
        for w = log_vec(1);
            cos_mat=cos(w * t_y);
            S_B_y = 1*trapz(C_B_y .* cos_mat) * dt;
        end
        
                
        for w = log_vec(1);
            cos_mat=cos(w * t_z);
            S_B_z = 1*trapz(C_B_z .* cos_mat) * dt;
        end
        Bx = (n * x_size * y_size * z_size) * S_B_x/3;
        By = (n * x_size * y_size * z_size) * S_B_y/3;
        Bz = (n * x_size * y_size * z_size) * S_B_z;
%%
gamma_temp2 = const * (0.5*(cosd(54.7))^2 * Bx + 0.5 * By + 0.5 * (sind(54.7))^2 * Bz);

factor2 = max(gamma_temp)/max(gamma_temp2);

gamma_Ag = const * (0.5*(cosd(54.7))^2 * Bx_full + 0.5 * By_full + 0.5 * (sind(54.7))^2 * Bz_full); %to account for finite size effects, both in MFP reduction and in less metal presence



%clear variables before saving file
x_pos = 0;
y_pos = 0;
z_pos = 0;
x_vec = 0;
y_vec = 0;
z_vec = 0;
pos_cubed = 0;
x_vel = 0;
y_vel = 0;
z_vel = 0;
position = 0;
velocity = 0;
Bx_temp = 0;
By_temp = 0;
Bz_temp = 0;
%%

w = 2870e6 * 2 * pi ; %hz, level separation
h = 1.054571800e-34; %reduced plank
e_0 = 8.854e-12; %epsilon_0
c = 299792458; %speed of light 
T = 297;
theta = 54.7;
K_B = 1.38064852e-23;
mu_B = 9.274009994e-24;
mu_0 = 1.25663753e-6;
g = 2.0023;
m_e = 9.10938356e-31;

a= z_size;

gamma_base = 3 * g^2 * mu_B^2 * mu_0^2 * K_B * T * (1 + 0.5 *(sind(54.7))^2) / (32 * pi * h^2);
z = height_0;
gamma_sol = gamma_base .* ((1/z) - (1/(z+a)));

factor = gamma_sol / max(gamma_temp2); %should change to gamma_temp

gamma_new = gamma_Ag * factor * factor2;

T1_free_ms = 6;
gamma_free = 1e3 / T1_free_ms;

sig_1 = 1e4;
sig_2 = 3e5;

gamma_full = sig_1*gamma_new + gamma_free;
gamma_full_2 = sig_2*(gamma_new) + gamma_free;
% gamma_full_3 = (gamma_new /100) + gamma_free;

T1_1 = 1./ gamma_full;
T1_2 = 1./ gamma_full_2;
% T1_3 = 1./ gamma_full_3;

time_1 = 200;
time_2 = 60;
% time_3 = 1800;
SCC = 2.5;

tau_opt_1 = 0.5./ gamma_full;

P1 = 1/3 + 2/3*exp(-gamma_full .* tau_opt_1);
sig_gamma_1 = SCC ./ ((P1 - 1/3) .* sqrt(time_1.*tau_opt_1));
sig_T1_1 = sig_gamma_1 ./ gamma_full.^2;

t_extra = 200e-6;

% % tau_opt_2 = 0.5 ./ gamma_full_2;
% 
% P2 = 1/3 + 2/3*exp(-gamma_full_2 .* tau_opt_2);
% sig_gamma_2 = SCC ./ ((P1 - 1/3) .* sqrt(time_2.*tau_opt_2));

tau_opt_2 = (0.5./gamma_full_2 - t_extra + sqrt(t_extra.^2 + 3 .* (1./gamma_full_2) .* t_extra + gamma_full_2.^(-2) / 4))/2;
sig_gamma_2 = (1.5 * SCC / sqrt(time_2)) .* exp(gamma_full_2.*tau_opt_2) .* sqrt(tau_opt_2 + t_extra) ./ tau_opt_2;

sig_T1_2 = sig_gamma_2 ./ gamma_full_2.^2;


Tau_1 = normrnd(1 ./ gamma_full, sig_T1_1);

Tau_2 = normrnd(1./ gamma_full_2, sig_T1_2);

% Sz = mu_0^2 * K_B * T * 6.3e7 / (16 * pi * z);
% Sz_max = 2 * mu_0^2 * K_B * T * 6e28 * q^2 / (pi * m_e * v_f);

%%%LESS PIXELS
% 

pixel_divider = 4;

x_rows = 1:(x_range+del_num);
x_rows_2 = 1:pixel_divider:(x_range + del_num);

Tau_2_plot = 1e3*Tau_2(1:pixel_divider:end);
Tau_1_plot = 1e3*Tau_1(1:pixel_divider:end);

sig_T1_1_plot = 1e3*sig_T1_1(1:pixel_divider:end);
sig_T1_2_plot = 1e3*sig_T1_2(1:pixel_divider:end);


figure
% plot(x_rows, 1e3*Tau_3, 'b-'); hold on;
% errorbar(x_rows,Tau_1_plot, sig_T1_1_plot,'ko'); hold on;
% errorbar(x_rows,Tau_2_plot, sig_T1_2_plot,'rd');

% plot(x_rows,Tau_1_plot,'ko', 'linewidth', 2); hold on;
plot(x_rows - max(x_rows + 1)/2, 1e3./gamma_full_2,'k-','linewidth', 1.5); hold on;
plot(x_rows_2 - max(x_rows + 1)/2,Tau_2_plot,'ro', 'linewidth', 2, 'markersize',9);

%ylim([0.4 2.8])
leg=legend('Simulation','Simulated measurement');
%set(leg,'edgecolor','none')
% si = annotation('textbox', 'String', [num2str(time_1), ' seconds / pixel'], 'Color', 'red', 'FontSize', 20, 'EdgeColor', 'none');
%vo2 = annotation('textbox', 'String', [num2str(time_2), ' seconds / pixel', num2str(t_extra), ' t extra ',num2str(T1_free_ms), 'T1 free ms', num2str(sig_2), 'sigma', num2str(SCC),'SCC'], 'Color', 'black', 'FontSize', 20, 'EdgeColor', 'none');

xlabel('X (nm)')
% xlim([-100, 100])
% ylim([45, 68])
ylabel('T_1 (ms)')
% ylim([0 11])

set(gcf, 'color', 'w')
set(gca, 'fontsize', 20)

