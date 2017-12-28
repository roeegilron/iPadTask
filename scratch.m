function scratch
hfig = figure; 
hfig.Units = 'normalized';
start = tic; 
htar = uicontrol(hfig);
htar.Units = 'normalized';
htar.Position = [ 0.5  0.9 0.1 0.1];
htar.Callback =  @targetmove; 
spaces = linspace(0.2 ,0.7,10);
drawnow; 
for i = 1:5 
    start = tic; 
    while toc(start) < 3
        drawnow; 
        val = logical(htar.Value);
        if val
            break;
            text = 'broke'
        end
        text = 'did not break';
        pause(0.01);
    end
    htar.Position(1) = spaces(randperm(length(spaces),1));
    htar.Position(2) = spaces(randperm(length(spaces),1));
    fprintf('%s\n',text);
end
% htext = uicontrol(hfig);
end

function targetmove(obj,event)
end