function [vw0, wr0, pinitwindgen, Tc1, Tc2, v_vw, m_pw, v_wr, v_pwmpp, ...
    v_wrmpp,v_pwdel,v_wrdel] = fun_WGmodel_startup(powersystemdl, pinitwindgenMW, Pn, diameter)

% This function sets up the parameters of the WG and inserts them into the
% Powersystem Simulink model.

load_system(powersystemdl);

% Setting up parameters
Tc1 = 0.05; % time constant
Tc2 = 0.05; % time constant
numWG = 9;  % number of total generators

% Setting up the LUTs and the initial equilibrium point
v_vw    = 5:.5:12;
[m_pw,v_wr,v_pwmpp,v_wrmpp,v_pwdel,v_wrdel,vw0,wr0, pinitwindgen] = fun_getwindpowercurve(0,v_vw,pinitwindgenMW, Pn, diameter);

% Set predefined WG parameters on Simulink model
for i=0:numWG-1
    set_param([powersystemdl '/WindGenerator' int2str(i)],'Tc1',sprintf('%f',Tc1),'Tc2',sprintf('%f',Tc2), 'pinitwindgen', ...
    sprintf('%f',pinitwindgen),'wr0',sprintf('%f',wr0),'v_vw',['[' sprintf('%f ',v_vw) ']'],'v_wr',['[' sprintf('%f ',v_wr) ']'],'m_pw',mat2str(m_pw), ...
    'v_wrdel',['[' sprintf('%f ',v_wrdel) ']'],'v_pwdel',['[' sprintf('%f ',v_pwdel) ']'],'v_wrmpp',['[' sprintf('%f ',v_wrmpp) ']'],'v_pwmpp',['[' sprintf('%f ',v_pwmpp) ']']);
end