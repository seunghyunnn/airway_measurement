%PATH setups 
path = "path to AirQuant";
addpath(path + "/library/util");
addpath(path);
AirQuantDir = AirQuantAddPath();

%Load DATA
CT_name = path + "CT-scan.nii";
seg_name = path + "Airway.nii";
skel_name = path + "Skeleton.nii";
meta = niftiinfo(CT_name);
source = double(niftiread(meta));
seg = logical(niftiread(seg_name));
skel = logical(niftiread(skel_name));

%Create AQnet and retrieve measurement 
num_rays = 799; %60; 
ray_interval = 0.5;%0.2;
AQnet = ClinicalAirways(skel, source=source, header=meta, seg=seg, fillholes=1, largestCC=1, plane_sample_sz=0.5, spline_sample_sz=0.5);
AQnet.MakeTubePatches(method='linear', gpu=0);
AQnet.Measure('AirwayFWHMesl', num_rays, ray_interval);
AQnet.ExportCSV('output.csv');
