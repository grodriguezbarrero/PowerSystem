function [m_pw,v_wr,v_pwmpp,v_wrmpp,v_pwdel,v_wrdel, vw0, wr0, pinitwindgen] = fun_getwindpowercurve(v_beta,v_vw, pinitwindgenMW, Pn, diameter)

% This function computes the power-speed curves (MPP and deloaded operation
% modes) for wind generation.
% The power-speed curve of a wind generator is used for this
% purpose. The resulting curve must be appropriately scaled.
%
% Input:    angle of attack (beta), wind speed (v_vw), initial Power
%           (pinitwindgen), nominal P (Pn), rotor diameter 
% Output:   wind power, pw; rotor speed, wr; MPP power, pwmpp; MPP rotor
%           speed, wrmpp; deloaded power, pwdel; deloaded rotor speed,
%           wrdel

deload = 0.1;   % percentage of deloading
rho = 1.275;    % air density

v_Wr = 0:0.01:3.4; % rotor speed range (rad/s)

Pn = Pn * 1e6;
Rb = diameter/2; % blade radius (m)

v_cp = [0.73, 151, 0.58, 0.002, 2.14, 13.2, 18.4, -0.02, -0.003]; % performance coefficients

Aw = Rb^2*pi; % surface

pinitwindgen = pinitwindgenMW/(Pn * 1e-6);

nvw = length(v_vw);
nwr = length(v_Wr);

m_pw    = zeros(nvw,nwr);
v_wr    = zeros(1,nwr);
v_pwmpp = zeros(nvw,1);
v_wrmpp = zeros(1,nvw);
v_pwdel = zeros(nvw,1);
v_wrdel = zeros(1,nvw);
v_iwrmpp= zeros(nvw,1);

for iw = nvw:-1:1 % for every wind speed:
    
    vw = v_vw(iw);
    lambda = v_Wr*Rb./vw;
    delta = (1./(lambda+v_cp(8).*v_beta)-v_cp(9)./(1+v_beta.^3));
    Cp = v_cp(1)*(v_cp(2).*delta-v_cp(3).*v_beta-v_cp(4).*v_beta.^v_cp(5)-v_cp(6)).*exp(-v_cp(7).*delta);
    m_pw(iw,:) = Cp*rho/2*Aw*vw.^3/Pn; % per unit mechanical power
    
end

[v_pwmpp,v_iwrmpp] = max(m_pw,[],2); % MPP
v_pwdel = (1-deload) * v_pwmpp; % deloaded

v_iwrdel= zeros(1,nvw);
v_wrdel = zeros(1,nvw+5);
v_Wrdel = zeros(1,nvw+5);

% find closest deloaded value that corresponds to pinitwindgen
i_pinitwindgen_lower  = find(v_pwdel <= pinitwindgen,1,'last');
i_pinitwindgen_higher = find(v_pwdel >= pinitwindgen,1,'first');

% interpolate to find initial wind speed
vw0 = v_vw(i_pinitwindgen_lower) + ...
    (v_vw(i_pinitwindgen_higher)-v_vw(i_pinitwindgen_lower))*(pinitwindgen-v_pwdel(i_pinitwindgen_lower))/(v_pwdel(i_pinitwindgen_higher)-v_pwdel(i_pinitwindgen_lower));

for iw = nvw:-1:1
    % it takes the right half of the curve after the MPP point corresponding to that
    % particular wind speed

    [~,v_iwrdel(iw)] = min(abs(m_pw(iw,v_iwrmpp(iw):end) - v_pwdel(iw)));
    v_Wrdel(iw)      = v_Wr(v_iwrmpp(iw)+v_iwrdel(iw)); % gives the corresponding wr
end

% find closest rotor speed value that corresponds to Wr0
Wr0_lower   = v_Wrdel(i_pinitwindgen_lower);
Wr0_higher  = v_Wrdel(i_pinitwindgen_higher);

% interpolate
Wr0 = Wr0_lower + ...
    (Wr0_higher-Wr0_lower)*(pinitwindgen-v_pwdel(i_pinitwindgen_lower))/(v_pwdel(i_pinitwindgen_higher)-v_pwdel(i_pinitwindgen_lower));

% we add a few "deloaded" points so that, when the wind speed becomes higher
% than the maximum specified one, the maximum power has been reached
for i_extra_vw = 1:5
    v_pwdel(nvw+i_extra_vw) = v_pwdel(nvw);
    v_Wrdel(nvw+i_extra_vw) = v_Wrdel(nvw) + i_extra_vw * (v_Wr(length(v_Wr))-v_Wrdel(nvw))/5;
end

ipwmppn = find(v_pwmpp<=1,1,'last');    % nominal power (1 pu)
Wrn = v_Wr(v_iwrmpp(ipwmppn));          % nominal speed
v_wr = v_Wr/Wrn;

v_Wrmpp = v_Wr(v_iwrmpp);
v_wrmpp = v_Wrmpp/Wrn;  % speed corresponding to MPP
v_wrdel = v_Wrdel/Wrn;  % speed corresponding to deloaded operation points

wr0     = Wr0/Wrn;      % turning to pu

%% TO DRAW FIGURE WR-PW CURVE:
figure;
title('MPP and Deloaded operation')
% plot(v_wr,m_pw',':b');hold on;
plot(v_wrmpp,v_pwmpp,'-r');hold on;
plot(v_wrdel,v_pwdel,'-b');hold on;
legend('MPP','Deloaded')
plot(wr0,pinitwindgen,'*', 'linewidth',4,'HandleVisibility','off');hold on;

plot(v_wr,m_pw',':b', 'HandleVisibility','off');hold on;
xlabel('Rotor speed (pu)')
ylabel('Mechanical power (pu)')
hold off;
sgt = sgtitle('Power-speed curve', 'interpreter','latex');
sgt.FontSize = 18;