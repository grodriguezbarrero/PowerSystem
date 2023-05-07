function [m_ufparam, m_rocofparam, v_pshed0, ...
    v_idxuf,v_idxrocofonly,v_idxrocofcmn] = fun_prepareuflsformat4simulinkformat(m_uflsparam, c_uflsID, str_uftype, str_rocoftype)

% fun_prepareuflsformat4simulinkformat
% Prepares the conversion of the format of the UFLS input to the format of
% the UFLS implementation required by Simulink
%
% m_ufparam:        matrix containing the parameters of the uf stages of
%                   dimension nstages x 1
% m_rocofparam:     matrix containing the parameters of the rocof stages of
%                   dimension nstages x 1
% v_idxuf:          vector of indices of m_uflsparam pointing to uf stages
% v_idxrocofcmn:    vector of indices of m_uflsparam pointing to rocof
%                   stages common to uf stages
% v_idxrocofonly:   vector of indices of m_uflsparam pointing to pure rocof
%                   stages
% v_pshed0:         vector of sheddable load nin % of demand of dimension
%                   nstages x 1
%
% The v_idx vectors will be used to convert the UFLS optimization output
% format to the format required by Simulink.

% retrieve sheddable load (in % of demand)
v_pshed0 = m_uflsparam(:,end); 

% retrieve and separate uf and rocof stages
c_relaytype = c_uflsID(2:end,1);
v_idxuf = find(strcmp(str_uftype,c_relaytype)); % get uf stages
v_idxrocof = find(strcmp(str_rocoftype,c_relaytype)); % get rocof stages
nufstages = length(v_idxuf);
nrocofstages = length(v_idxrocof);
nstages =  nufstages + nrocofstages; % efective number of stages

% retrieve uf and rocof stage IDs (substation bus numbers) and get common
% stages
v_ufID = m_uflsparam(v_idxuf,1); % get uf ID: nufstages x 1 vector
v_rocofID = m_uflsparam(v_idxrocof,1); % get rocof ID: nrocofstages x 1 vector
[v_IDcmn,v_idxcmnIDuf,v_idxcmnIDrocof] = intersect(v_ufID,v_rocofID); % get common stages (both uf and rocof)

% create two parameter sets of equal dimensions: 1 for uf stages (without rocof stages), 1 for
% rocof stages (without uf stages)
m_ufparam = zeros(nstages,5); % m_ufparam and m_rocofparam same size
m_rocofparam = zeros(nstages,5); 

% assign uf parameters to uf stages only
m_ufparam(v_idxuf,:) = m_uflsparam(v_idxuf,2:end);

% assign rocof parameters to rocof stages
v_idxrocofcmn = v_idxcmnIDrocof + nufstages;
v_idxrocofonly = setdiff(v_idxrocof,v_idxrocof(v_idxcmnIDrocof)); % pure rocof stages
m_rocofparam(v_idxcmnIDuf,:) = m_uflsparam(v_idxrocofcmn,2:end); % rocof stages common to uf stages
m_rocofparam(v_idxrocofonly,:) = m_uflsparam(v_idxrocofonly,2:end); % pure rocof stages

v_pshed0(v_idxrocofcmn) = 0; % set pshed at those rocof stages common to uf stages to zero (just to be sure)
