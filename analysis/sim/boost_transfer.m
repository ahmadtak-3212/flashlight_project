%% boost_cc_led_PI_stable.m
% Small-signal averaged model of boost -> current sense -> PI -> PWM

clear; clc; close all;

%% ====== Power stage and sense parameters ===============================
Vin      = 3;          % V, battery
Vout_nom = 6;          % V, nominal LED voltage
Iout_nom = 1;          % A, nominal LED current (you can leave this)
L        = 22e-6;      
C        = 120e-6;
fsw      = 100e3;
Rload    = Vout_nom / Iout_nom;

Rsense      = 0.2;     % Ohm, current-sense resistor

Imax_real   = 1.25;    % A, max LED current you see in hardware
K_sense_amp = 1/(Rsense * Imax_real);   % => 0..1 V for 0..1.25 A
% K_sense_amp = 4 in this case

%% ====== PI controller as hardware =====================================
% We implement: G_PI(s) = Kp + Ki/s
% with a series Rf-Cf in the feedback and an input resistor Rin:
% Kp = Rf/Rin, Ki = 1/(Rin*Cf)

Rin = 10e3;           % Ohm
Rf  = 680;            % Ohm
Cf  = 10e-6;         % F

Kp  = Rf / Rin;
Ki  = 1/(Rin * Cf);

% (These values give roughly Kp = 0.5, Ki = 500 – stable for this plant.)

%% ====== Linearized CCM boost converter model ===========================
% Steady-state
D   = 1 - Vin / Vout_nom;          % duty
V_o = Vout_nom;
I_o = V_o / Rload;
I_L = Vin / (Rload * (1-D)^2);

% ON:  diL/dt = Vin/L, dvC/dt = -vC/(R C)
A1 = [ 0,                         0;
       0,                -1/(Rload*C) ];

% OFF: diL/dt = (Vin - vC)/L, dvC/dt = iL/C - vC/(R C)
A2 = [ 0,                -1/L;
       1/C,  -1/(Rload*C) ];

% Duty-averaged A
A = D*A1 + (1-D)*A2;

% Duty perturbation input (Erickson/Maksimovic form)
Bd = [ V_o / L;
      -I_L / C ];

% Sense output: Vmeas = K_sense_amp * Rsense * i_out, i_out ≈ vC/Rload
C_vsense = [0, (Rsense*K_sense_amp)/Rload];   % 1×2
D_vsense = 0;

%% ====== Build loop in state space (add PI integrator state) ============
K_pwm = 1;   % normalized PWM gain (0–1 V triangle & control)

% States: [ x ; z ], x = [iL; vC], z = integrator state
% x_dot = A x + Bd*K_pwm*(Kp*(r - y) + Ki*z)
% z_dot = r - y,     y = C_vsense x
%
% => A_cl = [A - Bd*Kp*K_pwm*C,   Bd*Ki*K_pwm;
%            -C_vsense,          0]

A_cl = [A - Bd*Kp*K_pwm*C_vsense,  Bd*Ki*K_pwm;
        -C_vsense,                0              ];

B_cl = [Bd*Kp*K_pwm;
        1          ];        % input is setpoint r

C_y   = [C_vsense, 0];       % output y = Vmeas
C_i   = C_y / (Rsense * K_sense_amp); % LED current (A) from Vmeas

D_cl  = 0;

% State-space systems
sys_vsense = ss(A_cl, B_cl, C_y, D_cl);   % Vmeas / Vset
sys_iout   = ss(A_cl, B_cl, C_i, D_cl);   % I_LED / Vset

%% ====== Check poles and frequency response ============================
fprintf('Closed-loop poles (Vset -> Vmeas):\n');
disp(pole(sys_vsense));

figure;
bode(sys_iout);
grid on;
title('Closed-loop transfer: set-point \rightarrow LED current');

%% ====== Time-domain step in set-point ==============================
t_end = 1000e-3;          % 5 ms total sim time
Ts    = 1e-5;          % 10 us sample time  << 1.2e-4 from warning
t     = 0:Ts:t_end;    % time vector

Vset_low  = 0.3;
Vset_high = 0.7;
t_step    = 1e-3;

r = Vset_low * ones(size(t));
r(t >= t_step) = Vset_high;


[y_vsense, ~] = lsim(sys_vsense, r, t);
y_iout        = lsim(sys_iout,   r, t);

figure;
subplot(2,1,1);
plot(t*1e3, r, 'LineWidth', 1.5); hold on;
plot(t*1e3, y_vsense, 'LineWidth', 1.5);
ylabel('Voltage (V)');
legend('V_{set}','V_{meas}','Location','Best');
grid on;
title('Set-point step and sensed feedback');

subplot(2,1,2);
plot(t*1e3, y_iout, 'LineWidth', 1.5);
xlabel('Time (ms)');
ylabel('I_{LED} (A)');
grid on;
title('LED current response to set-point step');
