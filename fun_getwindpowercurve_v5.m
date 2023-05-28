% function [m_pw,v_wr,v_pwmpp,v_wrmpp,v_pwdel,v_wrdel, pinitwindgen, wr0] = fun_getwindpowercurve_v5(v_beta,v_vw, vw_in)

function [m_pw,v_wr,v_pwmpp,v_wrmpp,v_pwdel,v_wrdel, vw0, wr0] = fun_getwindpowercurve_v5(v_beta,v_vw, pinitwindgen)

% This newer version initialises a bunch of the variables used to zero.
% Requires: wind speeds, initial wind speed
% Provides: curve, equilibrium

% This function computes the power-speed curves for wind generation.
% The power-speed curve of a 1.5 MW wind generator is used for this
% purpose. The resulting curve must be appropriately scaled.
%
% Input:    angle of attack, beta, and wind speed, vw
% Output:   wind power, pw; rotor speed, wr; MPP power, pwmpp; MPP rotor
%           speed, wrmpp; deloaded power, pwdel; deloaded rotor speed,
%           wrdel

deload = 0.1; % percentage of deloading
rho = 1.275; % air density

% 1.5 MW wind generator data
Rb = 31.2; % blade radius (m)
% Rb = 172/2;
Aw = Rb^2*pi; % surface 
Pn = 1.5e6; % nominal power (MW)
% Pn = 7e6;
v_cp = [0.73, 151, 0.58, 0.002, 2.14, 13.2, 18.4, -0.02, -0.003]; % performance coefficients
v_Wr = 0:0.01:5; % rotor speed range (rad/s)

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

% ==> Algorithm to obtain deloaded speed and power:
% Look up for the "0.9*max(m_pw,[],2)" value (in other words, pw_del) and
% see its corresponding i. Then we look for the corresponding wr value with
% that i.

v_iwrdel= zeros(1,nvw);
v_wrdel = zeros(1,nvw+5);
v_Wrdel = zeros(1,nvw+5);

% for i=1:nvw
%     if v_vw(i) == vw_in
%         i_input_vw = i;
%     end
% end

% % look for the value closest to pw_del on the right hand side of pmax and
% % take note of the index. Then obtain the associated wr
% for iw = nvw:-1:1
%     % it takes the right half of the curve after the MPP point corresponding to that
%     % particular wind speed, and gets its index of the deloaded power
%     [~,v_iwrdel(iw)] = min(abs(m_pw(iw,v_iwrmpp(iw):end) - v_pwdel(iw)));
%     v_Wrdel(iw)      = v_Wr(v_iwrmpp(iw)+v_iwrdel(iw)); % gives the corresponding wr
%     if iw == i_input_vw                     % if we're dealing with the input speed
%         Wr0             = v_Wrdel(iw);      % store it's corresponding speed
%         pinitwindgen    = v_pwdel(iw);      % and deloaded power
%     end
% end


% find closest deloaded value that corresponds to pinitwindgen
i_pinitwindgen_lower  = find(v_pwdel <= pinitwindgen,1,'last');
i_pinitwindgen_higher = find(v_pwdel >= pinitwindgen,1,'first');

% interpolate
vw0 = v_vw(i_pinitwindgen_lower) + ...
    (v_vw(i_pinitwindgen_higher)-v_vw(i_pinitwindgen_lower))*(pinitwindgen-v_pwdel(i_pinitwindgen_lower))/(v_pwdel(i_pinitwindgen_higher)-v_pwdel(i_pinitwindgen_lower));

for iw = nvw:-1:1
    % it takes the right half of the curve after the MPP point corresponding to that
    % particular wind speed

    [~,v_iwrdel(iw)] = min(abs(m_pw(iw,v_iwrmpp(iw):end) - v_pwdel(iw)));
    v_Wrdel(iw)      = v_Wr(v_iwrmpp(iw)+v_iwrdel(iw)); % gives the corresponding wr
    
end

Wr0_lower   = v_Wrdel(i_pinitwindgen_lower);
Wr0_higher  = v_Wrdel(i_pinitwindgen_higher);

%interpolate
Wr0 = Wr0_lower + ...
    (Wr0_higher-Wr0_lower)*(pinitwindgen-v_pwdel(i_pinitwindgen_lower))/(v_pwdel(i_pinitwindgen_higher)-v_pwdel(i_pinitwindgen_lower));

% for iw = nvw:-1:1
%     % it takes the right half of the curve after the MPP point corresponding to that
%     % particular wind speed
% 
%     [~,v_iwrdel(iw)] = min(abs(m_pw(iw,v_iwrmpp(iw):end) - v_pwdel(iw)));
%     v_Wrdel(iw)      = v_Wr(v_iwrmpp(iw)+v_iwrdel(iw)); % gives the corresponding wr
%     
%     i_pwdel_lower  = find(m_pw(iw,v_iwrmpp(iw):end) <= v_pwdel(iw),1,'last');
%     i_pwdel_higher = find(m_pw(iw,v_iwrmpp(iw):end) >= v_pwdel(iw),1,'first');
%     
%     lower_than_b  = data(i_lower);
%     higher_than_b = data(i_higher);
% 
% end

% Wr0 = m_pw(vw0, wr0)

% we add a few "deloaded" points so that, when the wind speed becomes higher
% than the maximum specified one, the maximum power has been reached
for i_extra_vw = 1:5
    v_pwdel(nvw+i_extra_vw) = v_pwdel(nvw);
    v_Wrdel(nvw+i_extra_vw) = v_Wrdel(nvw) + i_extra_vw * (v_Wr(length(v_Wr))-v_Wrdel(nvw))/5;
end

% for i_extra_vw = 1:5
%     v_pwmpp(nvw+i_extra_vw) = v_pwmpp(nvw);
%     v_Wrmppp(nvw+i_extra_vw) = v_Wrmpp(nvw) + i_extra_vw * (v_Wr(length(v_Wr))-v_Wrmpp(nvw))/5;
% end

ipwmppn = find(v_pwmpp<=1,1,'last'); % nominal power (1 pu)
Wrn = v_Wr(v_iwrmpp(ipwmppn)); % nominal speed
v_wr = v_Wr/Wrn;
%v_wr = v_Wr;

v_Wrmpp = v_Wr(v_iwrmpp);
v_wrmpp = v_Wrmpp/Wrn; % speed corresponding to MPP
v_wrdel = v_Wrdel/Wrn; % speed corresponding to deloaded operation points

wr0     = Wr0/Wrn;

% TO DRAW FIGURE WR-PW CURVE:
figure;
title('MPP and Deloaded operation')
plot(v_wr,m_pw',':b');hold on;
plot(v_wrmpp,v_pwmpp,'-r');hold on;
plot(wr0,pinitwindgen,'*');hold on;
plot(v_wrdel,v_pwdel,'-r');hold off;