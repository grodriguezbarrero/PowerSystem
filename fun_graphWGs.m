function fun_graphWGs(igenscenario, igenonline, i_delta_vw, i_t_delta_vw, c_t_wg, c_w_wg, ...
    c_pufls_wg, c_WGpenetration_wg, c_pgenWGtot_wg, c_pgentot_wg, v_colours, m_fss, m_fmin, m_pufls)

% This function shows several signals (including the frequency) for three
% different WG penetrations.

hf = figure('WindowState','maximized');
subplot(5,1,1);

for WGgroupsonline = 1:3
    plot(c_t_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
        c_w_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
        'Color',v_colours(WGgroupsonline));hold on;
end
legend('3 WGs', '6 WGs', '9 WGs');
ylabel('Freq \omega (Hz)')
hold off;

subplot(5, 1, 2);

for WGgroupsonline = 1:3
    plot(c_t_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
        c_pufls_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
        'Color',v_colours(WGgroupsonline));hold on;
end
ylabel('P_{shedded}^{UFLS} (MW)')
hold off;

subplot(5, 1, 3);

for WGgroupsonline = 1:3
    plot(c_t_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
        c_WGpenetration_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
        'Color',v_colours(WGgroupsonline));hold on;
end
ylabel('WG pen. (%)')
hold off;

subplot(5, 1, 4);

for WGgroupsonline = 1:3
    plot(c_t_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
        c_pgenWGtot_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
        'Color',v_colours(WGgroupsonline));hold on;
end
ylabel('P_{gen}^{WG} (MW)')
hold off;

subplot(5, 1, 5);

for WGgroupsonline = 1:3
    plot(c_t_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
        c_pgentot_wg{igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw}, ...
        'Color',v_colours(WGgroupsonline));hold on;
end
xlabel('Time (s)')
ylabel('P_{gen}^{tot} (MW)')
hold off;

sgt = sgtitle(['Scenario ', num2str(igenscenario), ' with the number ', num2str(igenonline), ' Bus shut off'],'Color',"#0072BD", 'interpreter','latex');
sgt.FontSize = 18;

%% LaTeX table

% Initialize LaTeX table
latexTable = sprintf('\\begin{table}[ht]\n');
latexTable = [latexTable, sprintf('    \\centering\n')];
latexTable = [latexTable, sprintf('    \\caption{Indices.}\n')];
latexTable = [latexTable, sprintf('    \\begin{tabular}{cccc}\n')];
latexTable = [latexTable, sprintf('    \\\\')];

% Add table header
latexTable = [latexTable, sprintf('    %s & %s & %s & %s \\\\\n', '$n^\circ of WGs$', '$f_{ss} (Hz)$', '$f_{min} (Hz)$', '$P_{ufls} (MW)$')];
latexTable = [latexTable, sprintf('    \\hline\n')];

% Add table content
for WGgroupsonline = 1:3
    latexTable = [latexTable, sprintf('    %d & %.4f & %.4f & %.4f \\\\\n', WGgroupsonline*3, ...
        m_fss(igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw), ...
        m_fmin(igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw), ...
        m_pufls(igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw))];
end

% Finalize LaTeX table
latexTable = [latexTable, sprintf('    \\hline\n')];
latexTable = [latexTable, sprintf('    \\end{tabular}\n')];
latexTable = [latexTable, sprintf('    \\label{tb:results}\n')];
latexTable = [latexTable, sprintf('\\end{table}')];

% Print the LaTeX table
disp(latexTable);