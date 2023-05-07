function [m_pw,v_wr,v_pwmpp,v_wrmpp] = fun_getwindpowercurve(v_beta,v_vw)

% This function computes the power-speed curves for wind generation.
% The power-speed curve of a 1.5 MW wind generator is used for this
% purpose. The resulting curve must be appropriately scaled.
%
% Input:    angle of attack, beta, and wind speed, vw
% Output:   wind power, pw, rotor speed, wr, MPP power, pwmpp, MPP rotor
%           speed, wrmpp


rho = 1.275; % air density

% 1.5 MW wind generator data
Rb = 31.2; % blade radius (m)
Aw = Rb^2*pi; % surface 
Pn = 1.5e6; % nominal power (MW)
v_cp = [0.73, 151, 0.58, 0.002, 2.14, 13.2, 18.4, -0.02, -0.003]; % performance coefficients
v_Wr = 0:0.01:4; % rotor speed range (rad/s)

nvw = length(v_vw);

for iw = nvw:-1:1 % for every wind speed:
    
    vw = v_vw(iw);
    lambda = v_Wr*Rb./vw;
    delta = (1./(lambda+v_cp(8).*v_beta)-v_cp(9)./(1+v_beta.^3));
    Cp = v_cp(1)*(v_cp(2).*delta-v_cp(3).*v_beta-v_cp(4).*v_beta.^v_cp(5)-v_cp(6)).*exp(-v_cp(7).*delta);
    m_pw(iw,:) = Cp*rho/2*Aw*vw.^3/Pn; % per unit mechanical power

end

[v_pwmpp,v_iwrmpp] = max(m_pw,[],2); % MPP

ipwmppn = find(v_pwmpp<=1,1,'last'); % nominal power (1 pu)
Wrn = v_Wr(v_iwrmpp(ipwmppn)); % nominal speed
v_wr = v_Wr/Wrn;
%v_wr = v_Wr;

v_Wrmpp = v_Wr(v_iwrmpp);
v_wrmpp = v_Wrmpp/Wrn; % speed corresponding to MPP

% figure(1)
% title('P-wr plot')
% plot(v_wr,m_pw',':b');hold on;
% plot(v_wrmpp,v_pwmpp,'-r');hold off;
% figure(2)
% title('P-Wr plot')
% plot(v_Wr,m_pw',':b');hold on;