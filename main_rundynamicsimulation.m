function main_rundynamicsimulation

% -------------------------------------------------------------------------
% Predefined values
% -------------------------------------------------------------------------
tic

powersystemdl = 'Powersystem.slx';
load_system('Powersystem');

str_uftype      = 'uf';
str_rocoftype   = 'rocof';

fbase           = 50;
tsimulation     = 25;
t0              = 3;
numWG           = 9;

% Choose here the number of scenarios to run (from scenario 1 to 'nscenarios')
nscenarios      = 24;
    
% -------------------------------------------------------------------------
% Read input data
% -------------------------------------------------------------------------

disp('Reading data...');

xlsfilename = 'LaPalmaInputData_noESS_withoutFCUC.xls';
[status, c_sheets] = xlsfinfo(xlsfilename);

% read generator dynamic model data
m_gendata      = xlsread(xlsfilename,c_sheets{1});

 % read generation scenarios
m_genscenarios = xlsread(xlsfilename,c_sheets{3});
m_genscenarios = m_genscenarios(2:end,2:end);      % delete first row and column

v_pwg          = m_genscenarios(:, size(m_genscenarios,2)); % vector storing power generated by WGs in each scenario
m_genscenarios = m_genscenarios(1:end,1:end-1);      % delete last column

% correct max and min generation output
ngen = size(m_gendata,2)-1; % the '-1' is there to ignore the WG column
for igen = 1:ngen
    v_idxcommitted = find(m_genscenarios(:,igen)>0);
    m_gendata(6,igen) = min([m_genscenarios(v_idxcommitted,igen);m_gendata(6,igen)]); % pmax
    m_gendata(5,igen) = max([m_genscenarios(v_idxcommitted,igen);m_gendata(5,igen)]); % pmin
end

% Read Nominal Power of WG
Pn          = m_gendata(5,ngen+1);
diameter    = m_gendata(11,ngen+1);
R           = 1/m_gendata(2,ngen+1);
Hw          = m_gendata(3,ngen+1);

% read ufls parameters
[m_uflsparam,c_uflsID] = xlsread(xlsfilename,c_sheets{4}); 
[m_ufparam , m_rocofparam, v_pshed0] = ...
    fun_prepareuflsformat4simulinkformat(m_uflsparam, c_uflsID, str_uftype, str_rocoftype);

v_dfufpu = (m_ufparam(:,1)-fbase)/fbase;
v_tintuf = m_ufparam(:,3);
v_topnuf = m_ufparam(:,4);

v_dfrocofpu = (m_rocofparam(:,1)-fbase)/fbase;
v_dfdtrocofpu = m_rocofparam(:,2)/fbase;
v_tintrocof = m_rocofparam(:,3);
v_topnrocof = m_rocofparam(:,4);

% -------------------------------------------------------------------------
% Simulate all possible single generating unit outages
% -------------------------------------------------------------------------

disp('Simulation start...');

m_genscenarios  = m_genscenarios(1:nscenarios,:);
v_pwg           = v_pwg(1:nscenarios);

delta_vw        = [0, 0.5, 1];
t_delta_vw      = [t0-2, t0, t0+2];

nWGgroupsonline = 3; % 1,2 or 3 groups, equivalent to 3, 6 or 9 WGs
ndelta_vw       = length(delta_vw); % 0, 0.5, 1 m/s
nt_delta_vw     = length(t_delta_vw); % 2s before, 0s, 2s after CG loss
ngenonline      = 8; % there is at most 8 CGs per scenario

% preallocate output cells (save computation time)
c_t_wg              = cell(nscenarios, ngenonline, nWGgroupsonline, ndelta_vw, nt_delta_vw);
c_w_wg              = cell(nscenarios, ngenonline, nWGgroupsonline, ndelta_vw, nt_delta_vw);
c_pgentot_wg        = cell(nscenarios, ngenonline, nWGgroupsonline, ndelta_vw, nt_delta_vw);
c_pufls_wg          = cell(nscenarios, ngenonline, nWGgroupsonline, ndelta_vw, nt_delta_vw);
c_pgenWGtot_wg      = cell(nscenarios, ngenonline, nWGgroupsonline, ndelta_vw, nt_delta_vw);
c_WGpenetration_wg  = cell(nscenarios, ngenonline, nWGgroupsonline, ndelta_vw, nt_delta_vw);

m_fmin  = zeros(nscenarios, ngenonline, nWGgroupsonline, ndelta_vw, nt_delta_vw);
m_fss   = zeros(nscenarios, ngenonline, nWGgroupsonline, ndelta_vw, nt_delta_vw);
m_pufls = zeros(nscenarios, ngenonline, nWGgroupsonline, ndelta_vw, nt_delta_vw);

ngenscenarios = size(m_genscenarios,1);

% set fixed simulation block paramters
set_param([powersystemdl(1:end-4) '/UFLS'],'v_dfufpu',['[' sprintf('%f ',v_dfufpu) ']'],...
    'v_tintuf',['[' sprintf('%f ',v_tintuf) ']'],'v_topnuf',['[' sprintf('%f ',v_topnuf) ']'],... 
    'v_dfrocofpu',['[' sprintf('%f ',v_dfrocofpu) ']'],'v_dfdtrocofpu',['[' sprintf('%f ',v_dfdtrocofpu) ']'],...
    'v_tintrocof',['[' sprintf('%f ',v_tintrocof) ']'],'v_topnrocof',['[' sprintf('%f ',v_topnrocof) ']']); % set UFLS parameters 

set_param([powersystemdl(1:end-4) '/Perturbation'],'time',['[' sprintf('%f',t0) ']'],'Sampletime','0'); % set perturbation parameters 

set_param(powersystemdl(1:end-4),'StopTime',sprintf('%f',tsimulation));

% set fixed WG parameters
for i = 0:numWG-1
    set_param([powersystemdl(1:end-4) '/WindGenerator' int2str(i)],'R',sprintf('%f',R),'Hw',sprintf('%f',Hw));
end

% simulate each scenario
for igenscenario = ngenscenarios:-1:1
    
    fprintf('Scenario: %i', igenscenario);
    
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

    % simulate every single generator outage
    for igenonline = 1:ngenonline
        
        % remaining units
        v_iremgenonline = v_igenonline;
        v_iremgenonline(igenonline) = []; % take out the lost generator
        ngen = length(v_iremgenonline);

        % set model parameters
        fun_setsimulinkblockparameters(powersystemdl(1:end-4),ngen,m_gendata, ...
            v_genscenario,v_igenonline,igenonline,v_iremgenonline, Pn); %v_pshed0MW
        
        for WGgroupsonline = 1:3
            
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
            
            i_delta_vw = 1;

            for delta_vw = [0, 0.5, 1]
                
                % initialise the change in wind speed
                set_param([powersystemdl(1:end-4) '/Wind'],'After',['[' sprintf('%f',vw0-delta_vw) ']']);
                
                i_t_delta_vw = 1;
                
                for t_delta_vw = [t0-2, t0, t0+2]
                    
                    % initialise the time of the wind speed change
                    set_param([powersystemdl(1:end-4) '/Wind'],'time',['[' sprintf('%f',t0+t_delta_vw) ']']);
                    
                    % simulate it and store results
                    [c_t_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw},~, ...
                        c_w_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
                        c_pgentot_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
                        c_pufls_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
                        c_pgenWGtot_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
                        c_WGpenetration_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}] = sim(powersystemdl);
                    
                    % change from pu units to MWs
                    c_pgentot_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}    = ...
                        Sbase * c_pgentot_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw};
                    c_pufls_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}      = ...
                        Sbase * c_pufls_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw};
                    c_pgenWGtot_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}  = ...
                        Sbase * c_pgenWGtot_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw};
                    c_w_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}          = ...
                        fbase + fbase * c_w_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw};
                    
                    % store igenscenario characteristics
                    m_fss(igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw)      = ...
                        c_w_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}(end);
                    m_fmin(igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw)      = ...
                        min(c_w_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw});
                    m_pufls(igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw)    = ...
                        c_pufls_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}(end);
                    

                    i_t_delta_vw = i_t_delta_vw + 1;
                end
                i_delta_vw = i_delta_vw + 1;
            end
        end
    end
end

disp('Simulation stops.');

% close_system(powersystemdl,0);

%% ------------------------------------------------------------------------
% Display frequency deviation (among other things) for different parameters
% -------------------------------------------------------------------------

v_colours   = ["#EDB120" "#7E2F8E" "#77AC30" "#4DBEEE" "#A2142F" "#AE43F0" "#0076A8" "#0072BD" "#D95319"];

% ===> Choose parameters to print out their simulation here
igenscenario    = 24; % scenario 1, 2, ... 24
igenonline      = 1; % bus number being disconnected
WGgroupsonline  = 1; % 1, 2, 3 WGs groups (so 3, 6, 9 WGs)
i_delta_vw      = 1; % 0, 0.5, 1 m/s
i_t_delta_vw    = 1; % 2s before, 0s, 2s after
nscenarios      = 1; % 1, 2, ... 24

%% 

fun_graphScenarios(igenonline, WGgroupsonline, i_t_delta_vw, i_delta_vw, nscenarios, c_t_wg, c_w_wg, c_pufls_wg, c_WGpenetration_wg, c_pgenWGtot_wg, c_pgentot_wg, v_colours, m_fss, m_fmin, m_pufls)

fun_graphGeneratorLoss(igenscenario, WGgroupsonline, i_t_delta_vw, i_delta_vw, m_genscenarios, c_t_wg, c_w_wg, c_pufls_wg, c_WGpenetration_wg, c_pgenWGtot_wg, c_pgentot_wg, v_colours, m_fss, m_fmin, m_pufls)

fun_graphWGs(igenscenario, igenonline, i_delta_vw, i_t_delta_vw, c_t_wg, c_w_wg, c_pufls_wg, c_WGpenetration_wg, c_pgenWGtot_wg, c_pgentot_wg, v_colours, m_fss, m_fmin, m_pufls)

fun_graphWindSpeed(igenscenario, igenonline, WGgroupsonline, i_t_delta_vw, c_t_wg, c_w_wg, c_pufls_wg, c_WGpenetration_wg, c_pgenWGtot_wg, c_pgentot_wg, v_colours, m_fss, m_fmin, m_pufls)

fun_graphWindTiming(igenscenario, igenonline, WGgroupsonline, i_delta_vw, c_t_wg, c_w_wg, c_pufls_wg, c_WGpenetration_wg, c_pgenWGtot_wg, c_pgentot_wg, v_colours, m_fss, m_fmin, m_pufls)

[v_sum_pufls_delta_vw, v_sum_delta_fmin_delta_vw, v_sum_pufls_t_delta_vw, v_sum_delta_fmin_t_delta_vw] = ...
    fun_sums(m_pufls, m_fmin, fbase, ngenscenarios, m_genscenarios, t0);

fun_sim_no_droop(powersystemdl, igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw, ...
   c_t_wg, c_w_wg, c_pufls_wg, c_WGpenetration_wg, c_pgenWGtot_wg, c_pgentot_wg, t0, numWG, m_genscenarios, m_gendata, v_pshed0, v_pwg, Pn, diameter, fbase);

toc