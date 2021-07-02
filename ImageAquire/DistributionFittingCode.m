base_folder = uigetdir();
cd(base_folder);

folder_to_open = 'yellow_Ion_rec_00008';

num_files = 100;

freq_steps = 1000;

dwell_time = 8; %ms

num_counts = zeros(freq_steps,num_files);

    for file_numb = 1:num_files

    file_name = strcat(char(folder_to_open), '_', int2str(file_numb), '.txt');

    [A,B,C,D] = textread(char(file_name),'%s %s %s %s',-1);
    
    num_counts(:,file_numb) = str2double(B(2:end)) * (dwell_time/ 1000);

    end
    %%
    count_distribution = (reshape(num_counts,1,(freq_steps) * num_files));
    
    figure;
    subplot(2,1,1)
    hist(count_distribution,200,'Normalization','probability');
    xlabel('Number of Photons');
    ylabel('Probability');
    
    set(gcf, 'color', 'w')
    set(gca, 'fontsize', 20)

    set(gca, 'YScale', 'log')

    x_vec = 0:max(count_distribution);
    subplot(2,1,2)
    
    lambda = mean(count_distribution);
    plot(x_vec, exp(-lambda) .* lambda.^(x_vec) ./ factorial(x_vec))
    
        set(gcf, 'color', 'w')
    set(gca, 'fontsize', 20)