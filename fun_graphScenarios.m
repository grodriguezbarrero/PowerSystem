function fun_graphScenarios(igenonline, WGgroupsonline, i_t_delta_vw, i_delta_vw, nscenarios, c_t_wg, c_w_wg, c_pufls_wg, c_WGpenetration_wg, c_pgenWGtot_wg, c_pgentot_wg, v_colours, m_fss, m_fmin, m_pufls)

% This function shows several signals (including the frequency) with
% different scenarios
% igenonline = 2 is of particular interest; the same amount of power (2.35
% MW) gets disconnected almost everytime

hf = figure('WindowState','maximized');
subplot(5,1,1);

% labels = cellstr(num2str((1:ngenonline)'));
labels = cellstr(num2str((1:nscenarios)', 'Scen. %d'));

for igenscenario = 1:nscenarios
    plot(c_t_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
        c_w_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
        'Color',v_colours(igenscenario));hold on;
end
legend(labels);
ylabel('Freq \omega (Hz)')
hold off;

subplot(5, 1, 2);

for igenscenario = 1:nscenarios
    plot(c_t_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
        c_pufls_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
        'Color',v_colours(igenscenario));hold on;
end
ylabel('P_{shedded}^{UFLS} (MW)')
hold off;

subplot(5, 1, 3);

for igenscenario = 1:nscenarios
    plot(c_t_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
        c_WGpenetration_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
        'Color',v_colours(igenscenario));hold on;
end
ylabel('WG pen. (%)')
hold off;

subplot(5, 1, 4);

for igenscenario = 1:nscenarios
    plot(c_t_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
        c_pgenWGtot_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
        'Color',v_colours(igenscenario));hold on;
end
ylabel('P_{gen}^{WG} (MW)')
hold off;

subplot(5, 1, 5);

for igenscenario = 1:nscenarios
    plot(c_t_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
        c_pgentot_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
        'Color',v_colours(igenscenario));hold on;
end
xlabel('Time (s)')
ylabel('P_{gen}^{tot} (MW)')
hold off;

sgt = sgtitle(['Loss of generator ', num2str(igenonline)],'Color',"#0072BD", 'interpreter','latex');
sgt.FontSize = 18;

%%

% Define column names
columnNames = {'Scenario', '$f_{ss}$', '$f_{min}$', '$p_{ufls}$'};

% Initialize LaTeX table
latexTable = sprintf('\\begin{table}[ht]\n');
latexTable = [latexTable, sprintf('\\centering\n')];
latexTable = [latexTable, sprintf('\\caption{Table.}\n')];
latexTable = [latexTable, sprintf('\\\\n')];
latexTable = [latexTable, sprintf('\\begin{tabular}{cccc}\n')];

% Add table header
latexTable = [latexTable, sprintf('    %s & %s & %s & %s \\\\\n', 'Scenario', '$f_{ss} (Hz)$', '$f_{min} (Hz)$', '$P_{ufls} (MW)$')];
latexTable = [latexTable, sprintf('\\hline\n')];

% Add table content
for igenscenario = 1:nscenarios
    latexTable = [latexTable, sprintf('    %d & %.4f & %.4f & %.4f \\\\\n', igenscenario, ...
        m_fss(igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw), ...
        m_fmin(igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw), ...
        m_pufls(igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw))];
end

% Finalize LaTeX table
latexTable = [latexTable, sprintf('\\hline\n')];
latexTable = [latexTable, sprintf('\\end{tabular}\n')];
latexTable = [latexTable, sprintf('\\label{tb:results}\n')];
latexTable = [latexTable, sprintf('\\end{table}')];

% Print the LaTeX table
disp(latexTable);

