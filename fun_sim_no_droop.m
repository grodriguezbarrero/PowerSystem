function fun_sim_no_droop(powersystemdl, igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw, ...
   c_t_wg, c_w_wg, c_pufls_wg, c_WGpenetration_wg, c_pgenWGtot_wg, c_pgentot_wg, t0, numWG, m_genscenarios, m_gendata, v_pshed0, v_pwg, Pn, diameter, fbase)

load_system(powersystemdl(1:end-4));

% ================ Set droop ================
R = 10e99;
for i = 0:numWG-1
    set_param([powersystemdl(1:end-4) '/WindGenerator' int2str(i)],'R',sprintf('%f',R));
    %set_param([powersystemdl(1:end-4) '/WindGenerator' int2str(i)],'R',R);
end
% ModelParameterNames = get_param([powersystemdl(1:end-4) '/WindGenerator' int2str(i)],'ObjectParameters')

% ============= Set parameters ==============

switch i_delta_vw
    case 1
        delta_vw = 0;
    case 2
        delta_vw = 0.5;
    case 3
        delta_vw = 1;
    otherwise
        delta_vw = 0;
end

switch i_t_delta_vw
    case 1
        t_delta_vw = -2;
    case 2
        t_delta_vw = 0;
    case 3
        t_delta_vw = 2;
    otherwise
        t_delta_vw = -2;
end

pinitwindgen = v_pwg(igenscenario); % in MW
    
% initialise the WGs for each scenario
[vw0, wr0, pinitwindgen, ~, ~, ~, ~, ~, ~,~,~] = fun_WGmodel_startup(powersystemdl(1:end-4), pinitwindgen, Pn, diameter); % in pu

for i = 0:numWG-1
    set_param([powersystemdl(1:end-4) '/WindGenerator' int2str(i)],'pinitwindgen',sprintf('%f',pinitwindgen),'wr0',sprintf('%f',wr0));
end

% initialise initial wind speed
set_param([powersystemdl(1:end-4) '/Wind'], 'Before',['[' sprintf('%f',vw0) ']']);

% get generation scenario
v_genscenario = m_genscenarios(igenscenario,:); % generation of each unit in MW
pdem_CG = sum(v_genscenario); % demand = sum of generation (in MW)

% get online units
v_igenonline = find(v_genscenario>0); % a unit is online if its generation > 0 MW
ngenonline = length(v_igenonline);

% remaining units
v_iremgenonline = v_igenonline;
v_iremgenonline(igenonline) = []; % take out the lost generator
ngen = length(v_iremgenonline);

% set model parameters
fun_setsimulinkblockparameters(powersystemdl(1:end-4),ngen,m_gendata, ...
v_genscenario,v_igenonline,igenonline,v_iremgenonline, Pn); %v_pshed0MW

% ----

% base power to convert everything in pu on system basis
v_Mbase = m_gendata(4,v_iremgenonline);
Sbase = sum(v_Mbase);

pdem = pdem_CG + WGgroupsonline*3*pinitwindgen*Pn;  % total demand in MW (Pn = 1.5 MW)
v_pshed0MW = v_pshed0/100*pdem;                    

v_pshed0pu = v_pshed0MW/Sbase;
% set UFLS parameters (step size only)
set_param([powersystemdl(1:end-4) '/UFLS'],'v_pshed0pu',['[' sprintf('%f ',v_pshed0pu) ']']);

% set the right number of WGs
set_param([powersystemdl(1:end-4) '/numWG'],'Value',['[' sprintf('%f',WGgroupsonline) ']']);

% ----

% initialise the change in wind speed
set_param([powersystemdl(1:end-4) '/Wind'],'After',['[' sprintf('%f',vw0-delta_vw) ']']);

% ----

% initialise the time of the wind speed change
set_param([powersystemdl(1:end-4) '/Wind'],'time',['[' sprintf('%f',t0+t_delta_vw) ']']);

% ----

% ================ Simulate ================

c_t_nodroop             = cell(1);
c_w_nodroop             = cell(1);
c_pgentot_nodroop       = cell(1);
c_pufls_nodroop         = cell(1);
c_pgenWGtot_nodroop     = cell(1);
c_WGpenetration_nodroop = cell(1);

[c_t_nodroop,~, c_w_nodroop, c_pgentot_nodroop, c_pufls_nodroop, ...
    c_pgenWGtot_nodroop, c_WGpenetration_nodroop] = sim(powersystemdl);

% change from pu units to MWs
c_pgentot_nodroop       = Sbase * c_pgentot_nodroop;
c_pufls_nodroop         = Sbase * c_pufls_nodroop;
c_pgenWGtot_nodroop     = Sbase * c_pgenWGtot_nodroop;
c_w_nodroop             = fbase + fbase * c_w_nodroop;

hf = figure('WindowState','maximized');
subplot(5,1,1);

plot(c_t_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
    c_w_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
    'Color',"#EDB120");hold on;
plot(c_t_nodroop, c_w_nodroop,'Color',"#7E2F8E");hold on;

legend('Droop', 'No droop');
ylabel('Freq \omega (Hz)')
hold off;

subplot(5, 1, 2);

plot(c_t_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
    c_pufls_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
    'Color',"#EDB120");hold on;
plot(c_t_nodroop, c_pufls_nodroop,'Color',"#7E2F8E");hold on;
ylabel('P_{shed}^{UFLS} (MW)')
hold off;

subplot(5, 1, 3);

plot(c_t_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
    c_WGpenetration_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
    'Color',"#EDB120");hold on;
plot(c_t_nodroop, c_WGpenetration_nodroop,'Color',"#7E2F8E");hold on;
ylabel('WG pen. (%)')
hold off;

subplot(5, 1, 4);

plot(c_t_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
    c_pgenWGtot_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
    'Color',"#EDB120");hold on;
plot(c_t_nodroop, c_pgenWGtot_nodroop,'Color',"#7E2F8E");hold on;
ylabel('P_{gen}^{WG} (MW)')
hold off;

subplot(5, 1, 5);

plot(c_t_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
    c_pgentot_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
    'Color',"#EDB120");hold on;
plot(c_t_nodroop, c_pgentot_nodroop,'Color',"#7E2F8E");hold on;
xlabel('Time (s)')
ylabel('P_{gen}^{tot} (MW)')
hold off;

sgt = sgtitle(['Scenario ', num2str(igenscenario), ' with the number ', num2str(igenonline), ' Bus shut off'],'Color',"#0072BD", 'interpreter','latex');
sgt.FontSize = 18;