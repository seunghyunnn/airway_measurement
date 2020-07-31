% By Ashkan Pakzad, 2020. ashkanpakzad.github.io

%% Set-up directories
% names input files, give fullpaths if not in matlab path
% add AirQuant library to path
AirQuantDir = AirQuantAddPath();
results_dir = fullfile(AirQuantDir,'results');
casename = 'github_demo';

%% Get filenames
CT_name = [casename, '_raw.nii.gz'];
seg_name = [casename, '_seg.nii.gz'];
skel_name = [casename, '_seg_PTKskel.nii.gz'];

% Load CT data as double
meta = niftiinfo(CT_name);
CT = double(niftiread(meta));

% Load Airway segmentation and its skeleton as logicals
S = logical(niftiread(seg_name));
skel = logical(niftiread(skel_name));

%% Initialise AirQuant
% Parses CT, segmentation and skeleton to compute airway tree graph
% savename is given to automatically save/load results.
savename = fullfile(results_dir, [casename, '_AQ.mat']);
AQ = AirQuant(CT, meta, S, skel, savename);

%% Display Airway Graph in 3D and 2D
figure
PlotTree(AQ)

figure
plot(AQ)

%% compute lobes
AQ = ComputeAirwayLobes(AQ);
figure; PlotMap3D(AQ, 'Lobe');
% Generatlly use the save function when AQ given and returned by function.
save(AQ) 
% MATLAB's colourcoding can be a little buggy when viewing results.
% Note that the upper left lobe's lingular is treated seperately. An
% emulation of the middle lobe in the right lung. The Airway segmentation
% must reach all anatomical lobes for this function to be successful.

%% Plot the skeleton inside the segmentation
figure
patch(isosurface(S),'EdgeColor', 'none','FaceAlpha',0.3);
hold on
isosurface(skel)
axis vis3d

%% traverse the first indexed airway, measure and display results
% this may take a few minutes
idx = 26;
tic;
AQ = CreateAirwayImage(AQ, idx);
AQ = FindAirwayBoundariesFWHM(AQ, idx);
disp(toc/60)

PlotAirway3(AQ, idx)
% AirQuant doesn't save tapering measurements automatically 
% (only interpolated slices), so we can manually invoke the save method after
% performing measurements on a single branch.
save(AQ)

%% traverse all airway 
% this could take a number of hours, results will be saved along the way so
% can be interrupted.
tic;
AQ = AirwayImageAll(AQ);
time = toc;
disp(toc/60)

%% compute area of all airways
% This should only take a few minutes and automatically saves once all
% measurements are complete.
AQ = FindFWHMall(AQ);

%% Analysis
report = debuggingreport(AQ);

%% Construct single taper gradient path
terminalbranchlist = ListTerminalBranches(AQ); % list of terminal branches
terminal_link_idx = terminalbranchlist(1);
% get branch data for carina to terminal branch.
[logtaperrate, cum_arclength, cum_area, path] = ConstructTaperPath(AQ, terminal_link_idx); 
figure
plot(cum_arclength, cum_area);

%% Compute taper gradient path of all terminal branches
% Table with all carina-terminal branch data.
% running ComputeAirwayLobes before this function will group output by lobe.
AllTaperResults = ComputeTaperAll(AQ);

%% Display taper results of a single gradient path
figure
PlotTaperResults(AQ, AllTaperResults.terminalbranch(1))
