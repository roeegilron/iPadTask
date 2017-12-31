function MAIN()
hfig = setupExperiment();
%% jitter time line 
%% multiple targets 

end

function hfig = setupExperiment()
addpath(genpath(fullfile(pwd,'toolboxes')));
params = getparams();
handles = struct();
hfig = figure('UserData',handles); 
hfig.UserData.handles.params = params; 
hfig.UserData.handles.state = 1; % fixation;
hax = axes();
hax.Units = 'normalized';
hax.Box = 'off';
hax.XTick = [];
hax.YTick = [];
hold on; 
axis off 
grid off 
screen = get(0,'ScreenSize');
hfig.Units = 'normalized';
hax.Position = [0 0 1 1]; % make axes take up whole screen 
hfig.OuterPosition = [0 0 screen(3), screen(4)+40];
undecorateFig(hfig);
xlim([0 1]); 
ylim([0 1]);
%% setup trigger 
hfig.UserData.handles.sp = BioSemiSerialPort();
%% setup log file 
fn = sprintf('ipadtask_%s.txt', strrep(datestr(clock,31),':','-'));

mkdir(fullfile('..','logs'));
ffn = fullfile('..','logs',fn);
fid = fopen(ffn,'w+'); 
hfig.UserData.handles.fid = fid; 

dat.pressed = 0;
%% fixation 
hsca = scatter(0.5,0.5,params.size,'filled','MarkerFaceColor','r',...
    'ButtonDownFcn',@fixpressed,...
    'UserData',dat,...
    'Visible','on');
hfig.UserData.handles.hsca = hsca; 
%% target button 
htar = scatter(0.8,0,params.size,'filled','MarkerFaceColor','b',...
    'ButtonDownFcn',@buttonpressed,...
    'UserData',dat,...
    'Visible','off');
hfig.UserData.handles.htar = htar; 
%% run one trial button  
hrunOneTrial = text(gca,0.9,0.1,'Run One Trial');
hrunOneTrial.Rotation = 90;
hrunOneTrial.FontSize = 20;
hrunOneTrial.EdgeColor = [0.8 0.8 0.8];
hrunOneTrial.BackgroundColor = [0.9 0.9 0.9];
hrunOneTrial.LineWidth = 2;
hrunOneTrial.Margin = 15;
hrunOneTrial.ButtonDownFcn = @runOneTrial;
hfig.UserData.handles.hrunOneTrial = hrunOneTrial;
%% run experiment 
hrunExperiment = text(gca,0.9,0.8,'Run Experiment');
hrunExperiment.Rotation = 90;
hrunExperiment.FontSize = 20;
hrunExperiment.EdgeColor = [0.8 0.8 0.8];
hrunExperiment.BackgroundColor = [0.9 0.9 0.9];
hrunExperiment.LineWidth = 2;
hrunExperiment.Margin = 15;
hrunExperiment.ButtonDownFcn = @runExperiment;
hfig.UserData.handles.hrunExperiment = hrunExperiment;

%% run experiment 
hTestTrigger = text(gca,0.9,0.4,'Test Trigger');
hTestTrigger.Rotation = 90;
hTestTrigger.FontSize = 20;
hTestTrigger.EdgeColor = [0.8 0.8 0.8];
hTestTrigger.BackgroundColor = [0.9 0.9 0.9];
hTestTrigger.LineWidth = 2;
hTestTrigger.Margin = 15;
hTestTrigger.ButtonDownFcn = @TestTrigger;
hfig.UserData.handles.hTestTrigger = hTestTrigger;

% myDataStr = evalc('disp(params)');
% myDataStr2 = strrep(myDataStr, sprintf('\n'), '<br />');
% set(hrunExperiment, 'TooltipString', ['<html><pre><font face="courier new">' myDataStr2 '</font>'])

%% close figure 
hClose = text(gca,0.05,0.05,'x');
hClose.Rotation = 90;
hClose.FontSize = 20;
hClose.EdgeColor = [0.8 0.8 0.8];
hClose.BackgroundColor = [0.9 0.9 0.9];
hClose.LineWidth = 2;
hClose.Margin = 15;
hClose.ButtonDownFcn = @closeFigure;
hfig.UserData.handles.hClose = hClose;

drawnow;
end

function TestTrigger(obj,event)
hfig = gcf;
hfig.UserData.handles.sp.testTriggers
end

function closeFigure(obj,event)
hfig = gcf;
fid = hfig.UserData.handles.fid;
sp  = hfig.UserData.handles.sp;
delete(hfig); 
try
    fclose(fid);
    fclose(sp);
catch
    warning('issues with closing serial port and or log file');
end

end

function runExperiment(obj,event)
hfig = gcf;
params = hfig.UserData.handles.params;
%% set loop 
hfig.UserData.handles.startT = tic;
for i = 1:params.trials % loop on trials 
    title(sprintf('trial %d fixation started',i));
    runTrial(hfig,params,i); 
end

end

function runTrial(hfig,params,trialnum)
buttonMask(hfig,'hide');
%% fixation 
moveTargetRandom(hfig);
hsca = hfig.UserData.handles.hsca;
htar = hfig.UserData.handles.htar;
hfig.UserData.handles.state = 1; % fixation 
% choose random location for target to start at 

% wait for prep time params.trials      = 5.0;  % number of trials (blocks) 
hsca.Visible = 'on'; % show the middle dot 
drawnow; 
waitFor(params.fixation); % fixation 

%% preperations 
title(sprintf('prep trial %d started',trialnum));
hfig.UserData.handles.state = 2; % preperation 
htar.MarkerFaceColor = 'b'; % show target after fixation 
htar.Visible = 'on';% show target after fixation 
drawnow; 
waitFor(params.preperation);  % wait for prep 
hsca.MarkerFaceColor = 'g';  % change fixation to go 
drawnow; 
%% movement 
hfig.UserData.handles.userpressed = 0;
hfig.UserData.handles.state = 3; %movement

hfig.UserData.handles.htar.UserData.movecount = 0; % have not moved. 
hfig.UserData.handles.htar.UserData.totalmoves = params.step; % have not moved. 
while hfig.UserData.handles.htar.UserData.movecount <= params.step
    mvcnt = hfig.UserData.handles.htar.UserData.movecount;
    hfig.UserData.handles.userpressed = 0; % set pressed to zero 
%     ttluse = sprintf('mov %d/%d',mvcnt,params.step);title(ttluse);
    % fix move steps probelm - it moves a bunch in between steps introduce
    % step counter 
    startMove = tic; 
    while toc(startMove) < params.movement % while time exists  
        pause(0.01);
    end
    didpress = hfig.UserData.handles.userpressed; % read press state 
    if ~didpress
        moveTarget(hfig)
    end
end
htar.Visible = 'off';% hide target at end of trial 
hsca.MarkerFaceColor = 'r';  % change fixation to stop 
drawnow; 
buttonMask(hfig,'show');
end

function fixpressed(obj,event)
end

function buttonpressed(obj,event)
hfig = get(gcf);
if hfig.UserData.handles.state == 3 
    hfig.UserData.handles.userpressed = 1;
    moveTarget(hfig);
else % report pressed during other state 
end
    

% hfig.UserData.handles.htar.UserData.pressed = 1;
end

function waitFor(timewait)
startt = tic;
while toc(startt) < timewait
end
end

function moveTarget(hfig)
hfig.UserData.handles.htar.UserData.movecount = hfig.UserData.handles.htar.UserData.movecount + 1;
m = hfig.UserData.handles.htar.UserData.movecount;
total =  hfig.UserData.handles.htar.UserData.totalmoves;
if logical(hfig.UserData.handles.userpressed)
    ttluse = sprintf('mov %d/%d user pressed',m,total);title(ttluse);
    hfig.UserData.handles.userpressed = 0;
else
    ttluse = sprintf('mov %d/%d user did not press',m,total);title(ttluse);
end

targetloc = hfig.UserData.handles.params.targetloc;
x = hfig.UserData.handles.htar.XData; 
y = hfig.UserData.handles.htar.YData; 
postargidx = ~ismember(targetloc,[x y], 'rows');
postargets = targetloc(postargidx,:);
rowidx = randperm(size(postargets,1),1); % choose a random target from possible targets 
hfig.UserData.handles.htar.XData = postargets(rowidx,1);
hfig.UserData.handles.htar.YData = postargets(rowidx,2);

drawnow;
end

function moveTargetRandom(hfig)
targetloc = hfig.UserData.handles.params.targetloc;
postargets = targetloc;
rowidx = randperm(size(postargets,1),1); % choose a random target from possible targets 
hfig.UserData.handles.htar.XData = postargets(rowidx,1);
hfig.UserData.handles.htar.YData = postargets(rowidx,2);
end

function runOneTrial(obj,event)

hfig = gcf; 
buttonMask(hfig,'hide');
runTrial(hfig,hfig.UserData.handles.params,1); 
buttonMask(hfig,'show');
end

function buttonMask(hfig,task)
switch task 
    case 'hide'
        hfig.UserData.handles.hrunOneTrial.Visible = 'off';
        hfig.UserData.handles.hrunExperiment.Visible = 'off';
    case 'show'      
        hfig.UserData.handles.hrunOneTrial.Visible = 'on';
        hfig.UserData.handles.hrunExperiment.Visible = 'on';
end
end
