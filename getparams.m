function params = getparams()
%% Set params for experiment 
params.trials      = 10.0;  % number of trials (blocks) 
params.size        = 7e3; % size of the marker 
params.fixation    = 4.0; % fixation time 
params.preperation = 3.0; % time (secs) for movement prep 
params.movement    = 3.0; % time for each movement 
params.step        = 4.0; % number of steps (reaches)  

params.targetloc   = [0.8 0.5; ...
                      0.2 0.5; ... 
                      0.5 0.8; ...
                      0.5 0.2];
                   
params.targetloc   = [0.8 0.5; ...
                      0.2 0.5];
params.screensize  = get(groot,'ScreenSize');
end