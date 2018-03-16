nrun = size(subjects,2); % enter the number of runs here
jobfile = {};
jobfile{3} = {[scriptdir 'module_univariate_1run_complex_job.m']};
jobfile{4} = {[scriptdir 'module_univariate_1run_complex_job.m']};
inputs = cell(0, nrun);

for crun = 1:nrun
    theseepis = find(strncmp(blocksout{crun},'Run',3));
    outpath = [preprocessedpathstem subjects{crun} '/'];
    filestoanalyse = cell(1,length(theseepis));
    
    tempDesign = module_get_complex_event_times(subjects{crun},dates{crun},length(theseepis),minvols(crun));
    
    inputs{1, crun} = cellstr([outpath 'stats_test']);
    for sess = 1
        filestoanalyse{sess} = spm_select('ExtFPList',outpath,['^s3wtopup_' blocksin{crun}{theseepis(sess)}],1:minvols(crun));
        inputs{(100*(sess-1))+2, crun} = cellstr(filestoanalyse{sess});
        for cond_num = 1:80
            inputs{(100*(sess-1))+2+cond_num, crun} = cat(2, tempDesign{sess}{cond_num})';
        end
        for cond_num = 81:96 %Response trials
            inputs{(100*(sess-1))+2+cond_num, crun} = cat(2, tempDesign{sess}{cond_num+32})';
        end
        for cond_num = 97 %Button press
            inputs{(100*(sess-1))+2+cond_num, crun} = cat(2, tempDesign{sess}{81})';
        end
        for cond_num = 98 %Absent sound (written only)
            inputs{(100*(sess-1))+2+cond_num, crun} = cat(2, tempDesign{sess}{129})';
            %inputs{(100*(sess-1))+2+cond_num, crun} = [0];
        end
        inputs{(100*(sess-1))+101, crun} = cellstr([outpath 'rp_topup_' blocksin{crun}{theseepis(sess)}(1:end-4) '.txt']);
    end
    jobs{crun} = jobfile{length(theseepis)};
    
end

SPMworkedcorrectly = zeros(1,nrun);
parfor crun = 1:nrun
    spm('defaults', 'fMRI');
    spm_jobman('initcfg')
    try
        spm_jobman('run', jobs{crun}, inputs{:,crun});
        SPMworkedcorrectly(crun) = 1;
    catch
        SPMworkedcorrectly(crun) = 0;
    end
end
