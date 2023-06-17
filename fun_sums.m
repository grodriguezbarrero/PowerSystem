function [v_sum_pufls_delta_vw, v_sum_delta_fmin_delta_vw, v_sum_pufls_t_delta_vw, v_sum_delta_fmin_t_delta_vw] = ...
    fun_sums(m_pufls, m_fmin, fbase, ngenscenarios, m_genscenarios, t0)

v_sum_pufls_delta_vw        = zeros(1,3);
v_sum_delta_fmin_delta_vw   = zeros(1,3);
v_sum_pufls_t_delta_vw      = zeros(1,3);
v_sum_delta_fmin_t_delta_vw = zeros(1,3);

for igenscenario = ngenscenarios:-1:1

    % get generation scenario
    v_genscenario = m_genscenarios(igenscenario,:); % generation of each unit in MW    
    % get online units
    v_igenonline = find(v_genscenario>0); % a unit is online if its generation > 0 MW
    ngenonline = length(v_igenonline);

    for igenonline = 1:ngenonline
        for WGgroupsonline = 1:3
            i_delta_vw = 1;
            for delta_vw = [0, 0.5, 1]
                i_t_delta_vw = 1;
                for t_delta_vw = [t0-2, t0, t0+2]
                    
                    if delta_vw == 0
                        v_sum_pufls_delta_vw(1)       = v_sum_pufls_delta_vw(1)      + m_pufls(igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw);
                        v_sum_delta_fmin_delta_vw(1)  = v_sum_delta_fmin_delta_vw(1) + fbase - m_fmin(igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw);
                    elseif delta_vw == 0.5    
                        v_sum_pufls_delta_vw(2)       = v_sum_pufls_delta_vw(2) + m_pufls(igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw);
                        v_sum_delta_fmin_delta_vw(2)  = v_sum_delta_fmin_delta_vw(2) + fbase - m_fmin(igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw);
                    elseif delta_vw == 1
                        v_sum_pufls_delta_vw(3)       = v_sum_pufls_delta_vw(3) + m_pufls(igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw);
                        v_sum_delta_fmin_delta_vw(3)  = v_sum_delta_fmin_delta_vw(3) + fbase - m_fmin(igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw);
                    end
                    
                    if t_delta_vw == t0-2
                        v_sum_pufls_t_delta_vw(1)       = v_sum_pufls_t_delta_vw(1)        + m_pufls(igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw);
                        v_sum_delta_fmin_t_delta_vw(1)  = v_sum_delta_fmin_t_delta_vw(1) + fbase - m_fmin(igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw);
                    elseif t_delta_vw == t0  
                        v_sum_pufls_t_delta_vw(2)       = v_sum_pufls_t_delta_vw(2)        + m_pufls(igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw);
                        v_sum_delta_fmin_t_delta_vw(2)  = v_sum_delta_fmin_t_delta_vw(2) + fbase - m_fmin(igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw);
                    elseif t_delta_vw == t0+2
                        v_sum_pufls_t_delta_vw(3)       = v_sum_pufls_t_delta_vw(3)        + m_pufls(igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw);
                        v_sum_delta_fmin_t_delta_vw(3)  = v_sum_delta_fmin_t_delta_vw(3) + fbase - m_fmin(igenscenario, igenonline, WGgroupsonline, i_delta_vw, i_t_delta_vw);
                    end
                    
                    i_t_delta_vw = i_t_delta_vw + 1;
                end
                i_delta_vw = i_delta_vw + 1;
            end
        end
    end
end

%%

latexTable = sprintf('\\begin{table}[ht]\n');
latexTable = [latexTable, sprintf('    \\centering\n')];
latexTable = [latexTable, sprintf('    \\caption{Sums of the shed power and maximum deviations from the base frequency from all simulations, depending on the wind speed change.}\n')];
latexTable = [latexTable, sprintf('    \\begin{tabular}{cccc}\n')];
latexTable = [latexTable, sprintf('    \\\\')];
latexTable = [latexTable, sprintf('    \\hline\n')];
latexTable = [latexTable, sprintf('    %s & %s & %s & %s \\\\\n', ' ', '0 $m/s$', '0.5 $m/s$', '1 $m/s$')];
latexTable = [latexTable, sprintf('    %s & %.1f & %.1f & %.1f \\\\\n', '$\Sigma P_{ufls}$', v_sum_pufls_delta_vw(1), v_sum_pufls_delta_vw(2), v_sum_pufls_delta_vw(3))];
latexTable = [latexTable, sprintf('    %s & %.1f & %.1f & %.1f \\\\\n', '$\Sigma \Delta f_{min}$', v_sum_delta_fmin_delta_vw(1), v_sum_delta_fmin_delta_vw(2), v_sum_delta_fmin_delta_vw(3))];
latexTable = [latexTable, sprintf('    \\hline\n')];
latexTable = [latexTable, sprintf('    \\end{tabular}\n')];
latexTable = [latexTable, sprintf('    \\label{tb:sums_delta_vw}\n')];
latexTable = [latexTable, sprintf('\\end{table}')];

% Print the LaTeX table
disp(latexTable);

latexTable = sprintf('\\begin{table}[ht]\n');
latexTable = [latexTable, sprintf('    \\centering\n')];
latexTable = [latexTable, sprintf('    \\caption{Sums of the shed power and maximum deviations from the base frequency from all simulations, depending on the time of the wind speed change.}\n')];
latexTable = [latexTable, sprintf('    \\begin{tabular}{cccc}\n')];
latexTable = [latexTable, sprintf('    \\\\')];
latexTable = [latexTable, sprintf('    \\hline\n')];
latexTable = [latexTable, sprintf('    %s & %s & %s & %s \\\\\n', ' ', '-2 $s$', '0 $s$', '+2 $s$')];
latexTable = [latexTable, sprintf('    %s & %.1f & %.1f & %.1f \\\\\n', '$\Sigma P_{ufls}$', v_sum_pufls_t_delta_vw(1), v_sum_pufls_t_delta_vw(2), v_sum_pufls_t_delta_vw(3))];
latexTable = [latexTable, sprintf('    %s & %.1f & %.1f & %.1f \\\\\n', '$\Sigma \Delta f_{min}$', v_sum_delta_fmin_delta_vw(1), v_sum_delta_fmin_delta_vw(2), v_sum_delta_fmin_delta_vw(3))];
latexTable = [latexTable, sprintf('    \\hline\n')];
latexTable = [latexTable, sprintf('    \\end{tabular}\n')];
latexTable = [latexTable, sprintf('    \\label{tb:sums_t_delta_vw}\n')];
latexTable = [latexTable, sprintf('\\end{table}')];

% Print the LaTeX table
disp(latexTable);