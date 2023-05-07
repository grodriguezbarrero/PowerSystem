function [pinitwindgen, wr0, Tc1, Tc2, Hw, R, v_vw, m_pw, v_wr, v_pwmpp, ...
    v_wrmpp,v_pwdel,v_wrdel] = fun_WGmodel_startup_v3(vw)


% function [X0, pinitwindgen, wr0, Tc1, Tc2, Hw, R, v_vw, m_pw, v_wr, v_pwmpp, ...
%    v_wrmpp,v_pwdel,v_wrdel] = fun_WGmodel_startup_v3

% UPDATE: this model does not deal with beta
% This function sets up the parameters of the WG and inserts them into the
% Powersystem Simulink model.

powersystemdl = 'Powersystem';
load_system(powersystemdl);


%% Setting up parameters

% tsimulation = 50;
% X0 = [0.5161 0.5161 1.1861];
% xInitial = X0;

% if we set vw = 10
% pinitwindgen = 0.5161;
% wr0          = 1.1861;

% startup wind speed
% vw = 10; % CHANGE THIS
[~,~,~,~,pinitwindgen,wr0] = fun_getwindpowercurve_v4(0,vw);
pinitwindgen = pinitwindgen(1);
wr0 = wr0(1);

Tc1 = 0.05;
Tc2 = 0.05;
Hw  = 5;    % inertia
R   = 0.05; % droop

%% Setting up the LUTs
v_vw    = 5:.5:12;
len_v_wr = 401;
[m_pw,v_wr,v_pwmpp,v_wrmpp,v_pwdel,v_wrdel] = fun_getwindpowercurve_v4(0,v_vw);

%% Set predefined WG parameters on Simulink model
set_param([powersystemdl '/WindGenerator'],'Hw',sprintf('%f',Hw),'Tc1',sprintf('%f',Tc1),'Tc2',sprintf('%f',Tc2),'R',sprintf('%f',R), 'pinitwindgen', ...
    sprintf('%f',pinitwindgen),'wr0',sprintf('%f',wr0),'v_vw',['[' sprintf('%f ',v_vw) ']'],'v_wr',['[' sprintf('%f ',v_wr) ']'],'m_pw',mat2str(m_pw), ...
    'v_wrdel',['[' sprintf('%f ',v_wrdel) ']'],'v_pwdel',['[' sprintf('%f ',v_pwdel) ']'],'v_wrmpp',['[' sprintf('%f ',v_wrmpp) ']'],'v_pwmpp',['[' sprintf('%f ',v_pwmpp) ']']);

set_param([powersystemdl '/WindGenerator1'],'Hw',sprintf('%f',Hw),'Tc1',sprintf('%f',Tc1),'Tc2',sprintf('%f',Tc2),'R',sprintf('%f',R), 'pinitwindgen', ...
    sprintf('%f',pinitwindgen),'wr0',sprintf('%f',wr0),'v_vw',['[' sprintf('%f ',v_vw) ']'],'v_wr',['[' sprintf('%f ',v_wr) ']'],'m_pw',mat2str(m_pw), ...
    'v_wrdel',['[' sprintf('%f ',v_wrdel) ']'],'v_pwdel',['[' sprintf('%f ',v_pwdel) ']'],'v_wrmpp',['[' sprintf('%f ',v_wrmpp) ']'],'v_pwmpp',['[' sprintf('%f ',v_pwmpp) ']']);

set_param([powersystemdl '/WindGenerator2'],'Hw',sprintf('%f',Hw),'Tc1',sprintf('%f',Tc1),'Tc2',sprintf('%f',Tc2),'R',sprintf('%f',R), 'pinitwindgen', ...
    sprintf('%f',pinitwindgen),'wr0',sprintf('%f',wr0),'v_vw',['[' sprintf('%f ',v_vw) ']'],'v_wr',['[' sprintf('%f ',v_wr) ']'],'m_pw',mat2str(m_pw), ...
    'v_wrdel',['[' sprintf('%f ',v_wrdel) ']'],'v_pwdel',['[' sprintf('%f ',v_pwdel) ']'],'v_wrmpp',['[' sprintf('%f ',v_wrmpp) ']'],'v_pwmpp',['[' sprintf('%f ',v_pwmpp) ']']);


% tableData(:,:,i)   = zeros(length(v_vw), len_v_wr);

%[m_pw,v_wr,~,~] = fun_getwindpowercurve(0,v_vw); % get 2D table m_pw for given beta

% tableData(:,:)   = m_pw;          % fill the LUT table

% ---

% simOut = sim("SFR_WG");
% simOut3 = sim("WGmodel_v3");
% tableDataRaw = tableDataRaw(:, 2:end);  % get that first NaN column out

% tableDataReshaped   = reshape(tableDataRaw,[length(v_wr) length(v_vw) length(v_beta)]); % reshaped data into cube thingy
% tableData = reshape(repmat([4 5 6 7;16 19 20 23;10 18 23 26],1,2),[4,3,2]);


