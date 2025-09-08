clear; 
close all; 
clc;

device = serialport("COM12",9600);
device.Timeout = 0.3;
flush(device);
figure; 
ax = polaraxes; 
hold(ax,'on')
ax.ThetaZeroLocation = 'right';
ax.ThetaDir = 'counterclockwise';
thetalim(ax,[0,180]);
thetaticks(ax,0:30:180);
ax.RAxisLocation = 0;
rlim(ax,[0 50]);

h = polarscatter(ax,[],[],20,[],'filled','MarkerFaceAlpha','flat');
set(h, 'AlphaDataMapping','none');
cmap = lines(13);
theta = [];
r     = [];
C     = [];
des   = [];
posCounter = 0;
tol = 1e-3;

while true
if device.NumBytesAvailable == 0
    pause(0.05);
    if ~ishandle(h), 
        break; 
    end
    continue
end
try
    line = strtrim(readline(device));
catch ME
    if contains(lower(ME.message),'timeout')
        continue 
    else
        rethrow(ME)
    end
end

if isempty(line) || startsWith(line,"#")
    continue  
end

    if isempty(line), continue; end
    parts = split(line,',');
    if numel(parts) < 3, continue; end
    angDeg = str2double(parts{1});
    avgCm  = str2double(parts{2});
    reads  = str2double(parts(3:end));
    reads(~isfinite(reads)) = avgCm;
    if isempty(reads) || ~isfinite(angDeg), continue; end
    posCounter = posCounter + 1;
    idx = 1 + mod(posCounter-1, size(cmap,1));
    rgb = cmap(idx, :);  
    n = numel(reads);

    theta = [theta; repmat(deg2rad(angDeg), n+1, 1)];
    r = [r;avgCm; reads(:)];
    C = [C; repmat(rgb, n+1, 1)];
    des = [des; 1; 0.5*ones(n,1)];  

    if numel(theta) > 11
        last_angle = theta(end);
        prev_angle = theta(end-11);
        if (abs(last_angle - deg2rad(150)) < tol && abs(prev_angle - deg2rad(140)) < tol) ||(abs(last_angle - deg2rad(30))  < tol && abs(prev_angle - deg2rad(40))  < tol)
            theta = []; r = []; C = [];
            des = [];
            posCounter = 0;
        end
    end
    set(h,'ThetaData',theta,'RData',r,'CData',C, 'AlphaData',des);
    legend('Ultrasonic Data','Location','southoutside');
    title('2D Range Finder Mapping');
    drawnow limitrate
end
